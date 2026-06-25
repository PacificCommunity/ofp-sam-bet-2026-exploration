# Edit this file to choose the default run and add model rows.
# More detailed instructions are in README.md.

stepwise_run <- list(
  # Default model when STEP_SELECT is not provided.
  default_step_select = "all",

  # Short Kflow group label for one stepwise -> results -> report chain.
  # Override per launch when running several chains at once.
  flow_group = "bet-2026-stepwise-v2",

  # TRUE runs downstream plot/report after stepwise succeeds.
  trigger_next = TRUE,

  # Blank uses each model row's fevals value.
  mfcl_fevals = ""
)

# One row is one independent model folder under steps/<step_id>/model/.
stepwise_models <- data.frame(
  # Folder name and Kflow selector.
  step_id = c(
    "01-Diag23",
    "02-FixM",
    "03-RegFish",
    "04-WtAsLen21",
    "05-WtAsLenPlusLen21",
    "06-Full2024",
    "07-CAAL2026",
    "08-MixPeriod02",
    "09-SizeBasedSel",
    "10-OPR",
    "11-EffortCreep",
    "12-DataWeight40"
  ),
  enabled = rep(TRUE, 12),

  # Short model label used in logs, plots, and reports.
  model_label = c(
    "2023 diagnostic",
    "FixM",
    "New regions/fisheries",
    "Weights as lengths, 2021",
    "Weights as lengths plus lengths, 2021",
    "Full 2024 data",
    "Updated CAAL",
    "Mixing periods 0.2",
    "Size-based selectivity",
    "OPR",
    "Effort creep",
    "Data weighting 40"
  ),

  # Title shown in the Kflow job list.
  job_title = c(
    "2023 diagnostic",
    "FixM",
    "New regions/fisheries",
    "Weights as lengths to 2021",
    "Weights as lengths plus lengths to 2021",
    "Full 2024 data",
    "Updated CAAL",
    "Mixing periods 0.2",
    "Size-based selectivity",
    "OPR",
    "Effort creep",
    "Data weighting 40"
  ),

  # Stable key used by Kflow dependency links and selectors.
  job_key = c(
    "01-diag23",
    "02-fixm",
    "03-regfish",
    "04-wtaslen21",
    "05-wtaslenpluslen21",
    "06-full2024",
    "07-caal2026",
    "08-mixperiod02",
    "09-sizebasedsel",
    "10-opr",
    "11-effortcreep",
    "12-dataweight40"
  ),

  # Run settings for each model row.
  run_mode = rep("doitall", 12),
  input_par = rep("", 12),
  frq = rep("bet.frq", 12),
  output_par = rep("", 12),
  fevals = rep(1L, 12),
  stringsAsFactors = FALSE
)
