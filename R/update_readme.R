config_path <- Sys.getenv("CONFIG_R", "job-config.R")
readme_path <- Sys.getenv("README_MD", "README.md")

source("R/stepwise_config_helpers.R")
source_stepwise_config(config_path)

yaml_value <- function(path) {
  if (!file.exists(path) || !requireNamespace("yaml", quietly = TRUE)) {
    return(NULL)
  }
  yaml::read_yaml(path)
}

empty_to_blank <- function(x) {
  x <- as.character(x)
  x[is.na(x) | !nzchar(x)] <- "blank"
  x
}

escape_md <- function(x) {
  x <- empty_to_blank(x)
  x <- gsub("\\|", "\\\\|", x)
  x <- gsub("\n", " ", x, fixed = TRUE)
  x
}

code_value <- function(x) {
  paste0("`", escape_md(x), "`")
}

format_column <- function(values, column) {
  code_columns <- c(
    "setting", "value", "step_id", "enabled", "job_key", "run_mode",
    "input_par", "frq", "output_par", "fevals", "expected_source_folder",
    "status"
  )
  values <- empty_to_blank(values)
  if (column %in% code_columns) {
    return(code_value(values))
  }
  escape_md(values)
}

markdown_table <- function(df) {
  if (!nrow(df)) {
    return("_No rows configured._")
  }
  headers <- names(df)
  header_line <- paste(paste0("`", headers, "`"), collapse = " | ")
  sep_line <- paste(rep("---", length(headers)), collapse = " | ")
  body <- apply(df, 1, function(row) {
    values <- vapply(seq_along(headers), function(i) {
      format_column(row[[i]], headers[[i]])
    }, character(1))
    paste(values, collapse = " | ")
  })
  paste(c(
    paste0("| ", header_line, " |"),
    paste0("| ", sep_line, " |"),
    paste0("| ", body, " |")
  ), collapse = "\n")
}

generated_note <- paste0(
  "<!-- This section is generated from ",
  config_path,
  ". It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->"
)

readme_section <- function(lines, heading, body) {
  start <- which(lines == heading)
  if (length(start) != 1L) {
    stop("Expected exactly one README heading: ", heading, call. = FALSE)
  }
  start <- start[[1]]
  after <- lines[(start + 1L):length(lines)]
  next_heading <- grep("^## ", after)
  end <- if (length(next_heading)) start + next_heading[[1]] - 1L else length(lines) + 1L
  c(
    lines[seq_len(start)],
    "",
    generated_note,
    "",
    body,
    "",
    if (end <= length(lines)) lines[end:length(lines)] else character()
  )
}

kflow <- yaml_value("kflow.yaml")
docker_image <- if (is.null(kflow$docker_image)) "ghcr.io/pacificcommunity/tuna-flow:v1.5" else kflow$docker_image
program_path <- tryCatch(kflow$env$PROGRAM_PATH, error = function(e) NULL)
if (is.null(program_path) || !nzchar(program_path)) {
  program_path <- "/home/mfcl/mfclo64"
}

defaults <- data.frame(
  setting = c("default_step_select", "flow_group", "trigger_next", "mfcl_fevals", "docker_image", "program_path"),
  value = c(
    stepwise_value("default_step_select", "01-base-11par"),
    stepwise_value("flow_group", "bet-2026-e2e"),
    stepwise_value("trigger_next", "true"),
    stepwise_value("mfcl_fevals", ""),
    docker_image,
    program_path
  ),
  meaning = c(
    "Model selection used when `STEP_SELECT` is not supplied.",
    "Kflow group label used to connect stepwise, plot, and report jobs.",
    "Whether command-line Kflow submissions keep the downstream plot/report chain.",
    "Blank uses the row-level `fevals` value; a number overrides selected rows.",
    "Docker image used by Kflow and local Docker runs.",
    "MFCL executable path inside the Docker image."
  ),
  stringsAsFactors = FALSE
)

model_columns <- c(
  "step_id", "enabled", "model_label", "job_title", "job_key",
  "run_mode", "input_par", "frq", "output_par", "fevals"
)
model_rows <- stepwise_models[, intersect(model_columns, names(stepwise_models)), drop = FALSE]

source_folder <- function(step_id, source_dir = "") {
  if (nzchar(source_dir) && !is.na(source_dir)) {
    if (identical(source_dir, ".")) {
      return(file.path("steps", step_id))
    }
    if (grepl("^(/|[A-Za-z]:[\\\\/])", source_dir)) {
      return(source_dir)
    }
    return(file.path("steps", step_id, source_dir))
  }
  file.path("steps", step_id, "model")
}

source_dirs <- if ("source_dir" %in% names(stepwise_models)) stepwise_models$source_dir else rep("", nrow(stepwise_models))
folder_paths <- mapply(source_folder, stepwise_models$step_id, source_dirs, USE.NAMES = FALSE)
folder_checks <- data.frame(
  step_id = stepwise_models$step_id,
  expected_source_folder = folder_paths,
  status = ifelse(dir.exists(folder_paths), "exists", "missing"),
  stringsAsFactors = FALSE
)

lines <- readLines(readme_path, warn = FALSE)
lines <- readme_section(lines, "## Current Defaults", markdown_table(defaults))
lines <- readme_section(lines, "## Model Rows", markdown_table(model_rows))
lines <- readme_section(lines, "## Folder Checks", markdown_table(folder_checks))
writeLines(lines, readme_path, useBytes = TRUE)
