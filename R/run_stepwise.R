`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || !nzchar(as.character(x[[1]]))) y else x

env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) default else value
}

read_config <- function(path) {
  out <- list()
  if (!file.exists(path)) return(out)
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !grepl("^#", lines)]
  for (line in lines) {
    key <- sub("=.*$", "", line)
    value <- sub("^[^=]*=", "", line)
    value <- gsub("^[\"']|[\"']$", "", trimws(value))
    out[[key]] <- value
  }
  out
}

copy_dir <- function(from, to) {
  if (!dir.exists(from)) stop("Input directory not found: ", from, call. = FALSE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(files)) {
    ok <- file.copy(files, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
    if (!all(ok)) stop("Could not copy all files from ", from, call. = FALSE)
  }
  invisible(to)
}

latest_par <- function(model_dir) {
  pars <- list.files(model_dir, pattern = "[.]par[0-9]*$", full.names = FALSE)
  if (!length(pars)) return("")
  info <- file.info(file.path(model_dir, pars))
  pars[order(info$mtime, pars)][[length(pars)]]
}

truthy <- function(x, default = TRUE) {
  if (is.null(x) || !length(x) || !nzchar(as.character(x[[1]]))) return(default)
  tolower(trimws(as.character(x[[1]]))) %in% c("1", "true", "yes", "y", "on")
}

run_mfcl <- function(program, args, log_file, live_log = TRUE) {
  if (!isTRUE(live_log)) {
    return(system2(program, args, stdout = log_file, stderr = log_file, wait = TRUE))
  }
  quoted <- paste(c(shQuote(program), shQuote(args)), collapse = " ")
  command <- sprintf("set -o pipefail; %s 2>&1 | tee %s >&2", quoted, shQuote(log_file))
  system2("bash", c("-c", command), wait = TRUE)
}

bind_rows_fill <- function(rows) {
  rows <- rows[vapply(rows, function(x) is.data.frame(x) && nrow(x), logical(1))]
  if (!length(rows)) return(data.frame(stringsAsFactors = FALSE))
  cols <- unique(unlist(lapply(rows, names), use.names = FALSE))
  rows <- lapply(rows, function(x) {
    missing <- setdiff(cols, names(x))
    for (name in missing) x[[name]] <- NA
    x[, cols, drop = FALSE]
  })
  do.call(rbind, rows)
}

smoke_switch_args <- function(fevals = 1L) {
  switches <- c(
    1, 1, as.integer(fevals),
    1, 189, 1,
    1, 190, 1,
    1, 188, 1,
    1, 187, 0,
    1, 186, 0
  )
  c("-switch", as.character(length(switches) / 3L), as.character(switches))
}

par_footer <- function(path) {
  out <- c(objective = NA_real_, max_gradient = NA_real_)
  if (!file.exists(path)) return(out)
  lines <- readLines(path, warn = FALSE)
  objective_i <- grep("# Objective function value", lines, fixed = TRUE)
  gradient_i <- grep("# Maximum magnitude gradient", lines, fixed = TRUE)
  if (length(objective_i) && objective_i[[1]] < length(lines)) {
    out[["objective"]] <- suppressWarnings(as.numeric(lines[[objective_i[[1]] + 1L]]))
  }
  if (length(gradient_i) && gradient_i[[1]] < length(lines)) {
    out[["max_gradient"]] <- suppressWarnings(as.numeric(lines[[gradient_i[[1]] + 1L]]))
  }
  out
}

write_payload_timeseries <- function(payload_file, out_csv, scenario) {
  if (!requireNamespace("mfclshiny", quietly = TRUE) || !file.exists(payload_file)) {
    return(data.frame())
  }
  payload <- readRDS(payload_file)
  rep_obj <- tryCatch(payload$data$RepOut, error = function(e) NULL)
  if (is.null(rep_obj)) return(data.frame())
  payload_env <- getFromNamespace("mfclshiny_payload_env", "mfclshiny")()
  ts <- tryCatch(payload_env$mp_extract_rep_timeseries(rep_obj, scenario = scenario), error = function(e) data.frame())
  if (!nrow(ts)) return(ts)
  ts$model_token <- scenario
  ts$model_key <- scenario
  ts$plot_label <- scenario
  ts$report_label <- scenario
  write.csv(ts, out_csv, row.names = FALSE)
  ts
}

root <- getwd()
out_dir <- env("OUTPUT_DIR", "outputs")
work_dir <- file.path(root, "work")
input_root <- file.path(work_dir, "inputs")
program <- env("PROGRAM_PATH", "/home/mfcl/mfclo64")
mfcl_live_log <- truthy(env("MFCL_LIVE_LOG", "true"), default = TRUE)
step_select <- strsplit(env("STEP_SELECT", ""), ",", fixed = TRUE)[[1]]
step_select <- trimws(step_select[nzchar(trimws(step_select))])

steps <- sort(list.dirs("steps", recursive = FALSE, full.names = TRUE))
steps <- steps[grepl("^[0-9][0-9]-", basename(steps))]
if (length(step_select) && !any(tolower(step_select) %in% c("all", "*"))) {
  unknown <- setdiff(step_select, basename(steps))
  if (length(unknown)) stop("Unknown STEP_SELECT value(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  steps <- steps[basename(steps) %in% step_select]
}
if (!length(steps)) stop("No step folders selected under steps/.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  data.frame(step_id = basename(steps), step_dir = steps, stringsAsFactors = FALSE),
  file.path(out_dir, "selected-steps.csv"),
  row.names = FALSE
)

model_rows <- list()
for (step_dir in steps) {
  cfg <- read_config(file.path(step_dir, "config.env"))
  step_id <- basename(step_dir)
  if (!truthy(cfg$ENABLED %||% "true", default = TRUE)) {
    message("Skipping disabled step ", step_id)
    next
  }
  label <- cfg$MODEL_LABEL %||% step_id
  input_subdir <- cfg$INPUT_SUBDIR %||% "mfcl/inputs/2023_4region_1007"
  input_par <- cfg$INPUT_PAR %||% "11.par"
  output_par <- cfg$OUTPUT_PAR %||% paste0("smoke-", tools::file_path_sans_ext(input_par), ".par")
  fevals <- suppressWarnings(as.integer(env("SMOKE_FEVALS", cfg$SMOKE_FEVALS %||% "1")))
  if (!is.finite(fevals) || fevals < 1L) fevals <- 1L

  model_dir <- file.path(work_dir, "models", step_id)
  copy_dir(file.path(input_root, input_subdir), model_dir)
  patch_file <- file.path(step_dir, "patch.R")
  if (file.exists(patch_file)) {
    patch_env <- new.env(parent = globalenv())
    patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
    patch_env$step_id <- step_id
    patch_env$config <- cfg
    source(normalizePath(patch_file, mustWork = TRUE), local = patch_env)
  }

  frq <- cfg$FRQ %||% list.files(model_dir, pattern = "[.]frq$", full.names = FALSE)[[1]]
  if (!nzchar(frq) || is.na(frq)) stop("No .frq file found for ", step_id, call. = FALSE)
  if (!nzchar(input_par) || identical(tolower(input_par), "latest")) input_par <- latest_par(model_dir)
  if (!nzchar(input_par) || !file.exists(file.path(model_dir, input_par))) {
    stop("Input par not found for ", step_id, ": ", input_par, call. = FALSE)
  }

  log_file <- file.path(model_dir, "mfcl.log")
  args <- c(frq, input_par, output_par, smoke_switch_args(fevals))
  message("Running ", step_id, " (", label, ")")
  old <- setwd(model_dir)
  status <- tryCatch(
    run_mfcl(program, args, log_file = log_file, live_log = mfcl_live_log),
    finally = setwd(old)
  )
  if (!identical(status, 0L)) stop("MFCL failed for ", step_id, " with status ", status, call. = FALSE)

  final_par <- file.path(model_dir, output_par)
  if (!file.exists(final_par)) stop("MFCL did not create ", output_par, call. = FALSE)

  payload_status <- "mfclshiny_not_available"
  if (requireNamespace("mfclshiny", quietly = TRUE)) {
    payload_status <- tryCatch({
      if ("build_model_payload" %in% getNamespaceExports("mfclshiny")) {
        mfclshiny::build_model_payload(model_dir, overwrite = TRUE, recursive = FALSE)
      } else if ("build_model_payloads" %in% getNamespaceExports("mfclshiny")) {
        mfclshiny::build_model_payloads(model_dir, recursive = FALSE, overwrite = TRUE)
      }
      "ok"
    }, error = function(e) paste("error:", conditionMessage(e)))
  }
  writeLines(payload_status, file.path(model_dir, "model-payload-status.txt"))
  payload_file <- file.path(model_dir, "model_payload.rds")
  ts <- write_payload_timeseries(payload_file, file.path(model_dir, "depletion.csv"), label)
  footer <- par_footer(final_par)

  step_out <- file.path(out_dir, "models", step_id)
  dir.create(step_out, recursive = TRUE, showWarnings = FALSE)
  keep <- unique(c(output_par, "model_payload.rds", "model-payload-status.txt", "depletion.csv", "length.fit", "weight.fit", "temporary_tag_report", "tag.rep", "mfcl.log", frq))
  for (file in keep) {
    src <- file.path(model_dir, file)
    if (file.exists(src)) file.copy(src, file.path(step_out, basename(file)), overwrite = TRUE)
  }
  summary <- data.frame(
    step_id = step_id,
    model_label = label,
    input_subdir = input_subdir,
    input_par = input_par,
    output_par = output_par,
    smoke_fevals = fevals,
    objective = footer[["objective"]],
    max_gradient = footer[["max_gradient"]],
    payload = file.exists(file.path(step_out, "model_payload.rds")),
    payload_status = payload_status,
    depletion_rows = nrow(ts),
    stringsAsFactors = FALSE
  )
  write.csv(summary, file.path(step_out, "model-summary.csv"), row.names = FALSE)
  model_rows[[length(model_rows) + 1L]] <- summary
}

model_index <- bind_rows_fill(model_rows)
write.csv(model_index, file.path(out_dir, "model-index.csv"), row.names = FALSE)
write.csv(model_index, file.path(out_dir, "stepwise-summary.csv"), row.names = FALSE)
