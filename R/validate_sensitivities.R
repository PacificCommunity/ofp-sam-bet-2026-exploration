## Validate the generated 26-model initial robust-normal sensitivity design.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)
config <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config)
models <- config$stepwise_models

expected_ids <- sprintf("S%03d", 1:26)
actual_ids <- sub("-.*$", "", models$step_id)
if (!is.data.frame(models) || nrow(models) != 26L ||
    !identical(actual_ids, expected_ids) || anyDuplicated(models$step_id)) {
  fail("Expected contiguous model IDs S001:S026")
}
if (any(models$lf_likelihood != "normal") ||
    any(models$lf_downweight_factor != 1L) ||
    any(models$lf_size_divisor != 20L) ||
    any(as.logical(models$opr_enabled)) ||
    any(grepl("DM|DW[0-9]+|OPR", models$step_id))) {
  fail("Export must contain no DM, fixed-DW axis, or OPR model")
}
if (!identical(sort(unique(models$tag_flag2)), c(0L, 1L)) ||
    !identical(as.integer(table(models$tag_flag2)), c(13L, 13L)) ||
    any(!grepl("-TAGF2(OFF|ON)$", models$step_id))) {
  fail("Every structure must have explicit TAGF2OFF and TAGF2ON models")
}
age_levels <- c("BASE075", "BASE100", "REG075", "REG100", "SUB075", "SUB100")
if (!identical(
      as.integer(table(factor(models$age_length_variant, levels = age_levels))),
      c(6L, 4L, 4L, 4L, 4L, 4L)
    )) {
  fail("Age-length variant counts are incorrect")
}
structure_keys <- sub("-TAGF2(OFF|ON)$", "", sub("^S[0-9]{3}-", "", models$step_id))
if (length(unique(structure_keys)) != 13L ||
    any(table(structure_keys) != 2L)) {
  fail("Expected 13 structures with two tag settings each")
}

sensitivity_root <- file.path(root, "sensitivity")
model_dirs <- list.files(
  sensitivity_root,
  pattern = "^S[0-9]{3}-",
  full.names = FALSE
)
if (!setequal(model_dirs, models$step_id) || length(model_dirs) != 26L) {
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
  ini_lines <- readLines(file.path(model_dir, "bet.ini"), warn = FALSE)
  tag_start <- grep("^# tag flags[[:space:]]*$", ini_lines)
  if (length(tag_start) != 1L || tag_start + 98L > length(ini_lines)) {
    fail(row$step_id, ": tag flag block is missing or incomplete")
  }
  tag_rows <- strsplit(trimws(ini_lines[tag_start + seq_len(98L)]), "[[:space:]]+")
  tag_flag2 <- suppressWarnings(vapply(tag_rows, function(x) as.integer(x[[2L]]), 0L))
  if (anyNA(tag_flag2) || any(tag_flag2 != as.integer(row$tag_flag2))) {
    fail(row$step_id, ": tag_flags(:,2) does not match the model identity")
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

cat("Validated 26 paired initial robust-normal models with no second duplicate-use /2.\n")
