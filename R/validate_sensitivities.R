# Keep the original 30-core plus six-selectivity validation view unchanged.
# S037 is captured from job-config and validated separately at the end.
.tagv_model_id <- "S037-TC1-NOCUT-DW1-TAGF2ON"
.tagv_all_models <- NULL
.tagv_base_source <- base::source
.tagv_base_sys_source <- base::sys.source
.tagv_base_list_dirs <- base::list.dirs
.tagv_base_list_files <- base::list.files

.tagv_capture_models <- function(envir) {
  if (!is.environment(envir) ||
      !exists("stepwise_models", envir = envir, inherits = FALSE)) {
    return(invisible(NULL))
  }

  configured <- get("stepwise_models", envir = envir, inherits = FALSE)
  id_name <- intersect(c("step_id", "model_id", "id"), names(configured))
  if (length(id_name) == 0L) {
    return(invisible(NULL))
  }

  ids <- as.character(configured[[id_name[[1L]]]])
  if (!any(ids == .tagv_model_id)) {
    return(invisible(NULL))
  }

  assign(".tagv_all_models", configured, envir = .GlobalEnv)
  assign(
    "stepwise_models",
    configured[ids != .tagv_model_id, , drop = FALSE],
    envir = envir
  )
  invisible(NULL)
}

source <- function(file, local = FALSE, ...) {
  caller <- parent.frame()
  target <- if (isTRUE(local)) caller else local
  result <- .tagv_base_source(file = file, local = target, ...)
  capture_envir <- if (is.environment(target)) {
    target
  } else if (identical(target, FALSE)) {
    .GlobalEnv
  } else {
    caller
  }
  .tagv_capture_models(capture_envir)
  result
}

sys.source <- function(file, envir = baseenv(), ...) {
  result <- .tagv_base_sys_source(file = file, envir = envir, ...)
  .tagv_capture_models(envir)
  result
}

.tagv_hidden_path <- function(path) {
  path <- gsub("\\\\", "/", path)
  grepl(
    paste0("(^|/)", .tagv_model_id, "(/|$)"),
    path,
    perl = TRUE
  )
}

list.dirs <- function(...) {
  paths <- .tagv_base_list_dirs(...)
  paths[!.tagv_hidden_path(paths)]
}

list.files <- function(...) {
  paths <- .tagv_base_list_files(...)
  paths[!.tagv_hidden_path(paths)]
}
## Fail-fast validation for the curated 36-model BET sensitivity set.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(script_arg)) {
  script_path <- sub("^--file=", "", script_arg[[1L]])
  dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)))
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

fail <- function(...) stop(paste0(...), call. = FALSE)
assert_true <- function(ok, ...) {
  if (length(ok) != 1L || is.na(ok) || !isTRUE(ok)) fail(...)
  invisible(TRUE)
}
assert_exact_set <- function(actual, expected, label) {
  assert_true(
    length(actual) == length(expected) && !anyDuplicated(actual) &&
      setequal(actual, expected),
    label, " does not match the required set"
  )
}
pass <- function(message) cat("PASS: ", message, "\n", sep = "")

sha256_file <- function(path) {
  output <- suppressWarnings(system2(
    "sha256sum", c("--", path), stdout = TRUE, stderr = TRUE
  ))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    fail("sha256sum failed for ", path, ": ", paste(output, collapse = " "))
  }
  assert_true(length(output) > 0L, "sha256sum returned no output for ", path)
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

reference_input_set_sha256 <- function(input_dir) {
  files <- sort(list.files(input_dir, all.files = FALSE, no.. = TRUE))
  hashes <- vapply(file.path(input_dir, files), sha256_file, character(1))
  manifest <- tempfile("reference-inputs-sha256-")
  on.exit(unlink(manifest), add = TRUE)
  writeLines(sprintf("%s  %s", hashes, files), manifest, useBytes = TRUE)
  sha256_file(manifest)
}

read_raw <- function(path) {
  size <- file.info(path)$size
  assert_true(is.finite(size), "Cannot stat file: ", path)
  readBin(path, what = "raw", n = as.integer(size))
}

same_file <- function(left, right) {
  left_info <- file.info(left)
  right_info <- file.info(right)
  isTRUE(left_info$size == right_info$size) &&
    identical(read_raw(left), read_raw(right))
}

resolve_path <- function(path) {
  if (grepl("^/", path)) path else file.path(root, path)
}

read_ini_matrix <- function(lines, header, path) {
  hit <- which(trimws(lines) == header)
  assert_true(length(hit) == 1L, path, " must contain one ", header, " block")
  following_headers <- which(seq_along(lines) > hit & grepl("^[[:space:]]*#", lines))
  assert_true(length(following_headers) > 0L, "No section follows ", header, " in ", path)
  rows <- lines[seq.int(hit + 1L, following_headers[[1L]] - 1L)]
  rows <- rows[nzchar(trimws(rows))]
  fields <- strsplit(trimws(rows), "[[:space:]]+")
  widths <- unique(lengths(fields))
  assert_true(length(rows) > 0L && length(widths) == 1L,
              "Malformed ", header, " matrix in ", path)
  values <- suppressWarnings(as.numeric(unlist(fields, use.names = FALSE)))
  assert_true(!anyNA(values), "Non-numeric ", header, " matrix in ", path)
  matrix(values, nrow = length(rows), ncol = widths[[1L]], byrow = TRUE)
}

normalise_code <- function(value) {
  toupper(gsub("[._]+", "-", as.character(value)))
}

config_path <- file.path(root, "job-config.R")
assert_true(file.exists(config_path), "Missing job-config.R under ", root)
config_env <- new.env(parent = globalenv())
sys.source(config_path, envir = config_env)
models <- config_env$stepwise_models
assert_true(is.data.frame(models), "job-config.R must define stepwise_models")

required_columns <- c(
  "step_id", "age_length_variant", "age_length_source_path",
  "age_length_sha256", "lf_likelihood", "cutoff_cm",
  "lf_downweight_factor", "dm_grouping",
  "dm_estimate_relative_sample_size", "selectivity_treatment"
)
missing_columns <- setdiff(required_columns, names(models))
assert_true(!length(missing_columns),
            "stepwise_models is missing: ", paste(missing_columns, collapse = ", "))
assert_true(nrow(models) == 36L, "Expected exactly 36 configured models")
ids <- as.character(models$step_id)
assert_true(!anyNA(ids) && !anyDuplicated(ids), "Configured step IDs must be unique")
if ("enabled" %in% names(models)) {
  assert_true(all(models$enabled %in% TRUE), "All 36 models must be enabled")
}
if ("run_mode" %in% names(models)) {
  assert_true(all(models$run_mode == "doitall"), "All models must use doitall")
}
if ("job_title" %in% names(models)) {
  assert_true(!anyDuplicated(models$job_title), "Configured job titles must be unique")
}

age <- normalise_code(models$age_length_variant)
likelihood <- toupper(gsub("[^A-Za-z0-9]", "", models$lf_likelihood))
normal <- likelihood == "NORMAL"
dm <- likelihood == "DMNORE"
assert_true(all(normal | dm), "Only normal and DM-noRE LF likelihoods are allowed")

cutoff <- ifelse(
  is.na(models$cutoff_cm),
  "NOCUT",
  paste0("CUT", as.integer(models$cutoff_cm))
)
if ("cutoff_code" %in% names(models)) {
  assert_true(all(normalise_code(models$cutoff_code) == cutoff),
              "cutoff_code and cutoff_cm disagree")
}
downweight <- suppressWarnings(as.integer(models$lf_downweight_factor))
dm_group <- toupper(gsub("[^A-Za-z0-9]", "", models$dm_grouping))
dm_estimated <- as.logical(models$dm_estimate_relative_sample_size)
selectivity <- normalise_code(models$selectivity_treatment)
selectivity[is.na(selectivity) | !nzchar(selectivity)] <- "REFERENCE"

assert_true(all(!dm_estimated[normal]), "Normal models cannot estimate DM sample size")
assert_true(all(dm_group[normal] %in% c("NONE", "")),
            "Normal models cannot have DM grouping")
assert_true(all(!is.na(downweight[normal]) & downweight[normal] %in% c(1L, 10L)),
            "Normal models must use DW1 or DW10")
assert_true(all(is.na(downweight[dm])), "DM models cannot carry a normal downweight")
assert_true(all(dm_estimated[dm]), "Every DM model must be CEST")
assert_true(all(dm_group[dm] %in% c("PROCESS5", "G5PROC")),
            "Every DM model must use G5PROC")
assert_true(!any(cutoff == "CUT70"), "CUT70 is forbidden")
assert_true(!any(downweight == 5L, na.rm = TRUE), "DW5 is forbidden")
assert_true(!any(grepl("DW5|CUT70|(^|-)C0($|-)", toupper(ids), perl = TRUE)),
            "Step IDs cannot contain DW5, CUT70, or C0")
assert_true(all(grepl("DM-G5PROC-CEST", toupper(ids[dm]), fixed = TRUE)),
            "DM step IDs must identify G5PROC CEST")

design_key <- rep(NA_character_, nrow(models))
design_key[normal] <- paste0("NORMAL|", cutoff[normal], "|DW", downweight[normal])
design_key[dm] <- paste0("DM-G5PROC-CEST|", cutoff[dm])

age_levels <- c("BASE075", "REG075", "REG100", "SUB075", "SUB100")
core_configs <- c(
  "NORMAL|NOCUT|DW1", "NORMAL|NOCUT|DW10",
  "NORMAL|CUT90|DW1", "NORMAL|CUT90|DW10",
  "DM-G5PROC-CEST|NOCUT", "DM-G5PROC-CEST|CUT90"
)
core <- selectivity == "REFERENCE"
expected_core <- as.vector(outer(age_levels, core_configs, paste, sep = "|"))
actual_core <- paste(age[core], design_key[core], sep = "|")
assert_true(sum(core) == 30L, "Expected exactly 30 core models")
assert_exact_set(actual_core, expected_core, "Core age/configuration factorial")

selectivity_rows <- !core
selectivity_specs <- expand.grid(
  config = c("NORMAL|CUT90|DW1", "DM-G5PROC-CEST|CUT90"),
  treatment = c("SA28-N5", "SA28-N8", "IDX-Z2"),
  stringsAsFactors = FALSE
)
expected_selectivity <- paste(
  "BASE075", selectivity_specs$config, selectivity_specs$treatment, sep = "|"
)
actual_selectivity <- paste(
  age[selectivity_rows], design_key[selectivity_rows],
  selectivity[selectivity_rows], sep = "|"
)
assert_true(sum(selectivity_rows) == 6L,
            "Expected exactly six BASE075 selectivity variants")
assert_exact_set(actual_selectivity, expected_selectivity,
                 "BASE075 selectivity pairs")
if ("selectivity_reference" %in% names(models)) {
  for (index in which(selectivity_rows)) {
    source <- which(core & age == "BASE075" & design_key == design_key[[index]])
    assert_true(length(source) == 1L,
                "Cannot resolve selectivity reference for ", ids[[index]])
    assert_true(as.character(models$selectivity_reference[[index]]) == ids[[source]],
                "selectivity_reference is wrong for ", ids[[index]])
  }
}
pass("exact 30-model core factorial plus six BASE075 selectivity pairs")

reference_dir <- file.path(root, "reference-inputs", "job-5319", "mfcl-inputs")
reference_required <- c(
  "bet.age_length", "bet.frq", "bet.ini", "bet.reg_scaling",
  "bet.reg_scaling.full", "bet.tag", "doitall.sh", "fishery_map.R",
  "mfcl.cfg", "tag_rep_map.R"
)
expected_reference_sha256 <-
  "66532e40a12135811e23ef92434e7d011a3db3a8846e56928ec4080106b97fa3"
expected_ini_sha256 <-
  "932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117"
assert_true(dir.exists(reference_dir), "Missing reference input directory")
reference_files <- sort(list.files(reference_dir, all.files = FALSE, no.. = TRUE))
assert_true(identical(reference_files, sort(reference_required)),
            "Reference bundle must contain exactly the ten required inputs")
assert_true(reference_input_set_sha256(reference_dir) == expected_reference_sha256,
            "Reference bundle SHA-256 mismatch")
reference_ini_path <- file.path(reference_dir, "bet.ini")
assert_true(sha256_file(reference_ini_path) == expected_ini_sha256,
            "Reference bet.ini SHA-256 mismatch")

ini_lines <- readLines(reference_ini_path, warn = FALSE)
tag_flags <- read_ini_matrix(ini_lines, "# tag flags", reference_ini_path)
assert_true(nrow(tag_flags) == 98L && ncol(tag_flags) >= 2L,
            "bet.ini must contain exactly 98 tag-flag rows")
assert_true(
  all(tag_flags[, 1L] %in% 0:4) && all(tag_flags[, 2L] == 0),
  "Every tag flag row must preserve upstream column 1 and set column 2 to zero"
)

groups <- read_ini_matrix(
  ini_lines, "# tag fish rep group flags", reference_ini_path
)
active <- read_ini_matrix(
  ini_lines, "# tag_fish_rep active flags", reference_ini_path
)
targets <- read_ini_matrix(ini_lines, "# tag_fish_rep target", reference_ini_path)
penalties <- read_ini_matrix(ini_lines, "# tag_fish_rep penalty", reference_ini_path)
assert_true(
  identical(dim(groups), c(99L, 33L)) && identical(dim(active), dim(groups)) &&
    identical(dim(targets), dim(groups)) && identical(dim(penalties), dim(groups)),
  "Reporting-rate matrices must all be 99x33"
)
expected_group16 <- matrix(FALSE, nrow = 99L, ncol = 33L)
expected_group16[c(16:61, 99L), 25:28] <- TRUE
assert_true(identical(groups == 16, expected_group16),
            "Reporting group 16 must be exactly F25:F28 on PTTP/pooled rows")
assert_true(all(targets[expected_group16] == 52.015),
            "Reporting group 16 must have common target 52.015")
assert_true(all(penalties[expected_group16] == 485.2),
            "Reporting group 16 must have common penalty 485.2")

map_path <- file.path(reference_dir, "tag_rep_map.R")
map_env <- new.env(parent = baseenv())
sys.source(map_path, envir = map_env)
assert_true(exists("tag_rep_matrix", map_env, inherits = FALSE),
            "tag_rep_map.R must define tag_rep_matrix")
assert_true(exists("tag_rep_active_matrix", map_env, inherits = FALSE),
            "tag_rep_map.R must define tag_rep_active_matrix")
assert_true(
  identical(dim(map_env$tag_rep_matrix), dim(groups)) &&
    all(map_env$tag_rep_matrix == groups),
  "tag_rep_map.R group matrix does not match bet.ini"
)
assert_true(
  identical(dim(map_env$tag_rep_active_matrix), dim(active)) &&
    all(map_env$tag_rep_active_matrix == active),
  "tag_rep_map.R active matrix does not match bet.ini"
)
pass("reference hashes, tag flags, and reporting matrices")

read_words <- function(line) {
  words <- strsplit(trimws(line), "[[:space:]]+")[[1L]]
  if (identical(words, "")) character() else words
}

frq_shape <- function(lines, path) {
  header <- grep("Datasets / LFIntervals", lines, fixed = TRUE)
  assert_true(length(header) == 1L, "Expected one FRQ shape header in ", path)
  words <- read_words(lines[[header + 1L]])
  assert_true(length(words) >= 6L, "Malformed FRQ shape row in ", path)
  shape <- list(
    n_records = as.integer(words[[1L]]),
    n_lf = as.integer(words[[2L]]),
    lf_first = as.numeric(words[[3L]]),
    lf_width = as.numeric(words[[4L]]),
    n_wf = as.integer(words[[6L]])
  )
  assert_true(all(is.finite(unlist(shape))), "Non-numeric FRQ shape in ", path)
  shape$record_start <- length(lines) - shape$n_records + 1L
  assert_true(shape$record_start > header + 1L,
              "FRQ record count is inconsistent in ", path)
  shape
}

split_record <- function(line, shape, context) {
  words <- read_words(line)
  assert_true(length(words) >= 9L, "Malformed FRQ record in ", context)
  metadata <- words[1:7]
  if (identical(words[[8L]], "-1")) {
    lf <- NULL
    suffix <- words[9:length(words)]
  } else {
    lf_end <- 7L + shape$n_lf
    assert_true(length(words) > lf_end, "Truncated LF record in ", context)
    lf <- suppressWarnings(as.numeric(words[8:lf_end]))
    assert_true(!anyNA(lf), "Non-numeric LF count in ", context)
    suffix <- words[(lf_end + 1L):length(words)]
  }
  assert_true(
    (length(suffix) == 1L && identical(suffix, "-1")) ||
      length(suffix) == shape$n_wf,
    "Malformed WF suffix in ", context
  )
  list(metadata = metadata, lf = lf, suffix = suffix)
}

numeric_equal <- function(left, right) {
  length(left) == length(right) &&
    isTRUE(all.equal(left, right, tolerance = 1e-12, check.attributes = FALSE))
}

validate_cut90 <- function(source_path, variant_path) {
  source_lines <- readLines(source_path, warn = FALSE)
  variant_lines <- readLines(variant_path, warn = FALSE)
  assert_true(length(source_lines) == length(variant_lines),
              "CUT90 changed FRQ line count")
  shape <- frq_shape(source_lines, source_path)
  variant_shape <- frq_shape(variant_lines, variant_path)
  assert_true(identical(shape[1:5], variant_shape[1:5]),
              "CUT90 changed FRQ shape metadata")
  header <- seq_len(shape$record_start - 1L)
  assert_true(identical(source_lines[header], variant_lines[header]),
              "CUT90 changed FRQ header metadata")
  bins <- shape$lf_first + (seq_len(shape$n_lf) - 1L) * shape$lf_width
  upper <- bins > 90

  for (record_index in seq_len(shape$n_records)) {
    line_index <- shape$record_start + record_index - 1L
    context <- paste0("CUT90 record ", record_index)
    source <- split_record(source_lines[[line_index]], shape, context)
    variant <- split_record(variant_lines[[line_index]], shape, context)
    assert_true(identical(source$metadata, variant$metadata),
                "CUT90 changed record metadata in ", context)
    fishery <- suppressWarnings(as.integer(source$metadata[[4L]]))
    assert_true(!is.na(fishery), "Non-numeric fishery in ", context)

    if (!fishery %in% 21:23 || is.null(source$lf)) {
      assert_true(identical(source_lines[[line_index]], variant_lines[[line_index]]),
                  "CUT90 changed a non-target record in ", context)
      next
    }
    expected <- source$lf
    expected[upper] <- 0
    if (numeric_equal(expected, source$lf)) {
      assert_true(identical(source_lines[[line_index]], variant_lines[[line_index]]),
                  "CUT90 changed a target record without upper-bin counts in ", context)
      next
    }
    assert_true(identical(source$suffix, variant$suffix),
                "CUT90 changed WF data in ", context)
    if (sum(expected) <= 0) {
      assert_true(is.null(variant$lf),
                  "CUT90 did not encode an empty LF record as -1 in ", context)
    } else {
      assert_true(!is.null(variant$lf) && numeric_equal(variant$lf, expected),
                  "CUT90 changed counts outside upper F21:F23 LF bins in ", context)
    }
  }
}

sensitivity_root <- file.path(root, "sensitivity")
assert_true(dir.exists(sensitivity_root), "Missing sensitivity directory")
entries <- list.files(sensitivity_root, full.names = TRUE, no.. = TRUE)
top_dirs <- basename(entries[file.info(entries)$isdir %in% TRUE])
assert_exact_set(top_dirs, ids, "Generated sensitivity directories")
assert_true(!any(basename(list.dirs(sensitivity_root, recursive = TRUE)) %in%
                   c("steps", "staging", ".generation-staging")),
            "No steps or staging directory may remain under sensitivity")

for (variant in age_levels) {
  rows <- which(age == variant)
  paths <- unique(as.character(models$age_length_source_path[rows]))
  hashes <- unique(as.character(models$age_length_sha256[rows]))
  assert_true(length(paths) == 1L && length(hashes) == 1L,
              "Age source is inconsistent within ", variant)
  source <- resolve_path(paths[[1L]])
  assert_true(file.exists(source), "Missing age source for ", variant, ": ", source)
  assert_true(sha256_file(source) == hashes[[1L]],
              "Age source SHA-256 mismatch for ", variant)
  if ("age_length_source_file" %in% names(models)) {
    files <- unique(as.character(models$age_length_source_file[rows]))
    assert_true(length(files) == 1L && basename(source) == files[[1L]],
                "Age source filename is inconsistent for ", variant)
  }
}

required_model_inputs <- c(
  "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
  "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
  "tag_rep_map.R"
)
reference_copies <- c(
  "bet.ini", "bet.tag", "bet.reg_scaling", "bet.reg_scaling.full",
  "mfcl.cfg"
)
frq_paths <- character(nrow(models))
reference_frq <- file.path(reference_dir, "bet.frq")

for (index in seq_len(nrow(models))) {
  step_id <- ids[[index]]
  step_dir <- file.path(sensitivity_root, step_id)
  model_dir <- file.path(step_dir, "model")
  paths <- file.path(model_dir, required_model_inputs)
  assert_true(all(file.exists(paths)),
              "Incomplete model input set for ", step_id, ": ",
              paste(required_model_inputs[!file.exists(paths)], collapse = ", "))
  assert_true(all(file.info(paths)$size > 0), "Empty model input in ", step_id)
  for (file in reference_copies) {
    assert_true(same_file(file.path(model_dir, file), file.path(reference_dir, file)),
                step_id, "/model/", file, " differs from the reference")
  }
  if (models$selectivity_treatment[[index]] == "reference") {
    for (file in c("fishery_map.R", "tag_rep_map.R")) {
      assert_true(
        same_file(file.path(model_dir, file), file.path(reference_dir, file)),
        step_id, "/model/", file, " differs from the reference"
      )
    }
  }

  model_map_env <- new.env(parent = baseenv())
  sys.source(file.path(model_dir, "tag_rep_map.R"), envir = model_map_env)
  assert_true(
    exists("tag_rep_matrix", model_map_env, inherits = FALSE) &&
      exists("tag_rep_active_matrix", model_map_env, inherits = FALSE) &&
      identical(dim(model_map_env$tag_rep_matrix), dim(groups)) &&
      identical(dim(model_map_env$tag_rep_active_matrix), dim(active)) &&
      all(model_map_env$tag_rep_matrix == groups) &&
      all(model_map_env$tag_rep_active_matrix == active),
    "Generated tag reporting map does not match bet.ini in ", step_id
  )

  age_source <- resolve_path(as.character(models$age_length_source_path[[index]]))
  assert_true(same_file(file.path(model_dir, "bet.age_length"), age_source),
              "Configured age input is wrong in ", step_id)
  frq_paths[[index]] <- file.path(model_dir, "bet.frq")

  audit_path <- file.path(model_dir, "lf_cutoff_audit.csv")
  if (cutoff[[index]] == "NOCUT") {
    assert_true(same_file(frq_paths[[index]], reference_frq),
                "NOCUT FRQ differs from the reference in ", step_id)
    assert_true(!file.exists(audit_path),
                "NOCUT model cannot contain a cutoff audit: ", step_id)
  } else {
    assert_true(cutoff[[index]] == "CUT90", "Unexpected cutoff in ", step_id)
    assert_true(file.exists(audit_path), "Missing CUT90 audit in ", step_id)
    audit <- utils::read.csv(audit_path, stringsAsFactors = FALSE, check.names = FALSE)
    audit_required <- c("fishery", "cutoff_cm", "transform")
    assert_true(all(audit_required %in% names(audit)) && nrow(audit) == 3L,
                "Malformed CUT90 audit in ", step_id)
    assert_true(setequal(as.integer(audit$fishery), 21:23) &&
                  all(as.numeric(audit$cutoff_cm) == 90) &&
                  all(audit$transform == "lf_upper_cutoff"),
                "CUT90 audit disagrees with config in ", step_id)
  }

  manifest_path <- file.path(step_dir, "input_manifest.csv")
  assert_true(file.exists(manifest_path), "Missing input_manifest.csv in ", step_id)
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  assert_true("file" %in% names(manifest) &&
                all(required_model_inputs %in% manifest$file),
              "Input manifest is incomplete in ", step_id)
  if ("job_title" %in% names(models)) {
    readme <- file.path(step_dir, "README.md")
    assert_true(file.exists(readme), "Missing README.md in ", step_id)
    title <- readLines(readme, n = 1L, warn = FALSE)
    assert_true(identical(title, paste0("# ", models$job_title[[index]])),
                "README title disagrees with config in ", step_id)
  }
}

cut90_paths <- frq_paths[cutoff == "CUT90"]
assert_true(length(cut90_paths) > 0L, "No CUT90 FRQ was generated")
cut90_reference <- cut90_paths[[1L]]
for (path in cut90_paths[-1L]) {
  assert_true(same_file(path, cut90_reference),
              "Generated CUT90 FRQ inputs are not identical")
}
assert_true(!same_file(reference_frq, cut90_reference),
            "CUT90 FRQ is byte-identical to NOCUT")
validate_cut90(reference_frq, cut90_reference)
pass("36 core/selectivity directories and configured age/cutoff inputs")

cat("BASE VALIDATION PASSED: 36 core/selectivity sensitivities.\n")

# Restore unfiltered filesystem/config helpers for the explicit 37-model checks.
source <- .tagv_base_source
sys.source <- .tagv_base_sys_source
list.dirs <- .tagv_base_list_dirs
list.files <- .tagv_base_list_files

.tagv_fail <- function(message) {
  stop(paste0("[FAIL] ", message), call. = FALSE)
}

.tagv_assert <- function(condition, message) {
  if (length(condition) != 1L || is.na(condition) || !condition) {
    .tagv_fail(message)
  }
  invisible(TRUE)
}

.tagv_equal <- function(left, right) {
  isTRUE(all.equal(left, right, check.attributes = FALSE))
}

.tagv_normalise <- function(value) {
  toupper(gsub("[^A-Z0-9]+", "", as.character(value)))
}

.tagv_sha256 <- function(path) {
  command <- Sys.which("sha256sum")
  .tagv_assert(nzchar(command), "sha256sum is required")
  output <- system2(
    unname(command),
    args = shQuote(path),
    stdout = TRUE,
    stderr = TRUE
  )
  .tagv_assert(length(output) >= 1L, paste("could not hash", path))
  tolower(strsplit(trimws(output[[1L]]), "[[:space:]]+")[[1L]][[1L]])
}

.tagv_same_bytes <- function(left, right) {
  left_size <- file.info(left)$size
  right_size <- file.info(right)$size
  if (is.na(left_size) || is.na(right_size) || left_size != right_size) {
    return(FALSE)
  }
  identical(
    readBin(left, what = "raw", n = left_size),
    readBin(right, what = "raw", n = right_size)
  )
}

.tagv_relative <- function(path, parent) {
  prefix <- paste0(normalizePath(parent, mustWork = TRUE), .Platform$file.sep)
  absolute <- normalizePath(path, mustWork = TRUE)
  .tagv_assert(startsWith(absolute, prefix), paste(path, "is outside", parent))
  substring(absolute, nchar(prefix) + 1L)
}

.tagv_numeric_line <- function(line) {
  text <- trimws(line)
  if (!nzchar(text) || grepl("^#", text)) {
    return(NULL)
  }
  fields <- strsplit(text, "[[:space:]]+")[[1L]]
  values <- suppressWarnings(as.numeric(fields))
  if (length(values) < 2L || anyNA(values)) {
    return(NULL)
  }
  values
}

.tagv_read_tag_flags <- function(path) {
  lines <- readLines(path, warn = FALSE)
  header <- which(trimws(lines) == "# tag flags")
  .tagv_assert(length(header) == 1L, paste("tag-flags section missing in", path))
  following <- which(
    seq_along(lines) > header & grepl("^[[:space:]]*#", lines)
  )
  .tagv_assert(length(following) > 0L, paste("tag-flags section is unterminated in", path))
  row_indices <- seq.int(header + 1L, following[[1L]] - 1L)
  row_indices <- row_indices[nzchar(trimws(lines[row_indices]))]
  matrix <- read_ini_matrix(lines, "# tag flags", path)
  .tagv_assert(
    nrow(matrix) == 98L && length(row_indices) == 98L,
    paste("could not identify exactly 98 tag-flag rows in", path)
  )
  list(lines = lines, row_indices = row_indices, matrix = matrix)
}

.tagv_assert(
  is.data.frame(.tagv_all_models),
  "job-config did not expose the full S001-S037 model table"
)

.tagv_id_name <- intersect(
  c("step_id", "model_id", "id"),
  names(.tagv_all_models)
)
.tagv_assert(length(.tagv_id_name) >= 1L, "job-config has no model ID column")
.tagv_id_name <- .tagv_id_name[[1L]]
.tagv_ids <- as.character(.tagv_all_models[[.tagv_id_name]])

.tagv_assert(nrow(.tagv_all_models) == 37L, "expected exactly 37 configured models")
.tagv_assert(length(unique(.tagv_ids)) == 37L, "the 37 model IDs must be unique")
.tagv_assert(
  sum(.tagv_ids == .tagv_model_id) == 1L,
  paste("expected exactly one", .tagv_model_id)
)
.tagv_assert(
  sum(.tagv_ids != .tagv_model_id) == 36L,
  "S037 must be outside the 30-core plus six-selectivity factorial"
)

.tagv_s001_id <- .tagv_ids[grepl("^S001(?:-|$)", .tagv_ids, perl = TRUE)]
.tagv_assert(length(.tagv_s001_id) == 1L, "expected exactly one S001 model")
.tagv_s001_id <- .tagv_s001_id[[1L]]

.tagv_age_name <- intersect(
  c("age_length_variant", "age_variant"),
  names(.tagv_all_models)
)
.tagv_assert(length(.tagv_age_name) >= 1L, "job-config has no age variant column")
.tagv_age_name <- .tagv_age_name[[1L]]
.tagv_assert(
  sum(.tagv_normalise(.tagv_all_models[[.tagv_age_name]]) == "BASE075") == 13L,
  "BASE075 must contain 13 models: 12 factorial/selectivity models plus S037"
)

.tagv_s001_row <- .tagv_all_models[
  .tagv_ids == .tagv_s001_id,
  ,
  drop = FALSE
]
.tagv_s037_row <- .tagv_all_models[
  .tagv_ids == .tagv_model_id,
  ,
  drop = FALSE
]

.tagv_identity_metadata <- names(.tagv_all_models)[
  grepl(
    paste0(
      "^(step_id|model_id|id|substep|job_key|job_title|job_name|title|label|",
      "model_label|change_axis|description|notes?|sequence|order|index|sensitivity_id)$|",
      "(^|_)(output|work|job|model)_(dir|path|name)$"
    ),
    names(.tagv_all_models),
    ignore.case = TRUE,
    perl = TRUE
  )
]
.tagv_tag_controls <- names(.tagv_all_models)[
  grepl("tag.*flag|flag.*tag", names(.tagv_all_models), ignore.case = TRUE)
]
.tagv_setting_names <- setdiff(
  names(.tagv_all_models),
  unique(c(.tagv_identity_metadata, .tagv_tag_controls))
)
.tagv_assert(
  length(.tagv_setting_names) >= 1L,
  "no modeling settings were available for S001/S037 comparison"
)

for (.tagv_name in .tagv_setting_names) {
  .tagv_assert(
    .tagv_equal(
      .tagv_s001_row[[.tagv_name]],
      .tagv_s037_row[[.tagv_name]]
    ),
    paste("S037 differs from S001 in modeling setting", .tagv_name)
  )
}

.tagv_root <- NULL
for (.tagv_root_name in c("root", "repo_root", "project_root")) {
  if (exists(.tagv_root_name, inherits = FALSE)) {
    .tagv_candidate_root <- get(.tagv_root_name, inherits = FALSE)
    if (is.character(.tagv_candidate_root) &&
        length(.tagv_candidate_root) == 1L &&
        dir.exists(.tagv_candidate_root)) {
      .tagv_root <- normalizePath(.tagv_candidate_root, mustWork = TRUE)
      break
    }
  }
}
if (is.null(.tagv_root)) {
  .tagv_root <- normalizePath(getwd(), mustWork = TRUE)
}

.tagv_sensitivity_root <- file.path(.tagv_root, "sensitivity")
.tagv_model_dirs <- setNames(
  as.list(file.path(.tagv_sensitivity_root, .tagv_ids, "model")),
  .tagv_ids
)
.tagv_assert(
  all(vapply(.tagv_model_dirs, dir.exists, logical(1))),
  "every configured sensitivity must contain a model directory"
)
.tagv_siblings <- base::list.dirs(
  .tagv_sensitivity_root,
  full.names = FALSE,
  recursive = FALSE
)
.tagv_sibling_models <- .tagv_siblings[
  grepl("^S[0-9]{3}(?:-|$)", .tagv_siblings, perl = TRUE)
]
.tagv_assert(
  length(.tagv_sibling_models) == 37L &&
    setequal(.tagv_sibling_models, .tagv_ids),
  "generated model directories must match exactly the 37 configured model IDs"
)

.tagv_ini_hash <- "932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117"
.tagv_s001_dir <- .tagv_model_dirs[[.tagv_s001_id]]
.tagv_s037_dir <- .tagv_model_dirs[[.tagv_model_id]]
.tagv_s001_ini_candidates <- base::list.files(
  .tagv_s001_dir,
  pattern = "\\.ini$",
  full.names = TRUE,
  recursive = TRUE,
  ignore.case = TRUE
)
.tagv_s001_ini_hashes <- vapply(
  .tagv_s001_ini_candidates,
  .tagv_sha256,
  character(1)
)
.tagv_s001_ini <- .tagv_s001_ini_candidates[
  .tagv_s001_ini_hashes == .tagv_ini_hash
]
.tagv_assert(
  length(.tagv_s001_ini) == 1L,
  "S001 must contain exactly one INI matching the reference INI hash"
)
.tagv_s001_ini <- .tagv_s001_ini[[1L]]
.tagv_ini_relative <- .tagv_relative(.tagv_s001_ini, .tagv_s001_dir)
.tagv_s037_ini <- file.path(.tagv_s037_dir, .tagv_ini_relative)
.tagv_assert(file.exists(.tagv_s037_ini), "S037 is missing the S001-relative INI")
.tagv_assert(
  .tagv_sha256(.tagv_s037_ini) != .tagv_ini_hash,
  "S037 INI must differ from the zero-valued reference tag flags"
)

for (.tagv_id in setdiff(.tagv_ids, .tagv_model_id)) {
  .tagv_ini <- file.path(.tagv_model_dirs[[.tagv_id]], .tagv_ini_relative)
  .tagv_assert(file.exists(.tagv_ini), paste(.tagv_id, "is missing its INI"))
  .tagv_assert(
    .tagv_sha256(.tagv_ini) == .tagv_ini_hash,
    paste(.tagv_id, "INI differs from the zero-valued reference INI")
  )
}

.tagv_required_names <- NULL
for (.tagv_object_name in ls(envir = .GlobalEnv, all.names = TRUE)) {
  .tagv_object <- get(.tagv_object_name, envir = .GlobalEnv)
  if (!is.character(.tagv_object) || length(.tagv_object) != 10L) {
    next
  }
  .tagv_names <- basename(.tagv_object)
  if (sum(grepl("\\.ini$", .tagv_names, ignore.case = TRUE)) == 1L &&
      any(grepl("\\.frq$", .tagv_names, ignore.case = TRUE)) &&
      any(grepl("\\.tag$", .tagv_names, ignore.case = TRUE))) {
    .tagv_required_names <- .tagv_names
    break
  }
}
if (is.null(.tagv_required_names)) {
  .tagv_input_files <- base::list.files(
    dirname(.tagv_s001_ini),
    full.names = FALSE,
    recursive = FALSE
  )
  .tagv_required_names <- .tagv_input_files[
    !grepl(
      "readme|manifest|audit|log",
      .tagv_input_files,
      ignore.case = TRUE
    )
  ]
}
.tagv_required_names <- unique(.tagv_required_names)
.tagv_assert(
  length(.tagv_required_names) == 10L,
  "could not identify the exact ten-file generated input bundle"
)

for (.tagv_file_name in .tagv_required_names) {
  .tagv_s001_hits <- file.path(.tagv_s001_dir, .tagv_file_name)
  .tagv_s037_hits <- file.path(.tagv_s037_dir, .tagv_file_name)
  .tagv_assert(
    file.exists(.tagv_s001_hits) && file.exists(.tagv_s037_hits),
    paste("S001/S037 must each contain input", .tagv_file_name)
  )

  if (!grepl("\\.ini$", .tagv_file_name, ignore.case = TRUE)) {
    .tagv_assert(
      .tagv_same_bytes(.tagv_s001_hits, .tagv_s037_hits),
      paste("S037 input differs from S001:", .tagv_file_name)
    )
  }
}

.tagv_s001_flags <- .tagv_read_tag_flags(.tagv_s001_ini)
.tagv_s037_flags <- .tagv_read_tag_flags(.tagv_s037_ini)
.tagv_m001 <- .tagv_s001_flags$matrix
.tagv_m037 <- .tagv_s037_flags$matrix

.tagv_assert(nrow(.tagv_m001) == 98L, "S001 tag flags must have 98 rows")
.tagv_assert(nrow(.tagv_m037) == 98L, "S037 tag flags must have 98 rows")
.tagv_assert(
  ncol(.tagv_m001) == ncol(.tagv_m037) && ncol(.tagv_m001) >= 2L,
  "S001 and S037 tag-flag matrices must have the same width"
)
.tagv_assert(
  all(.tagv_m001[, 1L] %in% 0:4) && all(.tagv_m037[, 1L] %in% 0:4),
  "S001/S037 tag-flags column 1 must preserve upstream values"
)
.tagv_assert(all(.tagv_m001[, 2L] == 0), "S001 tag-flags column 2 must be 0")
.tagv_assert(all(.tagv_m037[, 2L] == 1), "S037 tag-flags column 2 must be 1")

.tagv_unchanged_columns <- setdiff(seq_len(ncol(.tagv_m001)), 2L)
.tagv_assert(
  identical(
    unname(.tagv_m001[, .tagv_unchanged_columns, drop = FALSE]),
    unname(.tagv_m037[, .tagv_unchanged_columns, drop = FALSE])
  ),
  "S001/S037 tag-flags columns other than column 2 must be identical"
)
.tagv_assert(
  identical(
    .tagv_s001_flags$lines[-.tagv_s001_flags$row_indices],
    .tagv_s037_flags$lines[-.tagv_s037_flags$row_indices]
  ),
  "S037 changes INI content outside the 98 tag-flag data rows"
)

cat(
  paste0(
    "[PASS] validated 37 models, including isolated S037 tag-flags column 2\n"
  )
)
