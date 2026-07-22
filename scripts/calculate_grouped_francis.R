#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (!length(args) %in% 2:3) {
  stop(
    "Usage: calculate_grouped_francis.R model_payload.rds output-directory [source-job]",
    call. = FALSE
  )
}

payload_path <- normalizePath(args[[1L]], mustWork = TRUE)
output_dir <- args[[2L]]
source_job <- if (length(args) == 3L) as.integer(args[[3L]]) else NA_integer_
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

required <- c("mfk_francis_ta18", ".mfk_francis_apply_tail_mapping")
if (requireNamespace("mfclkit", quietly = TRUE)) {
  ns <- asNamespace("mfclkit")
} else {
  ns <- new.env(parent = globalenv())
}
missing <- required[!vapply(required, exists, logical(1L), envir = ns,
                            inherits = FALSE)]
source_file <- Sys.getenv("MFCLKIT_FRANCIS_R", unset = "")
if (length(missing) && nzchar(source_file) && file.exists(source_file)) {
  ns <- new.env(parent = globalenv())
  sys.source(source_file, envir = ns)
  missing <- required[!vapply(required, exists, logical(1L), envir = ns,
                              inherits = FALSE)]
}
if (length(missing)) {
  stop("Required mfclkit functions are unavailable: ",
       paste(missing, collapse = ", "),
       ". Install mfclkit commit 0272c9d or set MFCLKIT_FRANCIS_R.",
       call. = FALSE)
}
francis_ta18 <- get("mfk_francis_ta18", envir = ns, inherits = FALSE)
apply_tail_mapping <- get(".mfk_francis_apply_tail_mapping", envir = ns,
                          inherits = FALSE)

payload <- readRDS(payload_path)
unpack_cache <- function(cache, name) {
  if (is.null(cache$bytes) || !identical(cache$storage, "serialized-object")) {
    stop("Payload does not contain a serialized ", name, " object.",
         call. = FALSE)
  }
  bytes <- cache$bytes
  if (!is.null(cache$compression) && !identical(cache$compression, "none")) {
    bytes <- memDecompress(bytes, type = cache$compression)
  }
  unserialize(bytes)
}
leng_out <- unpack_cache(payload$object_cache$objects$LengOut, "LengOut")
par_out <- unpack_cache(payload$object_cache$objects$ParOut, "ParOut")

flags <- methods::slot(par_out, "flags")
expected_controls <- c(`141` = 3, `311` = 1, `312` = 50, `313` = 1)
observed_controls <- vapply(names(expected_controls), function(flag) {
  value <- flags$value[flags$flagtype == 1 & flags$flag == as.integer(flag)]
  if (length(value) != 1L) return(NA_real_)
  as.numeric(value)
}, numeric(1L))
if (!identical(unname(observed_controls), unname(expected_controls))) {
  stop(
    "Fitted PAR controls do not match robust-normal TA1.8 settings: ",
    paste(names(observed_controls), observed_controls, sep = "=",
          collapse = ", "),
    call. = FALSE
  )
}

lf <- methods::slot(leng_out, "lenfits")
names(lf)[names(lf) == "length"] <- "length_midpoint"

new_sample <- c(
  TRUE,
  lf$fishery[-1L] != lf$fishery[-nrow(lf)] |
    lf$year[-1L] != lf$year[-nrow(lf)] |
    lf$month[-1L] != lf$month[-nrow(lf)] |
    lf$length_midpoint[-1L] <= lf$length_midpoint[-nrow(lf)]
)
lf$sample_id <- sprintf("sample-%06d", cumsum(new_sample))

group <- c(
  1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 3, 7, 6, 6, 7, 3,
  3, 4, 5, 7, 7, 7, 7, 4, 4, 5, 5, 8, 8, 8, 8, 8
)
group_name <- c(
  "Main longline", "Offshore longline",
  "Purse seine, set type unavailable", "Associated purse seine",
  "Unassociated purse seine", "Handline",
  "Other extraction fisheries", "Regional index fisheries"
)
fishery_name <- c(
  "LL.WEST.ALL.1", "LL.EAST.ALL.1", "LL.US.1", "LL.ALL.2",
  "LL.OS.2", "LL.ARCH.3", "LL.WEST.3", "LL.EAST.4", "LL.OS.3",
  "LL.ALL.5", "LL.AU.5", "PS.JP.1", "PL.JP.1", "HL.ID.2",
  "HL.PH.2", "PL.ALL.2", "PS.ID.2", "PS.PH.2", "PS.ASS.2",
  "PS.UNA.2", "MISC.ID.2", "MISC.PH.2", "MISC.VN.2",
  "PL.ALL.WEST.3", "PS.ASSOC.WEST.3", "PS.ASSOC.EAST.4",
  "PS.UNASSOC.WEST.3", "PS.UNASSOC.EAST.4", "Index R1",
  "Index R2", "Index R3", "Index R4", "Index R5"
)

tailed <- apply_tail_mapping(
  lf,
  active = TRUE,
  flag313 = 1,
  raw_sample_threshold = 50,
  sample_cols = "sample_id",
  sample_size_col = "sample_size",
  length_col = "length_midpoint",
  obs_col = "obs",
  pred_col = "pred"
)
tailed$data$group <- group[tailed$data$fishery]

# Setting the current divisor to one removes all inherited fishery-specific
# weighting. The fitted quantity is one absolute dispersion divisor per G8
# group, estimated from the pooled standardized mean-length residuals.
fit <- francis_ta18(
  tailed$data,
  sample_cols = "sample_id",
  pool_cols = "group",
  current_divisor = 1,
  sample_size_cap = 1000
)

groups <- fit$weights[, c(
  "group", "status", "n_used", "variance_z", "raw_multiplier",
  "continuous_divisor", "recommended_divisor"
)]
if (!identical(as.integer(groups$group), 1:8) ||
    any(groups$status != "ok") ||
    any(!is.finite(groups$continuous_divisor)) ||
    any(groups$continuous_divisor <= 0) ||
    any(!is.finite(groups$recommended_divisor)) ||
    any(groups$recommended_divisor < 1)) {
  stop("Grouped Francis calculation did not return eight valid groups.",
       call. = FALSE)
}
groups$source_job <- source_job
groups$group_name <- group_name[groups$group]
groups$fisheries <- vapply(
  groups$group,
  function(g) paste(which(group == g), collapse = ","),
  character(1L)
)
groups <- groups[, c(
  "source_job", "group", "group_name", "fisheries", "status", "n_used",
  "variance_z", "raw_multiplier", "continuous_divisor",
  "recommended_divisor"
)]

fisheries <- data.frame(
  source_job = source_job,
  fishery = seq_along(group),
  fishery_name = fishery_name,
  group = group,
  group_name = group_name[group],
  recommended_divisor = groups$recommended_divisor[
    match(group, groups$group)
  ],
  stringsAsFactors = FALSE
)

composition <- fit$compositions[fit$compositions$used, ]
composition$recommended_divisor <- groups$recommended_divisor[
  match(composition$group, groups$group)
]
composition$effective_sample_size <-
  pmin(composition$raw_sample_size, 1000) /
  composition$recommended_divisor
composition$post_reweight_z <-
  composition$z / sqrt(composition$recommended_divisor)

ess <- do.call(rbind, lapply(groups$group, function(g) {
  x <- composition[composition$group == g, ]
  data.frame(
    source_job = source_job,
    group = g,
    n_used = nrow(x),
    mean_ess = mean(x$effective_sample_size),
    median_ess = stats::median(x$effective_sample_size),
    post_var_z = stats::var(x$post_reweight_z)
  )
}))
ess <- rbind(
  ess,
  data.frame(
    source_job = source_job,
    group = 0L,
    n_used = nrow(composition),
    mean_ess = mean(composition$effective_sample_size),
    median_ess = stats::median(composition$effective_sample_size),
    post_var_z = NA_real_
  )
)

utils::write.csv(groups, file.path(output_dir, "grouped_francis_groups.csv"),
                 row.names = FALSE)
utils::write.csv(fisheries,
                 file.path(output_dir, "grouped_francis_fisheries.csv"),
                 row.names = FALSE)
utils::write.csv(ess, file.path(output_dir, "grouped_francis_ess.csv"),
                 row.names = FALSE)

cat("Usable compositions:", nrow(composition), "\n")
cat("Applied G8 divisors:",
    paste(groups$recommended_divisor, collapse = ", "), "\n")
cat("Overall mean ESS:",
    format(ess$mean_ess[ess$group == 0L], digits = 8), "\n")
