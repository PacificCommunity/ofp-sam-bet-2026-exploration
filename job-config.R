# Edit this file to choose the default run and add model rows.
# More detailed instructions are in README.md.

stepwise_run <- list(
  # Default model when STEP_SELECT is not provided.
  default_step_select = "01-base-11par",

  # Short Kflow group label for one stepwise -> results -> report chain.
  # Override per launch when running several chains at once.
  flow_group = "bet-2026-base",

  # TRUE runs downstream plot/report after stepwise succeeds.
  trigger_next = TRUE,

  # Blank uses each model row's fevals value.
  mfcl_fevals = ""
)

# One row is one independent model folder under steps/<step_id>/model/.
stepwise_models <- data.frame(
  # Folder name and Kflow selector.
  step_id = c(
    "01-base-11par",
    "02-continue-11par",
    "03-review-11par"
  ),
  enabled = c(TRUE, TRUE, TRUE),

  # Short model label used in logs, plots, and reports.
  model_label = c(
    "Base 11.par",
    "Base 11.par model 02",
    "Base 11.par model 03"
  ),

  # Title shown in the Kflow job list.
  job_title = c(
    "BET stepwise: Base 11.par",
    "BET stepwise: Base 11.par model 02",
    "BET stepwise: Base 11.par model 03"
  ),

  # Stable key used by Kflow dependency links and selectors.
  job_key = c(
    "01-base-11par",
    "02-continue-11par",
    "03-review-11par"
  ),

  # Run settings for each model row.
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
