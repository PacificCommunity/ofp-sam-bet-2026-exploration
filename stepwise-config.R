# Edit this file to choose and describe the independent stepwise models.
# Each row points at one folder under steps/. Kflow can run one row with
# STEP_SELECT=01-base-11par, several rows with commas, or every enabled row with
# STEP_SELECT=all.

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
  source_dir = c("", "", ""),
  input_par = c("11.par", "11.par", "11.par"),
  frq = c("bet.frq", "bet.frq", "bet.frq"),
  output_par = c("final.par", "final.par", "final.par"),
  fevals = c(1L, 1L, 1L),
  notes = c(
    "Starter base model from the bundled BET input files.",
    "Independent model slot. Add model files or patch.R in the matching step folder.",
    "Independent model slot. Add model files or patch.R in the matching step folder."
  ),
  stringsAsFactors = FALSE
)
