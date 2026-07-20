#!/usr/bin/env Rscript

fail <- function(...) stop(paste0(...), call. = FALSE)

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  normalizePath(sub("^--file=", "", script_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("R/validate_sensitivities.R", mustWork = TRUE)
}
repo_root <- dirname(dirname(script_path))
sensitivity_root <- file.path(repo_root, "sensitivity")
model_id <- "S001-TC1-NOCUT-DW10-RRASSOC"
control_id <- "S002-TC1-NOCUT-DW10"
model_root <- file.path(sensitivity_root, model_id)
model_dir <- file.path(model_root, "model")
reference_dir <- file.path(
  repo_root, "reference-inputs", "job-5319", "mfcl-inputs"
)
template_dir <- file.path(
  repo_root, "templates", "reporting-rate-association-split"
)
expected_runtime_image <- paste0(
  "ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:",
  "c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360"
)
expected_hashes <- c(
  "bet.age_length" =
    "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
  "bet.frq" =
    "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c",
  "bet.ini" =
    "3bf7d0260747dd2d65c5d0058268b10a04c782f54a798a2f6fce1f94dcf8f818",
  "bet.reg_scaling" =
    "5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3",
  "bet.reg_scaling.full" =
    "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed",
  "bet.tag" =
    "3f1b836a844ec2ca8e70fc5814d94c5a1ebc37ff4a5571c1dc1f6b83e477dfe8",
  "doitall.sh" =
    "227523a5ccc5841352a5008b10534bb095af3cde089342f29ea218e9fc867d75",
  "fishery_map.R" =
    "007f9ad46383da27b23e10d6f3a55bfcc5cc95c03e93f4fb4dac81d0d30aa38f",
  "mfcl.cfg" =
    "2ec8a291fae62c6f37541aec1de37444626d42b3290b371bb42b63d510034eae",
  "tag_rep_map.R" =
    "5c8d7b324c4796585c7f4b3e300ef10c45539c4a9bcd1b3679177959cf12765d"
)

sha256_file <- function(path) {
  if (!file.exists(path)) fail("Missing file: ", path)
  out <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  if (!length(out) || !identical(attr(out, "status"), NULL)) {
    fail("sha256sum failed for ", path)
  }
  sub("[[:space:]].*$", "", out[[1L]])
}

same_file <- function(a, b) identical(sha256_file(a), sha256_file(b))

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

read_matrix_section <- function(path, marker, integer = FALSE) {
  lines <- readLines(path, warn = FALSE)
  rows <- section_row_indices(lines, marker)
  tokens <- strsplit(trimws(lines[rows]), "[[:space:]]+")
  if (length(rows) != 99L || any(lengths(tokens) != 33L)) {
    fail(marker, " in ", path, " must be 99x33")
  }
  values <- unlist(tokens, use.names = FALSE)
  values <- if (integer) as.integer(values) else as.numeric(values)
  if (anyNA(values)) fail("Non-numeric value in ", marker)
  matrix(values, nrow = 99L, ncol = 33L, byrow = TRUE)
}

config_env <- new.env(parent = globalenv())
sys.source(file.path(repo_root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models
if (!is.data.frame(models) || nrow(models) != 1L ||
    !identical(models$step_id[[1L]], model_id) ||
    !isTRUE(models$enabled[[1L]]) ||
    !identical(models$base_sensitivity[[1L]], control_id) ||
    !identical(models$lf_likelihood[[1L]], "normal") ||
    models$tail_compression_percent[[1L]] != 1L ||
    is.finite(models$cutoff_cm[[1L]]) ||
    models$lf_size_divisor[[1L]] != 200L ||
    models$regional_scaling_weight[[1L]] != 50L ||
    models$tag_flag2[[1L]] != 0L ||
    !identical(models$tag_reporting_treatment[[1L]], "pttp_assoc_split")) {
  fail("job-config.R does not define the intended single focused model")
}

generated_ids <- list.dirs(
  sensitivity_root,
  recursive = FALSE,
  full.names = FALSE
)
if (!identical(generated_ids, model_id)) {
  fail(
    "sensitivity/ must contain only ", model_id,
    "; found: ", paste(generated_ids, collapse = ",")
  )
}

selection <- read.csv(
  file.path(repo_root, "SENSITIVITY_SELECTION.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
if (nrow(selection) != 1L ||
    !identical(selection$model[[1L]], model_id) ||
    !identical(selection$base_sensitivity[[1L]], control_id)) {
  fail("SENSITIVITY_SELECTION.csv must contain only the focused S001 model")
}

kflow_lines <- readLines(file.path(repo_root, "kflow.yaml"), warn = FALSE)
image_lines <- grep(
  "^[[:space:]]*docker_image:[[:space:]]*",
  kflow_lines,
  value = TRUE
)
actual_image <- trimws(sub(
  "^[[:space:]]*docker_image:[[:space:]]*",
  "",
  image_lines
))
if (length(image_lines) != 1L || !identical(actual_image, expected_runtime_image)) {
  fail("kflow.yaml must retain the digest-pinned Tuna Flow v2.5 image")
}

actual_hashes <- vapply(
  names(expected_hashes),
  function(name) sha256_file(file.path(model_dir, name)),
  character(1)
)
if (!identical(actual_hashes, expected_hashes)) {
  bad <- names(expected_hashes)[actual_hashes != expected_hashes]
  fail("Model file hash mismatch: ", paste(bad, collapse = ", "))
}

unchanged_reference_files <- c(
  "bet.age_length", "bet.frq", "bet.reg_scaling",
  "bet.reg_scaling.full", "bet.tag", "mfcl.cfg"
)
for (name in unchanged_reference_files) {
  if (!same_file(file.path(model_dir, name), file.path(reference_dir, name))) {
    fail(name, " differs from the audited source-control input")
  }
}
for (name in c("doitall.sh", "fishery_map.R", "tag_rep_map.R")) {
  if (!same_file(file.path(model_dir, name), file.path(template_dir, name))) {
    fail(name, " differs from the focused source-control template")
  }
}

source_ini <- file.path(template_dir, "bet.ini")
if (!identical(
  sha256_file(source_ini),
  "eaf9b6a5343d3face34580388ac7fdc2d6ae991bd1ad3ee12e2544e3b30a8de8"
)) {
  fail("Focused source-control bet.ini template has drifted")
}
derived_ini <- file.path(model_dir, "bet.ini")
markers <- c(
  rep = "# tag fish rep",
  group = "# tag fish rep group flags",
  active = "# tag_fish_rep active flags",
  target = "# tag_fish_rep target",
  penalty = "# tag_fish_rep penalty"
)
source_matrices <- list(
  rep = read_matrix_section(source_ini, markers[["rep"]]),
  group = read_matrix_section(source_ini, markers[["group"]], integer = TRUE),
  active = read_matrix_section(source_ini, markers[["active"]], integer = TRUE),
  target = read_matrix_section(source_ini, markers[["target"]]),
  penalty = read_matrix_section(source_ini, markers[["penalty"]])
)
derived_matrices <- list(
  rep = read_matrix_section(derived_ini, markers[["rep"]]),
  group = read_matrix_section(derived_ini, markers[["group"]], integer = TRUE),
  active = read_matrix_section(derived_ini, markers[["active"]], integer = TRUE),
  target = read_matrix_section(derived_ini, markers[["target"]]),
  penalty = read_matrix_section(derived_ini, markers[["penalty"]])
)

pttp_rows <- c(16:61, 99L)
pooled_cells <- matrix(FALSE, nrow = 99L, ncol = 33L)
pooled_cells[pttp_rows, 25:28] <- TRUE
associated_cells <- matrix(FALSE, nrow = 99L, ncol = 33L)
associated_cells[pttp_rows, 25:26] <- TRUE
unassociated_cells <- matrix(FALSE, nrow = 99L, ncol = 33L)
unassociated_cells[pttp_rows, 27:28] <- TRUE

if (!identical(source_matrices$group == 16L, pooled_cells) ||
    any(abs(source_matrices$rep[pooled_cells] - 0.52015) > 1e-12) ||
    any(abs(source_matrices$target[pooled_cells] - 52.015) > 1e-12) ||
    any(abs(source_matrices$penalty[pooled_cells] - 485.2) > 1e-12)) {
  fail("Source control no longer has the audited pooled PTTP prior")
}

expected_group <- source_matrices$group
expected_group[expected_group > 16L] <- expected_group[expected_group > 16L] + 1L
expected_group[unassociated_cells] <- 17L
expected_penalty <- source_matrices$penalty
expected_penalty[pooled_cells] <- 242.6

if (!identical(derived_matrices$group, expected_group) ||
    !identical(derived_matrices$penalty, expected_penalty) ||
    !identical(derived_matrices$rep, source_matrices$rep) ||
    !identical(derived_matrices$active, source_matrices$active) ||
    !identical(derived_matrices$target, source_matrices$target) ||
    !identical(sort(unique(derived_matrices$group[
      derived_matrices$group > 0L
    ])), 1:29) ||
    any(derived_matrices$group[associated_cells] != 16L) ||
    any(derived_matrices$group[unassociated_cells] != 17L) ||
    any(abs(derived_matrices$rep[pooled_cells] - 0.52015) > 1e-12) ||
    any(abs(derived_matrices$target[pooled_cells] - 52.015) > 1e-12) ||
    any(abs(derived_matrices$penalty[pooled_cells] - 242.6) > 1e-12)) {
  fail("Derived PTTP group split or prior mapping is incorrect")
}

ini_lines <- readLines(derived_ini, warn = FALSE)
tag_rows <- section_row_indices(ini_lines, "# tag flags")
tag_tokens <- strsplit(trimws(ini_lines[tag_rows]), "[[:space:]]+")
if (length(tag_rows) != 98L || any(lengths(tag_tokens) != 10L)) {
  fail("Derived # tag flags section is malformed")
}
tag_values <- matrix(
  as.integer(unlist(tag_tokens, use.names = FALSE)),
  nrow = 98L,
  ncol = 10L,
  byrow = TRUE
)
if (anyNA(tag_values) || any(tag_values[, 2L] != 0L)) {
  fail("Derived tag_flags(:,2) must remain zero")
}

doitall <- paste(
  readLines(file.path(model_dir, "doitall.sh"), warn = FALSE),
  collapse = "\n"
)
required_doitall_terms <- c(
  "tail compression",
  "-999 26 2",
  "-999 57 3",
  "-999 61 5",
  "-21 49 200",
  "-22 49 200",
  "-23 49 200"
)
if (any(!vapply(
  required_doitall_terms,
  grepl,
  logical(1),
  x = doitall,
  fixed = TRUE
))) {
  fail("doitall.sh drifted from TC1 NOCUT DW10 N5 control semantics")
}

required_documents <- c(
  file.path(repo_root, "README.md"),
  file.path(repo_root, "notes", "tag-reporting-association-split.md"),
  file.path(model_root, "README.md"),
  file.path(model_root, "input_manifest.csv")
)
for (path in required_documents) {
  if (!file.exists(path)) fail("Missing public documentation: ", path)
}
public_text <- paste(
  unlist(lapply(required_documents, readLines, warn = FALSE)),
  collapse = "\n"
)
required_terms <- c(
  model_id, control_id, "F25", "F26", "F27", "F28",
  "0.52015", "242.6", "485.2", "associated", "unassociated",
  "Observed recaptures remain pooled", "interpret"
)
if (any(!vapply(
  tolower(required_terms),
  grepl,
  logical(1),
  x = tolower(public_text),
  fixed = TRUE
))) {
  fail("Public documentation is missing the design, rationale, or interpretation")
}
forbidden_public_text <- paste0(
  "(?i)(/home/|/tmp/|/Users/|[A-Z]:[/\\\\]Users[/\\\\]|",
  "\\b(?:paul|john|thom|kyuhan|kyuhank)\\b)"
)
if (grepl(forbidden_public_text, public_text, perl = TRUE)) {
  fail("Public documentation contains a private path or personal identifier")
}
tracked_text <- paste(
  unlist(lapply(
    c(
      file.path(repo_root, "job-config.R"),
      file.path(repo_root, "R", "prepare_bet_2026_step_inputs.R"),
      file.path(repo_root, "R", "validate_sensitivities.R"),
      required_documents[1:3]
    ),
    readLines,
    warn = FALSE
  )),
  collapse = "\n"
)
obsolete_label_pattern <- paste0("S0", "42|", "41", "-model|S0", "41")
if (grepl(obsolete_label_pattern, tracked_text, perl = TRUE)) {
  fail("Focused branch still contains obsolete multi-model labeling")
}

message("Validated one focused sensitivity: ", model_id)
message("PTTP F25/F26 group 16; F27/F28 group 17")
message("Prior target 0.52015 and penalty 242.6 per group")
