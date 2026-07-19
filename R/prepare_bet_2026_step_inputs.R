## Rebuild the 30-model BET 2026 LF-age-length design (five age-length
## variants crossed with six LF configurations), two non-duplicate BASE075
## N8 models, five core TAGF2ON models, and normal/DM Y72-E2 OPR tag-control
## pairs.
## The complete corrected single-area-derived SA28-N5 treatment, including
## F29-F33 early-age zeros, is the common baseline.
##
## Every cell retains the exact effort-crept FRQ archived by Kflow Job 5319.
## The tag-control INI is the current upstream build-ini file wholesale, with
## the single intentional deviation that all tag_flags(:,2) values are zero.
## Display metadata and regional-scaling inputs come from the reviewed
## stepwise branch; tag data come from the latest tag-prep main branch. The
## script never reapplies effort creep. Normal-likelihood cells change only
## observed LF bins for CUT90 cells, parest flag 313, and fishery-49 overrides
## for F21/F22/F23. DM cells use only the reviewed G5PROC grouping and estimate
## the relative sample-size exponent. All index LF is retained; option 11
## cannot reproduce the normal models' fixed flag-49 duplicate-use correction.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stepwise_refresh_ref <- "experiment/tag-grouping-reg-scaling-2026"
stepwise_refresh_commit <- "26c74dc6f303faa951b1ab331d7de14ea20b7489"
build_ini_source <- "PacificCommunity/ofp-sam-2026-BET-YFT-build-ini"
build_ini_commit <- "548de05aff9bdc96a9ee7a817bbfd8068020ba26"
build_ini_source_path <- "BET/ini.mix-period/bet.2026.mix-0.2.ini"
tag_prep_commit <- "79733c429b320e84ed5047aa6c932c8f19dab187"
tag_prep_source <- "PacificCommunity/ofp-sam-2026-BET-YFT-tag-prep"
age_length_source_repo <-
  "https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build"
age_length_source_commit <- "96a06d21ef3c666f39ce456d3a6818b6c17324c4"
single_area_selectivity_source <-
  "PacificCommunity/ofp-sam-bet-yft-2026-single-area"
single_area_selectivity_commit <-
  "5363029b509cacf902aef2866efdc04634c89045"
required_project_files <- c(
  "job-config.R",
  file.path("R", "prepare_common.R"),
  file.path("R", "prepare_mfcl_inputs.R"),
  file.path("R", "prepare_doitall.R")
)
missing_project_files <- required_project_files[
  !file.exists(file.path(root, required_project_files))
]
if (length(missing_project_files)) {
  stop(
    "Run this script from the exploration root; missing: ",
    paste(missing_project_files, collapse = ", "),
    call. = FALSE
  )
}

sys.source(file.path(root, "R", "prepare_common.R"), envir = environment())
sys.source(file.path(root, "R", "prepare_mfcl_inputs.R"), envir = environment())

config_env <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models

reference_input_dir <- file.path(root, "reference-inputs", "job-5319", "mfcl-inputs")
reference_required <- c(
  "bet.age_length",
  "bet.frq",
  "bet.ini",
  "bet.reg_scaling",
  "bet.reg_scaling.full",
  "bet.tag",
  "doitall.sh",
  "fishery_map.R",
  "mfcl.cfg",
  "tag_rep_map.R"
)
expected_reference_sha256 <- "a864b81f4d07321e977454a0d4c8389c8008b00159f374601f40ad6a6f7379d7"
expected_frq_sha256 <-
  "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"
expected_ini_sha256 <-
  "932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117"
expected_tag_sha256 <-
  "3f1b836a844ec2ca8e70fc5814d94c5a1ebc37ff4a5571c1dc1f6b83e477dfe8"

fail <- function(...) stop(paste0(...), call. = FALSE)

opr_helper_env <- new.env(parent = globalenv())
sys.source(file.path(root, "R", "prepare_doitall.R"), envir = opr_helper_env)
if (!is.function(opr_helper_env$apply_opr)) {
  fail("R/prepare_doitall.R must provide the reviewed BET apply_opr() helper")
}
opr_source_repo <- "PacificCommunity/ofp-sam-bet-2026-stepwise"
opr_source_ref <- "experiment/step12-opr-terminal-penalty-lf-sensitivity"
opr_source_note <- paste(
  "Reviewed BET OPR apply_opr() semantics from",
  paste0(opr_source_repo, "@", opr_source_ref, ","),
  "maintained in R/prepare_doitall.R."
)

sha256_file <- function(path) {
  output <- suppressWarnings(system2(
    "sha256sum",
    c("--", path),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    fail("sha256sum failed for ", path, ": ", paste(output, collapse = " "))
  }
  if (!length(output)) fail("sha256sum returned no output for ", path)
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

if (!dir.exists(reference_input_dir)) {
  fail("Missing refreshed reference-input directory: ", reference_input_dir)
}
reference_files <- sort(list.files(reference_input_dir, all.files = FALSE, no.. = TRUE))
if (!identical(reference_files, sort(reference_required))) {
  fail(
    "Reference bundle must contain exactly: ",
    paste(sort(reference_required), collapse = ", ")
  )
}
reference_sha256 <- reference_input_set_sha256(reference_input_dir)
frq_sha256 <- sha256_file(file.path(reference_input_dir, "bet.frq"))
ini_sha256 <- sha256_file(file.path(reference_input_dir, "bet.ini"))
tag_sha256 <- sha256_file(file.path(reference_input_dir, "bet.tag"))
if (!identical(reference_sha256, expected_reference_sha256)) {
  fail("Refreshed reference input-set SHA-256 mismatch: ", reference_sha256)
}
if (!identical(frq_sha256, expected_frq_sha256)) {
  fail("Job 5319 archived bet.frq SHA-256 mismatch: ", frq_sha256)
}
if (!identical(ini_sha256, expected_ini_sha256)) {
  fail("Refreshed bet.ini SHA-256 mismatch: ", ini_sha256)
}
if (!identical(tag_sha256, expected_tag_sha256)) {
  fail("Refreshed bet.tag SHA-256 mismatch: ", tag_sha256)
}

tag_flag_sensitivity_controls <- c(
  "S033-TC1-NOCUT-DW1-TAGF2ON" = "S001-TC1-NOCUT-DW1",
  "S034-TC1-CUT90-DW1-TAGF2ON" = "S003-TC1-CUT90-DW1",
  "S035-DM-G5PROC-CEST-NOCUT-TAGF2ON" = "S005-DM-G5PROC-CEST-NOCUT",
  "S036-DM-G5PROC-CEST-CUT90-TAGF2ON" = "S006-DM-G5PROC-CEST-CUT90",
  "S037-TC1-NOCUT-DW10-TAGF2ON" = "S002-TC1-NOCUT-DW10",
  "S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON" =
    "S038-OPR-Y72-E2-S01-R50-I50",
  "S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON" =
    "S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50"
)
tag_flag_sensitivity_ids <- names(tag_flag_sensitivity_controls)

restore_upstream_tag_flag_column2 <- function(path, expected_rows = 98L) {
  lines <- readLines(path, warn = FALSE)
  header <- which(trimws(lines) == "# tag flags")
  if (length(header) != 1L) {
    fail("Expected exactly one '# tag flags' section in ", path)
  }

  later_headers <- which(
    seq_along(lines) > header & grepl("^[[:space:]]*#", lines)
  )
  section_end <- if (length(later_headers)) min(later_headers) - 1L else length(lines)
  section_rows <- seq.int(header + 1L, section_end)
  section_rows <- section_rows[nzchar(trimws(lines[section_rows]))]
  numeric_pattern <- paste0(
    "^([[:space:]]*[+-]?[0-9]+)([[:space:]]+)",
    "([+-]?[0-9]+)(.*)$"
  )
  matches <- lapply(lines[section_rows], function(line) {
    match <- regexec(numeric_pattern, line, perl = TRUE)
    regmatches(line, match)[[1L]]
  })
  if (length(section_rows) != expected_rows ||
      any(lengths(matches) != 5L)) {
    fail(
      "Tag flags in ", path, " must contain exactly ", expected_rows,
      " valid numeric rows"
    )
  }

  first_values <- vapply(matches, `[[`, character(1), 2L)
  second_values <- suppressWarnings(as.integer(vapply(matches, `[[`, character(1), 4L)))
  trailing_values <- vapply(matches, `[[`, character(1), 5L)
  if (anyNA(second_values) || any(second_values != 0L)) {
    fail("TAGF2ON models must start from the derived INI with tag_flags(:,2) all zero")
  }

  updated <- vapply(matches, function(parts) {
    paste0(parts[[2L]], parts[[3L]], "1", parts[[5L]])
  }, character(1))
  updated_matches <- lapply(updated, function(line) {
    match <- regexec(numeric_pattern, line, perl = TRUE)
    regmatches(line, match)[[1L]]
  })
  if (any(lengths(updated_matches) != 5L) ||
      !identical(first_values, vapply(updated_matches, `[[`, character(1), 2L)) ||
      !identical(trailing_values, vapply(updated_matches, `[[`, character(1), 5L)) ||
      any(as.integer(vapply(updated_matches, `[[`, character(1), 4L)) != 1L)) {
    fail("Could not safely restore tag_flags(:,2) for ", path)
  }

  lines[section_rows] <- updated
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

required_selectivity_columns <- c(
  "selectivity_treatment", "selectivity_reference",
  "tag_flag2", "tag_flag2_reference", "opr_enabled",
  "opr_year_effect", "opr_terminal_year_constraint",
  "opr_season_effect", "opr_region_effect", "opr_region_season_effect",
  "opr_terminal_penalty_flag", "opr_source"
)
if (!is.data.frame(models) ||
    !all(required_selectivity_columns %in% names(models)) ||
    nrow(models) != 41L ||
    anyDuplicated(models$step_id) || any(!models$enabled)) {
  fail("job-config.R must define exactly 41 unique enabled sensitivity cells")
}
if (!all(models$run_mode == "doitall") ||
    !all(models$regional_scaling_weight == 50L)) {
  fail("Every sensitivity must use doitall and regional-scaling weight 50")
}
normal_rows <- models$lf_likelihood == "normal"
if (!all(
  models$lf_size_divisor[normal_rows] ==
    20L * models$lf_downweight_factor[normal_rows]
)) {
  fail("Every F21/F22/F23 LF divisor must equal 20 times its targeted downweight factor")
}
if (!all(models$lf_likelihood %in% c("normal", "dm_nore"))) {
  fail("LF likelihood must be normal or dm_nore")
}
dm_rows <- models$lf_likelihood == "dm_nore"
tag_flag_rows <- models$step_id %in% tag_flag_sensitivity_ids
opr_rows <- as.logical(models$opr_enabled)
selectivity_rows <- models$selectivity_treatment == "sa28_n8"
core_rows <- !selectivity_rows & !tag_flag_rows & !opr_rows
finite_cutoff_rows <- is.finite(models$cutoff_cm)
if (any(models$cutoff_cm[finite_cutoff_rows] != 90) ||
    any(!models$lf_downweight_factor[normal_rows] %in% c(1L, 10L)) ||
    any(models$tail_compression_percent[normal_rows] != 1L) ||
    any(!is.na(models$lf_downweight_factor[dm_rows])) ||
    any(!is.na(models$lf_size_divisor[dm_rows])) ||
    any(models$tail_compression_percent[dm_rows] != 0L)) {
  fail("The final design permits only CUT90, normal DW1/DW10, and DM-specific tail controls")
}
if (any(models$dm_grouping[dm_rows] != "process5") ||
    any(!as.logical(models$dm_estimate_relative_sample_size[dm_rows])) ||
    any(grepl("CUT70|DW5|G1-|G2-|G4-|G7QUAL|C0-", models$step_id))) {
  fail("Every DM model must use G5PROC with the relative sample-size exponent estimated")
}
if (any(models$selectivity_treatment[!selectivity_rows] != "sa28_n5")) {
  fail("Every non-N8 model must use the corrected SA28-N5 baseline")
}

expected_age_levels <- c("BASE075", "REG075", "REG100", "SUB075", "SUB100")
age_level_counts <- table(factor(models$age_length_variant, levels = expected_age_levels))
if (!identical(as.integer(age_level_counts), c(17L, rep(6L, 4L))) ||
    anyDuplicated(models[core_rows, c("base_sensitivity", "age_length_variant")])) {
  fail(paste(
    "Expected 30 core models (five age-length variants x six LF configurations)",
    "plus two BASE075 N8 models, five core TAGF2ON models, and two two-model OPR tag pairs"
  ))
}
base_rows <- models$age_length_variant == "BASE075"
factorial_base_rows <- base_rows & core_rows
if (sum(factorial_base_rows) != 6L ||
    !identical(
      sub("-.*$", "", as.character(models$step_id[factorial_base_rows])),
      sprintf("S%03d", 1:6)
    )) {
  fail("The six BASE075 core identities must remain S001:S006")
}
inherit_columns <- c(
  "run_mode", "region_count", "regional_scaling_weight",
  "tail_compression_percent", "cutoff_cm", "cutoff_code",
  "lf_downweight_factor", "lf_size_divisor", "lf_likelihood",
  "dm_grouping", "dm_estimate_relative_sample_size"
)
base_by_id <- models[factorial_base_rows, c("base_sensitivity", inherit_columns), drop = FALSE]
for (level in expected_age_levels[-1L]) {
  level_rows <- models$age_length_variant == level
  level_models <- models[level_rows, c("base_sensitivity", inherit_columns), drop = FALSE]
  level_models <- level_models[match(base_by_id$base_sensitivity, level_models$base_sensitivity), , drop = FALSE]
  rownames(level_models) <- NULL
  rownames(base_by_id) <- NULL
  if (!identical(level_models, base_by_id)) {
    fail("Age-length level ", level, " does not inherit every base configuration exactly")
  }
}

expected_normal_keys <- c("NOCUT-DW1", "NOCUT-DW10", "CUT90-DW1", "CUT90-DW10")
expected_dm_keys <- c("NOCUT", "CUT90")
for (level in expected_age_levels) {
  level_core <- core_rows & models$age_length_variant == level
  level_normal <- level_core & normal_rows
  level_dm <- level_core & dm_rows
  normal_keys <- paste0(
    ifelse(is.finite(models$cutoff_cm[level_normal]), "CUT90", "NOCUT"),
    "-DW", as.integer(models$lf_downweight_factor[level_normal])
  )
  dm_keys <- ifelse(is.finite(models$cutoff_cm[level_dm]), "CUT90", "NOCUT")
  if (sum(level_core) != 6L || sum(level_normal) != 4L || sum(level_dm) != 2L ||
      !setequal(normal_keys, expected_normal_keys) || anyDuplicated(normal_keys) ||
      !setequal(dm_keys, expected_dm_keys) || anyDuplicated(dm_keys)) {
    fail("Age-length level ", level, " must contain the exact six-config core design")
  }
}

source_rows <- !duplicated(models$age_length_variant)
source_models <- models[source_rows, , drop = FALSE]
source_models <- source_models[match(expected_age_levels, source_models$age_length_variant), , drop = FALSE]
if (anyNA(source_models$age_length_source_path) ||
    any(source_models$age_length_variant == "BASE100")) {
  fail("Age-length sources must define exactly the reviewed five levels without BASE100")
}
for (i in seq_len(nrow(source_models))) {
  source_path <- file.path(root, source_models$age_length_source_path[[i]])
  if (!file.exists(source_path)) fail("Missing age-length source: ", source_path)
  if (!identical(sha256_file(source_path), source_models$age_length_sha256[[i]])) {
    fail("Age-length source SHA-256 mismatch: ", source_path)
  }
}

expected_selectivity_ids <- c(
  "S031-TC1-CUT90-DW1-SA28-N8",
  "S032-DM-G5PROC-CEST-CUT90-SA28-N8"
)
expected_selectivity_treatments <- rep("sa28_n8", 2L)
expected_selectivity_references <- c(
  "S003-TC1-CUT90-DW1",
  "S006-DM-G5PROC-CEST-CUT90"
)
if (sum(selectivity_rows) != 2L ||
    !identical(as.character(models$step_id[selectivity_rows]), expected_selectivity_ids) ||
    !identical(
      as.character(models$selectivity_treatment[selectivity_rows]),
      expected_selectivity_treatments
    ) ||
    !identical(
      as.character(models$selectivity_reference[selectivity_rows]),
      expected_selectivity_references
    ) ||
    any(models$age_length_variant[selectivity_rows] != "BASE075") ||
    any(models$cutoff_cm[selectivity_rows] != 90) ||
    sum(selectivity_rows & normal_rows) != 1L ||
    sum(selectivity_rows & dm_rows) != 1L ||
    any(models$lf_downweight_factor[selectivity_rows & normal_rows] != 1L) ||
    any(models$lf_size_divisor[selectivity_rows & normal_rows] != 20L) ||
    any(models$dm_grouping[selectivity_rows & dm_rows] != "process5") ||
    any(!models$dm_estimate_relative_sample_size[selectivity_rows & dm_rows])) {
  fail(paste(
    "Selectivity sensitivities must be the two non-duplicate CUT90 SA28-N8",
    "models based on corrected-N5 controls S003 and S006"
  ))
}
paired_control_columns <- c(
  "run_mode", "region_count", "regional_scaling_weight",
  "tail_compression_percent", "cutoff_cm", "cutoff_code",
  "cutoff_description", "lf_downweight_factor", "lf_size_divisor",
  "lf_likelihood", "dm_grouping", "dm_estimate_relative_sample_size",
  "age_length_variant", "age_length_source_file", "age_length_source_path",
  "age_length_sha256"
)
for (i in which(selectivity_rows)) {
  reference_id <- as.character(models$selectivity_reference[[i]])
  reference_index <- match(reference_id, models$step_id)
  if (is.na(reference_index) || any(!vapply(
    paired_control_columns,
    function(column) identical(models[[column]][[i]], models[[column]][[reference_index]]),
    logical(1)
  ))) {
    fail("Selectivity sensitivity does not inherit its paired reference: ", models$step_id[[i]])
  }
}

tag_flag_control_columns <- unique(c(
  paired_control_columns,
  "selectivity_treatment", "opr_enabled", "opr_year_effect",
  "opr_terminal_year_constraint", "opr_season_effect", "opr_region_effect",
  "opr_region_season_effect", "opr_terminal_penalty_flag", "opr_source"
))

expected_opr_ids <- c(
  "S038-OPR-Y72-E2-S01-R50-I50",
  "S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON",
  "S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50",
  "S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON"
)
opr_indices <- match(expected_opr_ids, models$step_id)
normal_opr_indices <- opr_indices[1:2]
dm_opr_indices <- opr_indices[3:4]
opr_base_indices <- match(
  c("S001-TC1-NOCUT-DW1", "S005-DM-G5PROC-CEST-NOCUT"),
  models$step_id
)
if (anyNA(opr_indices) || anyNA(opr_base_indices) || sum(opr_rows) != 4L ||
    !identical(as.character(models$step_id[opr_rows]), expected_opr_ids) ||
    any(models$age_length_variant[opr_indices] != "BASE075") ||
    any(models$selectivity_treatment[opr_indices] != "sa28_n5") ||
    any(is.finite(models$cutoff_cm[opr_indices])) ||
    any(models$lf_likelihood[normal_opr_indices] != "normal") ||
    any(models$tail_compression_percent[normal_opr_indices] != 1L) ||
    any(models$lf_downweight_factor[normal_opr_indices] != 1L) ||
    any(models$lf_size_divisor[normal_opr_indices] != 20L) ||
    any(models$lf_likelihood[dm_opr_indices] != "dm_nore") ||
    any(models$dm_grouping[dm_opr_indices] != "process5") ||
    any(!models$dm_estimate_relative_sample_size[dm_opr_indices]) ||
    any(models$tail_compression_percent[dm_opr_indices] != 0L) ||
    any(!is.na(models$lf_downweight_factor[dm_opr_indices])) ||
    any(!is.na(models$lf_size_divisor[dm_opr_indices])) ||
    any(models$opr_year_effect[opr_indices] != 72L) ||
    any(models$opr_terminal_year_constraint[opr_indices] != 2L) ||
    any(models$opr_season_effect[opr_indices] != 1L) ||
    any(models$opr_region_effect[opr_indices] != 50L) ||
    any(models$opr_region_season_effect[opr_indices] != 50L) ||
    any(models$opr_terminal_penalty_flag[opr_indices] != 0L) ||
    !identical(models$tag_flag2[opr_indices], c(0L, 1L, 0L, 1L))) {
  fail("OPR pairs must retain exact S001/S005 controls with Y72 E2 S01 R50 I50 and penalty disabled")
}
for (pair in seq_along(opr_base_indices)) {
  control_index <- opr_indices[c(1L, 3L)[[pair]]]
  for (column in c(paired_control_columns, "selectivity_treatment")) {
    if (!identical(models[[column]][[control_index]],
                   models[[column]][[opr_base_indices[[pair]]]])) {
      fail(expected_opr_ids[[c(1L, 3L)[[pair]]]],
           " differs from its non-OPR control in setting ", column)
    }
  }
}
tag_flag_indices <- match(tag_flag_sensitivity_ids, models$step_id)
tag_flag_reference_indices <- match(
  unname(tag_flag_sensitivity_controls), models$step_id
)
if (anyNA(tag_flag_indices) || anyNA(tag_flag_reference_indices) ||
    any(models$age_length_variant[tag_flag_indices] != "BASE075") ||
    any(models$tag_flag2[tag_flag_indices] != 1L) ||
    any(models$tag_flag2_reference[tag_flag_indices] !=
          unname(tag_flag_sensitivity_controls)) ||
    any(models$selectivity_treatment[tag_flag_indices] != "sa28_n5")) {
  fail("The seven TAGF2ON identities, controls, BASE075 inputs, or SA28-N5 baseline are wrong")
}
for (i in seq_along(tag_flag_indices)) {
  if (any(!vapply(
    tag_flag_control_columns,
    function(column) identical(
      models[[column]][[tag_flag_indices[[i]]]],
      models[[column]][[tag_flag_reference_indices[[i]]]]
    ),
    logical(1)
  ))) {
    fail(tag_flag_sensitivity_ids[[i]], " differs from its flag-column-2=0 control")
  }
}

fishery_map_env <- new.env(parent = globalenv())
sys.source(
  file.path(reference_input_dir, "fishery_map.R"),
  envir = fishery_map_env
)
reference_fishery_map <- fishery_map_env$fishery_map
if (!is.data.frame(reference_fishery_map) ||
    !identical(reference_fishery_map$fishery, 1:33)) {
  fail("Reference fishery_map.R must define fisheries 1:33 in order")
}
dm_group_ids_for <- function(grouping) {
  grouping <- as.character(grouping[[1L]])
  fishery <- reference_fishery_map$fishery
  ids <- switch(
    grouping,
    gear1 = rep(1L, length(fishery)),
    gear2 = ifelse(fishery <= 28L, 1L, 2L),
    gear4 = ifelse(
      reference_fishery_map$group == "LL",
      1L,
      ifelse(
        grepl("^PS", reference_fishery_map$group),
        2L,
        ifelse(
          reference_fishery_map$group %in% c("PL", "HL", "MISC"),
          3L,
          ifelse(reference_fishery_map$group == "Index", 4L, NA_integer_)
        )
      )
    ),
    process5 = {
      out <- rep(NA_integer_, length(fishery))
      out[fishery %in% 1:11] <- 1L
      out[fishery %in% c(12L, 19:20, 25:28)] <- 2L
      out[fishery %in% 17:18] <- 3L
      out[fishery %in% c(13:16, 21:24)] <- 4L
      out[fishery %in% 29:33] <- 5L
      out
    },
    quality7 = {
      out <- rep(NA_integer_, length(fishery))
      out[fishery %in% 1:11] <- 1L
      out[fishery %in% c(19L, 25:26)] <- 2L
      out[fishery %in% c(20L, 27:28)] <- 3L
      out[fishery %in% 17:18] <- 4L
      out[fishery %in% 12:13] <- 5L
      out[fishery %in% c(14:16, 21:24)] <- 6L
      out[fishery %in% 29:33] <- 7L
      out
    },
    fail("Unknown DM grouping: ", grouping)
  )
  ids <- as.integer(ids)
  if (anyNA(ids)) fail("Every fishery must map to a reviewed DM group")
  names(ids) <- fishery
  ids
}

dm_group_names_for <- function(grouping) {
  switch(
    as.character(grouping[[1L]]),
    gear1 = "All LF",
    gear2 = c("Extraction", "Index"),
    gear4 = c("Longline", "Purse seine", "Other extraction", "Index"),
    process5 = c(
      "Longline extraction", "Large-scale purse seine", "Domestic purse seine",
      "Other extraction", "Index"
    ),
    quality7 = c(
      "Longline extraction", "Associated purse seine", "Unassociated purse seine",
      "Domestic purse seine", "Japanese PS/PL", "Other extraction", "Index"
    ),
    fail("Unknown DM grouping")
  )
}

expected_dm_group_counts <- list(
  gear1 = 33L,
  gear2 = c(28L, 5L),
  gear4 = c(11L, 9L, 8L, 5L),
  process5 = c(11L, 7L, 2L, 8L, 5L),
  quality7 = c(11L, 3L, 3L, 2L, 2L, 7L, 5L)
)
for (grouping in names(expected_dm_group_counts)) {
  ids <- dm_group_ids_for(grouping)
  counts <- as.integer(table(factor(ids, levels = seq_along(expected_dm_group_counts[[grouping]]))))
  if (!identical(counts, expected_dm_group_counts[[grouping]])) {
    fail("Unexpected fishery counts for ", grouping)
  }
}

sensitivity_root <- file.path(root, "sensitivity")
forbidden_dirs <- c(
  file.path(root, "steps"),
  file.path(root, ".generation-staging"),
  file.path(sensitivity_root, "steps"),
  file.path(sensitivity_root, "staging"),
  file.path(sensitivity_root, ".generation-staging")
)
if (any(dir.exists(forbidden_dirs))) {
  fail("Sensitivity generation requires no steps or staging directories")
}
dir.create(sensitivity_root, recursive = TRUE, showWarnings = FALSE)
existing_entries <- list.files(sensitivity_root, full.names = TRUE, no.. = TRUE)
existing_dirs <- basename(existing_entries[file.info(existing_entries)$isdir %in% TRUE])
extra_dirs <- setdiff(existing_dirs, models$step_id)
unexpected_dirs <- extra_dirs[!grepl("^S[0-9]{3}-", extra_dirs)]
if (length(unexpected_dirs)) {
  fail(
    "Refusing to remove unexpected sensitivity folders: ",
    paste(unexpected_dirs, collapse = ", ")
  )
}

copy_exact <- function(from, to) {
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(
    from,
    to,
    overwrite = TRUE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (!isTRUE(copied)) fail("Failed to copy ", from, " to ", to)
  invisible(to)
}

cutoff_sentence <- function(cutoff_cm) {
  if (is.finite(cutoff_cm)) {
    sprintf(
      paste0(
        "For F21/F22/F23, observed LF counts in bins with midpoint above the ",
        "%.0f cm cutoff are set to zero."
      ),
      cutoff_cm
    )
  } else {
    "For F21/F22/F23, observed LF counts are unchanged; no cutoff is applied."
  }
}

cutoff_provenance <- function(cutoff_cm) {
  if (is.finite(cutoff_cm) && cutoff_cm == 90) {
    paste(
      "The 90 cm threshold reproduces the historical treatment documented in",
      "WCPFC-SC19-2023/SA-WP-05 for the corresponding Indonesia, Philippines,",
      "and Vietnam domestic small-fish length compositions; 90 cm is retained",
      "and only bins with midpoint greater than 90 cm are zeroed."
    )
  } else {
    "This model retains its previously selected cutoff treatment."
  }
}

replace_flag_value <- function(line, actor, flag, value) {
  pattern <- sprintf(
    "^([[:space:]]*%s[[:space:]]+%s[[:space:]]+)([^[:space:]#]+)(.*)$",
    actor,
    flag
  )
  match <- regmatches(line, regexec(pattern, line, perl = TRUE))[[1L]]
  if (length(match) != 4L) {
    fail("Could not replace flag ", actor, "/", flag, " in archived doitall.sh")
  }
  paste0(match[[2L]], value, match[[4L]])
}

selectivity_treatment_note <- function(treatment) {
  treatment <- as.character(treatment[[1L]])
  switch(
    treatment,
    reference = "Reference five-region selectivity settings retained.",
    sa28_n5 = paste(
      "The corrected N5 baseline assigns independent selectivity groups to F1-F28,",
      "applies the audited young-age, F9 monotonicity, and upper-age constraints,",
      "leaves F14, F15, F20, and F28 without an old-age tail penalty,",
      "fixes the first two ages of F29-F33 to zero, uses five nodes, and splits",
      "regional-index groups F29-F33 in phase 5. Fish flag 24 group labels are",
      "contiguous in every phase without changing group membership. Fish flag 26=2 evaluates the",
      "flag-57 cubic spline on scaled mean length-at-age to produce final",
      "selectivity-at-age; flag 61 supplies nodes on that coordinate."
    ),
    sa28_n8 = paste(
      "The corrected N8 treatment is identical to N5 except that F12 PS.JP.1",
      "and F13 PL.JP.1 use eight rather than five spline nodes."
    ),
    fail("Unknown selectivity treatment: ", treatment)
  )
}

single_area_selectivity_block <- function(nodes) {
  nodes <- as.integer(nodes[[1L]])
  if (!nodes %in% c(5L, 8L)) fail("SA28 F12/F13 nodes must be 5 or 8")
  extraction_group_ids <- 1:28
  extraction_labels <- sub(
    "^[0-9]+\\.",
    "",
    as.character(reference_fishery_map$fishery_name[1:28])
  )
  node_lines <- if (nodes == 8L) {
    c(
      "  -12 61 8  # eight spline nodes on scaled mean length-at-age for PS.JP.1",
      "  -13 61 8  # eight spline nodes on scaled mean length-at-age for PL.JP.1"
    )
  } else {
    character()
  }
  c(
    "# Selectivity settings",
    "  -999 3 37  # all selectivities equal for age class 37 and older",
    "  -999 26 2  # build selectivity-at-age by evaluating the spline on scaled mean length-at-age (not length-bin selectivity)",
    "  -999 57 3  # cubic spline basis for selectivity",
    "  -999 61 5  # five spline nodes on the scaled mean-length-at-age coordinate",
    node_lines,
    "# SA28: independent extraction selectivity with contiguous MFCL group labels.",
    sprintf(
      "  -%d 24 %d  # %s",
      1:28,
      extraction_group_ids,
      extraction_labels
    ),
    "  -29 24 29  # Index R1; shared initialization group through phase 4",
    "  -30 24 29  # Index R2; shared initialization group through phase 4",
    "  -31 24 29  # Index R3; shared initialization group through phase 4",
    "  -32 24 29  # Index R4; shared initialization group through phase 4",
    "  -33 24 29  # Index R5; shared initialization group through phase 4",
    "# Single-area extraction monotonicity constraint.",
    "   -9 16 1",
    "# Single-area extraction young-age constraints.",
    sprintf("  -%d 75 2", 1:12),
    "  -13 75 1",
    "  -15 75 5",
    "# Corrected regional-index early-age constraints.",
    "  -29 75 2  # Index R1",
    "  -30 75 2  # Index R2",
    "  -31 75 2  # Index R3",
    "  -32 75 2  # Index R4",
    "  -33 75 2  # Index R5",
    "# Single-area extraction age-spline and upper-age constraints.",
    "  -12 16 2  -12 3 25",
    "  -13 16 2  -13 3 30",
    "  -14 16 0  -14 3 37",
    "  -15 16 0  -15 3 37",
    "  -17 16 2  -17 3 25",
    "  -18 16 2  -18 3 25",
    "  -19 16 2  -19 3 25",
    "  -20 16 0  -20 3 37",
    "  -25 16 2  -25 3 25",
    "  -26 16 2  -26 3 25",
    "  -27 16 2  -27 3 30",
    "  -28 16 0  -28 3 37",
    "  -16 16 2  -16 3 25",
    "  -24 16 2  -24 3 25",
    "  -21 16 2  -21 3 10",
    "  -22 16 2  -22 3 7",
    "  -23 16 2  -23 3 6"
  )
}

apply_selectivity_treatment <- function(lines, treatment) {
  treatment <- as.character(treatment[[1L]])
  if (identical(treatment, "reference")) return(lines)
  block_start <- grep("^# Selectivity settings[[:space:]]*$", lines)
  block_end <- grep("^# Turn on weighted spline", lines)
  if (length(block_start) != 1L || length(block_end) != 1L || block_start >= block_end) {
    fail("Archived doitall.sh must contain one complete PHASE1 selectivity block")
  }
  if (treatment %in% c("sa28_n5", "sa28_n8")) {
    nodes <- if (identical(treatment, "sa28_n8")) 8L else 5L
    return(c(
      lines[seq_len(block_start - 1L)],
      single_area_selectivity_block(nodes),
      lines[block_end:length(lines)]
    ))
  }
  fail("Unknown selectivity treatment: ", treatment)
}

canonicalize_final_selectivity_group_labels <- function(lines, treatment) {
  treatment <- as.character(treatment[[1L]])
  if (!treatment %in% c("sa28_n5", "sa28_n8")) return(lines)
  phase_start <- grep("<<PHASE5[[:space:]]*$", lines)
  phase_end <- grep("^PHASE5[[:space:]]*$", lines)
  if (length(phase_start) != 1L || length(phase_end) != 1L || phase_start >= phase_end) {
    fail("Archived doitall.sh must contain one complete PHASE5 block")
  }
  for (fishery in 29:33) {
    hit <- grep(
      sprintf("^[[:space:]]*-%d[[:space:]]+24[[:space:]]+", fishery),
      lines
    )
    hit <- hit[hit > phase_start & hit < phase_end]
    if (length(hit) != 1L) {
      fail("PHASE5 must contain one selectivity-group line for fishery ", fishery)
    }
    lines[[hit]] <- sprintf(
      "  -%d 24 %d  # Index R%d; separate final selectivity from phase 5 onward",
      fishery, fishery, fishery - 28L
    )
  }
  lines
}

apply_selectivity_fishery_map <- function(path, treatment) {
  treatment <- as.character(treatment[[1L]])
  if (!treatment %in% c("sa28_n5", "sa28_n8")) {
    return(invisible(path))
  }
  lines <- readLines(path, warn = FALSE)
  insertion <- grep("^selectivity_group_map <-", lines)
  if (length(insertion) != 1L) {
    fail("Generated fishery_map.R must contain one selectivity_group_map assignment")
  }
  overrides <- c(
    "# SA28 extraction and final index groups are independent with contiguous labels.",
    "fishery_map$selectivity_group[1:28] <- 1:28",
    "fishery_map$selectivity_group[29:33] <- 29:33",
    "fishery_map$selectivity_name[1:28] <- sub(\"^[0-9]+\\\\.\", \"\", fishery_map$fishery_name[1:28])",
    "fishery_map$selectivity_name[29:33] <- paste0(\"Index R\", 1:5)",
    ""
  )
  lines <- append(lines, overrides, after = insertion - 1L)
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

cpue_hac4 <- data.frame(
  fishery = 29:33,
  index = paste0("R", 1:5),
  base_flag92 = c(35L, 24L, 21L, 24L, 23L),
  de4 = c(
    1.29476547433727,
    1.58770333326732,
    2.82036231277202,
    1.79774557593873,
    1.68640693000139
  ),
  flag92 = c(40L, 30L, 35L, 32L, 30L),
  stringsAsFactors = FALSE
)
cpue_hac4$base_sigma <- cpue_hac4$base_flag92 / 100
cpue_hac4$target_sigma <- cpue_hac4$base_sigma * sqrt(cpue_hac4$de4)
if (!identical(as.integer(round(100 * cpue_hac4$target_sigma)), cpue_hac4$flag92)) {
  fail("HAC4 CPUE sigma flags do not match base_sigma * sqrt(DE4)")
}
cpue_hac4_manifest_note <- paste(
  "Branch-wide CPUE HAC4 sensitivity from S014 Kflow job 9777 weighted",
  "log-residuals: Bartlett Newey-West lag 4; F29-F33 flag 92 values are",
  "40, 30, 35, 32, and 30. Fish flag 66 remains 1, so MFCL applies the",
  "FRQ effort_weight as a per-fishery-normalized temporal variance multiplier;",
  "parest flag 371 remains at its initialized value zero."
)

apply_cpue_hac4_sigma <- function(lines) {
  comment_start <- grep("^# fish flag 92 =", lines)
  comment_end <- grep("^# precision pattern used by", lines)
  if (length(comment_start) != 1L || length(comment_end) != 1L ||
      comment_start > comment_end) {
    fail("Archived doitall.sh has an unexpected CPUE variance comment block")
  }
  comment_block <- c(
    "# fish flag 92 = round(sigma * 100); fish flag 94 allows unequal sigma.",
    "# fish flag 66=1 reads FRQ effort_weight as temporal variance multiplier lambda_t.",
    "# With parest flag 371=0, MFCL uses lambda_t * sigma^2 after normalizing",
    "# lambda_t to mean one within each fishery.",
    "# HAC4 target = base sigma * sqrt(Bartlett Newey-West DE at lag 4)."
  )
  lines <- c(
    lines[seq_len(comment_start - 1L)],
    comment_block,
    lines[seq.int(comment_end + 1L, length(lines))]
  )

  for (i in seq_len(nrow(cpue_hac4))) {
    row <- cpue_hac4[i, , drop = FALSE]
    pattern <- sprintf(
      "(^|[[:space:]])-%d[[:space:]]+92[[:space:]]+%d([[:space:]]|$)",
      row$fishery,
      row$base_flag92
    )
    hit <- grep(pattern, lines)
    if (length(hit) != 1L) {
      fail("Archived doitall.sh must contain exactly one base flag 92 for F", row$fishery)
    }
    replacement <- sprintf("\\1-%d 92 %d\\2", row$fishery, row$flag92)
    lines[[hit]] <- sub(pattern, replacement, lines[[hit]])
    lines[[hit]] <- sub("[[:space:]]*#.*$", "", lines[[hit]])
    lines[[hit]] <- paste0(
      sub("[[:space:]]+$", "", lines[[hit]]),
      sprintf(
        "  # Index %s HAC4 sigma: base %.2f, DE4 %.6f, target %.3f, applied %.2f",
        row$index,
        row$base_sigma,
        row$de4,
        row$target_sigma,
        row$flag92 / 100
      )
    )
  }
  lines
}

dm_nmax_target <- 20L

write_sensitivity_doitall <- function(
    to,
    tail_percent,
    divisor,
    lf_likelihood,
    dm_grouping,
    dm_estimate_relative_sample_size,
    selectivity_treatment) {
  source_path <- file.path(reference_input_dir, "doitall.sh")
  lines <- readLines(source_path, warn = FALSE)
  tc_hit <- grep("^[[:space:]]*1[[:space:]]+313[[:space:]]+", lines)
  if (length(tc_hit) != 1L) fail("Archived doitall.sh must contain one 1/313 flag")
  lines[[tc_hit]] <- replace_flag_value(
    lines[[tc_hit]],
    actor = 1L,
    flag = 313L,
    value = as.integer(tail_percent)
  )

  target_existing <- grep(
    "^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+",
    lines
  )
  if (length(target_existing)) {
    fail("Archived doitall.sh unexpectedly contains F21/F22/F23 flag-49 overrides")
  }
  global_49 <- grep("^[[:space:]]*-999[[:space:]]+49[[:space:]]+", lines)
  if (length(global_49) != 1L) fail("Archived doitall.sh must contain one global flag-49 line")
  if (!identical(lf_likelihood, "dm_nore")) {
    override_lines <- sprintf(
      "  -%d 49 %d  # sensitivity-only F%d LF effective-sample-size divisor",
      21:23,
      as.integer(divisor),
      21:23
    )
    lines <- append(lines, override_lines, after = global_49)
  }

  if (identical(lf_likelihood, "dm_nore")) {
    if (!dm_grouping %in% c("gear1", "gear2", "gear4", "process5", "quality7")) {
      fail("DM sensitivity requires a reviewed grouping mapping")
    }
    dm_group_ids <- dm_group_ids_for(dm_grouping)
    dm_group_names <- dm_group_names_for(dm_grouping)
    lf_likelihood_hit <- grep(
      "^[[:space:]]*1[[:space:]]+141[[:space:]]+", lines
    )
    lf_preprocess_hit <- grep(
      "^[[:space:]]*1[[:space:]]+311[[:space:]]+", lines
    )
    if (length(lf_likelihood_hit) != 1L || length(lf_preprocess_hit) != 1L) {
      fail("Archived doitall.sh must contain one LF likelihood and one LF tail-compression switch")
    }
    lines[[lf_likelihood_hit]] <-
      "  1 141 11    # LF Dirichlet-multinomial likelihood without random effects"
    lines[[lf_preprocess_hit]] <- paste(
      "  1 311 1",
      "# retain LF preprocessing gate so the inherited N < 50 filter remains active"
    )
    if (any(grepl("^[[:space:]]*1[[:space:]]+(320|342)[[:space:]]+", lines))) {
      fail("Archived doitall.sh unexpectedly contains DM parest flags 320 or 342")
    }
    lf_likelihood_hit <- grep(
      "^[[:space:]]*1[[:space:]]+141[[:space:]]+", lines
    )
    lines <- append(
      lines,
      c(
        "  1 320 5     # DM LF tail compression; retain at least five class intervals",
        sprintf("  1 342 %d  # DM-noRE maximum LF effective sample size", dm_nmax_target)
      ),
      after = lf_likelihood_hit
    )

    if (any(grepl("^[[:space:]]*-[0-9]+[[:space:]]+(68|69|89)[[:space:]]+", lines))) {
      fail("Archived doitall.sh unexpectedly contains LF DM fishery flags")
    }
    dm_group_lines <- sprintf(
      "  -%d 68 %d  # DM LF group: %s",
      as.integer(names(dm_group_ids)),
      dm_group_ids,
      dm_group_names[dm_group_ids]
    )
    global_49 <- grep("^[[:space:]]*-999[[:space:]]+49[[:space:]]+", lines)
    insertion_point <- global_49
    lines <- append(
      lines,
      c(
        dm_group_lines,
        "  -999 69 1  # estimate group-specific DM LF scalar exponent",
        "  -999 89 0  # stage relative sample-size exponent as fixed at zero"
      ),
      after = insertion_point
    )

    if (isTRUE(dm_estimate_relative_sample_size)) {
      phase2_open <- grep("<<PHASE2[[:space:]]*$", lines)
      if (length(phase2_open) != 1L) {
        fail("Archived doitall.sh must contain exactly one PHASE2 opening command")
      }
      lines <- append(
        lines,
        "  -999 89 1  # estimate group-specific DM LF relative sample-size exponent",
        after = phase2_open
      )
    }

    phase2_open <- grep("<<PHASE2[[:space:]]*$", lines)
    phase2_end <- grep("^PHASE2[[:space:]]*$", lines)
    if (length(phase2_open) != 1L || length(phase2_end) != 1L || phase2_open >= phase2_end) {
      fail("Archived doitall.sh must contain one complete PHASE2 block")
    }
    phase2_report <- grep(
      "^[[:space:]]*1[[:space:]]+190[[:space:]]+1([[:space:]]|$)",
      lines
    )
    phase2_report <- phase2_report[
      phase2_report > phase2_open & phase2_report < phase2_end
    ]
    if (length(phase2_report) != 1L) {
      fail("Archived doitall.sh must enable exactly one PHASE2 plot report")
    }
    lines[[phase2_report]] <- paste(
      "  1 190 0",
      "# defer DM plot reporting until the final phase; MFCL 2.4 crashes on the early report"
    )

    phase7_open <- grep("<<PHASE7[[:space:]]*$", lines)
    phase7_end <- grep("^PHASE7[[:space:]]*$", lines)
    if (length(phase7_open) != 1L || length(phase7_end) != 1L || phase7_open >= phase7_end ||
        !grepl("bet.frq 06.par 07.par", lines[[phase7_open]], fixed = TRUE)) {
      fail("Archived doitall.sh must contain the expected PHASE7 transition")
    }
    lines[[phase7_open]] <- sub(
      "bet.frq 06.par 07.par",
      "bet.frq 06a.par 07.par",
      lines[[phase7_open]],
      fixed = TRUE
    )
    lines <- append(
      lines,
      c(
        "# DM numerical continuation: estimate overall length-at-age SD first.",
        "$program_path bet.frq 06.par 06a.par -file - <<PHASE7A",
        "  1 15 1   # estimate overall SD of length-at-age",
        "  1 16 0   # retain length-dependent SD fixed for this transition",
        "  1 1 250  # function evaluations",
        "  1 50 -1  # convergence criterion",
        "PHASE7A",
        ""
      ),
      after = phase7_open - 1L
    )

    phase9_open <- grep("<<PHASE9[[:space:]]*$", lines)
    phase9_end <- grep("^PHASE9[[:space:]]*$", lines)
    if (length(phase9_open) != 1L || length(phase9_end) != 1L || phase9_open >= phase9_end ||
        !grepl("bet.frq 08.par 09.par", lines[[phase9_open]], fixed = TRUE)) {
      fail("Archived doitall.sh must contain the expected PHASE9 transition")
    }
    lines[[phase9_open]] <- sub(
      "bet.frq 08.par 09.par",
      "bet.frq 08a.par 09.par",
      lines[[phase9_open]],
      fixed = TRUE
    )
    lines <- append(
      lines,
      c(
        "# DM numerical continuation: relax the SRR penalty before widening the tag F bound.",
        "$program_path bet.frq 08.par 08a.par -file - <<PHASE9A",
        "  2 145 -1   # SRR penalty weight 10^-1",
        "  1 1 500    # function evaluations",
        "  1 50 -2    # convergence criterion",
        "  2 116 100  # retain tag Newton-Raphson F bound at 1.0",
        "PHASE9A",
        ""
      ),
      after = phase9_open - 1L
    )

    phase11_open <- grep("<<PHASE11[[:space:]]*$", lines)
    phase11_end <- grep("^PHASE11[[:space:]]*$", lines)
    if (length(phase11_open) != 1L || length(phase11_end) != 1L || phase11_open >= phase11_end) {
      fail("Archived doitall.sh must contain one complete PHASE11 block")
    }
    if (any(grepl(
      "^[[:space:]]*1[[:space:]]+190[[:space:]]+1([[:space:]]|$)",
      lines[seq.int(phase11_open, phase11_end)]
    ))) {
      fail("Archived doitall.sh unexpectedly enables plot reporting inside PHASE11")
    }
    lines <- append(
      lines,
      "  1 190 1  # write the DM plot report only after all fitting phases are active",
      after = phase11_end - 1L
    )
  }
  lines <- apply_cpue_hac4_sigma(lines)
  lines <- apply_selectivity_treatment(lines, selectivity_treatment)
  lines <- canonicalize_final_selectivity_group_labels(lines, selectivity_treatment)
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}

design_context_note <- function(row) {
  paste(
    "This model belongs to the public 41-model design: 30 core age-length/LF",
    "combinations, two targeted N8 controls, five core TAGF2ON controls,",
    "and normal plus DM OPR tag-control pairs. Every model uses the complete",
    "single-area-derived selectivity baseline, including F29-F33 first-two-age",
    "zeros; N8 changes only F12 PS.JP.1 and F13 PL.JP.1. Age-length levels are",
    "BASE075, REG075, REG100, SUB075, and SUB100. DM models use DM-noRE,",
    "G5PROC, estimated relative sample-size exponent C, and Nmax 20.",
    "All models on this branch use the HAC4-adjusted CPUE sigma flags",
    "F29-F33 = 40, 30, 35, 32, and 30 while retaining the original FRQ",
    "effort_weight variance multipliers and parest flag 371=0 semantics.",
    "TAGF2ON changes only all 98 tag_flags(:,2) values. OPR is activated in",
    "phase 3, movement in phase 4, and regional scaling in phase 5; terminal",
    "penalty is disabled. Fish flag 26=2 evaluates the flag-57 cubic spline on",
    "scaled mean length-at-age to produce final selectivity-at-age; flag-61",
    "nodes use that coordinate, while flags 75/3/16 remain age constraints.",
    "This setting is separate from the LF likelihood. This model uses age-length level",
    paste0(as.character(row$age_length_variant), ".")
  )
}

write_model_manifest <- function(step_dir, row, treatment, has_cutoff) {
  reference_source <- file.path(
    "reference-inputs", "job-5319", "mfcl-inputs"
  )
  anchor_note <- paste0(
    "MFCL-setting-identical to the retained Job 5319 anchor; public explanatory ",
    "doitall comments are normalized in the refreshed reference ",
    "bundle; reference-set SHA-256 ", expected_reference_sha256, "."
  )
  stepwise_refresh_note <- paste0(
    "Refreshed from PacificCommunity/ofp-sam-bet-2026-stepwise@",
    stepwise_refresh_commit, " (", stepwise_refresh_ref, ")."
  )
  build_ini_note <- paste0(
    "Upstream INI from ", build_ini_source, "@", build_ini_commit,
    " path ", build_ini_source_path, "."
  )
  is_dm <- identical(as.character(row$lf_likelihood), "dm_nore")
  is_opr <- isTRUE(row$opr_enabled[[1L]])
  step_id <- as.character(row$step_id)
  is_tag_flag_sensitivity <- step_id %in% tag_flag_sensitivity_ids
  tag_flag_reference <- unname(tag_flag_sensitivity_controls[step_id])
  selectivity_treatment <- as.character(row$selectivity_treatment)
  has_selectivity_sensitivity <- !identical(selectivity_treatment, "reference")
  selectivity_note <- selectivity_treatment_note(selectivity_treatment)
  frq_note <- paste(
    paste0(
      "Exact retained Job 5319 effort-crept bet.frq; SHA-256 ",
      expected_frq_sha256, "."
    ),
    treatment,
    cutoff_provenance(as.numeric(row$cutoff_cm)),
    if (has_cutoff && is_dm) {
      paste(
        "Counts are not transferred; retained LF categories use MFCL option 11;",
        "MFCL internally normalizes retained counts; an all-zero LF vector",
        "becomes one -1 whole-sample sentinel."
      )
    } else if (has_cutoff) {
      paste(
        "Counts are not transferred; LF categories remain in the MFCL option-3",
        "likelihood; MFCL internally renormalizes retained counts; an all-zero",
        "LF vector becomes one -1 whole-sample sentinel."
      )
    } else {
      "No FRQ transform is applied."
    },
    "Effort creep is not reapplied."
  )
  if (is_dm && !has_cutoff) {
    frq_note <- paste(
      frq_note,
      "All extraction and index LF observations are retained byte-for-byte.",
      "The normal-likelihood flag-49 extra /2 correction is inert under",
      "option 11 and therefore is not reproduced in this DM sensitivity."
    )
  } else if (is_dm) {
    frq_note <- paste(
      frq_note,
      "All F29/F30/F31/F32/F33 index LF observations are retained unchanged.",
      "Only the established F21/F22/F23 upper-bin cutoff transform is applied.",
      "The normal-likelihood flag-49 extra /2 correction is inert under",
      "option 11 and therefore is not reproduced in this DM sensitivity."
    )
  }
  if (is_dm) {
    group_count <- switch(
      as.character(row$dm_grouping),
      process5 = 5L,
      fail("Manifest generation supports only the reviewed process5 DM grouping")
    )
    c_note <- if (isTRUE(row$dm_estimate_relative_sample_size[[1L]])) {
      "the relative sample-size exponent is fixed at zero in PHASE1 and estimated from PHASE2"
    } else {
      "the relative sample-size exponent remains fixed at MFCL default zero in every phase"
    }
    cutoff_note <- if (has_cutoff) {
      sprintf(
        "the established F21/F22/F23 cutoff above %.0f cm is applied",
        as.numeric(row$cutoff_cm)
      )
    } else {
      "no LF cutoff is applied"
    }
    doitall_note <- paste(
      "Retained Job 5319 doitall sequence with LF likelihood option 11;",
      "the LF preprocessing gate and N < 50 filter retained; percentage and",
      "DM-specific LF tail compression retains at least five class intervals; DM maximum effective sample",
      sprintf("size %d;", dm_nmax_target),
      "Nmax is fixed from PHASE1 and inherited by every later phase;",
      group_count, "reviewed LF group(s); group-specific scalar",
      "exponents estimated from PHASE1;", paste0(c_note, ";"), paste0(cutoff_note, "."),
      "Inherited flag-49 lines are inert under DM-noRE, so the normal models'",
      "fixed extra /2 is not reproduced. These are deliberate DM",
      "grouping/overdispersion sensitivities, not exact duplicate-use corrections."
    )
  } else {
    doitall_note <- sprintf(
      paste0(
        "Retained Job 5319 doitall control sequence except parest flag ",
        "313=%d and three new flag-49 overrides for F21/F22/F23, each with ",
        "divisor %d; %s"
      ),
      as.integer(row$tail_compression_percent),
      as.integer(row$lf_size_divisor),
      if (has_selectivity_sensitivity) {
        "all inherited non-selectivity settings are unchanged."
      } else {
        "inherited settings for every other fishery are unchanged."
      }
    )
  }
  if (has_selectivity_sensitivity) {
    doitall_note <- paste(
      doitall_note,
      selectivity_note,
      if (selectivity_treatment %in% c("sa28_n5", "sa28_n8")) {
        paste0(
          "Extraction constraints are mapped from ",
          single_area_selectivity_source, "@", single_area_selectivity_commit, "."
        )
      } else {
        "No extraction selectivity control is changed."
      }
    )
  }
  if (is_opr) {
    doitall_note <- paste(
      doitall_note,
      opr_source_note,
      paste(
        "Fixed OPR controls: parest 155=72, 221=72, 202=2, 217=1,",
        "216=50, 218=50, and 397=0. Terminal penalty is disabled and is",
        "not a sensitivity axis."
      )
    )
  }
  doitall_note <- paste(doitall_note, cpue_hac4_manifest_note)

  manifest_sources <- file.path(
    reference_source,
    c(
      "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
      "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
      "tag_rep_map.R"
    )
  )
  manifest_sources[[2L]] <- paste0(
    "https://github.com/", build_ini_source, "/blob/", build_ini_commit, "/",
    build_ini_source_path
  )
  manifest_source_commits <- c(
    "", build_ini_commit, tag_prep_commit, "",
    stepwise_refresh_commit, stepwise_refresh_commit, "", "",
    stepwise_refresh_commit, ""
  )
  age_length_note <- anchor_note
  if (!identical(as.character(row$age_length_variant), "BASE075")) {
    manifest_sources[[4L]] <- as.character(row$age_length_source_path)
    manifest_source_commits[[4L]] <- age_length_source_commit
    age_length_note <- paste(
      "Exact", as.character(row$age_length_variant), "age-length input from",
      paste0(age_length_source_repo, "@", age_length_source_commit, ";"),
      paste0("original file ", as.character(row$age_length_source_file), ";"),
      paste0("SHA-256 ", as.character(row$age_length_sha256), ".")
    )
  }

  manifest <- data.frame(
    role = c(
      "frq", "ini", "tag", "age_length", "reg_scaling",
      "reg_scaling_full", "doitall", "mfcl_config", "fishery_map",
      "tag_reporting_map"
    ),
    file = c(
      "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
      "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
      "tag_rep_map.R"
    ),
    source = manifest_sources,
    source_commit = manifest_source_commits,
    note = c(
      frq_note,
      paste(
        build_ini_note,
        paste0("Tag-control ini SHA-256 ", expected_ini_sha256, ";"),
        if (is_tag_flag_sensitivity) {
          paste(
            paste0(step_id, " restores all 98 tag_flags(:,2) values to the upstream value 1;"),
            paste0("its exact flag-column-2=0 control is ", tag_flag_reference, ";"),
            "column 1 and every other INI value remain unchanged."
          )
        } else {
          paste(
            "the only intentional deviation from that upstream file is that all 98",
            "tag_flags(:,2) values are 0."
          )
        }
      ),
      paste(
        paste0("Latest tag data from ", tag_prep_source, "@", tag_prep_commit, " (main);"),
        paste0("tag SHA-256 ", expected_tag_sha256, "; byte-identical to PDH 13-DataWeighting.")
      ),
      age_length_note,
      paste(
        stepwise_refresh_note,
        "MFCL-ready active matrix, exactly full-source rows 53:72 (20x5); fixed weight 50."
      ),
      paste(
        stepwise_refresh_note,
        "Complete 292x5 sensitivity source retained for alternative period windows; not read by MFCL."
      ),
      doitall_note,
      anchor_note,
      paste(
        stepwise_refresh_note,
        if (selectivity_treatment %in% c("sa28_n5", "sa28_n8")) {
          paste(
            "Updated fishery names plus corrected independent F1-F28 display groups;",
            "regional indices share group 29 in phases 1-4 and split to groups 29:33 in phase 5."
          )
        } else {
          "Updated fishery names used by MFCLShiny."
        }
      ),
      paste(
        "Generated from the derived bet.ini and refreshed fishery_map.R;",
        paste0("INI upstream ", build_ini_source, "@", build_ini_commit, ";"),
        paste0("fishery metadata ", stepwise_refresh_note),
        "reporting groups match bet.ini and bet.tag."
      )
    ),
    stringsAsFactors = FALSE
  )
  manifest <- rbind(
    manifest,
    data.frame(
      role = "design_context",
      file = "job-config.R",
      source = "job-config.R",
      source_commit = NA_character_,
      note = design_context_note(row),
      stringsAsFactors = FALSE
    )
  )
  if (has_cutoff) {
    manifest <- rbind(
      manifest,
      data.frame(
        role = "frq_transform_audit",
        file = "lf_cutoff_audit.csv",
        source = file.path(reference_source, "bet.frq"),
        source_commit = NA_character_,
        note = paste(
          treatment,
          "The audit reconciles removed counts, affected records, all-zero LF sentinels, and minimum-sample crossings."
        ),
        stringsAsFactors = FALSE
      )
    )
  }
  if (is_opr) {
    manifest <- rbind(
      manifest,
      data.frame(
        role = "opr_settings",
        file = "opr_settings.csv",
        source = "R/prepare_doitall.R::apply_opr",
        source_commit = NA_character_,
        note = paste(
          opr_source_note,
          "Y72-E2-S01-R50-I50; compatibility 221=72; parest 397=0."
        ),
        stringsAsFactors = FALSE
      )
    )
  }
  utils::write.csv(
    manifest,
    file.path(step_dir, "input_manifest.csv"),
    row.names = FALSE,
    na = ""
  )
}

add_age_length_readme <- function(lines, row) {
  if (identical(as.character(row$age_length_variant), "BASE075")) return(lines)
  status_line <- grep("^Status:", lines)
  if (length(status_line) != 1L) fail("Generated model README must contain one status line")
  section <- c(
    "",
    "## Age-length variant",
    "",
    paste0("Semantic level: `", as.character(row$age_length_variant), "`."),
    paste0("Paired base sensitivity: `", as.character(row$base_sensitivity), "`."),
    paste0("Model input: `", as.character(row$age_length_source_path), "`."),
    paste0("Source repository: ", age_length_source_repo, "."),
    paste0("Source commit: `", age_length_source_commit, "`."),
    paste0("Source file: `", as.character(row$age_length_source_file), "`."),
    paste0("SHA-256: `", as.character(row$age_length_sha256), "`."),
    paste(
      "Every other model input and all inherited normal/DM/cutoff controls are",
      "identical to the paired BASE075 sensitivity."
    )
  )
  append(lines, section, after = status_line[[1L]] - 2L)
}

add_design_context_readme <- function(lines, row) {
  status_line <- grep("^Status:", lines)
  if (length(status_line) != 1L) fail("Generated model README must contain one status line")
  section <- c(
    "",
    "## 41-model design context",
    "",
    design_context_note(row)
  )
  append(lines, section, after = status_line[[1L]] - 2L)
}

add_selectivity_readme <- function(lines, row) {
  treatment <- as.character(row$selectivity_treatment)
  if (identical(treatment, "reference")) return(lines)
  status_line <- grep("^Status:", lines)
  if (length(status_line) != 1L) fail("Generated model README must contain one status line")
  scientific_question <- switch(
    treatment,
    sa28_n5 = paste(
      "This is the promoted core baseline: independent extraction groups, audited",
      "support constraints, five nodes, and phase-5 regional-index splitting."
    ),
    sa28_n8 = paste(
      "This changes only F12 PS.JP.1 and F13 PL.JP.1 from five to eight nodes",
      "relative to the complete corrected N5 baseline."
    )
  )
  is_promoted_baseline <- identical(treatment, "sa28_n5")
  section <- c(
    "",
    if (is_promoted_baseline) "## Corrected selectivity baseline" else "## Selectivity sensitivity",
    "",
    paste0(
      "Selectivity nodes: `",
      if (treatment == "sa28_n8") "N8" else "N5",
      "`. The single-area-derived F1-F28 structure is common to all 41 models."
    ),
    if (!is_promoted_baseline) {
      paste0("Paired N5 reference: `", as.character(row$selectivity_reference), "`.")
    } else NULL,
    selectivity_treatment_note(treatment),
    scientific_question,
    paste(
      "The LF likelihood, CUT90 transform, composition weighting, BASE075",
      "age-length input, tag controls, phase sequence, and regional-scaling",
      "settings are inherited from the paired reference."
    ),
    if (identical(treatment, "sa28_n8")) {
      "All non-F12/F13 selectivity settings are required to be identical to corrected N5."
    } else NULL,
    if (treatment %in% c("sa28_n5", "sa28_n8")) {
      paste0(
        "Corrected selectivity source: `", single_area_selectivity_source, "@",
        single_area_selectivity_commit, "`."
      )
    } else {
      "The current five-region extraction configuration is retained exactly."
    }
  )
  append(lines, section, after = status_line[[1L]] - 2L)
}

append_opr_readme <- function(step_dir, row) {
  if (!isTRUE(row$opr_enabled[[1L]])) return(invisible(step_dir))
  path <- file.path(step_dir, "README.md")
  lines <- readLines(path, warn = FALSE)
  status_line <- grep("^Status:", lines)
  if (length(status_line) != 1L) fail("Generated OPR README must contain one status line")
  section <- c(
    "",
    "## Recruitment OPR control",
    "",
    "This model uses the reviewed BET `apply_opr()` switch semantics.",
    "",
    "| MFCL control | Fixed value |",
    "| --- | ---: |",
    "| Annual OPR coefficients, parest 155 | 72 |",
    "| Compatibility state, parest 221 | 72 |",
    "| End window, parest 202 | 2 |",
    "| Season coefficients, parest 217 | 1 |",
    "| Region coefficients, parest 216 | 50 |",
    "| Region-season coefficients, parest 218 | 50 |",
    "| Terminal penalty, parest 397 | 0 (disabled) |",
    "",
    paste(
      "The OPR structure is fixed at Y72-E2-S01-R50-I50. Terminal penalty",
      "is disabled in every OPR model and is not a sensitivity axis. OPR is",
      "activated in phase 3, movement in phase 4, and regional scaling in phase 5."
    ),
    opr_source_note
  )
  lines <- append(lines, section, after = status_line[[1L]] - 2L)
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

write_model_readme <- function(step_dir, row, treatment, audit = NULL) {
  is_dm <- identical(as.character(row$lf_likelihood), "dm_nore")
  step_id <- as.character(row$step_id)
  is_tag_flag_sensitivity <- step_id %in% tag_flag_sensitivity_ids
  tag_flag_reference <- unname(tag_flag_sensitivity_controls[step_id])
  if (is_dm) {
    grouping <- as.character(row$dm_grouping)
    grouping_text <- switch(
      grouping,
      gear1 = "G1: F1:F33 in one pooled LF group",
      gear2 = "G2: extraction F1:F28 in group 1; index F29:F33 in group 2",
      gear4 = paste(
        "G4: longline F1:F11; purse seine F12/F17:F20/F25:F28;",
        "other extraction F13:F16/F21:F24; index F29:F33"
      ),
      process5 = paste(
        "G5PROC: longline F1:F11; large-scale purse seine F12/F19:F20/F25:F28;",
        "domestic purse seine F17:F18; other extraction F13:F16/F21:F24;",
        "index F29:F33"
      ),
      quality7 = paste(
        "G7QUAL: longline F1:F11; associated purse seine F19/F25:F26;",
        "unassociated purse seine F20/F27:F28; domestic purse seine F17:F18;",
        "Japanese PS/PL F12:F13; other extraction F14:F16/F21:F24;",
        "index F29:F33"
      )
    )
    grouping_basis <- switch(
      grouping,
      process5 = paste(
        "This primary grouping follows observation and reweighting processes:",
        "catch-reweighted longline, large-scale purse seine, domestic purse seine,",
        "unreweighted or small-scale extraction, and abundance-reweighted index LF."
      ),
      quality7 = paste(
        "This secondary grouping challenges G5PROC by separating associated and",
        "unassociated purse seine LF and pooling the low-catch, multimodal Japanese",
        "PS/PL series identified in the 2023 assessment."
      ),
      ""
    )
    c_text <- if (isTRUE(row$dm_estimate_relative_sample_size[[1L]])) {
      "CEST: c is fixed at zero in PHASE1 and estimated from PHASE2"
    } else {
      "C0: c remains fixed at MFCL default zero in every phase"
    }
    cutoff_value <- as.numeric(row$cutoff_cm)
    cutoff_text <- if (is.finite(cutoff_value)) {
      sprintf("Established F21/F22/F23 upper-bin cutoff above %.0f cm", cutoff_value)
    } else {
      "None"
    }
    audit_line <- if (is.data.frame(audit)) {
      paste(
        sprintf(
          "F%d removed %s counts from %d records (%d all-zero LF sentinels)",
          audit$fishery,
          format(audit$removed_count, digits = 15L, trim = TRUE),
          audit$affected_records,
          audit$emptied_records
        ),
        collapse = "; "
      )
    } else {
      "No LF transform is applied; bet.frq is byte-identical to the Job 5319 archive."
    }
    lines <- c(
      paste0("# ", as.character(row$job_title)),
      "",
      "This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.",
      "",
      "## Design",
      "",
      "| Control | Setting |",
      "| --- | --- |",
      "| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |",
      paste0("| LF grouping | ", grouping_text, " |"),
      "| Group scalar exponent d | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |",
      paste0("| Relative sample-size exponent c | ", c_text, " |"),
      paste0("| DM maximum effective sample size | ", dm_nmax_target, " |"),
      "| DM fitting | Nmax 20 from PHASE1 onward; later phases inherit it unchanged |",
      "| LF preprocessing | Enabled; inherited N < 50 filter retained |",
      "| LF tail compression | Percentage compression disabled; DM compression retains at least five class intervals (`parest flag 320 = 5`) |",
      paste0("| LF cutoff | ", cutoff_text, " |"),
      "| Index LF | F29:F33 retained unchanged |",
      "| Regional-scaling penalty weight | 50 |",
      "| CPUE sigma sensitivity | HAC4 flags F29:F33 = 40, 30, 35, 32, 30; flag 66=1 retained |",
      "",
      if (nzchar(grouping_basis)) c(
        "## Grouping rationale",
        "",
        grouping_basis,
        paste(
          "The grouping is informed by WCPFC-SC19-2023/SA-WP-05 and",
          "WCPFC-SC22-2026/SA-IP06; it changes DM dispersion sharing only,",
          "not fishery definitions, selectivity sharing, or LF observations."
        ),
        ""
      ) else character(),
      "## Interpretation",
      "",
      paste(
        "The normal-likelihood models use flag 49 to apply an extra /2 to LF",
        "streams used as both extraction and index data. MFCL option 11 ignores",
        "flag 49 and has no fixed 0.5 LF-contribution control, so that correction",
        "cannot be reproduced in these models."
      ),
      paste(
        "Both extraction and index LF representations are retained. Grouping and",
        "DM overdispersion are the sensitivity axes; they are not exact",
        "duplicate-use corrections and do not model correlation introduced by",
        "aggregation differences between representations."
      ),
      if (is.finite(cutoff_value)) {
        paste(
          treatment,
          "This is exactly the established transform used by the corresponding",
          "normal-likelihood cutoff model; no index or other fishery LF is changed."
        )
      } else {
        "No LF cutoff transform is applied."
      },
      "",
      "## Provenance and audit",
      "",
      paste0("The reference input-set SHA-256 is `", expected_reference_sha256, "`."),
      paste0("The retained Job 5319 effort-crept `bet.frq` SHA-256 is `", expected_frq_sha256, "`; effort creep is not reapplied."),
      audit_line,
      paste0(
        "The tag-control `.ini` comes from `", build_ini_source, "@",
        build_ini_commit, "` path `", build_ini_source_path,
        "`, with only `tag_flags(:,2)` changed from 1 to 0."
      ),
      paste0("The tag data come from tag-prep commit `", tag_prep_commit, "`."),
      "No MFCL source or executable is changed.",
      "",
      "Status: generated and ready for validation; Kflow has not been submitted."
    )
    lines <- add_selectivity_readme(lines, row)
    lines <- add_age_length_readme(lines, row)
    lines <- add_design_context_readme(lines, row)
    writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
    return(invisible(step_dir))
  }
  cutoff_value <- as.numeric(row$cutoff_cm)
  cutoff_label <- if (is.finite(cutoff_value)) {
    sprintf("above %.0f cm", cutoff_value)
  } else {
    "none"
  }
  audit_line <- if (is.data.frame(audit)) {
    paste(
      sprintf(
        "F%d removed %s counts from %d records (%d all-zero LF sentinels)",
        audit$fishery,
        format(audit$removed_count, digits = 15L, trim = TRUE),
        audit$affected_records,
        audit$emptied_records
      ),
      collapse = "; "
    )
  } else {
    "No cutoff audit is required because bet.frq is byte-identical to the Job 5319 archive."
  }
  lines <- c(
    paste0("# ", as.character(row$job_title)),
    "",
    "This is one model in the curated BET 2026 TC1 LF sensitivity set.",
    "",
    "## Design",
    "",
    "| Control | Setting |",
    "| --- | --- |",
    sprintf("| Global MFCL LF tail compression | %d%% |", as.integer(row$tail_compression_percent)),
    sprintf("| F21/F22/F23 observed LF upper-bin zeroing | %s |", cutoff_label),
    sprintf("| F21/F22/F23 LF likelihood downweight | %dx; flag-49 divisor %d |", as.integer(row$lf_downweight_factor), as.integer(row$lf_size_divisor)),
    "| Regional-scaling penalty weight | 50 |",
    "",
    "## Observed LF semantics",
    "",
    treatment,
    cutoff_provenance(cutoff_value),
    paste(
      "The bins remain as categories in the MFCL option-3 LF likelihood, and",
      "MFCL internally renormalizes retained counts. Counts are not transferred.",
      "An all-zero LF vector is represented by one `-1` whole-sample sentinel;",
      "record metadata and weight-frequency data remain unchanged."
    ),
    "",
    "## Provenance and controls",
    "",
    paste0(
      "The refreshed reference bundle has input-set SHA-256 `",
      expected_reference_sha256, "`."
    ),
    paste0(
      "The retained Job 5319 effort-crept `bet.frq` has SHA-256 `", expected_frq_sha256,
      "`; effort creep is not reapplied."
    ),
    if (is_tag_flag_sensitivity) {
      paste0(
        "`bet.ini` starts from `", build_ini_source, "@", build_ini_commit,
        "` path `", build_ini_source_path,
        "`. ", step_id,
        " restores all 98 `tag_flags(:,2)` values to the upstream value 1; its exact ",
        "flag-column-2=0 control is `", tag_flag_reference,
        "`; column 1 and every other INI value remain unchanged."
      )
    } else {
      paste0(
        "`bet.ini` comes wholesale from `", build_ini_source, "@", build_ini_commit,
        "` path `", build_ini_source_path,
        "`; the only intentional deviation is changing all 98 `tag_flags(:,2)` values from 1 to 0."
      )
    },
    paste0(
      "`fishery_map.R` comes from stepwise commit `", stepwise_refresh_commit,
      "`; `tag_rep_map.R` is regenerated from that metadata and the derived `bet.ini`."
    ),
    paste0(
      "`bet.tag` is the latest tag-prep main file at commit `",
      tag_prep_commit, "` and is byte-identical to PDH 13-DataWeighting."
    ),
    paste(
      "`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and",
      "`bet.reg_scaling.full` retains the complete 292x5 sensitivity source.",
      "The active matrix is exactly full-source rows 53:72."
    ),
    if (identical(as.character(row$selectivity_treatment), "reference")) {
      paste(
        "The `doitall.sh` changes are limited to flag 313 and three new",
        "F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls",
        "remain unchanged."
      )
    } else {
      paste(
        "Beyond the inherited CUT90 and flag-49 treatment, `doitall.sh` changes",
        "only the documented selectivity treatment; all other Job 5319 controls",
        "remain unchanged."
      )
    },
    "No MFCL source or executable is changed.",
    "",
    "## Cutoff audit",
    "",
    audit_line,
    "",
    "Status: generated and ready for validation; Kflow has not been submitted."
  )
  lines <- add_selectivity_readme(lines, row)
  lines <- add_age_length_readme(lines, row)
  lines <- add_design_context_readme(lines, row)
  writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
}

regional_active_lines <- readLines(
  file.path(reference_input_dir, "bet.reg_scaling"), warn = FALSE
)
regional_full_lines <- readLines(
  file.path(reference_input_dir, "bet.reg_scaling.full"), warn = FALSE
)
regional_active_fields <- lengths(strsplit(trimws(regional_active_lines), "[[:space:]]+"))
regional_full_fields <- lengths(strsplit(trimws(regional_full_lines), "[[:space:]]+"))
if (length(regional_active_lines) != 20L || any(regional_active_fields != 5L)) {
  fail("Reference bet.reg_scaling must be exactly 20x5")
}
if (length(regional_full_lines) != 292L || any(regional_full_fields != 5L)) {
  fail("Reference bet.reg_scaling.full must be exactly 292x5")
}
if (!identical(regional_active_lines, regional_full_lines[53:72])) {
  fail("Reference bet.reg_scaling must equal bet.reg_scaling.full rows 53:72")
}

staging_root <- tempfile("sensitivity-staging-", tmpdir = root)
backup_root <- tempfile("sensitivity-backup-", tmpdir = root)
dir.create(staging_root, recursive = TRUE, showWarnings = FALSE)
on.exit({
  if (dir.exists(staging_root)) unlink(staging_root, recursive = TRUE, force = TRUE)
  if (dir.exists(backup_root) && !dir.exists(sensitivity_root)) {
    file.rename(backup_root, sensitivity_root)
  }
}, add = TRUE)

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  step_id <- as.character(row$step_id)
  step_dir <- file.path(staging_root, step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  for (file in c(
    "bet.frq", "bet.ini", "bet.tag", "bet.reg_scaling",
    "bet.reg_scaling.full", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
  )) {
    copy_exact(
      file.path(reference_input_dir, file),
      file.path(model_dir, file)
    )
  }
  copy_exact(
    file.path(root, as.character(row$age_length_source_path)),
    file.path(model_dir, "bet.age_length")
  )
  apply_selectivity_fishery_map(
    file.path(model_dir, "fishery_map.R"),
    as.character(row$selectivity_treatment)
  )

  cutoff_cm <- as.numeric(row$cutoff_cm)
  cutoff_audit <- NULL
  if (is.finite(cutoff_cm)) {
    cutoff_audit <- apply_lf_upper_cutoffs(
      file.path(model_dir, "bet.frq"),
      max_bin_by_fishery = stats::setNames(rep(cutoff_cm, 3L), c("21", "22", "23"))
    )
    cutoff_audit$transform <- "lf_upper_cutoff"
    utils::write.csv(
      cutoff_audit,
      file.path(model_dir, "lf_cutoff_audit.csv"),
      row.names = FALSE,
      na = ""
    )
  }

  if (as.character(row$step_id) %in% tag_flag_sensitivity_ids) {
    restore_upstream_tag_flag_column2(file.path(model_dir, "bet.ini"))
  }
  canonicalize_tag_reporting_group_labels(file.path(model_dir, "bet.ini"))
  validate_tag_reporting_grouped_initial_values(file.path(model_dir, "bet.ini"))
  write_generated_tag_rep_map(model_dir)

  write_sensitivity_doitall(
    file.path(model_dir, "doitall.sh"),
    tail_percent = as.integer(row$tail_compression_percent),
    divisor = as.integer(row$lf_size_divisor),
    lf_likelihood = as.character(row$lf_likelihood),
    dm_grouping = as.character(row$dm_grouping),
    dm_estimate_relative_sample_size =
      isTRUE(row$dm_estimate_relative_sample_size[[1L]]),
    selectivity_treatment = as.character(row$selectivity_treatment)
  )
  if (isTRUE(row$opr_enabled[[1L]])) {
    doitall_path <- file.path(model_dir, "doitall.sh")
    lines <- readLines(doitall_path, warn = FALSE)
    lines <- opr_helper_env$apply_opr(
      lines,
      year_effect = 72L,
      season_effect = 1L,
      region_effect = 50L,
      region_season_effect = 50L,
      terminal_year_constraint = 2L,
      terminal_penalty_flag = 0L,
      compatibility_year_effect = 72L
    )
    if (any(grepl("^[[:space:]]*1[[:space:]]+397[[:space:]]+100([[:space:]]|$)", lines))) {
      fail(step_id, " unexpectedly enables the terminal penalty")
    }
    writeLines(lines, doitall_path, useBytes = TRUE)
    Sys.chmod(doitall_path, mode = "0755")
    utils::write.csv(
      data.frame(
        year_effect = 72L,
        terminal_year_constraint = 2L,
        season_effect = 1L,
        region_effect = 50L,
        region_season_effect = 50L,
        compatibility_year_effect = 72L,
        terminal_penalty_flag = 0L,
        source = "R/prepare_doitall.R::apply_opr",
        stringsAsFactors = FALSE
      ),
      file.path(step_dir, "opr_settings.csv"),
      row.names = FALSE,
      na = ""
    )
  }
  treatment <- cutoff_sentence(cutoff_cm)
  write_model_manifest(
    step_dir,
    row,
    treatment,
    has_cutoff = is.finite(cutoff_cm)
  )
  write_model_readme(step_dir, row, treatment, cutoff_audit)
  append_opr_readme(step_dir, row)
}

if (!file.rename(sensitivity_root, backup_root)) {
  fail("Could not move the existing sensitivity tree to its atomic backup")
}
if (!file.rename(staging_root, sensitivity_root)) {
  file.rename(backup_root, sensitivity_root)
  fail("Could not install the fully generated sensitivity tree")
}
unlink(backup_root, recursive = TRUE, force = TRUE)

cat(sprintf("Generated %d sensitivity folders from the refreshed reference bundle.\n", nrow(models)))
cat(sprintf("Refreshed reference input-set SHA-256: %s\n", reference_sha256))
cat(sprintf("Job 5319 archived bet.frq SHA-256: %s\n", frq_sha256))
cat(sprintf(
  "Build-ini tag-control source: %s@%s (%s)\n",
  build_ini_source, build_ini_commit, build_ini_source_path
))
cat(sprintf("Stepwise supporting-input source commit: %s\n", stepwise_refresh_commit))
cat(sprintf("Tag-prep main source commit: %s\n", tag_prep_commit))
cat("Regional scaling: active 20x5 plus retained full 292x5 source\n")
cat("Effort creep reapplied: no\n")
cat("Kflow submitted: no\n")
