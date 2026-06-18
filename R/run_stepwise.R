`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || !nzchar(as.character(x[[1]]))) y else x

env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) default else value
}

read_config <- function(path) {
  out <- list()
  if (!file.exists(path)) return(out)
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !grepl("^#", lines)]
  for (line in lines) {
    key <- sub("=.*$", "", line)
    value <- sub("^[^=]*=", "", line)
    value <- gsub("^[\"']|[\"']$", "", trimws(value))
    out[[key]] <- value
  }
  out
}

copy_dir <- function(from, to) {
  if (!dir.exists(from)) stop("Input directory not found: ", from, call. = FALSE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(files)) {
    ok <- file.copy(files, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
    if (!all(ok)) stop("Could not copy all files from ", from, call. = FALSE)
  }
  invisible(to)
}

same_path <- function(a, b) {
  normalizePath(a, winslash = "/", mustWork = FALSE) == normalizePath(b, winslash = "/", mustWork = FALSE)
}

is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:[\\\\/])", path)
}

copy_model_source <- function(from, to, step_dir = "") {
  if (!dir.exists(from)) stop("Input directory not found: ", from, call. = FALSE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (nzchar(step_dir) && same_path(from, step_dir)) {
    control <- c("README.md", "patch.R", "config.env", "model")
    files <- files[
      !basename(files) %in% control &
        !grepl("(^[.]git$|^[.]Rproj[.]user$|[.]Rproj$|^[.]DS_Store$)", basename(files))
    ]
  }
  if (!length(files)) stop("No model input files found in ", from, call. = FALSE)
  ok <- file.copy(files, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
  if (!all(ok)) stop("Could not copy all files from ", from, call. = FALSE)
  invisible(to)
}

has_model_files <- function(path, input_par = "") {
  if (!dir.exists(path)) return(FALSE)
  files <- list.files(path, all.files = FALSE, recursive = FALSE, full.names = FALSE)
  any(grepl("[.]frq$", files)) || (nzchar(input_par) && input_par %in% files)
}

latest_par <- function(model_dir) {
  pars <- list.files(model_dir, pattern = "[.]par[0-9]*$", full.names = FALSE)
  if (!length(pars)) return("")
  info <- file.info(file.path(model_dir, pars))
  pars[order(info$mtime, pars)][[length(pars)]]
}

par_number <- function(path) {
  stem <- tools::file_path_sans_ext(basename(path))
  value <- suppressWarnings(as.integer(stem))
  if (is.na(value)) NA_integer_ else value
}

next_par_name <- function(input_par) {
  stem <- tools::file_path_sans_ext(basename(input_par))
  ext <- tools::file_ext(basename(input_par))
  number <- suppressWarnings(as.integer(stem))
  if (is.na(number)) {
    return(paste0(stem, "-next.", if (nzchar(ext)) ext else "par"))
  }
  width <- max(nchar(stem), nchar(as.character(number + 1L)))
  sprintf(paste0("%0", width, "d.par"), number + 1L)
}

best_par <- function(model_dir) {
  pars <- list.files(model_dir, pattern = "[.]par[0-9]*$", full.names = FALSE)
  if (!length(pars)) return("")
  numbers <- vapply(pars, par_number, integer(1))
  if (any(!is.na(numbers))) {
    return(pars[order(ifelse(is.na(numbers), -Inf, numbers), pars)][[length(pars)]])
  }
  latest_par(model_dir)
}

truthy <- function(x, default = TRUE) {
  if (is.null(x) || !length(x) || !nzchar(as.character(x[[1]]))) return(default)
  tolower(trimws(as.character(x[[1]]))) %in% c("1", "true", "yes", "y", "on")
}

run_mfcl <- function(program, args, log_file, live_log = TRUE) {
  if (!isTRUE(live_log)) {
    return(system2(program, args, stdout = log_file, stderr = log_file, wait = TRUE))
  }
  quoted <- paste(c(shQuote(program), shQuote(args)), collapse = " ")
  command <- sprintf("set -o pipefail; %s 2>&1 | tee %s >&2", quoted, shQuote(log_file))
  system2("bash", c("-c", command), wait = TRUE)
}

run_script <- function(script, program, log_file, live_log = TRUE, fevals = "") {
  if (!file.exists(script)) stop("Run script not found: ", basename(script), call. = FALSE)
  script_env <- c(sprintf("PROGRAM_PATH=%s", shQuote(program)))
  if (nzchar(as.character(fevals))) {
    script_env <- c(
      script_env,
      sprintf("MFCL_FEVALS=%s", shQuote(as.character(fevals))),
      sprintf("SMOKE_FEVALS=%s", shQuote(as.character(fevals)))
    )
  }
  command <- sprintf("set -o pipefail; %s bash %s", paste(script_env, collapse = " "), shQuote(script))
  if (isTRUE(live_log)) {
    command <- sprintf("%s 2>&1 | tee %s >&2", command, shQuote(log_file))
    return(system2("bash", c("-c", command), wait = TRUE))
  }
  system2("bash", c("-c", command), stdout = log_file, stderr = log_file, wait = TRUE)
}

bind_rows_fill <- function(rows) {
  rows <- rows[vapply(rows, function(x) is.data.frame(x) && nrow(x), logical(1))]
  if (!length(rows)) return(data.frame(stringsAsFactors = FALSE))
  cols <- unique(unlist(lapply(rows, names), use.names = FALSE))
  rows <- lapply(rows, function(x) {
    missing <- setdiff(cols, names(x))
    for (name in missing) x[[name]] <- NA
    x[, cols, drop = FALSE]
  })
  do.call(rbind, rows)
}

smoke_switch_args <- function(fevals = 1L) {
  switches <- c(
    1, 1, as.integer(fevals),
    1, 189, 1,
    1, 190, 1,
    1, 188, 1,
    1, 187, 0,
    1, 186, 0
  )
  c("-switch", as.character(length(switches) / 3L), as.character(switches))
}

par_footer <- function(path) {
  out <- c(objective = NA_real_, max_gradient = NA_real_)
  if (!file.exists(path)) return(out)
  lines <- readLines(path, warn = FALSE)
  objective_i <- grep("# Objective function value", lines, fixed = TRUE)
  gradient_i <- grep("# Maximum magnitude gradient", lines, fixed = TRUE)
  if (length(objective_i) && objective_i[[1]] < length(lines)) {
    out[["objective"]] <- suppressWarnings(as.numeric(lines[[objective_i[[1]] + 1L]]))
  }
  if (length(gradient_i) && gradient_i[[1]] < length(lines)) {
    out[["max_gradient"]] <- suppressWarnings(as.numeric(lines[[gradient_i[[1]] + 1L]]))
  }
  out
}

read_step_table <- function(path, steps_root) {
  if (file.exists(path)) {
    cfg_env <- new.env(parent = globalenv())
    source(path, local = cfg_env)
    if (!exists("stepwise_models", envir = cfg_env, inherits = FALSE)) {
      stop("stepwise-config.R must define stepwise_models.", call. = FALSE)
    }
    table <- get("stepwise_models", envir = cfg_env, inherits = FALSE)
    if (!is.data.frame(table)) stop("stepwise_models must be a data frame.", call. = FALSE)
  } else {
    dirs <- sort(list.dirs(steps_root, recursive = FALSE, full.names = FALSE))
    dirs <- dirs[grepl("^[0-9][0-9]-", dirs)]
    table <- data.frame(step_id = dirs, stringsAsFactors = FALSE)
  }
  if (!"step_id" %in% names(table)) stop("stepwise-config.R must include a step_id column.", call. = FALSE)
  table$step_id <- trimws(as.character(table$step_id))
  table <- table[nzchar(table$step_id), , drop = FALSE]
  if (!nrow(table)) stop("No step rows found in stepwise-config.R.", call. = FALSE)
  table
}

row_to_config <- function(table, i) {
  row <- table[i, , drop = FALSE]
  values <- as.list(row)
  names(values) <- toupper(gsub("[^A-Za-z0-9]+", "_", names(values)))
  values <- lapply(values, function(x) {
    x <- as.character(x[[1]])
    if (is.na(x)) "" else trimws(x)
  })
  values[vapply(values, nzchar, logical(1))]
}

resolve_source_dir <- function(source_dir, input_subdir, step_dir, root, input_root, input_par) {
  if (!nzchar(source_dir)) {
    model_subdir <- file.path(step_dir, "model")
    if (dir.exists(model_subdir)) return(model_subdir)
    if (has_model_files(step_dir, input_par)) return(step_dir)
    source_dir <- input_subdir
  }
  candidates <- if (is_absolute_path(source_dir)) {
    source_dir
  } else if (identical(source_dir, ".")) {
    step_dir
  } else {
    c(
      file.path(step_dir, source_dir),
      file.path(root, source_dir),
      file.path(input_root, source_dir)
    )
  }
  candidates <- candidates[dir.exists(candidates)]
  if (!length(candidates)) stop("Model source directory not found for ", basename(step_dir), ": ", source_dir, call. = FALSE)
  candidates[[1]]
}

relative_display_path <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- paste0(normalizePath(root, winslash = "/", mustWork = FALSE), "/")
  sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", root)), "", path)
}

build_payload <- function(model_dir, step_id) {
  attempts <- character()
  payload_file <- file.path(model_dir, "model_payload.rds")

  try_builder <- function(label, expr) {
    attempts <<- c(attempts, label)
    tryCatch({
      force(expr)
      if (file.exists(payload_file)) return(TRUE)
      FALSE
    }, error = function(e) {
      attempts <<- c(attempts, paste0(label, " error: ", conditionMessage(e)))
      FALSE
    })
  }

  validate_payload_file <- function(method) {
    payload <- tryCatch(readRDS(payload_file), error = function(e) NULL)
    if (is.null(tryCatch(payload$data$RepOut, error = function(e) NULL))) {
      stop("model_payload.rds for ", step_id, " does not contain data$RepOut.", call. = FALSE)
    }
    method
  }

  if (requireNamespace("mfclshiny", quietly = TRUE)) {
    if ("build_model_payload" %in% getNamespaceExports("mfclshiny")) {
      if (try_builder("mfclshiny::build_model_payload", {
        mfclshiny::build_model_payload(
          model_dir,
          output_file = payload_file,
          overwrite = TRUE,
          recursive = FALSE
        )
      })) {
        return(validate_payload_file("mfclshiny::build_model_payload"))
      }
    }
    if ("build_model_payloads" %in% getNamespaceExports("mfclshiny")) {
      if (try_builder("mfclshiny::build_model_payloads", {
        mfclshiny::build_model_payloads(model_dir, recursive = FALSE, overwrite = TRUE)
      })) {
        return(validate_payload_file("mfclshiny::build_model_payloads"))
      }
    }
  }

  if (requireNamespace("mfclrtmb", quietly = TRUE) &&
      "write_mfcl_shiny_payload" %in% getNamespaceExports("mfclrtmb")) {
    if (try_builder("mfclrtmb::write_mfcl_shiny_payload", {
      mfclrtmb::write_mfcl_shiny_payload(output_dir = model_dir, input_dir = model_dir, payload_file = payload_file)
    })) {
      return(validate_payload_file("mfclrtmb::write_mfcl_shiny_payload"))
    }
  }

  if (!file.exists(payload_file)) {
    stop(
      "model_payload.rds was not created for ", step_id,
      ". Tried: ", paste(attempts, collapse = " | "),
      call. = FALSE
    )
  }
  validate_payload_file(paste(attempts, collapse = " | "))
}

root <- getwd()
out_dir <- env("OUTPUT_DIR", "outputs")
work_dir <- file.path(root, "work")
input_root <- file.path(work_dir, "inputs")
program <- env("PROGRAM_PATH", "/home/mfcl/mfclo64")
mfcl_live_log <- truthy(env("MFCL_LIVE_LOG", "true"), default = TRUE)
step_select <- strsplit(env("STEP_SELECT", ""), ",", fixed = TRUE)[[1]]
step_select <- trimws(step_select[nzchar(trimws(step_select))])
default_input_dir <- env("DEFAULT_INPUT_DIR", "")

step_table <- read_step_table(file.path(root, "stepwise-config.R"), file.path(root, "steps"))
if (length(step_select) && !any(tolower(step_select) %in% c("all", "*"))) {
  unknown <- setdiff(step_select, step_table$step_id)
  if (length(unknown)) stop("Unknown STEP_SELECT value(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  step_table <- step_table[step_table$step_id %in% step_select, , drop = FALSE]
}
if (!nrow(step_table)) stop("No step folders selected.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  step_table,
  file.path(out_dir, "selected-steps.csv"),
  row.names = FALSE
)

model_rows <- list()
for (i in seq_len(nrow(step_table))) {
  step_id <- step_table$step_id[[i]]
  step_dir <- file.path(root, "steps", step_id)
  if (!dir.exists(step_dir)) stop("Step folder not found: steps/", step_id, call. = FALSE)
  cfg <- read_config(file.path(step_dir, "config.env"))
  cfg <- modifyList(cfg, row_to_config(step_table, i))
  step_id <- basename(step_dir)
  if (!truthy(cfg$ENABLED %||% "true", default = TRUE)) {
    message("Skipping disabled step ", step_id)
    next
  }
  label <- cfg$MODEL_LABEL %||% step_id
  source_dir <- cfg$SOURCE_DIR %||% ""
  input_subdir <- cfg$INPUT_SUBDIR %||% default_input_dir
  run_mode <- tolower(cfg$RUN_MODE %||% "last_par")
  input_par <- cfg$INPUT_PAR %||% "latest"
  output_par <- cfg$OUTPUT_PAR %||% ""
  run_script_name <- cfg$RUN_SCRIPT %||% "doitall.sh"
  fevals <- suppressWarnings(as.integer(env("MFCL_FEVALS", env("SMOKE_FEVALS", cfg$FEVALS %||% cfg$SMOKE_FEVALS %||% "1"))))
  if (!is.finite(fevals) || fevals < 1L) fevals <- 1L

  model_dir <- file.path(work_dir, "models", step_id)
  model_source <- resolve_source_dir(source_dir, input_subdir, step_dir, root, input_root, input_par)
  copy_model_source(model_source, model_dir, step_dir = step_dir)
  patch_file <- file.path(step_dir, "patch.R")
  if (file.exists(patch_file)) {
    patch_env <- new.env(parent = globalenv())
    patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
    patch_env$step_id <- step_id
    patch_env$config <- cfg
    source(normalizePath(patch_file, mustWork = TRUE), local = patch_env)
  }

  frqs <- list.files(model_dir, pattern = "[.]frq$", full.names = FALSE)
  frq <- cfg$FRQ %||% if (length(frqs)) frqs[[1]] else ""
  if (!nzchar(frq) || is.na(frq)) stop("No .frq file found for ", step_id, call. = FALSE)
  log_file <- file.path(model_dir, "mfcl.log")
  message("Running ", step_id, " (", label, ")")
  message("  source: ", relative_display_path(model_source, root))
  message("  mode:   ", run_mode)
  old <- setwd(model_dir)
  status <- tryCatch({
    if (run_mode %in% c("doitall", "script")) {
      message("  script: ", run_script_name)
      message("  fevals: ", fevals, " (available to script as MFCL_FEVALS; not applied by the runner)")
      run_script(file.path(model_dir, run_script_name), program = program, log_file = log_file, live_log = mfcl_live_log, fevals = fevals)
    } else {
      if (run_mode %in% c("last", "latest", "last_par", "latest_par")) {
        input_par <- best_par(model_dir)
      } else if (!nzchar(input_par) || identical(tolower(input_par), "latest")) {
        input_par <- best_par(model_dir)
      }
      if (!nzchar(input_par) || !file.exists(file.path(model_dir, input_par))) {
        stop("Input par not found for ", step_id, ": ", input_par, call. = FALSE)
      }
      if (!nzchar(output_par)) output_par <- next_par_name(input_par)
      message("  input:  ", frq, " + ", input_par)
      message("  output: ", output_par)
      message("  fevals: ", fevals, " (applied through runner -switch arguments)")
      args <- c(frq, input_par, output_par, smoke_switch_args(fevals))
      run_mfcl(program, args, log_file = log_file, live_log = mfcl_live_log)
    }
  }, finally = setwd(old))
  if (!identical(status, 0L)) stop("MFCL failed for ", step_id, " with status ", status, call. = FALSE)

  final_output_par <- if (run_mode %in% c("doitall", "script")) best_par(model_dir) else output_par
  final_par <- file.path(model_dir, final_output_par)
  if (!nzchar(final_output_par) || !file.exists(final_par)) {
    stop("MFCL did not create a final par file for ", step_id, call. = FALSE)
  }
  message("  final par: ", final_output_par)

  message("  building model_payload.rds")
  payload_status <- build_payload(model_dir, step_id)
  message("  payload: ", payload_status)
  payload_file <- file.path(model_dir, "model_payload.rds")
  footer <- par_footer(final_par)

  step_out <- file.path(out_dir, "models", step_id)
  dir.create(step_out, recursive = TRUE, showWarnings = FALSE)
  keep <- unique(c(final_output_par, "model_payload.rds"))
  for (file in keep) {
    src <- file.path(model_dir, file)
    if (file.exists(src)) file.copy(src, file.path(step_out, basename(file)), overwrite = TRUE)
  }
  summary <- data.frame(
    step_id = step_id,
    model_label = label,
    model_source = relative_display_path(model_source, root),
    run_mode = run_mode,
    input_par = input_par,
    frq = frq,
    output_par = final_output_par,
    fevals = fevals,
    objective = footer[["objective"]],
    max_gradient = footer[["max_gradient"]],
    payload = file.exists(file.path(step_out, "model_payload.rds")),
    payload_status = payload_status,
    stringsAsFactors = FALSE
  )
  model_rows[[length(model_rows) + 1L]] <- summary
}

model_index <- bind_rows_fill(model_rows)
write.csv(model_index, file.path(out_dir, "model-index.csv"), row.names = FALSE)
