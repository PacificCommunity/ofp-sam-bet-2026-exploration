# Complete 4 x 3 x 3 BET 2026 MFCL sensitivity factorial.
# Tail compression is global. Observed LF upper-bin zeroing and LF likelihood
# downweighting apply only to fisheries 21, 22, and 23. Regional scaling is
# fixed at weight 50.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-conflict-exploration",
  trigger_next = FALSE
)

tail_compression_levels <- c(0L, 1L, 3L, 5L)
cutoff_levels <- c(NA_real_, 100, 70)
downweight_levels <- c(1L, 10L, 100L)

sensitivity_grid <- expand.grid(
  regional_scaling_weight = 50L,
  tail_compression_percent = tail_compression_levels,
  cutoff_cm = cutoff_levels,
  lf_downweight_factor = downweight_levels,
  KEEP.OUT.ATTRS = FALSE,
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

generated_ids <- sprintf(
  "S%03d-TC%d-%s-DW%d",
  seq_len(nrow(sensitivity_grid)),
  sensitivity_grid$tail_compression_percent,
  sensitivity_grid$cutoff_code,
  sensitivity_grid$lf_downweight_factor
)

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
  substep = sprintf("S%03d", seq_len(nrow(sensitivity_grid))),
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
