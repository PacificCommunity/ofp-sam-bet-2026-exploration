# Curated BET 2026 MFCL LF sensitivity set.
# Four fitted TC1 models have a positive-definite Hessian. Three additional
# CUT90 models reproduce the historical upper-length treatment, with targeted
# downweight levels for fisheries 21, 22, and 23 only. Tail compression is
# global. Regional scaling is fixed at weight 50.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-conflict-exploration",
  trigger_next = FALSE
)

sensitivity_grid <- data.frame(
  step_id = c(
    "S010-TC1-CUT70-DW1",
    "S014-TC1-NOCUT-DW10",
    "S022-TC1-CUT70-DW10",
    "S034-TC1-CUT70-DW100",
    "S037-TC1-CUT90-DW1",
    "S038-TC1-CUT90-DW5",
    "S039-TC1-CUT90-DW10"
  ),
  regional_scaling_weight = rep(50L, 7L),
  tail_compression_percent = rep(1L, 7L),
  cutoff_cm = c(70, NA_real_, 70, 70, 90, 90, 90),
  lf_downweight_factor = c(1L, 10L, 10L, 100L, 1L, 5L, 10L),
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

stepwise_models <- data.frame(
  step_id = generated_ids,
  enabled = TRUE,
  major_step = "LF conflict sensitivities",
  substep = sub("-.*$", "", generated_ids),
  change_axis = sprintf(
    paste0(
      "regional-scaling weight %d; global MFCL LF tail compression %d%%; ",
      "%s; F21/F22/F23 LF likelihood downweight %dx with flag-49 divisor %d"
    ),
    sensitivity_grid$regional_scaling_weight,
    sensitivity_grid$tail_compression_percent,
    sensitivity_grid$cutoff_description,
    sensitivity_grid$lf_downweight_factor,
    sensitivity_grid$lf_size_divisor
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
  stringsAsFactors = FALSE
)
