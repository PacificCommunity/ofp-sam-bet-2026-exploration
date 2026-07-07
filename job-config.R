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
    "02a-NewExe",
    "02b-Ini1007",
    "02c-LengthWeight",
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
  enabled = rep(TRUE, 17),

  # Scientific grouping for reporting/provenance.
  major_step = c(
    "01-Diagnostic",
    "02-Executable",
    "02-Executable",
    "02-Executable",
    "03-FixM",
    "04-NewStructure",
    "05-ConvertToLength",
    "06-LengthPlusLength",
    "07-DataTo2024",
    "08-RegionalCPUE",
    "09-NewOtoliths",
    "10-TagMixing",
    "11-TimeVaryingCV",
    "12-OrthogonalPoly",
    "13-LengthBasedSel",
    "14-EffortCreep",
    "15-DataWeighting"
  ),
  substep = c(
    "01a",
    "02a",
    "02b",
    "02c",
    "03a",
    "04",
    "05a",
    "06a",
    "07a",
    "08a",
    "09a",
    "10a",
    "11a",
    "12a",
    "13a",
    "14a",
    "15a"
  ),
  change_axis = c(
    "historical diagnostic",
    "current MFCL executable with 1003 ini",
    "promote diagnostic ini to 1007",
    "bias-corrected 2026 length-weight parameters",
    "fixed natural mortality from mgc=-5 diagnostic after 02c",
    "5-region structure with global CPUE",
    "convert weight compositions to length",
    "add additional length compositions",
    "2024 data with global CPUE",
    "regional CPUE and regional-scaling prior",
    "new otolith/CAAL input",
    "release-specific tag mixing periods",
    "time-varying CPUE CV",
    "orthogonal-polynomial recruitment",
    "length-based selectivity",
    "effort creep",
    "data weighting"
  ),
  # Short model label used in logs, plots, and reports.
  model_label = c(
    "Diag2023",
    "NewExe 1003",
    "Ini 1007",
    "Length-weight",
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
    "01 Diag2023",
    "02a NewExe 1003",
    "02b Ini 1007",
    "02c Length-weight",
    "03 FixM",
    "04 New structure",
    "05 Convert to length",
    "06 Length plus length",
    "07 Data to 2024",
    "08 Regional CPUE",
    "09 New otoliths",
    "10 Tag mixing KS",
    "11 Time-varying CV",
    "12 Orthogonal polynomial",
    "13 Length-based selectivity",
    "14 Effort creep",
    "15 Data weighting"
  ),

  # Stable key used by Kflow dependency links and selectors.
  job_key = c(
    "01-diag2023",
    "02a-newexe",
    "02b-ini1007",
    "02c-lengthweight",
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

  # Run settings for each model row. All rows use native MFCL for this stepwise run.
  run_mode = rep("doitall", 17),
  region_count = c(rep(9L, 5), rep(5L, 12)),
  kflow_memory = c(rep("14GB", 5), rep("8GB", 12)),
  mfcl_program_path = c(
    "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0",
    rep("", 16)
  ),
  input_par = rep("", 17),
  frq = rep("bet.frq", 17),
  output_par = rep("", 17),
  stringsAsFactors = FALSE
)
