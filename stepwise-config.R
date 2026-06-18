# Edit this file to choose and describe the independent stepwise models.
# Each row points at one folder under steps/. Kflow can run one row with
# STEP_SELECT=01-base-11par, several rows with commas, or every enabled row with
# STEP_SELECT=all.

stepwise_run <- list(
  default_step_select = "01-base-11par",
  flow_group = "bet-2026-e2e",
  trigger_next = TRUE,
  mfcl_fevals = ""
)

stepwise_value <- function(name, default = "") {
  value <- stepwise_run[[name]]
  if (is.null(value) || length(value) == 0 || is.na(value[[1]])) {
    return(default)
  }
  if (is.logical(value)) {
    return(tolower(as.character(value[[1]])))
  }
  as.character(value[[1]])
}

stepwise_job_title <- function(step_select = stepwise_value("default_step_select")) {
  paste("BET stepwise", step_select)
}

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
  run_mode = c(
    "last_par",
    "last_par",
    "last_par"
  ),
  source_dir = c("", "", ""),
  input_par = c("11.par", "11.par", "11.par"),
  frq = c("bet.frq", "bet.frq", "bet.frq"),
  output_par = c("", "", ""),
  fevals = c(1L, 1L, 1L),
  notes = c(
    "Starter base model from the model files in steps/01-base-11par/model.",
    "Independent model slot. Add model files or patch.R in the matching step folder.",
    "Independent model slot. Add model files or patch.R in the matching step folder."
  ),
  stringsAsFactors = FALSE
)
