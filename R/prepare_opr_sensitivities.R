## Generate the 39 BET 2026 recruitment OPR sensitivity folders.
##
## The generator copies S002-TC1-NOCUT-DW1 byte-for-byte, then changes only
## the doitall control sequence through the reviewed apply_opr() helper.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)

required <- c(
  "opr-config.R",
  file.path("R", "prepare_common.R"),
  file.path("R", "prepare_doitall.R"),
  file.path("sensitivity", "S002-TC1-NOCUT-DW1", "model", "doitall.sh"),
  file.path("sensitivity", "S002-TC1-NOCUT-DW1", "input_manifest.csv")
)
missing <- required[!file.exists(file.path(root, required))]
if (length(missing)) {
  fail("Run from the exploration root; missing: ", paste(missing, collapse = ", "))
}

sys.source(file.path(root, "R", "prepare_common.R"), envir = environment())
sys.source(file.path(root, "R", "prepare_doitall.R"), envir = environment())
config <- new.env(parent = globalenv())
sys.source(file.path(root, "opr-config.R"), envir = config)
models <- config$opr_models
base_step_id <- config$opr_base_step_id

if (!is.data.frame(models) || nrow(models) != 39L) {
  fail("opr-config.R must define exactly 39 OPR sensitivity models")
}
if (anyDuplicated(models$step_id)) fail("OPR sensitivity IDs must be unique")
if (!all(models$year_effect == 74L - models$terminal_year_constraint)) {
  fail("Every annual/end pair must be saturated for the 73-year model period")
}
if (!identical(sort(unique(models$terminal_year_constraint)), 1:3)) {
  fail("OPR terminal windows must be exactly E1, E2, and E3")
}
if (!all(models$terminal_penalty_flag %in% c(0L, 100L)) ||
    sum(models$terminal_penalty_flag == 100L) != 18L) {
  fail("Terminal penalty design must contain 18 flag-397=100 models")
}
if (!all(models$tail_compression_percent == 1L) ||
    !all(models$cutoff_code == "NOCUT") ||
    !all(models$lf_downweight_factor == 1L) ||
    !all(models$lf_size_divisor == 20L) ||
    !all(models$regional_scaling_weight == 50L)) {
  fail("All OPR models must retain TC1-NOCUT-DW1 and regional scaling 50")
}

base_step_dir <- file.path(root, "sensitivity", base_step_id)
base_model_dir <- file.path(base_step_dir, "model")
output_root <- file.path(root, "opr-sensitivity")
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

existing <- list.files(output_root, full.names = TRUE, no.. = TRUE)
existing_dirs <- basename(existing[file.info(existing)$isdir %in% TRUE])
unexpected <- setdiff(existing_dirs, models$step_id)
if (length(unexpected)) {
  fail("Refusing to remove unexpected OPR folders: ", paste(unexpected, collapse = ", "))
}

copy_tree <- function(from, to) {
  entries <- list.files(
    from, recursive = TRUE, full.names = FALSE, all.files = TRUE,
    no.. = TRUE, include.dirs = TRUE
  )
  info <- file.info(file.path(from, entries))
  dirs <- entries[info$isdir %in% TRUE]
  files <- entries[!info$isdir %in% TRUE]
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  for (dir in dirs) {
    dir.create(file.path(to, dir), recursive = TRUE, showWarnings = FALSE)
  }
  for (file in files) {
    target <- file.path(to, file)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    if (!isTRUE(file.copy(
      file.path(from, file), target, overwrite = TRUE,
      copy.mode = TRUE, copy.date = TRUE
    ))) fail("Failed to copy base model file: ", file)
  }
}

flag_hits <- function(lines, actor, flag, value) {
  grep(sprintf(
    "^[[:space:]]*%s[[:space:]]+%s[[:space:]]+%s([[:space:]]|$)",
    actor, flag, value
  ), lines)
}

write_model_readme <- function(step_dir, row) {
  penalty <- if (row$terminal_penalty_flag == 100L) {
    "ON: parest 397=100 (native MFCL weight 10), activated in the final refinement"
  } else {
    "OFF: parest 397=0 throughout"
  }
  writeLines(c(
    paste0("# ", row$step_id),
    "",
    "This model is one BET 2026 recruitment OPR sensitivity.",
    "",
    "## Fixed base controls",
    "",
    paste0("- Base model: `", base_step_id, "`"),
    "- Global LF tail compression: 1%",
    "- F21/F22/F23 upper-length cutoff: none",
    "- F21/F22/F23 LF downweight: 1x (flag-49 divisor 20)",
    "- Regional-scaling weight: 50",
    "- Effort creep: inherited once from Job 5319; not reapplied",
    "",
    "## OPR settings",
    "",
    "| Control | Value |",
    "| --- | ---: |",
    sprintf("| Annual temporal coefficients, parest 155 | %d |", row$year_effect),
    sprintf("| Terminal window in calendar years, parest 202 | %d |", row$terminal_year_constraint),
    sprintf("| Season temporal coefficients, parest 217 | %d |", row$season_effect),
    sprintf("| Region temporal coefficients, parest 216 | %d |", row$region_effect),
    sprintf("| Region-season temporal coefficients, parest 218 | %d |", row$region_season_effect),
    sprintf("| Terminal penalty flag, parest 397 | %d |", row$terminal_penalty_flag),
    "",
    paste0("Terminal penalty: ", penalty, "."),
    paste0("Design role: ", row$interpretation, "."),
    "The annual/end pair is saturated for the 1952-2024 annual basis.",
    "No MFCL source code or executable is modified.",
    "",
    "Status: generated; not submitted to Kflow."
  ), file.path(step_dir, "README.md"), useBytes = TRUE)
}

base_manifest <- utils::read.csv(
  file.path(base_step_dir, "input_manifest.csv"),
  stringsAsFactors = FALSE, check.names = FALSE
)
required_manifest_columns <- c("role", "file", "source", "source_commit", "note")
if (!all(required_manifest_columns %in% names(base_manifest))) {
  fail("Base input_manifest.csv has an unexpected schema")
}

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  step_dir <- file.path(output_root, row$step_id)
  model_dir <- file.path(step_dir, "model")
  unlink(step_dir, recursive = TRUE, force = TRUE)
  dir.create(step_dir, recursive = TRUE, showWarnings = FALSE)
  copy_tree(base_model_dir, model_dir)

  doitall_path <- file.path(model_dir, "doitall.sh")
  lines <- readLines(doitall_path, warn = FALSE)
  if (length(flag_hits(lines, 1L, 313L, 1L)) != 1L) {
    fail(row$step_id, ": base doitall does not retain TC=1%")
  }
  for (fishery in 21:23) {
    if (length(flag_hits(lines, paste0("-", fishery), 49L, 20L)) != 1L) {
      fail(row$step_id, ": base doitall does not retain DW1 for F", fishery)
    }
  }

  lines <- apply_opr(
    lines,
    year_effect = as.integer(row$year_effect),
    season_effect = as.integer(row$season_effect),
    region_effect = as.integer(row$region_effect),
    region_season_effect = as.integer(row$region_season_effect),
    terminal_year_constraint = as.integer(row$terminal_year_constraint),
    terminal_penalty_flag = as.integer(row$terminal_penalty_flag),
    compatibility_year_effect = as.integer(row$year_effect)
  )
  writeLines(lines, doitall_path, useBytes = TRUE)
  Sys.chmod(doitall_path, mode = "0755")

  settings <- row
  settings$base_step_id <- base_step_id
  settings$terminal_penalty_native_weight <- row$terminal_penalty_flag / 10
  utils::write.csv(
    settings, file.path(step_dir, "opr_settings.csv"),
    row.names = FALSE, na = ""
  )

  manifest <- base_manifest
  manifest$source <- file.path(
    "sensitivity", base_step_id, "model", basename(manifest$file)
  )
  manifest$note <- paste0("Inherited from ", base_step_id, ". ", manifest$note)
  doitall_row <- which(manifest$role == "doitall")
  if (length(doitall_row) != 1L) fail("Base manifest must contain one doitall row")
  manifest$note[doitall_row] <- paste0(
    manifest$note[doitall_row],
    " OPR-only changes: 155=", row$year_effect,
    ", 202=", row$terminal_year_constraint,
    ", 217=", row$season_effect,
    ", 216=", row$region_effect,
    ", 218=", row$region_season_effect,
    ", 397=", row$terminal_penalty_flag, "."
  )
  utils::write.csv(
    manifest, file.path(step_dir, "input_manifest.csv"),
    row.names = FALSE, na = ""
  )
  write_model_readme(step_dir, row)
}

manifest <- models
manifest$model_dir <- file.path("opr-sensitivity", models$step_id, "model")
utils::write.csv(
  manifest, file.path(output_root, "manifest.csv"),
  row.names = FALSE, na = ""
)

writeLines(c(
  "# BET 2026 Recruitment OPR Sensitivities",
  "",
  "These 39 models start from `S002-TC1-NOCUT-DW1` and change only the",
  "recruitment orthogonal-polynomial controls in `doitall.sh`.",
  "",
  "## Fixed controls",
  "",
  "- Global LF tail compression: 1%",
  "- F21/F22/F23 cutoff: none",
  "- F21/F22/F23 LF downweight: 1x",
  "- Regional-scaling weight: 50",
  "- Job 5319 effort-creep FRQ inherited unchanged; no duplicate transform",
  "",
  "## OPR design",
  "",
  "- Saturated annual/end pairs: Y73-E1, Y72-E2, Y71-E3",
  "- Terminal penalty: parest 397=0 or 100 (native weight 0 or 10)",
  "- Season time-basis sizes: 1 (constant), 3 (quadratic), 5 (quartic)",
  "- Region and interaction time-basis sizes: 50, 15, and 5",
  "",
  "The complete machine-readable design is in `manifest.csv`.",
  "No model in this directory has been submitted to Kflow."
), file.path(output_root, "README.md"), useBytes = TRUE)

cat(sprintf("Generated %d OPR sensitivity models from %s.\n", nrow(models), base_step_id))
cat("Effort creep reapplied: no\n")
cat("Kflow submitted: no\n")
