# Edit this file to choose the default run and add model rows.
# More detailed instructions are in README.md.

stepwise_run <- list(
  # Default model when STEP_SELECT is not provided.
  default_step_select = "all",

  # Short Kflow group label for one stepwise -> results -> report chain.
  # Override per launch when running several chains at once.
  flow_group = "bet-2026-stepwise-v2",

  # TRUE runs downstream plot/report after stepwise succeeds.
  trigger_next = TRUE
)

# One row is one independent model folder under steps/<step_id>/model/.
stepwise_models <- data.frame(
  # Folder name and Kflow selector.
  step_id = c(
    "01-Diag2023",
    "02-NewExe",
    "03-FixM",
    "04-NewStructure",
    "05-ConvertToLength",
    "06-LengthPlusLength",
    "07-DataTo2024",
    "08-RegionalCPUE",
    "09-NewOtoliths",
    "10-TagMixingKS",
    "11-TimeVaryingCV",
    "12-OrthogonalPoly",
    "13-LengthBasedSel",
    "14-EffortCreep",
    "15-DataWeighting"
  ),
  enabled = rep(TRUE, 15),

  # Short model label used in logs, plots, and reports.
  model_label = c(
    "Diag2023",
    "NewExe",
    "FixM",
    "New structure",
    "Convert to length",
    "Length plus length",
    "Data to 2024",
    "Regional CPUE",
    "New otoliths",
    "Tag mixing KS",
    "Time-varying CV",
    "Orthogonal polynomial",
    "Length-based selectivity",
    "Effort creep",
    "Data weighting"
  ),

  # Title shown in the Kflow job list.
  job_title = c(
    "Diag2023",
    "NewExe",
    "FixM",
    "New structure",
    "Convert to length",
    "Length plus length",
    "Data to 2024",
    "Regional CPUE",
    "New otoliths",
    "Tag mixing KS",
    "Time-varying CV",
    "Orthogonal polynomial",
    "Length-based selectivity",
    "Effort creep",
    "Data weighting"
  ),

  # Stable key used by Kflow dependency links and selectors.
  job_key = c(
    "01-diag2023",
    "02-newexe",
    "03-fixm",
    "04-newstructure",
    "05-converttolength",
    "06-lengthpluslength",
    "07-datato2024",
    "08-regionalcpue",
    "09-newotoliths",
    "10-tagmixingks",
    "11-timevaryingcv",
    "12-orthogonalpoly",
    "13-lengthbasedsel",
    "14-effortcreep",
    "15-dataweighting"
  ),

  # Run settings for each model row.
  run_mode = rep("doitall", 15),
  mfcl_program_path = c(
    "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0",
    rep("", 14)
  ),
  input_par = rep("", 15),
  frq = rep("bet.frq", 15),
  output_par = rep("", 15),
  stringsAsFactors = FALSE
)
