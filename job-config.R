# Curated BET 2026 MFCL LF sensitivity set.
# The original 17 LF configurations are crossed with five age-length inputs.
# Six focused BASE075 models add observation-process and quality-informed
# Dirichlet-multinomial groupings without expanding the age-length factorial.

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
  stringsAsFactors = FALSE
)
