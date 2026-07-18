# Curated BET 2026 MFCL LF sensitivity set.
# The exported design at the end of this file promotes the complete
# single-area-derived SA28-N5 selectivity treatment to the core baseline.
# Legacy rows above that exported design remain only as setting templates.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-conflict-exploration",
  trigger_next = FALSE
)

sensitivity_grid <- data.frame(
  step_id = c(
    "S001-TC1-NOCUT-DW1",
    "S002-TC1-NOCUT-DW5",
    "S003-TC1-NOCUT-DW10",
    "S004-TC1-CUT70-DW1",
    "S005-TC1-CUT70-DW5",
    "S006-TC1-CUT70-DW10",
    "S007-TC1-CUT90-DW1",
    "S008-TC1-CUT90-DW5",
    "S009-TC1-CUT90-DW10",
    "S010-DM-G4-CEST-NOCUT",
    "S011-DM-G1-C0-NOCUT",
    "S012-DM-G1-CEST-NOCUT",
    "S013-DM-G2-C0-NOCUT",
    "S014-DM-G2-CEST-NOCUT",
    "S015-DM-G4-C0-NOCUT",
    "S016-DM-G4-CEST-CUT70",
    "S017-DM-G4-CEST-CUT90"
  ),
  regional_scaling_weight = rep(50L, 17L),
  tail_compression_percent = c(rep(1L, 9L), rep(0L, 8L)),
  cutoff_cm = c(
    NA_real_, NA_real_, NA_real_,
    70, 70, 70,
    90, 90, 90,
    rep(NA_real_, 6L),
    70, 90
  ),
  lf_downweight_factor = c(
    rep(c(1L, 5L, 10L), 3L),
    rep(NA_integer_, 8L)
  ),
  lf_likelihood = c(rep("normal", 9L), rep("dm_nore", 8L)),
  dm_grouping = c(
    rep("none", 9L),
    "gear4", "gear1", "gear1", "gear2", "gear2", "gear4", "gear4", "gear4"
  ),
  dm_estimate_relative_sample_size = c(
    rep(FALSE, 9L),
    TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE
  ),
  stringsAsFactors = FALSE
)
sensitivity_grid$lf_size_divisor <-
  20L * sensitivity_grid$lf_downweight_factor
sensitivity_grid$cutoff_code <- ifelse(
  is.na(sensitivity_grid$cutoff_cm),
  "NOCUT",
  paste0("CUT", as.integer(sensitivity_grid$cutoff_cm))
)
sensitivity_grid$cutoff_description <- ifelse(
  is.na(sensitivity_grid$cutoff_cm),
  "F21/F22/F23 observed LF counts are unchanged; no cutoff is applied",
  sprintf(
    paste0(
      "F21/F22/F23 observed LF counts in bins with midpoint above the ",
      "%.0f cm cutoff are set to zero"
    ),
    sensitivity_grid$cutoff_cm
  )
)

age_length_variants <- data.frame(
  age_length_variant = c("BASE075", "REG075", "REG100", "SUB075", "SUB100"),
  age_length_source_file = c(
    "bet.age_length",
    "bet.2026.regional.0.75.age_length",
    "bet.2026.regional.1.age_length",
    "bet.2026.sub.basin.0.75.age_length",
    "bet.2026.sub.basin.1.age_length"
  ),
  age_length_source_path = c(
    "reference-inputs/job-5319/mfcl-inputs/bet.age_length",
    "reference-inputs/age-length-variants/bet.2026.regional.0.75.age_length",
    "reference-inputs/age-length-variants/bet.2026.regional.1.age_length",
    "reference-inputs/age-length-variants/bet.2026.sub.basin.0.75.age_length",
    "reference-inputs/age-length-variants/bet.2026.sub.basin.1.age_length"
  ),
  age_length_sha256 = c(
    "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
    "83e66c115df9ec2adabea262c650716dc711ad7ca9e1fdb98a5675778ee0ad74",
    "381f3098fb4e7fc3496f89c4ce538442472e445200812a03ca5ec3f68b4ce5bb",
    "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
    "7e6c0513e2f36ca2044c1d5a2de37c589c75fafabc3fd96b45683cbb1236b083"
  ),
  stringsAsFactors = FALSE
)

base_sensitivity_grid <- sensitivity_grid
base_sensitivity_grid$base_sensitivity <- base_sensitivity_grid$step_id
base_sensitivity_grid$age_length_variant <- "BASE075"
base_sensitivity_grid$age_length_source_file <-
  age_length_variants$age_length_source_file[[1L]]
base_sensitivity_grid$age_length_source_path <-
  age_length_variants$age_length_source_path[[1L]]
base_sensitivity_grid$age_length_sha256 <-
  age_length_variants$age_length_sha256[[1L]]

age_length_variant_starts <- c(REG075 = 18L, REG100 = 35L, SUB075 = 52L, SUB100 = 69L)
expanded_age_length_grids <- lapply(names(age_length_variant_starts), function(variant) {
  grid <- base_sensitivity_grid
  base_ids <- grid$step_id
  variant_info <- age_length_variants[
    age_length_variants$age_length_variant == variant,
    ,
    drop = FALSE
  ]
  grid$step_id <- sprintf(
    "S%03d-%s-AL%s",
    age_length_variant_starts[[variant]] + seq_len(nrow(grid)) - 1L,
    sub("^S[0-9]{3}-", "", base_ids),
    variant
  )
  grid$base_sensitivity <- base_ids
  grid$age_length_variant <- variant
  grid$age_length_source_file <- variant_info$age_length_source_file[[1L]]
  grid$age_length_source_path <- variant_info$age_length_source_path[[1L]]
  grid$age_length_sha256 <- variant_info$age_length_sha256[[1L]]
  grid
})
sensitivity_grid <- do.call(
  rbind,
  c(list(base_sensitivity_grid), expanded_age_length_grids)
)
rownames(sensitivity_grid) <- NULL

focused_grouping_specs <- data.frame(
  source_id = rep(
    c(
      "S010-DM-G4-CEST-NOCUT",
      "S016-DM-G4-CEST-CUT70",
      "S017-DM-G4-CEST-CUT90"
    ),
    2L
  ),
  step_id = c(
    "S086-DM-G5PROC-CEST-NOCUT",
    "S087-DM-G5PROC-CEST-CUT70",
    "S088-DM-G5PROC-CEST-CUT90",
    "S089-DM-G7QUAL-CEST-NOCUT",
    "S090-DM-G7QUAL-CEST-CUT70",
    "S091-DM-G7QUAL-CEST-CUT90"
  ),
  dm_grouping = rep(c("process5", "quality7"), each = 3L),
  stringsAsFactors = FALSE
)
focused_grouping_grid <- sensitivity_grid[
  match(focused_grouping_specs$source_id, sensitivity_grid$step_id),
  ,
  drop = FALSE
]
focused_grouping_grid$step_id <- focused_grouping_specs$step_id
focused_grouping_grid$base_sensitivity <- focused_grouping_specs$step_id
focused_grouping_grid$dm_grouping <- focused_grouping_specs$dm_grouping
sensitivity_grid <- rbind(sensitivity_grid, focused_grouping_grid)
rownames(sensitivity_grid) <- NULL

sensitivity_grid$selectivity_treatment <- "reference"
sensitivity_grid$selectivity_reference <- sensitivity_grid$step_id

focused_selectivity_specs <- data.frame(
  source_id = c(
    rep("S008-TC1-CUT90-DW5", 3L),
    rep("S088-DM-G5PROC-CEST-CUT90", 3L)
  ),
  step_id = c(
    "S092-TC1-CUT90-DW5-SA28-N5",
    "S093-TC1-CUT90-DW5-SA28-N8",
    "S094-TC1-CUT90-DW5-IDX-Z2",
    "S095-DM-G5PROC-CEST-CUT90-SA28-N5",
    "S096-DM-G5PROC-CEST-CUT90-SA28-N8",
    "S097-DM-G5PROC-CEST-CUT90-IDX-Z2"
  ),
  selectivity_treatment = rep(c("sa28_n5", "sa28_n8", "idx_z2"), 2L),
  stringsAsFactors = FALSE
)
focused_selectivity_grid <- sensitivity_grid[
  match(focused_selectivity_specs$source_id, sensitivity_grid$step_id),
  ,
  drop = FALSE
]
focused_selectivity_grid$step_id <- focused_selectivity_specs$step_id
focused_selectivity_grid$base_sensitivity <- focused_selectivity_specs$step_id
focused_selectivity_grid$selectivity_treatment <-
  focused_selectivity_specs$selectivity_treatment
focused_selectivity_grid$selectivity_reference <-
  focused_selectivity_specs$source_id
sensitivity_grid <- rbind(sensitivity_grid, focused_selectivity_grid)
rownames(sensitivity_grid) <- NULL

generated_ids <- sensitivity_grid$step_id

model_labels <- sprintf(
  paste0(
    "global MFCL LF tail compression %d%%; %s; ",
    "F21/F22/F23 LF likelihood downweight %dx with flag-49 divisor %d"
  ),
  sensitivity_grid$tail_compression_percent,
  sensitivity_grid$cutoff_description,
  sensitivity_grid$lf_downweight_factor,
  sensitivity_grid$lf_size_divisor
)
dm_rows <- sensitivity_grid$lf_likelihood == "dm_nore"
dm_group_labels <- c(
  gear1 = "one pooled LF group",
  gear2 = "two LF groups separating extraction and index fisheries",
  gear4 = paste(
    "four gear/data-source groups separating longline, purse seine,",
    "other extraction, and index fisheries"
  ),
  process5 = paste(
    "five observation-process groups separating longline extraction,",
    "large-scale purse seine, domestic purse seine, other extraction, and index fisheries"
  ),
  quality7 = paste(
    "seven quality-informed groups separating longline, associated purse seine,",
    "unassociated purse seine, domestic purse seine, Japanese PS/PL, other extraction, and index fisheries"
  )
)
model_labels[dm_rows] <- paste0(
  "MFCL LF Dirichlet-multinomial noRE; all index LF retained; ",
  unname(dm_group_labels[sensitivity_grid$dm_grouping[dm_rows]]), "; ",
  ifelse(
    sensitivity_grid$dm_estimate_relative_sample_size[dm_rows],
    "relative sample-size exponent estimated from PHASE2",
    "relative sample-size exponent fixed at MFCL default zero"
  ),
  "; DM tail compression min 5 classes; ",
  ifelse(
    is.na(sensitivity_grid$cutoff_cm[dm_rows]),
    "uncut LF data",
    paste0(
      "established F21/F22/F23 upper-bin cutoff above ",
      as.integer(sensitivity_grid$cutoff_cm[dm_rows]),
      " cm"
    )
  ),
  "; DM self-weighting/overdispersion sensitivity, not fixed duplicate-use correction"
)
s010_row <- sensitivity_grid$step_id == "S010-DM-G4-CEST-NOCUT"
model_labels[s010_row] <- paste0(
  "MFCL LF Dirichlet-multinomial noRE; all extraction and index LF retained ",
  "in four gear/data-source groups; separate index group; ",
  "estimated relative sample-size covariate; DM tail compression min 5 classes; ",
  "uncut LF data with DM self-scaling, not fixed duplicate-use correction"
)
alternative_age_rows <- sensitivity_grid$age_length_variant != "BASE075"
model_labels[alternative_age_rows] <- paste0(
  model_labels[alternative_age_rows],
  "; age-length variant ",
  sensitivity_grid$age_length_variant[alternative_age_rows],
  " from ",
  sensitivity_grid$age_length_source_file[alternative_age_rows]
)
selectivity_labels <- c(
  sa28_n5 = paste(
    "SA28-N5 extraction selectivity: independent F1-F28 groups with",
    "single-area young-age, monotonic, and upper-age constraints;",
    "F12/F13 retain five spline nodes; regional indices unchanged"
  ),
  sa28_n8 = paste(
    "SA28-N8 extraction selectivity: independent F1-F28 groups with",
    "single-area young-age, monotonic, upper-age, and eight-node F12/F13",
    "settings; regional indices unchanged"
  ),
  idx_z2 = paste(
    "IDX-Z2 index selectivity: current extraction and five-region index",
    "grouping retained; F29-F33 fixed to zero for the first two ages"
  )
)
selectivity_rows <- sensitivity_grid$selectivity_treatment != "reference"
model_labels[selectivity_rows] <- paste0(
  model_labels[selectivity_rows],
  "; ",
  unname(selectivity_labels[
    sensitivity_grid$selectivity_treatment[selectivity_rows]
  ])
)

stepwise_models <- data.frame(
  step_id = generated_ids,
  enabled = TRUE,
  major_step = "LF conflict sensitivities",
  substep = sub("-.*$", "", generated_ids),
  change_axis = paste0(
    "regional-scaling weight ", sensitivity_grid$regional_scaling_weight,
    "; ", model_labels
  ),
  model_label = model_labels,
  job_title = paste("BET 2026", generated_ids, model_labels),
  job_key = tolower(gsub("[^A-Za-z0-9]+", "-", generated_ids)),
  run_mode = "doitall",
  region_count = 5L,
  kflow_memory = "8GB",
  mfcl_program_path = "",
  input_par = "",
  frq = "bet.frq",
  output_par = "",
  expected_final_par = "11.par",
  regional_scaling_weight = sensitivity_grid$regional_scaling_weight,
  tail_compression_percent = sensitivity_grid$tail_compression_percent,
  cutoff_cm = sensitivity_grid$cutoff_cm,
  cutoff_code = sensitivity_grid$cutoff_code,
  cutoff_description = sensitivity_grid$cutoff_description,
  lf_downweight_factor = sensitivity_grid$lf_downweight_factor,
  lf_size_divisor = sensitivity_grid$lf_size_divisor,
  lf_likelihood = sensitivity_grid$lf_likelihood,
  dm_grouping = sensitivity_grid$dm_grouping,
  dm_estimate_relative_sample_size =
    sensitivity_grid$dm_estimate_relative_sample_size,
  base_sensitivity = sensitivity_grid$base_sensitivity,
  age_length_variant = sensitivity_grid$age_length_variant,
  age_length_source_file = sensitivity_grid$age_length_source_file,
  age_length_source_path = sensitivity_grid$age_length_source_path,
  age_length_sha256 = sensitivity_grid$age_length_sha256,
  selectivity_treatment = sensitivity_grid$selectivity_treatment,
  selectivity_reference = sensitivity_grid$selectivity_reference,
  stringsAsFactors = FALSE
)

# Canonical enabled design: 5 age-length variants x 6 corrected SA28-N5 core
# configurations, 4 non-duplicate BASE075 selectivity sensitivities, and 5
# isolated BASE075 tag-flag sensitivities. Existing rows are schema-complete
# setting templates only; no obsolete model remains enabled.
.design_catalogue <- stepwise_models
.design_ages <- c("BASE075", "REG075", "REG100", "SUB075", "SUB100")

.design_one <- function(rows, description) {
  if (nrow(rows) != 1L) {
    stop(
      "Expected exactly one existing template for ", description,
      "; found ", nrow(rows),
      call. = FALSE
    )
  }
  rows
}

.design_reference_rows <- function(rows) {
  if ("selectivity_treatment" %in% names(rows)) {
    rows <- rows[rows$selectivity_treatment == "reference", , drop = FALSE]
  }
  rows
}

.design_normal_template <- function(age_variant, cutoff, data_weight) {
  candidates <- .design_catalogue[
    .design_catalogue$age_length_variant == age_variant,
    ,
    drop = FALSE
  ]
  candidates <- .design_reference_rows(candidates)
  pattern <- paste0(
    "-TC1-", cutoff, "-DW", data_weight, "(?:-|$)"
  )
  candidates <- candidates[
    grepl(pattern, candidates$step_id, perl = TRUE),
    ,
    drop = FALSE
  ]
  .design_one(
    candidates,
    paste(age_variant, "normal", cutoff, paste0("DW", data_weight))
  )
}

.design_dm_template <- function(cutoff) {
  candidates <- .design_catalogue[
    .design_catalogue$age_length_variant == "BASE075",
    ,
    drop = FALSE
  ]
  candidates <- .design_reference_rows(candidates)
  pattern <- paste0("-DM-G5PROC-CEST-", cutoff, "(?:-|$)")
  candidates <- candidates[
    grepl(pattern, candidates$step_id, perl = TRUE),
    ,
    drop = FALSE
  ]
  .design_one(candidates, paste("BASE075 DM G5PROC CEST", cutoff))
}

.design_set_identity <- function(
    row,
    number,
    slug,
    age_variant,
    label,
    base_sensitivity = NULL,
    selectivity_treatment = "reference",
    selectivity_reference = NULL) {
  step_id <- paste0(sprintf("S%03d", number), "-", slug)
  row$step_id <- step_id
  row$age_length_variant <- age_variant

  if ("base_sensitivity" %in% names(row)) {
    row$base_sensitivity <- if (is.null(base_sensitivity)) {
      step_id
    } else {
      base_sensitivity
    }
  }
  if ("selectivity_treatment" %in% names(row)) {
    row$selectivity_treatment <- selectivity_treatment
  }
  if ("selectivity_reference" %in% names(row)) {
    row$selectivity_reference <- if (is.null(selectivity_reference)) {
      step_id
    } else {
      selectivity_reference
    }
  }
  if ("model_label" %in% names(row)) {
    row$model_label <- label
  }
  if ("model_description" %in% names(row)) {
    row$model_description <- label
  }
  if ("enabled" %in% names(row)) {
    row$enabled <- TRUE
  }
  if ("substep" %in% names(row)) {
    row$substep <- sub("-.*$", "", step_id)
  }
  if ("change_axis" %in% names(row)) {
    row$change_axis <- paste0(
      "regional-scaling weight ", row$regional_scaling_weight,
      "; ", label
    )
  }
  if ("job_title" %in% names(row)) {
    row$job_title <- paste("BET 2026", step_id, label)
  }
  if ("job_key" %in% names(row)) {
    row$job_key <- tolower(gsub("[^A-Za-z0-9]+", "-", step_id))
  }

  numeric_id_columns <- intersect(
    c("step", "step_number", "model_number", "sensitivity_number"),
    names(row)
  )
  for (column in numeric_id_columns) {
    if (is.integer(.design_catalogue[[column]])) {
      row[[column]] <- as.integer(number)
    } else if (is.numeric(.design_catalogue[[column]])) {
      row[[column]] <- number
    }
  }
  row
}

.design_core_specs <- data.frame(
  slug = c(
    "TC1-NOCUT-DW1",
    "TC1-NOCUT-DW10",
    "TC1-CUT90-DW1",
    "TC1-CUT90-DW10",
    "DM-G5PROC-CEST-NOCUT",
    "DM-G5PROC-CEST-CUT90"
  ),
  label = c(
    "normal TC1 NOCUT DW1",
    "normal TC1 NOCUT DW10",
    "normal TC1 CUT90 DW1",
    "normal TC1 CUT90 DW10",
    "DM G5PROC CEST NOCUT",
    "DM G5PROC CEST CUT90"
  ),
  cutoff = c("NOCUT", "NOCUT", "CUT90", "CUT90", "NOCUT", "CUT90"),
  data_weight = c("1", "10", "1", "10", NA, NA),
  dm = c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

.design_age_columns <- grep(
  "^age_length",
  names(.design_catalogue),
  value = TRUE
)
.design_rows <- list()
.design_number <- 0L

for (age_variant in .design_ages) {
  age_template <- .design_normal_template(age_variant, "NOCUT", "1")
  age_suffix <- if (age_variant == "BASE075") "" else paste0("-", age_variant)

  for (configuration in seq_len(nrow(.design_core_specs))) {
    .design_number <- .design_number + 1L
    spec <- .design_core_specs[configuration, , drop = FALSE]

    if (spec$dm) {
      row <- .design_dm_template(spec$cutoff)
      row[, .design_age_columns] <- age_template[, .design_age_columns]
    } else {
      row <- .design_normal_template(
        age_variant,
        spec$cutoff,
        spec$data_weight
      )
    }

    .design_rows[[.design_number]] <- .design_set_identity(
      row = row,
      number = .design_number,
      slug = paste0(spec$slug, age_suffix),
      age_variant = age_variant,
      label = paste(age_variant, spec$label),
      base_sensitivity = paste0(
        sprintf("S%03d", configuration), "-", spec$slug
      ),
      selectivity_treatment = "sa28_n5"
    )
  }
}

.design_selectivity_specs <- data.frame(
  number = c(31L, 32L),
  slug = c(
    "TC1-CUT90-DW1-SA28-N8",
    "DM-G5PROC-CEST-CUT90-SA28-N8"
  ),
  treatment = rep("sa28_n8", 2L),
  dm = c(FALSE, TRUE),
  label = c(
    "BASE075 normal TC1 CUT90 DW1 N8",
    "BASE075 DM G5PROC CEST CUT90 N8"
  ),
  stringsAsFactors = FALSE
)
.design_normal_cut90_dw1 <- .design_rows[[3L]]
.design_dm_cut90 <- .design_rows[[6L]]
.design_normal_reference <- .design_normal_cut90_dw1$step_id[[1L]]
.design_dm_reference <- .design_dm_cut90$step_id[[1L]]

for (configuration in seq_len(nrow(.design_selectivity_specs))) {
  spec <- .design_selectivity_specs[configuration, , drop = FALSE]
  row <- if (spec$dm) .design_dm_cut90 else .design_normal_cut90_dw1
  reference <- if (spec$dm) .design_dm_reference else .design_normal_reference

  .design_rows[[length(.design_rows) + 1L]] <- .design_set_identity(
    row = row,
    number = spec$number,
    slug = spec$slug,
    age_variant = "BASE075",
    label = spec$label,
    selectivity_treatment = spec$treatment,
    selectivity_reference = reference
  )
}

.design_tag_flag2_specs <- data.frame(
  number = 33:37,
  control_index = c(1L, 3L, 5L, 6L, 2L),
  slug = c(
    "TC1-NOCUT-DW1-TAGF2ON",
    "TC1-CUT90-DW1-TAGF2ON",
    "DM-G5PROC-CEST-NOCUT-TAGF2ON",
    "DM-G5PROC-CEST-CUT90-TAGF2ON",
    "TC1-NOCUT-DW10-TAGF2ON"
  ),
  label = c(
    "BASE075 normal TC1 NOCUT DW1 TAGF2ON",
    "BASE075 normal TC1 CUT90 DW1 TAGF2ON",
    "BASE075 DM G5PROC CEST NOCUT TAGF2ON",
    "BASE075 DM G5PROC CEST CUT90 TAGF2ON",
    "BASE075 normal TC1 NOCUT DW10 TAGF2ON"
  ),
  stringsAsFactors = FALSE
)

.design_tag_flag2_controls <- character(nrow(.design_tag_flag2_specs))
for (configuration in seq_len(nrow(.design_tag_flag2_specs))) {
  spec <- .design_tag_flag2_specs[configuration, , drop = FALSE]
  control <- .design_rows[[spec$control_index]]
  control_id <- control$step_id[[1L]]
  .design_tag_flag2_controls[[configuration]] <- control_id
  .design_rows[[length(.design_rows) + 1L]] <- .design_set_identity(
    row = control,
    number = spec$number,
    slug = spec$slug,
    age_variant = "BASE075",
    label = spec$label,
    base_sensitivity = control_id,
    selectivity_treatment = "sa28_n5",
    selectivity_reference = control_id
  )
}

.design_opr_control_id <- .design_rows[[1L]]$step_id[[1L]]
.design_opr_control <- .design_set_identity(
  row = .design_rows[[1L]],
  number = 38L,
  slug = "OPR-Y72-E2-S01-R50-I50",
  age_variant = "BASE075",
  label = "BASE075 corrected N5 normal TC1 NOCUT DW1 OPR Y72 E2 S01 R50 I50",
  base_sensitivity = .design_opr_control_id,
  selectivity_treatment = "sa28_n5",
  selectivity_reference = .design_opr_control_id
)
.design_rows[[length(.design_rows) + 1L]] <- .design_opr_control
.design_opr_tag_id <- "S038-OPR-Y72-E2-S01-R50-I50"
.design_rows[[length(.design_rows) + 1L]] <- .design_set_identity(
  row = .design_opr_control,
  number = 39L,
  slug = "OPR-Y72-E2-S01-R50-I50-TAGF2ON",
  age_variant = "BASE075",
  label = "BASE075 corrected N5 normal TC1 NOCUT DW1 OPR Y72 E2 S01 R50 I50 TAGF2ON",
  base_sensitivity = .design_opr_tag_id,
  selectivity_treatment = "sa28_n5",
  selectivity_reference = .design_opr_tag_id
)

.design_opr_dm_control_id <- .design_rows[[5L]]$step_id[[1L]]
.design_opr_dm_control <- .design_set_identity(
  row = .design_rows[[5L]],
  number = 40L,
  slug = "OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50",
  age_variant = "BASE075",
  label = paste(
    "BASE075 corrected N5 DM-noRE G5PROC C-estimated NOCUT",
    "OPR Y72 E2 S01 R50 I50"
  ),
  base_sensitivity = .design_opr_dm_control_id,
  selectivity_treatment = "sa28_n5",
  selectivity_reference = .design_opr_dm_control_id
)
.design_rows[[length(.design_rows) + 1L]] <- .design_opr_dm_control

.design_opr_dm_tag_id <- "S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50"
.design_rows[[length(.design_rows) + 1L]] <- .design_set_identity(
  row = .design_opr_dm_control,
  number = 41L,
  slug = "OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON",
  age_variant = "BASE075",
  label = paste(
    "BASE075 corrected N5 DM-noRE G5PROC C-estimated NOCUT",
    "OPR Y72 E2 S01 R50 I50 TAGF2ON"
  ),
  base_sensitivity = .design_opr_dm_tag_id,
  selectivity_treatment = "sa28_n5",
  selectivity_reference = .design_opr_dm_tag_id
)

stepwise_models <- do.call(rbind, .design_rows)
rownames(stepwise_models) <- NULL
stepwise_models$tag_flag2 <- 0L
stepwise_models$tag_flag2[grepl("^S0(33|34|35|36|37|39|41)-", stepwise_models$step_id)] <- 1L
stepwise_models$tag_flag2_reference <- stepwise_models$step_id
stepwise_models$tag_flag2_reference[
  grepl("^S0(33|34|35|36|37)-", stepwise_models$step_id)
] <- .design_tag_flag2_controls
stepwise_models$tag_flag2_reference[
  stepwise_models$step_id == "S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON"
] <- .design_opr_tag_id
stepwise_models$tag_flag2_reference[
  stepwise_models$step_id ==
    "S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON"
] <- .design_opr_dm_tag_id

stepwise_models$opr_enabled <- grepl("^S0(38|39|40|41)-OPR-", stepwise_models$step_id)
stepwise_models$opr_year_effect <- ifelse(stepwise_models$opr_enabled, 72L, NA_integer_)
stepwise_models$opr_terminal_year_constraint <- ifelse(
  stepwise_models$opr_enabled, 2L, NA_integer_
)
stepwise_models$opr_season_effect <- ifelse(stepwise_models$opr_enabled, 1L, NA_integer_)
stepwise_models$opr_region_effect <- ifelse(stepwise_models$opr_enabled, 50L, NA_integer_)
stepwise_models$opr_region_season_effect <- ifelse(
  stepwise_models$opr_enabled, 50L, NA_integer_
)
stepwise_models$opr_terminal_penalty_flag <- ifelse(
  stepwise_models$opr_enabled, 0L, NA_integer_
)
stepwise_models$opr_source <- ifelse(
  stepwise_models$opr_enabled,
  "BET OPR apply_opr() in R/prepare_doitall.R",
  ""
)

.design_expected_prefix <- sprintf("S%03d", 1:41)
.design_actual_prefix <- sub("-.*$", "", stepwise_models$step_id)
if (nrow(stepwise_models) != 41L ||
    anyDuplicated(stepwise_models$step_id) ||
    !identical(.design_actual_prefix, .design_expected_prefix)) {
  stop("Canonical design must contain the contiguous model IDs S001:S041", call. = FALSE)
}
if (!identical(
  as.integer(table(factor(
    stepwise_models$age_length_variant,
    levels = .design_ages
  ))),
  c(17L, 6L, 6L, 6L, 6L)
)) {
  stop("Canonical design has incorrect age-length variant counts", call. = FALSE)
}
if (!identical(
      stepwise_models$tag_flag2,
      c(rep(0L, 32L), rep(1L, 5L), 0L, 1L, 0L, 1L)
    ) ||
    !identical(
      stepwise_models$tag_flag2_reference[stepwise_models$tag_flag2 == 1L],
      c(.design_tag_flag2_controls, .design_opr_tag_id, .design_opr_dm_tag_id)
    )) {
  stop(
    "TAGF2ON models must be isolated copies of their corrected controls",
    call. = FALSE
  )
}
if (sum(stepwise_models$opr_enabled) != 4L ||
    any(stepwise_models$opr_year_effect[stepwise_models$opr_enabled] != 72L) ||
    any(stepwise_models$opr_terminal_year_constraint[stepwise_models$opr_enabled] != 2L) ||
    any(stepwise_models$opr_season_effect[stepwise_models$opr_enabled] != 1L) ||
    any(stepwise_models$opr_region_effect[stepwise_models$opr_enabled] != 50L) ||
    any(stepwise_models$opr_region_season_effect[stepwise_models$opr_enabled] != 50L) ||
    any(stepwise_models$opr_terminal_penalty_flag[stepwise_models$opr_enabled] != 0L)) {
  stop("OPR pair must use Y72 E2 S01 R50 I50 with terminal penalty disabled", call. = FALSE)
}
if (any(grepl(
  "DW5|CUT70|(?:^|-)C0(?:-|$)|(?:^|-)G(?:1|2|4|7)(?:-|$)",
  stepwise_models$step_id,
  perl = TRUE
))) {
  stop("Canonical design contains a prohibited configuration", call. = FALSE)
}

# Obsolete focused/special objects are not part of the exported configuration.
.design_obsolete <- grep(
  "focused|special",
  ls(envir = environment()),
  value = TRUE,
  ignore.case = TRUE
)
if (length(.design_obsolete)) {
  rm(list = .design_obsolete, envir = environment())
}
rm(
  .design_catalogue,
  .design_ages,
  .design_core_specs,
  .design_age_columns,
  .design_rows,
  .design_number,
  .design_selectivity_specs,
  .design_normal_cut90_dw1,
  .design_dm_cut90,
  .design_normal_reference,
  .design_dm_reference,
  .design_tag_flag2_specs,
  .design_tag_flag2_controls,
  .design_opr_control_id,
  .design_opr_control,
  .design_opr_tag_id,
  .design_opr_dm_control_id,
  .design_opr_dm_control,
  .design_opr_dm_tag_id,
  .design_expected_prefix,
  .design_actual_prefix,
  .design_obsolete,
  .design_one,
  .design_reference_rows,
  .design_normal_template,
  .design_dm_template,
  .design_set_identity
)
