#!/usr/bin/env Rscript

fail <- function(...) stop(paste0(...), call. = FALSE)

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("R/prepare_bet_2026_step_inputs.R", mustWork = TRUE)
}
repo_root <- dirname(dirname(script_path))
reference_dir <- file.path(
  repo_root, "reference-inputs", "job-5319", "mfcl-inputs"
)
template_dir <- file.path(
  repo_root, "templates", "reporting-rate-association-split"
)
sensitivity_root <- file.path(repo_root, "sensitivity")
model_id <- "S001-TC1-NOCUT-DW10-RRASSOC"
model_dir <- file.path(sensitivity_root, model_id, "model")
control_id <- "S002-TC1-NOCUT-DW10"
control_commit <- "6654763923ffa8c91b5e3df6aabc9483dc797cbd"
expected_ini_sha256 <-
  "3bf7d0260747dd2d65c5d0058268b10a04c782f54a798a2f6fce1f94dcf8f818"

sha256_file <- function(path) {
  if (!file.exists(path)) fail("Missing file: ", path)
  out <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  if (!length(out) || !identical(attr(out, "status"), NULL)) {
    fail("sha256sum failed for ", path)
  }
  sub("[[:space:]].*$", "", out[[1L]])
}

section_row_indices <- function(lines, marker) {
  header <- which(trimws(lines) == marker)
  if (length(header) != 1L) fail("Expected one ", marker, " section")
  later_headers <- which(
    seq_along(lines) > header & grepl("^[[:space:]]*#", lines)
  )
  section_end <- if (length(later_headers)) min(later_headers) - 1L else length(lines)
  rows <- seq.int(header + 1L, section_end)
  rows[nzchar(trimws(lines[rows]))]
}

read_matrix_section <- function(lines, marker, integer = FALSE) {
  rows <- section_row_indices(lines, marker)
  tokens <- strsplit(trimws(lines[rows]), "[[:space:]]+")
  if (length(rows) != 99L || any(lengths(tokens) != 33L)) {
    fail(marker, " must contain a 99x33 matrix")
  }
  values <- unlist(tokens, use.names = FALSE)
  values <- if (integer) as.integer(values) else as.numeric(values)
  if (anyNA(values)) fail("Non-numeric value in ", marker)
  list(
    rows = rows,
    tokens = tokens,
    matrix = matrix(values, nrow = 99L, ncol = 33L, byrow = TRUE)
  )
}

validate_tag_flag2_zero <- function(path) {
  lines <- readLines(path, warn = FALSE)
  rows <- section_row_indices(lines, "# tag flags")
  tokens <- strsplit(trimws(lines[rows]), "[[:space:]]+")
  if (length(rows) != 98L || any(lengths(tokens) != 10L)) {
    fail("# tag flags must contain 98 rows and 10 columns")
  }
  values <- matrix(
    as.integer(unlist(tokens, use.names = FALSE)),
    nrow = 98L,
    ncol = 10L,
    byrow = TRUE
  )
  if (anyNA(values) || any(values[, 2L] != 0L)) {
    fail("All 98 tag_flags(:,2) values must be zero")
  }
  invisible(TRUE)
}

apply_pttp_reporting_association_split <- function(path) {
  markers <- c(
    rep = "# tag fish rep",
    group = "# tag fish rep group flags",
    active = "# tag_fish_rep active flags",
    target = "# tag_fish_rep target",
    penalty = "# tag_fish_rep penalty"
  )
  lines <- readLines(path, warn = FALSE)
  sections <- list(
    rep = read_matrix_section(lines, markers[["rep"]]),
    group = read_matrix_section(lines, markers[["group"]], integer = TRUE),
    active = read_matrix_section(lines, markers[["active"]], integer = TRUE),
    target = read_matrix_section(lines, markers[["target"]]),
    penalty = read_matrix_section(lines, markers[["penalty"]])
  )

  source_group <- sections$group$matrix
  expected_rows <- c(16:61, 99L)
  expected_cells <- matrix(FALSE, nrow = 99L, ncol = 33L)
  expected_cells[expected_rows, 25:28] <- TRUE

  if (!identical(source_group == 16L, expected_cells) ||
      !identical(sort(unique(source_group[source_group > 0L])), 1:28) ||
      any(abs(sections$rep$matrix[expected_cells] - 0.52015) > 1e-12) ||
      any(sections$active$matrix[expected_cells] != 1L) ||
      any(abs(sections$target$matrix[expected_cells] - 52.015) > 1e-12) ||
      any(abs(sections$penalty$matrix[expected_cells] - 485.2) > 1e-12)) {
    fail(paste(
      "The source INI is not the audited pooled PTTP control:",
      "group 16, start 0.52015, target 52.015, penalty 485.2"
    ))
  }

  split_group <- source_group
  split_group[split_group > 16L] <- split_group[split_group > 16L] + 1L
  split_group[expected_rows, 27:28] <- 17L

  lines[sections$group$rows] <- vapply(
    seq_len(nrow(split_group)),
    function(i) paste(split_group[i, ], collapse = " "),
    character(1)
  )

  split_penalty_tokens <- sections$penalty$tokens
  for (i in expected_rows) {
    split_penalty_tokens[[i]][25:28] <- "242.6"
  }
  lines[sections$penalty$rows] <- vapply(
    split_penalty_tokens,
    paste,
    collapse = " ",
    FUN.VALUE = character(1)
  )

  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

config_env <- new.env(parent = globalenv())
sys.source(file.path(repo_root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models
if (!is.data.frame(models) || nrow(models) != 1L ||
    !identical(models$step_id[[1L]], model_id) ||
    !isTRUE(models$enabled[[1L]]) ||
    !identical(models$tag_reporting_treatment[[1L]], "pttp_assoc_split")) {
  fail("job-config.R must export only ", model_id)
}

existing_dirs <- list.dirs(sensitivity_root, recursive = FALSE, full.names = FALSE)
if (length(existing_dirs) && !identical(existing_dirs, model_id)) {
  fail(
    "This focused branch may contain only ", model_id,
    "; found: ", paste(existing_dirs, collapse = ", ")
  )
}

dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

reference_files <- c(
  "bet.age_length", "bet.frq", "bet.reg_scaling",
  "bet.reg_scaling.full", "bet.tag", "mfcl.cfg"
)
for (name in reference_files) {
  source <- file.path(reference_dir, name)
  destination <- file.path(model_dir, name)
  if (!file.copy(source, destination, overwrite = TRUE, copy.mode = TRUE)) {
    fail("Could not copy ", source)
  }
}

template_files <- c("bet.ini", "doitall.sh", "fishery_map.R", "tag_rep_map.R")
for (name in template_files) {
  source <- file.path(template_dir, name)
  destination <- file.path(model_dir, name)
  if (!file.copy(source, destination, overwrite = TRUE, copy.mode = TRUE)) {
    fail("Could not copy ", source)
  }
}

apply_pttp_reporting_association_split(file.path(model_dir, "bet.ini"))
validate_tag_flag2_zero(file.path(model_dir, "bet.ini"))
actual_ini_sha256 <- sha256_file(file.path(model_dir, "bet.ini"))
if (!identical(actual_ini_sha256, expected_ini_sha256)) {
  fail(
    "Derived bet.ini SHA-256 mismatch: expected ", expected_ini_sha256,
    ", got ", actual_ini_sha256
  )
}

selection <- data.frame(
  model = model_id,
  base_sensitivity = control_id,
  age_length_variant = "BASE075",
  age_length_source_file = "bet.age_length",
  age_length_source_path =
    "reference-inputs/job-5319/mfcl-inputs/bet.age_length",
  age_length_sha256 = models$age_length_sha256[[1L]],
  lf_likelihood = "normal",
  tail_compression_percent = 1L,
  cutoff_cm = NA_real_,
  downweight = 10L,
  dm_grouping = "none",
  dm_relative_sample_size_estimated = FALSE,
  dm_nmax = NA_integer_,
  hessian_pdh = "Not run",
  status = "prepared",
  basis = paste(
    "Isolated PTTP reporting-rate association split;",
    paste0("source control=", control_id, "@", control_commit, ";"),
    "F25/F26=group16, F27/F28=group17;",
    "target=0.52015 and penalty=242.6 per group"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  selection,
  file.path(repo_root, "SENSITIVITY_SELECTION.csv"),
  row.names = FALSE,
  na = ""
)

model_files <- c(
  "bet.age_length", "bet.frq", "bet.ini", "bet.reg_scaling",
  "bet.reg_scaling.full", "bet.tag", "mfcl.cfg", "doitall.sh",
  "fishery_map.R", "tag_rep_map.R"
)
manifest <- data.frame(
  role = c(
    "age_length", "frq", "ini", "reg_scaling", "reg_scaling_full",
    "tag", "mfcl_config", "doitall", "fishery_map", "tag_reporting_map"
  ),
  file = model_files,
  source = c(
    file.path("reference-inputs/job-5319/mfcl-inputs", c("bet.age_length", "bet.frq")),
    paste0(
      "templates/reporting-rate-association-split/bet.ini; derived from ",
      control_id, "@", control_commit
    ),
    file.path(
      "reference-inputs/job-5319/mfcl-inputs",
      c("bet.reg_scaling", "bet.reg_scaling.full", "bet.tag", "mfcl.cfg")
    ),
    file.path(
      "templates/reporting-rate-association-split",
      c("doitall.sh", "fishery_map.R", "tag_rep_map.R")
    )
  ),
  sha256 = vapply(
    file.path(model_dir, model_files),
    sha256_file,
    character(1)
  ),
  change = c(
    rep("unchanged from source control", 2L),
    paste(
      "PTTP F25/F26 group 16 and F27/F28 group 17;",
      "target 0.52015 and penalty 242.6 per group;",
      "later group IDs shifted by one"
    ),
    rep("unchanged from source control", 4L),
    rep("unchanged model structure from source control", 2L),
    "audit map regenerated for the split reporting groups"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  manifest,
  file.path(dirname(model_dir), "input_manifest.csv"),
  row.names = FALSE
)

message("Prepared ", model_id)
message("Derived bet.ini SHA-256: ", actual_ini_sha256)
