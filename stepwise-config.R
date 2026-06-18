# BET 2026 stepwise model configuration.
#
# This is the main file to edit when adding, selecting, naming, or lightly
# changing model runs. Each row in `stepwise_models` points to one independent
# model folder under `steps/`.
# See README.md for the human-readable guide.
#
# Common launch examples:
#   STEP_SELECT=01-base-11par
#     Run only steps/01-base-11par.
#   STEP_SELECT=01-base-11par,03-review-11par
#     Run two independent model folders in one job.
#   STEP_SELECT=all
#     Run every row where enabled is TRUE.
#   MFCL_FEVALS=10
#     Override the per-row `fevals` value for one quick direct-MFCL test job.
#     This is automatically applied only for run_mode "last_par" or "single".
#     For run_mode "doitall", the value is passed to doitall.sh as the
#     environment variables MFCL_FEVALS and SMOKE_FEVALS, but the script must
#     explicitly use them.
#
# Folder convention:
#   steps/<step_id>/model/
#     Put that model's MFCL inputs here: .frq, .ini, .tag, .age_length, .par,
#     doitall.sh if needed, and any related model files.
#   steps/<step_id>/patch.R
#     Optional. Use only for a small scripted edit that should happen just
#     before MFCL runs.

stepwise_run <- list(
  # Default model folder used by `make local`, `make docker`, and `make kflow`
  # when STEP_SELECT is not supplied. Keep this narrow so adding new folders
  # does not accidentally run everything.
  default_step_select = "01-base-11par",

  # Label used to group the automatic stepwise -> plot -> report chain in Kflow.
  # Example: "bet-2026-e2e", "bet-2026-debug", "bet-2026-base-check".
  flow_group = "bet-2026-x111",

  # TRUE: command-line `make kflow` keeps the default dependency chain and
  # launches plot/report when stepwise succeeds.
  # FALSE: `make kflow` submits only the selected stepwise model job.
  # One-off override:
  #   make kflow TRIGGER_NEXT=false STEP_SELECT=01-base-11par
  trigger_next = TRUE,

  # Blank means use each row's `fevals`.
  # This controls the runner's quick-test -switch arguments for "last_par" and
  # "single" modes. It does not automatically modify a doitall.sh run.
  # In "doitall" mode, the value is only made available to the script as
  # MFCL_FEVALS/SMOKE_FEVALS.
  # Set a number here to override every selected row, for example:
  #   mfcl_fevals = "1"   # very quick smoke run
  #   mfcl_fevals = "50"  # longer local/cluster check
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

stepwise_selected_models <- function(step_select = stepwise_value("default_step_select")) {
  selected <- trimws(strsplit(as.character(step_select), ",", fixed = TRUE)[[1]])
  selected <- selected[nzchar(selected)]
  if (!length(selected)) {
    selected <- stepwise_value("default_step_select")
  }
  if (any(tolower(selected) %in% c("all", "*"))) {
    out <- stepwise_models[isTRUE(stepwise_models$enabled) | stepwise_models$enabled %in% TRUE, , drop = FALSE]
    if (!nrow(out)) {
      out <- stepwise_models[0, , drop = FALSE]
    }
    return(out)
  }
  out <- stepwise_models[stepwise_models$step_id %in% selected, , drop = FALSE]
  if (!nrow(out)) {
    return(data.frame(step_id = selected, model_label = selected, stringsAsFactors = FALSE))
  }
  out
}

stepwise_model_label <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  labels <- trimws(as.character(rows$model_label))
  labels[!nzchar(labels) | is.na(labels)] <- rows$step_id[!nzchar(labels) | is.na(labels)]
  if (!length(labels)) {
    return(as.character(step_select))
  }
  if (length(labels) == 1L) {
    return(labels[[1]])
  }
  paste0(labels[[1]], " +", length(labels) - 1L, " models")
}

stepwise_job_key <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  if (!nrow(rows)) {
    key <- as.character(step_select)
  } else if (nrow(rows) == 1L) {
    key <- rows$step_id[[1]]
  } else {
    key <- paste0(rows$step_id[[1]], "-plus-", nrow(rows) - 1L)
  }
  key <- tolower(gsub("[^A-Za-z0-9_.-]+", "-", key))
  gsub("^-+|-+$", "", key)
}

stepwise_job_title <- function(step_select = stepwise_value("default_step_select")) {
  paste("BET stepwise:", stepwise_model_label(step_select))
}

# Model table.
#
# Add a new model by copying one row, changing `step_id`, and creating the
# matching folder under steps/. Keep labels short because they are reused in
# Kflow, plots, and summaries.
#
# Column guide:
#   step_id:
#     Folder name under `steps/`. Use numbered names so the intended order is
#     obvious, for example "04-steepness-low".
#   enabled:
#     TRUE to allow STEP_SELECT=all to run it. FALSE keeps the row documented
#     but skipped by all-mode.
#   model_label:
#     Human-readable short name for Kflow/plot/report labels.
#   run_mode:
#     "last_par"  Continue from the latest numbered .par and write the next one.
#                 Example: 11.par -> 12.par. This is the normal quick check.
#                 Uses `fevals` through runner-generated MFCL -switch arguments.
#     "single"    Use `input_par` and `output_par` exactly as listed.
#                 Uses `fevals` through runner-generated MFCL -switch arguments.
#     "doitall"   Run doitall.sh from the model folder, then keep the final .par.
#                 Does not automatically use `fevals`; doitall.sh must read
#                 MFCL_FEVALS/SMOKE_FEVALS if that behavior is wanted.
#   source_dir:
#     Blank means auto-detect `steps/<step_id>/model/`.
#     Use "." to use files directly in `steps/<step_id>/`.
#     Use a relative or absolute folder only for a deliberate shared source.
#   input_par:
#     Starting par file for "last_par" or "single"; use "latest" to auto-pick.
#   frq:
#     MFCL frequency file name, usually "bet.frq".
#   output_par:
#     Blank lets "last_par" choose the next numbered par.
#     Required for "single" if you want a precise output name.
#   fevals:
#     Quick test function evaluations for this row. Override with MFCL_FEVALS.
#     Applied by this runner only for "last_par" and "single"; only passed
#     through as an environment variable for "doitall".
#   notes:
#     Free text for humans. Use this to document why the model exists.
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
