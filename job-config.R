# One focused model is active in this exploration repository.

stepwise_run <- list(
  default_step_select = "12-EffortCreep",
  flow_group = "bet-2026-regscaling-exploration",
  trigger_next = FALSE
)

stepwise_models <- data.frame(
  step_id = "12-EffortCreep",
  enabled = TRUE,
  major_step = "Exploration",
  substep = "E01",
  change_axis = "regional-scaling input window alignment",
  model_label = "Regional scaling aligned",
  job_title = "BET 2026 regional-scaling alignment",
  job_key = "regscaling-aligned",
  run_mode = "doitall",
  region_count = 5L,
  kflow_memory = "8GB",
  mfcl_program_path = "",
  input_par = "",
  frq = "bet.frq",
  output_par = "",
  expected_final_par = "11.par",
  stringsAsFactors = FALSE
)
