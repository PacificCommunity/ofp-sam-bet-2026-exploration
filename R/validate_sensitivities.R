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

config_env <- new.env(parent = globalenv())
sys.source(file.path(repo_root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models
if (!is.data.frame(models)) fail("job-config.R did not create the stepwise_models data frame")

core_prefixes <- sprintf("S%03d", 1:30)
selectivity_prefixes <- c("S032", "S033", "S035", "S036")
tag_prefixes <- sprintf("S%03d", 37:41)
expected_prefixes <- c(core_prefixes, selectivity_prefixes, tag_prefixes)
actual_prefixes <- sub("-.*$", "", as.character(models$step_id))
if (nrow(models) != 39L || !identical(actual_prefixes, expected_prefixes)) {
  fail("Expected 39 models with prefixes S001:S030, S032:S033, and S035:S041")
}
if (anyDuplicated(models$step_id)) fail("Model IDs are not unique")
if (any(actual_prefixes %in% c("S031", "S034"))) {
  fail("Retired duplicate N5 identities S031/S034 remain in the design")
}

tag_controls <- c(
  "S037-TC1-NOCUT-DW1-TAGF2ON" = "S001-TC1-NOCUT-DW1",
  "S038-TC1-CUT90-DW1-TAGF2ON" = "S003-TC1-CUT90-DW1",
  "S039-DM-G5PROC-CEST-NOCUT-TAGF2ON" = "S005-DM-G5PROC-CEST-NOCUT",
  "S040-DM-G5PROC-CEST-CUT90-TAGF2ON" = "S006-DM-G5PROC-CEST-CUT90",
  "S041-TC1-NOCUT-DW10-TAGF2ON" = "S002-TC1-NOCUT-DW10"
)
if (!identical(as.character(tail(models$step_id, 5L)), names(tag_controls))) {
  fail("TAGF2ON identities or order do not match the confirmed five-model design")
}

tag_index <- match(names(tag_controls), models$step_id)
control_index <- match(unname(tag_controls), models$step_id)
if (anyNA(tag_index) || anyNA(control_index) ||
    any(models$age_length_variant[tag_index] != "BASE075") ||
    any(models$tag_flag2[tag_index] != 1L) ||
    any(models$tag_flag2[-tag_index] != 0L) ||
    any(models$selectivity_treatment[c(1:30, tag_index)] != "sa28_n5")) {
  fail("Core/TAGF2ON baseline, BASE075, or tag-flag design is incorrect")
}

semantic_columns <- c(
  "run_mode", "region_count", "regional_scaling_weight",
  "tail_compression_percent", "cutoff_cm", "cutoff_code",
  "lf_downweight_factor", "lf_size_divisor", "lf_likelihood",
  "dm_grouping", "dm_estimate_relative_sample_size",
  "age_length_variant", "age_length_source", "selectivity_treatment"
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
  "S032" = "sa28_n8", "S033" = "sa28_n5_idx_z2",
  "S035" = "sa28_n8", "S036" = "sa28_n5_idx_z2"
)
selectivity_index <- match(names(expected_selectivity), actual_prefixes)
if (anyNA(selectivity_index) ||
    !identical(as.character(models$selectivity_treatment[selectivity_index]),
               unname(expected_selectivity))) {
  fail("The four retained selectivity sensitivities are not N8/IDX-Z2 normal/DM pairs")
}

age_counts <- table(factor(
  models$age_length_variant,
  levels = c("BASE075", "REG075", "REG100", "SUB075", "SUB100")
))
if (!identical(as.integer(age_counts), c(15L, 6L, 6L, 6L, 6L))) {
  fail("Expected age-length counts BASE075=15 and all other variants=6")
}
dm <- models$lf_likelihood == "dm_nore"
normal <- models$lf_likelihood == "normal"
if (any(models$dm_grouping[dm] != "process5") ||
    any(!models$dm_estimate_relative_sample_size[dm]) ||
    any(!models$lf_downweight_factor[normal] %in% c(1L, 10L)) ||
    any(grepl("CUT70|DW5|G4|C0", models$step_id))) {
  fail("Forbidden CUT70/DW5/G4/C0 or an invalid G5PROC/CEST configuration remains")
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
same_file <- function(left, right) identical(sha256_file(left), sha256_file(right))

expected_ini_sha256 <- "932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117"
non_sensitivity_ini <- list.files(repo_root, pattern = "^bet\\.ini$", recursive = TRUE,
                                  full.names = TRUE)
non_sensitivity_ini <- non_sensitivity_ini[!grepl("/sensitivity/", non_sensitivity_ini)]
reference_ini <- non_sensitivity_ini[vapply(
  non_sensitivity_ini, function(path) identical(sha256_file(path), expected_ini_sha256), logical(1)
)]
if (!length(reference_ini)) fail("Could not find the unchanged derived reference bet.ini")

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
  if (!identical(sha256_file(ini), expected_ini_sha256)) {
    fail(id, " flag-column-2=0 INI is not byte-identical to the derived reference")
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

canonical <- function(line) {
  line <- sub("#.*$", "", line)
  gsub("[[:space:]]+", " ", trimws(line))
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

expected_groups <- c(1:24, 30:33, rep(25L, 5L))
for (fishery in 1:33) require_triple(n5_flags, -fishery, 24L,
                                     expected_groups[[fishery]], n5_reference_id)
expected_zeros <- c(setNames(rep(2L, 12L), 1:12), `13` = 1L, `15` = 5L)
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
for (id in c(core_ids, tag_ids)) {
  if (!identical(selectivity_block(id), n5_block)) {
    fail(id, " does not inherit the exact complete corrected N5 block")
  }
  all_flags <- flag_triples(readLines(model_file(id, "doitall.sh"), warn = FALSE), id)
  for (fishery in 29:33) {
    rows <- all_flags[all_flags$actor == -fishery & all_flags$flag == 24L, , drop = FALSE]
    if (!nrow(rows) || tail(rows$value, 1L) != fishery - 4L) {
      fail(id, " does not split F29-F33 to groups 25:29 in phase 5")
    }
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
for (pair in list(c("S032", "S003"), c("S035", "S006"))) {
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

strip_idx_z2 <- function(block) block[
  !grepl("^# IDX-Z2:", block) &
    !grepl("^[[:space:]]*-(29|30|31|32|33)[[:space:]]+75[[:space:]]+2([[:space:]]|$)", block)
]
for (pair in list(c("S033", "S003"), c("S036", "S006"))) {
  treatment_id <- models$step_id[actual_prefixes == pair[[1L]]]
  control_id <- models$step_id[actual_prefixes == pair[[2L]]]
  block <- selectivity_block(treatment_id)
  flags <- flag_triples(block, treatment_id)
  for (fishery in 29:33) require_triple(flags, -fishery, 75L, 2L, treatment_id)
  if (length(block) - length(strip_idx_z2(block)) != 6L ||
      !identical(strip_idx_z2(block), selectivity_block(control_id))) {
    fail(treatment_id, " must differ from N5 only by F29-F33 flag75=2")
  }
  treatment_doitall <- readLines(model_file(treatment_id, "doitall.sh"), warn = FALSE)
  control_doitall <- readLines(model_file(control_id, "doitall.sh"), warn = FALSE)
  if (!identical(strip_idx_z2(treatment_doitall), control_doitall)) {
    fail(treatment_id, " has a non-F29/F33 difference elsewhere in doitall.sh")
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
  "39", "F12", "PS.JP.1", "F13", "PL.JP.1", "S031", "S034",
  "corrected", "five", "eight", "IDX-Z2"
)
if (any(!vapply(required_readme_terms, grepl, logical(1), x = readme,
                fixed = TRUE))) {
  fail("README does not document the promoted baseline, targets, count, and retired duplicates")
}

cat("Validation passed: 39 non-duplicate sensitivity models.\n")
cat("Core S001-S030 and TAGF2ON S037-S041 inherit the exact corrected N5 baseline.\n")
cat("N8 axis: only F12 PS.JP.1 and F13 PL.JP.1 change flag 61 from 5 to 8.\n")
cat("IDX-Z2 axis: corrected N5 plus flag 75=2 for F29-F33.\n")
cat("Retired duplicates: S031 and S034. Retained: S032, S033, S035, S036.\n")
cat("TAGF2ON models differ from their controls only in all 98 tag_flags(:,2) values.\n")
