# BET 2026 targeted PTTP reporting-rate sensitivity.
#
# This branch intentionally exports one model only. The model is derived from
# S002-TC1-NOCUT-DW10 in commit
# 6654763923ffa8c91b5e3df6aabc9483dc797cbd, but that control is retained as
# provenance rather than duplicated in this focused branch.

model_id <- "S001-TC1-NOCUT-DW10-RRASSOC"
control_id <- "S002-TC1-NOCUT-DW10"

stepwise_models <- data.frame(
  step_id = model_id,
  enabled = TRUE,
  major_step = "Tag reporting-rate sensitivity",
  substep = "S001",
  change_axis = paste(
    "PTTP reporting rates split between associated F25/F26",
    "and unassociated F27/F28 fisheries"
  ),
  model_label = paste(
    "BASE075 normal TC1 NOCUT DW10 PTTP reporting rates split",
    "for associated F25/F26 and unassociated F27/F28 fisheries"
  ),
  job_title = paste(
    "BET 2026", model_id,
    "BASE075 normal TC1 NOCUT DW10 PTTP reporting-rate association split"
  ),
  job_key = "s001-tc1-nocut-dw10-rrassoc",
  run_mode = "doitall",
  region_count = 5L,
  kflow_memory = "8GB",
  mfcl_program_path = "",
  input_par = "",
  frq = "bet.frq",
  output_par = "",
  expected_final_par = "11.par",
  regional_scaling_weight = 50L,
  tail_compression_percent = 1L,
  cutoff_cm = NA_real_,
  cutoff_code = "NOCUT",
  cutoff_description = "F21/F22/F23 observed LF counts are unchanged; no cutoff is applied",
  lf_downweight_factor = 10L,
  lf_size_divisor = 200L,
  lf_likelihood = "normal",
  dm_grouping = "none",
  dm_estimate_relative_sample_size = FALSE,
  base_sensitivity = control_id,
  age_length_variant = "BASE075",
  age_length_source_file = "bet.age_length",
  age_length_source_path =
    "reference-inputs/job-5319/mfcl-inputs/bet.age_length",
  age_length_sha256 =
    "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
  selectivity_treatment = "sa28_n5",
  selectivity_reference = control_id,
  tag_flag2 = 0L,
  tag_flag2_reference = model_id,
  tag_reporting_treatment = "pttp_assoc_split",
  tag_reporting_reference = control_id,
  opr_enabled = FALSE,
  opr_year_effect = NA_integer_,
  opr_terminal_year_constraint = NA_integer_,
  opr_season_effect = NA_integer_,
  opr_region_effect = NA_integer_,
  opr_region_season_effect = NA_integer_,
  opr_terminal_penalty_flag = NA_integer_,
  opr_source = "",
  stringsAsFactors = FALSE
)

rm(model_id, control_id)
