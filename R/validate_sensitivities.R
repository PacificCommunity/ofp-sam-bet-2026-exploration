## Validate the generated 13-model initial robust-normal sensitivity design.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)
config <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config)
models <- config$stepwise_models

expected_ids <- sprintf("S%03d", 1:13)
actual_ids <- sub("-.*$", "", models$step_id)
if (!is.data.frame(models) || nrow(models) != 13L ||
    !identical(actual_ids, expected_ids) || anyDuplicated(models$step_id)) {
  fail("Expected contiguous model IDs S001:S013")
}
if (any(models$lf_likelihood != "normal") ||
    any(models$lf_downweight_factor != 1L) ||
    any(models$lf_size_divisor != 20L) ||
    any(as.logical(models$opr_enabled)) ||
    any(grepl("DM|DW[0-9]+|OPR", models$step_id))) {
  fail("Export must contain no DM, fixed-DW axis, or OPR model")
}

sensitivity_root <- file.path(root, "sensitivity")
model_dirs <- list.files(
  sensitivity_root,
  pattern = "^S[0-9]{3}-",
  full.names = FALSE
)
if (!setequal(model_dirs, models$step_id) || length(model_dirs) != 13L) {
  fail("Generated sensitivity folders do not match job-config.R")
}

duplicate_fisheries <- c(1L, 2L, 4L, 6L, 7L, 8L, 10L, 29L:33L)
for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  model_dir <- file.path(sensitivity_root, row$step_id, "model")
  required <- c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "doitall.sh")
  if (!all(file.exists(file.path(model_dir, required)))) {
    fail(row$step_id, ": missing required model input")
  }
  lines <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
  if (sum(grepl(
        "^[[:space:]]*-999[[:space:]]+49[[:space:]]+20([[:space:]]|$)",
        lines
      )) != 1L ||
      sum(grepl(
        "^[[:space:]]*-999[[:space:]]+50[[:space:]]+20([[:space:]]|$)",
        lines
      )) != 1L) {
    fail(row$step_id, ": global LF/WF divisor 20 is not unique")
  }
  if (sum(grepl(
        "^[[:space:]]*1[[:space:]]+141[[:space:]]+3([[:space:]]|$)",
        lines
      )) != 1L ||
      any(grepl(
        "^[[:space:]]*1[[:space:]]+(141[[:space:]]+11|342)[[:space:]]+",
        lines
      )) ||
      any(grepl(
        "^[[:space:]]*-[0-9]+[[:space:]]+(68|69|89)[[:space:]]+",
        lines
      ))) {
    fail(row$step_id, ": non-normal or DM control found")
  }
  for (fishery in duplicate_fisheries) {
    inherited <- sprintf(
      "-%d[[:space:]]+49[[:space:]]+40|-%d[[:space:]]+50[[:space:]]+40",
      fishery,
      fishery
    )
    if (any(grepl(inherited, lines))) {
      fail(row$step_id, ": duplicate-use divisor 40 remains for F", fishery)
    }
  }
  for (fishery in 21:23) {
    pattern <- sprintf(
      "^[[:space:]]*-%d[[:space:]]+49[[:space:]]+20([[:space:]]|$)",
      fishery
    )
    if (sum(grepl(pattern, lines)) != 1L) {
      fail(row$step_id, ": initial F", fishery, " divisor is not 20")
    }
  }
}

cat("Validated 13 initial robust-normal models with no second duplicate-use /2.\n")
