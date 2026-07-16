# Kflow execution table for the OPR recruitment sensitivity models.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-opr-recruitment-sensitivities",
  trigger_next = FALSE
)

manifest_path <- file.path("opr-sensitivity", "manifest.csv")
if (!file.exists(manifest_path)) {
  stop("Missing OPR sensitivity manifest: ", manifest_path, call. = FALSE)
}

stepwise_models <- read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_columns <- c("step_id", "job_title", "expected_final_par")
missing_columns <- setdiff(required_columns, names(stepwise_models))
if (length(missing_columns)) {
  stop(
    "OPR sensitivity manifest is missing column(s): ",
    paste(missing_columns, collapse = ", "),
    call. = FALSE
  )
}
if (nrow(stepwise_models) != 39L || anyDuplicated(stepwise_models$step_id)) {
  stop("OPR sensitivity manifest must contain 39 unique models.", call. = FALSE)
}

stepwise_models$enabled <- TRUE
stepwise_models$major_step <- "OPR recruitment sensitivities"
stepwise_models$substep <- sprintf("OPR%03d", seq_len(nrow(stepwise_models)))
stepwise_models$change_axis <- sprintf(
  paste0(
    "OPR year %d; terminal end %d; terminal penalty %d; ",
    "season %d; region %d; interaction %d"
  ),
  stepwise_models$year_effect,
  stepwise_models$terminal_year_constraint,
  stepwise_models$terminal_penalty_flag,
  stepwise_models$season_effect,
  stepwise_models$region_effect,
  stepwise_models$region_season_effect
)
stepwise_models$model_label <- stepwise_models$job_title
stepwise_models$job_key <- tolower(gsub("[^A-Za-z0-9]+", "-", stepwise_models$step_id))
stepwise_models$run_mode <- "doitall"
stepwise_models$region_count <- 5L
stepwise_models$kflow_memory <- "8GB"
stepwise_models$mfcl_program_path <- ""
stepwise_models$input_par <- ""
stepwise_models$frq <- "bet.frq"
stepwise_models$output_par <- ""
