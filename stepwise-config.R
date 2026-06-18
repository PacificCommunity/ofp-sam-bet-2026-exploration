stepwise_run <- list(
  default_step_select = "01-base-11par",
  flow_group = "bet-2026-x111",
  trigger_next = TRUE,
  mfcl_fevals = ""
)

stepwise_models <- data.frame(
  step_id = c(
    "01-base-11par",
    "02-continue-11par",
    "03-review-11par"
  ),
  enabled = c(TRUE, TRUE, TRUE),
  model_label = c(
    "Base 11.par",
    "Base 11.par model 02",
    "Base 11.par model 03"
  ),
  job_title = c(
    "BET stepwise: Base 11.par",
    "BET stepwise: Base 11.par model 02",
    "BET stepwise: Base 11.par model 03"
  ),
  job_key = c(
    "01-base-11par",
    "02-continue-11par",
    "03-review-11par"
  ),
  run_mode = c(
    "last_par",
    "last_par",
    "last_par"
  ),
  input_par = c("11.par", "11.par", "11.par"),
  frq = c("bet.frq", "bet.frq", "bet.frq"),
  output_par = c("", "", ""),
  fevals = c(1L, 1L, 1L),
  stringsAsFactors = FALSE
)
