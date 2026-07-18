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

expected_runtime_image <- paste0(
  "ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:",
  "c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360"
)
kflow_path <- file.path(repo_root, "kflow.yaml")
if (!file.exists(kflow_path)) fail("Missing kflow.yaml")
kflow_lines <- readLines(kflow_path, warn = FALSE)
docker_image_lines <- grep("^[[:space:]]*docker_image:[[:space:]]*", kflow_lines, value = TRUE)
actual_runtime_image <- if (length(docker_image_lines) == 1L) {
  trimws(sub("^[[:space:]]*docker_image:[[:space:]]*", "", docker_image_lines))
} else {
  ""
}
if (length(docker_image_lines) != 1L ||
    !identical(actual_runtime_image, expected_runtime_image)) {
  fail("kflow.yaml must use the exact tested digest-pinned Tuna Flow v2.5 image")
}

config_env <- new.env(parent = globalenv())
sys.source(file.path(repo_root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models
if (!is.data.frame(models)) fail("job-config.R did not create the stepwise_models data frame")

core_prefixes <- sprintf("S%03d", 1:30)
selectivity_prefixes <- c("S031", "S032")
tag_prefixes <- sprintf("S%03d", 33:37)
opr_prefixes <- sprintf("S%03d", 38:41)
expected_prefixes <- c(core_prefixes, selectivity_prefixes, tag_prefixes, opr_prefixes)
actual_prefixes <- sub("-.*$", "", as.character(models$step_id))
if (nrow(models) != 41L || !identical(actual_prefixes, expected_prefixes)) {
  fail("Expected 41 models with prefixes S001:S030, S031, S032, and S033:S041")
}
if (anyDuplicated(models$step_id)) fail("Model IDs are not unique")

selection_path <- file.path(repo_root, "SENSITIVITY_SELECTION.csv")
selection <- read.csv(selection_path, stringsAsFactors = FALSE, check.names = FALSE)
if (nrow(selection) != 41L ||
    !identical(as.character(selection$model), as.character(models$step_id))) {
  fail("SENSITIVITY_SELECTION.csv must contain exactly the current S001:S041 models")
}
tag_controls <- c(
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
if (!all(names(tag_controls) %in% models$step_id)) {
  fail("TAGF2ON identities do not match the confirmed seven-model design")
}

tag_index <- match(names(tag_controls), models$step_id)
control_index <- match(unname(tag_controls), models$step_id)
if (anyNA(tag_index) || anyNA(control_index) ||
    any(models$age_length_variant[tag_index] != "BASE075") ||
    any(models$tag_flag2[tag_index] != 1L) ||
    any(models$tag_flag2[-tag_index] != 0L) ||
    any(models$selectivity_treatment[models$selectivity_treatment != "sa28_n8"] != "sa28_n5")) {
  fail("Core/TAGF2ON baseline, BASE075, or tag-flag design is incorrect")
}

semantic_columns <- c(
  "run_mode", "region_count", "regional_scaling_weight",
  "tail_compression_percent", "cutoff_cm", "cutoff_code",
  "lf_downweight_factor", "lf_size_divisor", "lf_likelihood",
  "dm_grouping", "dm_estimate_relative_sample_size",
  "age_length_variant", "age_length_source", "selectivity_treatment",
  "opr_enabled", "opr_year_effect", "opr_terminal_year_constraint",
  "opr_season_effect", "opr_region_effect", "opr_region_season_effect",
  "opr_terminal_penalty_flag", "opr_source"
)
for (i in seq_along(tag_index)) {
  for (column in semantic_columns) {
    if (!identical(models[[column]][[tag_index[[i]]]],
                   models[[column]][[control_index[[i]]]])) {
      fail(names(tag_controls)[[i]], " differs from ", tag_controls[[i]],
           " in setting ", column)
    }
  }
}

expected_selectivity <- c(
  "S031" = "sa28_n8", "S032" = "sa28_n8"
)
selectivity_index <- match(names(expected_selectivity), actual_prefixes)
if (anyNA(selectivity_index) ||
    !identical(as.character(models$selectivity_treatment[selectivity_index]),
               unname(expected_selectivity))) {
  fail("The two retained selectivity sensitivities are not the N8 normal/DM pair")
}

age_counts <- table(factor(
  models$age_length_variant,
  levels = c("BASE075", "REG075", "REG100", "SUB075", "SUB100")
))
if (!identical(as.integer(age_counts), c(17L, 6L, 6L, 6L, 6L))) {
  fail("Expected age-length counts BASE075=17 and all other variants=6")
}
dm <- models$lf_likelihood == "dm_nore"
normal <- models$lf_likelihood == "normal"
if (any(models$dm_grouping[dm] != "process5") ||
    any(!models$dm_estimate_relative_sample_size[dm]) ||
    any(!models$lf_downweight_factor[normal] %in% c(1L, 10L)) ||
    any(grepl("CUT70|DW5|G4|C0", models$step_id))) {
  fail("Forbidden CUT70/DW5/G4/C0 or an invalid G5PROC/CEST configuration remains")
}

opr_ids <- c(
  "S038-OPR-Y72-E2-S01-R50-I50",
  "S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON",
  "S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50",
  "S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON"
)
opr_index <- match(opr_ids, models$step_id)
normal_opr_index <- opr_index[1:2]
dm_opr_index <- opr_index[3:4]
if (anyNA(opr_index) || sum(models$opr_enabled) != 4L ||
    any(models$age_length_variant[opr_index] != "BASE075") ||
    any(is.finite(models$cutoff_cm[opr_index])) ||
    any(models$selectivity_treatment[opr_index] != "sa28_n5") ||
    any(models$lf_likelihood[normal_opr_index] != "normal") ||
    any(models$tail_compression_percent[normal_opr_index] != 1L) ||
    any(models$lf_downweight_factor[normal_opr_index] != 1L) ||
    any(models$lf_size_divisor[normal_opr_index] != 20L) ||
    any(models$lf_likelihood[dm_opr_index] != "dm_nore") ||
    any(models$dm_grouping[dm_opr_index] != "process5") ||
    any(!models$dm_estimate_relative_sample_size[dm_opr_index]) ||
    any(models$tail_compression_percent[dm_opr_index] != 0L) ||
    any(!is.na(models$lf_downweight_factor[dm_opr_index])) ||
    any(!is.na(models$lf_size_divisor[dm_opr_index])) ||
    any(models$opr_year_effect[opr_index] != 72L) ||
    any(models$opr_terminal_year_constraint[opr_index] != 2L) ||
    any(models$opr_season_effect[opr_index] != 1L) ||
    any(models$opr_region_effect[opr_index] != 50L) ||
    any(models$opr_region_season_effect[opr_index] != 50L) ||
    any(models$opr_terminal_penalty_flag[opr_index] != 0L) ||
    !identical(models$tag_flag2[opr_index], c(0L, 1L, 0L, 1L)) ||
    any(grepl("Y71|TP[0-9]", models$step_id))) {
  fail("Normal and DM OPR pairs must be fixed Y72-E2-S01-R50-I50 with penalty disabled and tag flags 0/1")
}

generated_ids <- sort(list.dirs(sensitivity_root, recursive = FALSE, full.names = FALSE))
if (!identical(generated_ids, sort(as.character(models$step_id)))) {
  missing <- setdiff(models$step_id, generated_ids)
  extra <- setdiff(generated_ids, models$step_id)
  fail("Generated sensitivity directories do not match design; missing=",
       paste(missing, collapse = ","), "; extra=", paste(extra, collapse = ","))
}

model_file <- function(id, name) file.path(sensitivity_root, id, "model", name)
model_inputs <- c(
  "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
  "bet.reg_scaling.full", "doitall.sh", "fishery_map.R", "tag_rep_map.R"
)
for (id in models$step_id) {
  missing <- model_inputs[!file.exists(file.path(sensitivity_root, id, "model", model_inputs))]
  if (length(missing)) fail(id, " is missing model inputs: ", paste(missing, collapse = ", "))
}

sha256_file <- function(path) {
  output <- suppressWarnings(system2("sha256sum", path, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) fail("sha256sum failed for ", path)
  sub("[[:space:]].*$", "", output[[1L]])
}

doitall_semantic_sha256 <- function(ids) {
  output <- character()
  for (id in sort(ids)) {
    path <- model_file(id, "doitall.sh")
    lines <- readLines(path, warn = FALSE)
    lines <- sub("#.*$", "", lines)
    lines <- gsub("[[:space:]]+", " ", trimws(lines))
    lines <- lines[nzchar(lines)]
    output <- c(output, paste0(id, "/model/doitall.sh"), lines)
  }
  manifest <- tempfile("doitall-semantic-")
  on.exit(unlink(manifest), add = TRUE)
  writeLines(output, manifest, useBytes = TRUE)
  sha256_file(manifest)
}
expected_doitall_semantic_sha256 <-
  "86cf094a05d86fa8037d19aa6f1d2417addcf0b55eac1ed6ac5cbcf488d343da"
actual_doitall_semantic_sha256 <- doitall_semantic_sha256(models$step_id)
if (!identical(actual_doitall_semantic_sha256, expected_doitall_semantic_sha256)) {
  fail("Generated doitall command semantics changed; only comments were permitted")
}
same_file <- function(left, right) identical(sha256_file(left), sha256_file(right))

expected_ini_sha256 <- "932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117"
expected_generated_ini_sha256 <- "eaf9b6a5343d3face34580388ac7fdc2d6ae991bd1ad3ee12e2544e3b30a8de8"
non_sensitivity_ini <- list.files(repo_root, pattern = "^bet\\.ini$", recursive = TRUE,
                                  full.names = TRUE)
non_sensitivity_ini <- non_sensitivity_ini[!grepl("/sensitivity/", non_sensitivity_ini)]
reference_ini <- non_sensitivity_ini[vapply(
  non_sensitivity_ini, function(path) identical(sha256_file(path), expected_ini_sha256), logical(1)
)]
if (!length(reference_ini)) fail("Could not find the unchanged derived reference bet.ini")

ini_matrix <- function(path, marker) {
  lines <- readLines(path, warn = FALSE)
  start <- which(trimws(lines) == marker)
  if (length(start) != 1L) fail(path, " must contain exactly one ", marker, " section")
  later <- which(seq_along(lines) > start & grepl("^[[:space:]]*#", lines))
  section_end <- if (length(later)) min(later) - 1L else length(lines)
  rows <- seq.int(start + 1L, section_end)
  rows <- rows[nzchar(trimws(lines[rows]))]
  values <- strsplit(trimws(lines[rows]), "[[:space:]]+")
  widths <- unique(lengths(values))
  if (length(widths) != 1L) fail(path, " has an uneven ", marker, " matrix")
  matrix(
    as.numeric(unlist(values, use.names = FALSE)),
    nrow = length(values),
    byrow = TRUE
  )
}

reporting_markers <- c(
  rep = "# tag fish rep",
  group = "# tag fish rep group flags",
  active = "# tag_fish_rep active flags",
  target = "# tag_fish_rep target",
  penalty = "# tag_fish_rep penalty"
)
reference_reporting <- lapply(reporting_markers, ini_matrix, path = reference_ini[[1L]])
partition_equivalent <- function(left, right) {
  if (!identical(dim(left), dim(right)) ||
      !identical(left == 0, right == 0)) return(FALSE)
  left_labels <- sort(unique(left[left > 0]))
  right_labels <- sort(unique(right[right > 0]))
  if (length(left_labels) != length(right_labels)) return(FALSE)
  left_to_right <- vapply(left_labels, function(label) {
    length(unique(right[left == label]))
  }, integer(1))
  right_to_left <- vapply(right_labels, function(label) {
    length(unique(left[right == label]))
  }, integer(1))
  all(left_to_right == 1L) && all(right_to_left == 1L)
}

canonical_reporting <- NULL
for (id in models$step_id) {
  path <- model_file(id, "bet.ini")
  matrices <- lapply(reporting_markers, ini_matrix, path = path)
  if (!all(vapply(matrices, function(x) identical(dim(x), c(99L, 33L)), logical(1)))) {
    fail(id, " does not have five 99x33 reporting-rate matrices")
  }
  labels <- sort(unique(as.integer(matrices$group[matrices$group > 0])))
  if (!identical(labels, 1:28)) {
    fail(id, " reporting-rate group labels are not contiguous 1:28")
  }
  if (!partition_equivalent(reference_reporting$group, matrices$group)) {
    fail(id, " reporting-rate partition differs from the unchanged reference INI")
  }
  for (name in c("rep", "active", "target", "penalty")) {
    if (!identical(matrices[[name]], reference_reporting[[name]])) {
      fail(id, " changes reporting-rate ", name, " values from the reference INI")
    }
  }
  zero <- matrices$group == 0
  if (any(abs(matrices$rep[zero]) > 1e-12) || any(matrices$active[zero] != 0) ||
      any(abs(matrices$target[zero]) > 1e-12) ||
      any(abs(matrices$penalty[zero]) > 1e-12)) {
    fail(id, " has nonzero values outside reporting-rate groups")
  }
  for (group in labels) {
    cells <- matrices$group == group
    unique_counts <- vapply(
      matrices[c("rep", "active", "target", "penalty")],
      function(x) length(unique(round(x[cells], 12))),
      integer(1)
    )
    if (any(unique_counts != 1L)) {
      fail(id, " has mixed reporting-rate values within group ", group)
    }
  }
  if (is.null(canonical_reporting)) {
    canonical_reporting <- matrices
  } else if (!all(vapply(names(matrices), function(name) {
    identical(matrices[[name]], canonical_reporting[[name]])
  }, logical(1)))) {
    fail(id, " reporting-rate matrices differ from the common 41-model definition")
  }
}

tag_section <- function(path) {
  lines <- readLines(path, warn = FALSE)
  header <- which(trimws(lines) == "# tag flags")
  if (length(header) != 1L) fail(path, " must contain exactly one # tag flags section")
  later <- which(seq_along(lines) > header & grepl("^[[:space:]]*#", lines))
  section_end <- if (length(later)) min(later) - 1L else length(lines)
  rows <- seq.int(header + 1L, section_end)
  rows <- rows[nzchar(trimws(lines[rows]))]
  values <- lapply(lines[rows], function(line) {
    value <- suppressWarnings(as.integer(strsplit(trimws(line), "[[:space:]]+")[[1L]]))
    if (length(value) != 10L || anyNA(value)) fail("Invalid tag-flags row in ", path)
    value
  })
  matrix <- do.call(rbind, values)
  if (!identical(dim(matrix), c(98L, 10L))) fail(path, " must have a 98x10 tag-flags matrix")
  list(lines = lines, rows = rows, matrix = matrix)
}

for (id in setdiff(models$step_id, names(tag_controls))) {
  ini <- model_file(id, "bet.ini")
  if (!identical(sha256_file(ini), expected_generated_ini_sha256)) {
    fail(id, " flag-column-2=0 INI is not the canonicalized derived reference")
  }
  if (any(tag_section(ini)$matrix[, 2L] != 0L)) fail(id, " does not keep tag flag column 2 at zero")
}

for (id in names(tag_controls)) {
  control <- tag_controls[[id]]
  for (name in setdiff(model_inputs, "bet.ini")) {
    if (!same_file(model_file(id, name), model_file(control, name))) {
      fail(id, " differs from control ", control, " outside bet.ini: ", name)
    }
  }
  tag_ini <- tag_section(model_file(id, "bet.ini"))
  control_ini <- tag_section(model_file(control, "bet.ini"))
  if (any(tag_ini$matrix[, 2L] != 1L) || any(control_ini$matrix[, 2L] != 0L) ||
      !identical(tag_ini$matrix[, -2L, drop = FALSE],
                 control_ini$matrix[, -2L, drop = FALSE]) ||
      !identical(tag_ini$lines[-tag_ini$rows], control_ini$lines[-control_ini$rows])) {
    fail(id, " is not an isolated 98-row tag_flags(:,2) 0-to-1 change from ", control)
  }
  provenance_files <- list.files(file.path(sensitivity_root, id),
                                 pattern = "(README\\.md|manifest.*\\.csv)$",
                                 recursive = TRUE, full.names = TRUE)
  provenance <- paste(unlist(lapply(provenance_files, readLines, warn = FALSE)), collapse = "\n")
  if (!grepl(control, provenance, fixed = TRUE) ||
      !grepl("upstream value 1", provenance, fixed = TRUE)) {
    fail(id, " documentation does not identify its control and upstream flag value")
  }
}

opr_pairs <- list(
  c(control = opr_ids[[1L]], tag = opr_ids[[2L]], base = "S001-TC1-NOCUT-DW1"),
  c(control = opr_ids[[3L]], tag = opr_ids[[4L]], base = "S005-DM-G5PROC-CEST-NOCUT")
)
for (pair in opr_pairs) {
  for (name in setdiff(model_inputs, "doitall.sh")) {
    if (!same_file(model_file(pair[["control"]], name), model_file(pair[["base"]], name))) {
      fail(pair[["control"]], " differs from its non-OPR control outside doitall.sh: ", name)
    }
  }
}
opr_env <- new.env(parent = globalenv())
sys.source(file.path(repo_root, "R", "prepare_common.R"), envir = opr_env)
sys.source(file.path(repo_root, "R", "prepare_doitall.R"), envir = opr_env)
if (!is.function(opr_env$apply_opr)) fail("Missing reviewed apply_opr() helper")
for (pair in opr_pairs) {
  expected_opr_doitall <- opr_env$apply_opr(
    readLines(model_file(pair[["base"]], "doitall.sh"), warn = FALSE),
    year_effect = 72L,
    season_effect = 1L,
    region_effect = 50L,
    region_season_effect = 50L,
    terminal_year_constraint = 2L,
    terminal_penalty_flag = 0L,
    compatibility_year_effect = 72L
  )
  actual_opr_doitall <- readLines(model_file(pair[["control"]], "doitall.sh"), warn = FALSE)
  if (!identical(actual_opr_doitall, expected_opr_doitall) ||
      any(grepl("^[[:space:]]*1[[:space:]]+397[[:space:]]+100([[:space:]]|$)",
                actual_opr_doitall))) {
    fail(pair[["control"]], " is not the exact reviewed Y72-E2-S01-R50-I50 penalty-off OPR transform")
  }
}
opr_settings_paths <- file.path(sensitivity_root, opr_ids, "opr_settings.csv")
if (any(!file.exists(opr_settings_paths)) || any(!vapply(
  opr_settings_paths[-1L], same_file, logical(1), left = opr_settings_paths[[1L]]
))) {
  fail("All OPR controls must have identical machine-readable OPR settings")
}
opr_settings <- utils::read.csv(opr_settings_paths[[1L]], stringsAsFactors = FALSE)
if (nrow(opr_settings) != 1L || opr_settings$year_effect != 72L ||
    opr_settings$terminal_year_constraint != 2L ||
    opr_settings$season_effect != 1L || opr_settings$region_effect != 50L ||
    opr_settings$region_season_effect != 50L ||
    opr_settings$compatibility_year_effect != 72L ||
    opr_settings$terminal_penalty_flag != 0L) {
  fail("OPR settings CSV does not encode fixed Y72-E2-S01-R50-I50 with penalty disabled")
}
for (id in opr_ids) {
  documentation <- paste(unlist(lapply(
    c(file.path(sensitivity_root, id, "README.md"),
      file.path(sensitivity_root, id, "input_manifest.csv")),
    readLines, warn = FALSE
  )), collapse = "\n")
  if (!grepl("apply_opr", documentation, fixed = TRUE) ||
      !grepl("Y72-E2-S01-R50-I50", documentation, fixed = TRUE) ||
      !grepl("397=0", documentation, fixed = TRUE)) {
    fail(id, " lacks exact OPR provenance or fixed-control documentation")
  }
}

canonical <- function(line) {
  line <- sub("#.*$", "", line)
  gsub("[[:space:]]+", " ", trimws(line))
}

phase_bounds <- function(lines, phase, id) {
  start <- grep(sprintf("<<PHASE%d[[:space:]]*$", phase), lines)
  end <- grep(sprintf("^PHASE%d[[:space:]]*$", phase), lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    fail(id, " does not contain one complete phase ", phase)
  }
  c(start = start, end = end)
}
require_in_phase <- function(lines, value, bounds, id) {
  hits <- which(vapply(lines, canonical, character(1)) == value)
  if (length(hits) != 1L || hits <= bounds[["start"]] || hits >= bounds[["end"]]) {
    fail(id, " requires exactly one `", value, "` inside the expected phase")
  }
}
dm_group_map <- integer(33L)
dm_group_map[1:11] <- 1L
dm_group_map[c(12L, 19L, 20L, 25:28)] <- 2L
dm_group_map[17:18] <- 3L
dm_group_map[c(13:16, 21:24)] <- 4L
dm_group_map[29:33] <- 5L
for (id in opr_ids[3:4]) {
  lines <- readLines(model_file(id, "doitall.sh"), warn = FALSE)
  phase1 <- phase_bounds(lines, 1L, id)
  phase2 <- phase_bounds(lines, 2L, id)
  phase3 <- phase_bounds(lines, 3L, id)
  phase4 <- phase_bounds(lines, 4L, id)
  phase5 <- phase_bounds(lines, 5L, id)
  if (!(phase1[["end"]] < phase2[["start"]] &&
        phase2[["end"]] < phase3[["start"]] &&
        phase3[["end"]] < phase4[["start"]] &&
        phase4[["end"]] < phase5[["start"]])) {
    fail(id, " does not preserve the phase 1-5 order")
  }
  require_in_phase(lines, "1 141 11", phase1, id)
  require_in_phase(lines, "1 320 5", phase1, id)
  require_in_phase(lines, "1 342 30", phase1, id)
  require_in_phase(lines, "-999 69 1", phase1, id)
  require_in_phase(lines, "-999 89 0", phase1, id)
  require_in_phase(lines, "-999 89 1", phase2, id)
  require_in_phase(lines, "1 155 72", phase3, id)
  require_in_phase(lines, "1 202 2", phase3, id)
  require_in_phase(lines, "1 217 1", phase3, id)
  require_in_phase(lines, "1 216 50", phase3, id)
  require_in_phase(lines, "1 218 50", phase3, id)
  require_in_phase(lines, "1 397 0", phase3, id)
  require_in_phase(lines, "2 68 1", phase4, id)
  require_in_phase(lines, "2 69 1", phase4, id)
  for (value in c("1 77 50", "1 78 1", "1 79 240", "1 80 220", "1 81 1")) {
    require_in_phase(lines, value, phase5, id)
  }
  for (fishery in seq_len(33L)) {
    require_in_phase(
      lines,
      sprintf("-%d 68 %d", fishery, dm_group_map[[fishery]]),
      phase1,
      id
    )
  }
}
selectivity_block <- function(id) {
  lines <- readLines(model_file(id, "doitall.sh"), warn = FALSE)
  start <- which(trimws(lines) == "# Selectivity settings")
  end <- grep("^# Turn on weighted spline", lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    fail(id, " has an invalid PHASE1 selectivity block")
  }
  lines[start:(end - 1L)]
}
flag_triples <- function(lines, id) {
  output <- list()
  k <- 0L
  for (line in lines) {
    text <- canonical(line)
    if (!nzchar(text)) next
    tokens <- suppressWarnings(as.integer(strsplit(text, " ", fixed = TRUE)[[1L]]))
    if (anyNA(tokens) || length(tokens) %% 3L != 0L) next
    for (j in seq.int(1L, length(tokens), by = 3L)) {
      k <- k + 1L
      output[[k]] <- tokens[j:(j + 2L)]
    }
  }
  if (!length(output)) fail("No selectivity flags parsed for ", id)
  result <- as.data.frame(do.call(rbind, output))
  names(result) <- c("actor", "flag", "value")
  result
}
require_triple <- function(flags, actor, flag, value, id) {
  hits <- flags$actor == actor & flags$flag == flag & flags$value == value
  if (sum(hits) != 1L) fail(id, " requires exactly one flag triple ", actor, "/", flag, "=", value)
}

n5_reference_id <- "S003-TC1-CUT90-DW1"
n5_block <- selectivity_block(n5_reference_id)
n5_flags <- flag_triples(n5_block, n5_reference_id)
require_triple(n5_flags, -999L, 3L, 37L, n5_reference_id)
require_triple(n5_flags, -999L, 26L, 2L, n5_reference_id)
require_triple(n5_flags, -999L, 57L, 3L, n5_reference_id)
require_triple(n5_flags, -999L, 61L, 5L, n5_reference_id)

expected_groups <- c(1:28, rep(29L, 5L))
for (fishery in 1:33) require_triple(n5_flags, -fishery, 24L,
                                     expected_groups[[fishery]], n5_reference_id)
expected_zeros <- c(
  setNames(rep(2L, 12L), 1:12),
  `13` = 1L,
  `15` = 5L,
  setNames(rep(2L, 5L), 29:33)
)
zero_flags <- n5_flags[n5_flags$flag == 75L, c("actor", "value")]
zero_flags <- zero_flags[order(zero_flags$actor), , drop = FALSE]
expected_zero_df <- data.frame(
  actor = -as.integer(names(expected_zeros)), value = as.integer(expected_zeros)
)
expected_zero_df <- expected_zero_df[order(expected_zero_df$actor), , drop = FALSE]
row.names(zero_flags) <- row.names(expected_zero_df) <- NULL
if (!identical(zero_flags, expected_zero_df)) fail("Corrected N5 early-age-zero rules drifted")

monotonic <- n5_flags[n5_flags$flag == 16L & n5_flags$value == 1L, , drop = FALSE]
if (nrow(monotonic) != 1L || monotonic$actor[[1L]] != -9L) {
  fail("Corrected N5 monotonicity must apply only to F9")
}
upper <- c(`12` = 25L, `13` = 30L, `15` = 25L, `16` = 25L,
           `17` = 25L, `18` = 25L, `19` = 25L, `21` = 10L,
           `22` = 7L, `23` = 6L, `24` = 25L, `25` = 25L,
           `26` = 25L, `27` = 30L)
upper_rows <- n5_flags[n5_flags$flag == 3L & n5_flags$actor != -999L,
                       c("actor", "value")]
upper_rows <- upper_rows[order(upper_rows$actor), , drop = FALSE]
expected_upper <- data.frame(actor = -as.integer(names(upper)), value = as.integer(upper))
expected_upper <- expected_upper[order(expected_upper$actor), , drop = FALSE]
row.names(upper_rows) <- row.names(expected_upper) <- NULL
if (!identical(upper_rows, expected_upper)) fail("Corrected N5 upper-age settings drifted")
if (any(n5_flags$flag == 61L & n5_flags$actor != -999L)) {
  fail("Corrected N5 must not have fishery-specific node overrides")
}

core_ids <- models$step_id[actual_prefixes %in% core_prefixes]
tag_ids <- names(tag_controls)
for (id in unique(c(core_ids, tag_ids, opr_ids))) {
  if (!identical(selectivity_block(id), n5_block)) {
    fail(id, " does not inherit the exact complete corrected N5 block")
  }
  all_flags <- flag_triples(readLines(model_file(id, "doitall.sh"), warn = FALSE), id)
  for (fishery in 29:33) {
    rows <- all_flags[all_flags$actor == -fishery & all_flags$flag == 24L, , drop = FALSE]
    if (!nrow(rows) || tail(rows$value, 1L) != fishery) {
      fail(id, " does not split F29-F33 to contiguous groups 29:33 in phase 5")
    }
  }
}

for (id in models$step_id) {
  flags <- flag_triples(selectivity_block(id), id)
  for (fishery in 29:33) require_triple(flags, -fishery, 75L, 2L, id)
}

ambiguous_comment <- paste("set length-dependent", "selectivity option")
tracked_comment_paths <- c(
  file.path(repo_root, "R", "prepare_bet_2026_step_inputs.R"),
  file.path(repo_root, "templates", "5-region", "doitall.sh"),
  file.path(repo_root, "reference-inputs", "job-5319", "mfcl-inputs", "doitall.sh"),
  vapply(models$step_id, model_file, character(1), name = "doitall.sh")
)
for (path in tracked_comment_paths) {
  if (any(grepl(ambiguous_comment, readLines(path, warn = FALSE), fixed = TRUE))) {
    fail("Ambiguous fish-flag-26 comment remains in ", path)
  }
}

expected_flag26_comment <- paste(
  "-999 26 2  # build selectivity-at-age by evaluating the spline on scaled",
  "mean length-at-age (not length-bin selectivity)"
)
expected_flag57_comment <- "-999 57 3  # cubic spline basis for selectivity"
expected_flag61_comment <-
  "-999 61 5  # five spline nodes on the scaled mean-length-at-age coordinate"
for (id in models$step_id) {
  lines <- readLines(model_file(id, "doitall.sh"), warn = FALSE)
  canonical_lines <- vapply(lines, canonical, character(1))
  all_flags <- flag_triples(lines, id)
  selectivity_flags <- flag_triples(selectivity_block(id), id)

  flag26 <- all_flags[all_flags$flag == 26L, , drop = FALSE]
  if (nrow(flag26) != 1L || flag26$actor != -999L || flag26$value != 2L) {
    fail(id, " must retain exactly one global fish flag 26=2 with no override")
  }
  flag57 <- selectivity_flags[selectivity_flags$flag == 57L, , drop = FALSE]
  if (nrow(flag57) != 1L || flag57$actor != -999L || flag57$value != 3L) {
    fail(id, " must retain exactly one global cubic-spline flag 57=3")
  }
  flag61 <- selectivity_flags[selectivity_flags$flag == 61L, , drop = FALSE]
  expected_nodes <- if (startsWith(id, "S031-") || startsWith(id, "S032-")) {
    data.frame(actor = c(-999L, -12L, -13L), value = c(5L, 8L, 8L))
  } else {
    data.frame(actor = -999L, value = 5L)
  }
  actual_nodes <- flag61[, c("actor", "value"), drop = FALSE]
  rownames(actual_nodes) <- NULL
  if (!identical(actual_nodes, expected_nodes)) {
    fail(id, " has an unexpected flag-61 node control")
  }
  required_comments <- c(
    expected_flag26_comment,
    expected_flag57_comment,
    expected_flag61_comment
  )
  if (any(!vapply(required_comments, function(comment) {
    sum(trimws(lines) == comment) == 1L
  }, logical(1)))) {
    fail(id, " lacks the required unambiguous global selectivity comments")
  }

  phase1 <- phase_bounds(lines, 1L, id)
  phase5 <- phase_bounds(lines, 5L, id)
  initial_groups <- integer(33L)
  final_groups <- integer(33L)
  for (fishery in 1:33) {
    pattern <- sprintf("^-%d 24 ", fishery)
    hits <- grep(pattern, canonical_lines)
    initial <- hits[hits > phase1[["start"]] & hits < phase1[["end"]]]
    if (length(initial) != 1L) {
      fail(id, " must define every fishery's flag-24 group exactly once in phase 1")
    }
    initial_groups[[fishery]] <- as.integer(strsplit(
      canonical_lines[[initial]], " ", fixed = TRUE
    )[[1L]][[3L]])
    final_groups[[fishery]] <- initial_groups[[fishery]]
    split <- hits[hits > phase5[["start"]] & hits < phase5[["end"]]]
    expected_hits <- if (fishery >= 29L) 2L else 1L
    expected_splits <- if (fishery >= 29L) 1L else 0L
    if (length(hits) != expected_hits || length(split) != expected_splits ||
        any(hits > phase5[["end"]])) {
      fail(id, " has an unexpected flag-24 override outside the reviewed phase 1/5 design")
    }
    if (fishery < 29L) next
    final_groups[[fishery]] <- as.integer(strsplit(
      canonical_lines[[split]], " ", fixed = TRUE
    )[[1L]][[3L]])
    if (canonical_lines[[initial]] != sprintf("-%d 24 29", fishery) ||
        canonical_lines[[split]] != sprintf("-%d 24 %d", fishery, fishery)) {
      fail(id, " must share F29-F33 through phase 4 and split them from phase 5 onward")
    }
    expected_initial_comment <- sprintf(
      "-%d 24 29  # Index R%d; shared initialization group through phase 4",
      fishery, fishery - 28L
    )
    expected_split_comment <- sprintf(
      "-%d 24 %d  # Index R%d; separate final selectivity from phase 5 onward",
      fishery, fishery, fishery - 28L
    )
    if (sum(trimws(lines) == expected_initial_comment) != 1L ||
        sum(trimws(lines) == expected_split_comment) != 1L) {
      fail(id, " lacks clear phase-specific index selectivity comments")
    }
  }
  expected_initial_groups <- c(1:28, rep(29L, 5L))
  expected_final_groups <- 1:33
  contiguous <- function(x) identical(sort(unique(x)), seq.int(min(x), max(x)))
  if (!identical(initial_groups, expected_initial_groups) ||
      !identical(final_groups, expected_final_groups) ||
      !contiguous(initial_groups) || !contiguous(final_groups)) {
    fail(id, paste(
      "must preserve 29 phase-1 and 33 phase-5 selectivity partitions",
      "with contiguous MFCL flag-24 labels and no membership collision"
    ))
  }
}

map_reference <- model_file(n5_reference_id, "fishery_map.R")
map_env <- new.env(parent = globalenv())
sys.source(map_reference, envir = map_env)
fishery_map <- map_env$fishery_map
fishery_names <- sub("^[0-9]+\\.", "", as.character(fishery_map$fishery_name))
if (!identical(fishery_names[c(12L, 13L)], c("PS.JP.1", "PL.JP.1"))) {
  fail("Targeted node fisheries must be F12 PS.JP.1 and F13 PL.JP.1")
}
for (id in models$step_id) {
  if (!same_file(model_file(id, "fishery_map.R"), map_reference)) {
    fail(id, " fishery/selectivity mapping differs from the corrected baseline")
  }
}

strip_n8 <- function(block) block[!grepl(
  "^[[:space:]]*-(12|13)[[:space:]]+61[[:space:]]+8([[:space:]]|$)", block
)]
for (pair in list(c("S031", "S003"), c("S032", "S006"))) {
  treatment_id <- models$step_id[actual_prefixes == pair[[1L]]]
  control_id <- models$step_id[actual_prefixes == pair[[2L]]]
  block <- selectivity_block(treatment_id)
  flags <- flag_triples(block, treatment_id)
  require_triple(flags, -12L, 61L, 8L, treatment_id)
  require_triple(flags, -13L, 61L, 8L, treatment_id)
  if (length(block) - length(strip_n8(block)) != 2L ||
      !identical(strip_n8(block), selectivity_block(control_id))) {
    fail(treatment_id, " must differ from N5 only by F12/F13 flag61=8")
  }
  treatment_doitall <- readLines(model_file(treatment_id, "doitall.sh"), warn = FALSE)
  control_doitall <- readLines(model_file(control_id, "doitall.sh"), warn = FALSE)
  if (!identical(strip_n8(treatment_doitall), control_doitall)) {
    fail(treatment_id, " has a non-F12/F13 difference elsewhere in doitall.sh")
  }
  for (name in setdiff(model_inputs, "doitall.sh")) {
    if (!same_file(model_file(treatment_id, name), model_file(control_id, name))) {
      fail(treatment_id, " differs from its N5 control outside doitall.sh: ", name)
    }
  }
}

input_signature <- function(id) paste(vapply(
  model_inputs,
  function(name) paste0(name, "=", sha256_file(model_file(id, name))),
  character(1)
), collapse = "|")
signatures <- vapply(models$step_id, input_signature, character(1))
if (anyDuplicated(signatures)) {
  duplicate_groups <- split(models$step_id, signatures)
  duplicate_groups <- duplicate_groups[lengths(duplicate_groups) > 1L]
  fail("Accidental duplicate generated models: ",
       paste(vapply(duplicate_groups, paste, collapse = "/", FUN.VALUE = character(1)),
             collapse = "; "))
}

readme <- paste(readLines(file.path(repo_root, "README.md"), warn = FALSE), collapse = "\n")
required_readme_terms <- c(
  "41", "S001", "S041", "contiguous", "F12", "PS.JP.1", "F13",
  "PL.JP.1", "S031", "S032", "corrected", "five", "eight", "F29-F33",
  "S038-OPR-Y72-E2-S01-R50-I50", "S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON",
  "S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50",
  "S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON",
  "Terminal penalty is disabled", expected_runtime_image,
  "DM final-report and model-payload generation requires Tuna Flow v2.5",
  "scaled mean length-at-age", "flag 26", "phase 5"
)
if (any(!vapply(required_readme_terms, grepl, logical(1), x = readme,
                fixed = TRUE))) {
  fail("README does not document the contiguous design, promoted baseline, and targets")
}

public_documents <- c(
  file.path(repo_root, "README.md"),
  list.files(
    sensitivity_root,
    pattern = "(README\\.md|input_manifest\\.csv)$",
    recursive = TRUE,
    full.names = TRUE
  )
)
forbidden_public_text <- paste0(
  "(?i)(/home/|/tmp/|/Users/|[A-Z]:[/\\\\]Users[/\\\\]|",
  "\\b(?:paul|john|thom|kyuhan|kyuhank)\\b)"
)
required_generated_terms <- c(
  "41-model", "single-area-derived", "F29-F33", "BASE075", "REG075",
  "REG100", "SUB075", "SUB100", "G5PROC", "Nmax 30", "F12 PS.JP.1",
  "F13 PL.JP.1", "TAGF2ON", "phase 3", "phase 4", "phase 5",
  "terminal penalty is disabled"
)
for (path in public_documents) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  if (grepl(forbidden_public_text, text, perl = TRUE)) {
    fail("Public documentation contains a local path or personal-name wording: ", path)
  }
  if (!identical(path, file.path(repo_root, "README.md")) &&
      any(!vapply(required_generated_terms, grepl, logical(1), x = text,
                  fixed = TRUE))) {
    fail("Generated public documentation lacks the complete design context: ", path)
  }
}

cat("Validation passed: 41 non-duplicate sensitivity models.\n")
cat("Core S001-S030 and TAGF2ON S033-S037 inherit the exact corrected N5 baseline.\n")
cat("N8 axis: only F12 PS.JP.1 and F13 PL.JP.1 change flag 61 from 5 to 8.\n")
cat("Index baseline: every model has flag 75=2 for F29-F33 Index R1-R5.\n")
cat("Selectivity groups: flag-24 labels are contiguous, with 29 phase-1 and 33 phase-5 partitions.\n")
cat("Identifiers are contiguous S001:S041; retained N8 models are S031 and S032.\n")
cat("OPR pairs: normal S001 and DM S005 controls use the exact reviewed Y72-E2-S01-R50-I50 transform with parest 397=0.\n")
cat("DM OPR controls retain G5PROC, C estimation, Nmax 30, and phase order OPR/movement/regional scaling = 3/4/5.\n")
cat("All seven TAGF2ON models differ from their controls only in all 98 tag_flags(:,2) values.\n")
cat("Public README/manifests contain full design context without local paths or personal-name wording.\n")
cat("Runtime image: exact tested Tuna Flow v2.5 digest pin verified.\n")
cat("Selectivity semantics: all 41 models retain one global flag 26=2, flag 57=3, and the intended flag-61 nodes.\n")
cat("Index selectivity: F29-F33 share through phase 4 and split from phase 5 onward in every model.\n")
cat("Command audit: contiguous-design doitall semantic SHA-256 matches the locked value.\n")
