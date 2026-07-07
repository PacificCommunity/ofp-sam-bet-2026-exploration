## Small dependency-free helpers for Makefile/Kflow labels.
## They read `job-config.R` and turn STEP_SELECT values into display labels,
## stable job keys, and per-step config values.

source_stepwise_config <- function(path = "job-config.R") {
  source(path, local = .GlobalEnv)
  invisible(TRUE)
}

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
  # Accept "all", "*" or comma-separated step IDs.
  selected <- trimws(strsplit(as.character(step_select), ",", fixed = TRUE)[[1]])
  selected <- selected[nzchar(selected)]
  if (!length(selected)) {
    selected <- stepwise_value("default_step_select")
  }
  if (any(tolower(selected) %in% c("all", "*"))) {
    enabled <- if ("enabled" %in% names(stepwise_models)) {
      tolower(as.character(stepwise_models$enabled)) %in% c("true", "t", "1", "yes", "y")
    } else {
      rep(TRUE, nrow(stepwise_models))
    }
    return(stepwise_models[enabled, , drop = FALSE])
  }
  out <- stepwise_models[stepwise_models$step_id %in% selected, , drop = FALSE]
  if (!nrow(out)) {
    return(data.frame(step_id = selected, model_label = selected, stringsAsFactors = FALSE))
  }
  out
}

stepwise_first_value <- function(rows, column, fallback) {
  if (column %in% names(rows)) {
    value <- trimws(as.character(rows[[column]][[1]]))
    if (length(value) && nzchar(value) && !is.na(value)) {
      return(value)
    }
  }
  fallback
}

stepwise_engine_label <- function(run_mode) {
  run_mode <- tolower(gsub("-", "_", trimws(as.character(run_mode))))
  if (run_mode %in% c("doitall", "script")) {
    return("native MFCL")
  }
  "MFCL"
}

stepwise_kflow_memory <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  if (!nrow(rows)) return("")
  if ("kflow_memory" %in% names(rows)) {
    memory <- trimws(as.character(rows$kflow_memory))
    memory <- memory[nzchar(memory) & !is.na(memory)]
    if (length(memory)) {
      return(memory[[which.max(grepl("^12", memory))]])
    }
  }
  if ("region_count" %in% names(rows)) {
    regions <- suppressWarnings(as.integer(rows$region_count))
    if (any(regions == 9L, na.rm = TRUE)) return("12GB")
    if (any(regions == 5L, na.rm = TRUE)) return("8GB")
  }
  ""
}

stepwise_run_mode <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  if (!nrow(rows) || !"run_mode" %in% names(rows)) return("")
  values <- trimws(as.character(rows$run_mode))
  values <- unique(values[nzchar(values) & !is.na(values)])
  if (length(values) == 1L) values[[1L]] else ""
}

stepwise_row_value <- function(step_select, column, default = "") {
  rows <- stepwise_selected_models(step_select)
  if (!nrow(rows) || !column %in% names(rows)) {
    return(default)
  }
  values <- trimws(as.character(rows[[column]]))
  values <- unique(values[nzchar(values) & !is.na(values)])
  if (!length(values)) {
    return(default)
  }
  if (length(values) == 1L) {
    return(values[[1]])
  }
  paste0(values[[1]], " +", length(values) - 1L, " values")
}

stepwise_model_labels <- function(rows) {
  labels <- if ("model_label" %in% names(rows)) {
    trimws(as.character(rows$model_label))
  } else {
    rep("", nrow(rows))
  }
  labels[!nzchar(labels) | is.na(labels)] <- rows$step_id[!nzchar(labels) | is.na(labels)]
  labels
}

stepwise_model_label <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  if (!nrow(rows)) {
    return(as.character(step_select))
  }
  selected <- trimws(strsplit(as.character(step_select), ",", fixed = TRUE)[[1]])
  if (any(tolower(selected) %in% c("all", "*")) && nrow(rows) > 1L) {
    return(paste0("All ", nrow(rows), " stepwise models"))
  }
  labels <- stepwise_model_labels(rows)
  if (length(labels) == 1L) {
    suffix <- if ("run_mode" %in% names(rows)) stepwise_engine_label(rows$run_mode[[1]]) else ""
    program <- if ("mfcl_program_path" %in% names(rows)) as.character(rows$mfcl_program_path[[1]]) else ""
    if (nzchar(program) && grepl("2023_diagnostic|diagnostic", basename(program), ignore.case = TRUE)) {
      suffix <- "native MFCL old"
    }
    return(if (nzchar(suffix)) paste0(labels[[1]], " (", suffix, ")") else labels[[1]])
  }
  paste0(labels[[1]], " +", length(labels) - 1L, " models")
}

stepwise_job_key <- function(step_select = stepwise_value("default_step_select")) {
  # Keep job keys URL/log friendly; use titles only for display text.
  rows <- stepwise_selected_models(step_select)
  selected <- trimws(strsplit(as.character(step_select), ",", fixed = TRUE)[[1]])
  if (!nrow(rows)) {
    key <- as.character(step_select)
  } else if (any(tolower(selected) %in% c("all", "*")) && nrow(rows) > 1L) {
    key <- paste0("all-", nrow(rows))
  } else if (nrow(rows) == 1L) {
    key <- stepwise_first_value(rows, "job_key", rows$step_id[[1]])
  } else {
    key <- paste0(rows$step_id[[1]], "-plus-", nrow(rows) - 1L)
  }
  key <- tolower(gsub("[^A-Za-z0-9_.-]+", "-", key))
  gsub("^-+|-+$", "", key)
}

stepwise_job_title <- function(step_select = stepwise_value("default_step_select")) {
  rows <- stepwise_selected_models(step_select)
  selected <- trimws(strsplit(as.character(step_select), ",", fixed = TRUE)[[1]])
  if (any(tolower(selected) %in% c("all", "*")) && nrow(rows) > 1L) {
    return(paste0("All ", nrow(rows), " models"))
  }
  if (nrow(rows) == 1L) {
    title <- stepwise_first_value(rows, "job_title", "")
    if (nzchar(title)) {
      return(title)
    }
  }
  stepwise_model_label(step_select)
}
