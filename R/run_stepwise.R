## Run selected BET stepwise model folders locally or under Kflow.
##
## The runner stages one model folder at a time, runs either `doitall.sh` or a
## single par advance, then writes compact artifacts under `outputs/`.

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || !nzchar(as.character(x[[1]]))) y else x

env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) default else value
}

env_or_null <- function(name) {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) NULL else value
}

apply_env_overrides <- function(cfg, keys) {
  for (key in keys) {
    value <- env_or_null(key)
    if (!is.null(value)) cfg[[key]] <- value
  }
  cfg
}

read_config <- function(path) {
  # Minimal KEY=value reader for optional per-step config.env overrides.
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
  # Copy model files without carrying step-level docs/control files.
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

copy_raw_mfcl_inputs <- function(from, to) {
  if (!dir.exists(from)) {
    return(FALSE)
  }
  if (dir.exists(to)) {
    unlink(to, recursive = TRUE, force = TRUE)
  }
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (!length(files)) {
    return(TRUE)
  }
  ok <- file.copy(files, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
  all(ok)
}

has_model_files <- function(path, input_par = "") {
  if (!dir.exists(path)) return(FALSE)
  files <- list.files(path, all.files = FALSE, recursive = FALSE, full.names = FALSE)
  any(grepl("[.]frq$", files)) || (nzchar(input_par) && input_par %in% files)
}

canonical_par_files <- function(model_dir) {
  list.files(model_dir, pattern = "^[0-9]+[.]par$", full.names = FALSE)
}

noncanonical_par_like_files <- function(model_dir) {
  files <- list.files(model_dir, pattern = "[.]par[0-9]*$", full.names = FALSE)
  setdiff(files, canonical_par_files(model_dir))
}

latest_par <- function(model_dir) {
  pars <- canonical_par_files(model_dir)
  if (!length(pars)) return("")
  info <- file.info(file.path(model_dir, pars))
  pars[order(info$mtime, pars)][[length(pars)]]
}

par_number <- function(path) {
  stem <- sub("[.]par$", "", basename(path))
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
  pars <- canonical_par_files(model_dir)
  if (!length(pars)) return("")
  numbers <- vapply(pars, par_number, integer(1))
  if (any(!is.na(numbers))) {
    return(pars[order(ifelse(is.na(numbers), -Inf, numbers), pars)][[length(pars)]])
  }
  latest_par(model_dir)
}

mode_key <- function(run_mode) {
  gsub("-", "_", tolower(trimws(as.character(run_mode %||% ""))), fixed = TRUE)
}

engine_label <- function(run_engine, program = "") {
  if (identical(run_engine, "mfclrtmb")) return("mfclrtmb")
  if (grepl("2023_diagnostic|diagnostic", basename(program), ignore.case = TRUE)) {
    return("native MFCL old")
  }
  "native MFCL"
}

engine_token <- function(run_engine) {
  if (identical(run_engine, "mfclrtmb")) "rtmb" else "native"
}

step_display_token <- function(step_id) {
  token <- sub("-.*$", "", trimws(as.character(step_id %||% "")))
  if (nzchar(token)) token else "model"
}

strip_engine_suffix <- function(label) {
  sub(
    "\\s*\\((native MFCL old|native MFCL|mfclrtmb|rtmb|MFCL)\\)\\s*$",
    "",
    trimws(as.character(label %||% "")),
    ignore.case = TRUE
  )
}

model_display_label <- function(label, run_engine, program = "", step_id = "") {
  base <- strip_engine_suffix(label)
  if (!nzchar(base)) base <- trimws(as.character(step_id %||% "model"))
  paste0(step_display_token(step_id), "[", engine_token(run_engine), "]-", base)
}

format_elapsed_time <- function(seconds) {
  seconds <- suppressWarnings(as.numeric(seconds))
  if (!length(seconds) || !is.finite(seconds)) return("")
  seconds <- max(0, round(seconds))
  if (seconds < 90) return(sprintf("%ds", seconds))
  minutes <- round(seconds / 60)
  if (minutes < 90) return(sprintf("%dm", minutes))
  hours <- minutes %/% 60
  minutes <- minutes %% 60
  if (minutes > 0) sprintf("%dh %02dm", hours, minutes) else sprintf("%dh", hours)
}

parse_mfclrtmb_fit_elapsed_seconds <- function(log_file) {
  if (!file.exists(log_file)) return(NA_real_)
  lines <- readLines(log_file, warn = FALSE)
  phase_lines <- grep("\\[mfclrtmb\\] phase-[^ ]+ .*total [0-9.]+s", lines, value = TRUE)
  if (!length(phase_lines)) return(NA_real_)
  totals <- suppressWarnings(as.numeric(sub(".*total ([0-9.]+)s\\).*", "\\1", phase_lines)))
  totals <- totals[is.finite(totals)]
  if (!length(totals)) NA_real_ else max(totals)
}

manifest_value <- function(x) {
  if (inherits(x, "POSIXt")) return(format(x, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  if (is.logical(x)) return(tolower(as.character(x[[1L]])))
  if (is.numeric(x)) return(x[[1L]])
  as.character(x[[1L]])
}

write_payload_metadata <- function(payload_file, model_dir, metadata) {
  metadata <- metadata[!vapply(metadata, is.null, logical(1))]
  metadata <- lapply(metadata, manifest_value)
  registry_fields <- c(
    "model_label", "base_model_label", "plot_label", "model_token",
    "job_key", "run_engine", "engine_label", "run_mode", "requested_run_mode",
    "region_count", "kflow_memory", "model_run_elapsed_seconds",
    "model_fit_elapsed_seconds", "model_run_time"
  )

  model_info <- if (file.exists(file.path(model_dir, "model_info.rds"))) {
    tryCatch(readRDS(file.path(model_dir, "model_info.rds")), error = function(e) list())
  } else {
    list()
  }
  if (!is.list(model_info)) model_info <- list()
  if (is.null(model_info$registry) || !is.list(model_info$registry)) {
    model_info$registry <- list()
  }
  for (name in names(metadata)) {
    model_info[[name]] <- metadata[[name]]
  }
  for (name in intersect(registry_fields, names(metadata))) {
    model_info$registry[[name]] <- metadata[[name]]
  }
  saveRDS(model_info, file.path(model_dir, "model_info.rds"), compress = "gzip")

  manifest_path <- file.path(model_dir, "model_payload_manifest.json")
  manifest_csv <- file.path(model_dir, "model_payload_manifest.csv")
  manifest <- if (file.exists(manifest_csv)) {
    tryCatch(read.csv(manifest_csv, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) data.frame())
  } else {
    data.frame()
  }
  if (!nrow(manifest)) {
    manifest <- data.frame(
      schema = "mfclshiny.model_payload_manifest.v1",
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
  for (name in names(metadata)) {
    manifest[[name]] <- metadata[[name]]
  }
  write.csv(manifest, manifest_csv, row.names = FALSE)
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(manifest, manifest_path, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE, null = "null")
  }
  registry <- as.data.frame(metadata[intersect(registry_fields, names(metadata))],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  write.csv(registry, file.path(model_dir, "model-registry.csv"), row.names = FALSE)
  invisible(TRUE)
}

is_doitall_mode <- function(run_mode) {
  mode_key(run_mode) %in% c("doitall", "script")
}

is_mfclrtmb_doitall_mode <- function(run_mode) {
  mode_key(run_mode) %in% c(
    "mfclrtmb",
    "rtmb",
    "mfclrtmb_doitall",
    "rtmb_doitall",
    "doitall_rtmb"
  )
}

is_mfclrtmb_par_mode <- function(run_mode) {
  mode_key(run_mode) %in% c(
    "mfclrtmb_par",
    "rtmb_par",
    "mfclrtmb_single_par",
    "rtmb_single_par",
    "mfclrtmb_noopt",
    "rtmb_noopt"
  )
}

is_mfclrtmb_mode <- function(run_mode) {
  is_mfclrtmb_doitall_mode(run_mode) || is_mfclrtmb_par_mode(run_mode)
}

is_doitall_like_mode <- function(run_mode) {
  is_doitall_mode(run_mode) || is_mfclrtmb_doitall_mode(run_mode)
}

is_latest_par_mode <- function(run_mode) {
  run_mode %in% c("last", "latest", "last_par", "latest_par", "par", "single", "single_par")
}

is_job_par_mode <- function(run_mode) {
  run_mode %in% c("job_par", "previous_job_par", "input_job_par", "kflow_job_par")
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

run_script <- function(script, program, log_file, live_log = TRUE) {
  if (!file.exists(script)) stop("Run script not found: ", basename(script), call. = FALSE)
  mfcl_shim_dir <- tempfile("mfcl-bin-")
  dir.create(mfcl_shim_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(mfcl_shim_dir, recursive = TRUE, force = TRUE), add = TRUE)
  mfcl_shim <- file.path(mfcl_shim_dir, "mfclo64")
  writeLines(c(
    "#!/bin/sh",
    sprintf("exec %s \"$@\"", shQuote(program))
  ), mfcl_shim, useBytes = TRUE)
  Sys.chmod(mfcl_shim, mode = "0755")
  script_env <- c(
    PROGRAM_PATH = program,
    PATH = paste(mfcl_shim_dir, Sys.getenv("PATH"), sep = .Platform$path.sep)
  )
  env_assign <- paste(
    sprintf("%s=%s", names(script_env), shQuote(unname(script_env))),
    collapse = " "
  )
  command <- sprintf("set -o pipefail; %s bash %s", env_assign, shQuote(script))
  if (isTRUE(live_log)) {
    command <- sprintf("%s 2>&1 | tee %s >&2", command, shQuote(log_file))
    return(system2("bash", c("-c", command), wait = TRUE))
  }
  system2("bash", c("-c", command), stdout = log_file, stderr = log_file, wait = TRUE)
}

run_mfclrtmb_doitall <- function(model_dir, frq, script, log_file, live_log = TRUE) {
  if (!file.exists(script)) stop("Run script not found: ", basename(script), call. = FALSE)
  if (!requireNamespace("mfclrtmb", quietly = TRUE)) {
    stop(
      "RUN_MODE=mfclrtmb_doitall needs the mfclrtmb R package. ",
      "Install it locally or include mfclrtmb in KFLOW_REPO_RUNTIME_PACKAGES.",
      call. = FALSE
    )
  }

  root_name <- sub("[.]frq$", "", basename(frq))
  runner <- tempfile("mfclrtmb-doitall-", fileext = ".R")
  on.exit(unlink(runner), add = TRUE)
  writeLines(c(
    "truthy <- function(x, default = FALSE) {",
    "  if (is.null(x) || !nzchar(x)) return(default)",
    "  tolower(trimws(x)) %in% c('1', 'true', 'yes', 'y', 'on')",
    "}",
    "env_chr <- function(name, default = NULL) {",
    "  x <- Sys.getenv(name, unset = '')",
    "  if (!nzchar(x)) default else x",
    "}",
    "env_int <- function(name, default = NULL) {",
    "  x <- env_chr(name)",
    "  if (is.null(x)) return(default)",
    "  y <- suppressWarnings(as.integer(x))",
    "  if (is.na(y)) stop(name, ' must be an integer', call. = FALSE)",
    "  y",
    "}",
    "env_phase <- function(name, default = Inf) {",
    "  x <- env_chr(name)",
    "  if (is.null(x)) return(default)",
    "  if (tolower(x) %in% c('inf', 'infinity')) return(Inf)",
    "  y <- suppressWarnings(as.integer(x))",
    "  if (is.na(y)) stop(name, ' must be an integer phase or Inf', call. = FALSE)",
    "  y",
    "}",
    "env_bool_null <- function(name) {",
    "  x <- env_chr(name)",
    "  if (is.null(x)) return(NULL)",
    "  truthy(x)",
    "}",
    "suppressPackageStartupMessages(library(mfclrtmb))",
    "cat('[stepwise-mfclrtmb] package: ', as.character(utils::packageVersion('mfclrtmb')), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] case_dir: ', Sys.getenv('MFCLRTMB_CASE_DIR'), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] root: ', Sys.getenv('MFCLRTMB_ROOT'), '\\n', sep = '')",
    "result <- mfclrtmb::run_mfcl_rtmb_doitall(",
    "  case_dir = Sys.getenv('MFCLRTMB_CASE_DIR'),",
    "  output_dir = Sys.getenv('MFCLRTMB_OUTPUT_DIR'),",
    "  root = Sys.getenv('MFCLRTMB_ROOT'),",
    "  doitall_file = Sys.getenv('MFCLRTMB_DOITALL_FILE'),",
    "  start_phase = env_int('MFCLRTMB_START_PHASE'),",
    "  resume = truthy(env_chr('MFCLRTMB_RESUME', 'false')),",
    "  max_phase = env_phase('MFCLRTMB_MAX_PHASE', Inf),",
    "  start_par = env_chr('MFCLRTMB_START_PAR'),",
    "  start_control_par = env_chr('MFCLRTMB_START_CONTROL_PAR'),",
    "  run_optimization = truthy(env_chr('MFCLRTMB_RUN_OPTIMIZATION', 'true'), TRUE),",
    "  optimizer = env_chr('MFCLRTMB_OPTIMIZER', 'fmm'),",
    "  maxfn = env_int('MFCLRTMB_MAXFN'),",
    "  strict_switches = truthy(env_chr('MFCLRTMB_STRICT_SWITCHES', 'true'), TRUE),",
    "  write_mfcl_files = truthy(env_chr('MFCLRTMB_WRITE_MFCL_FILES', 'true'), TRUE),",
    "  write_payload = FALSE,",
    "  run_post_switches = truthy(env_chr('MFCLRTMB_RUN_POST_SWITCHES', 'true'), TRUE),",
    "  exact_report = truthy(env_chr('MFCLRTMB_EXACT_REPORT', 'true'), TRUE),",
    "  write_objective_trace = truthy(env_chr('MFCLRTMB_WRITE_OBJECTIVE_TRACE', 'false')),",
    "  write_progress = truthy(env_chr('MFCLRTMB_WRITE_PROGRESS', 'true'), TRUE),",
    "  verbose = truthy(env_chr('MFCLRTMB_VERBOSE', 'true'), TRUE),",
    "  verbose_eval = env_bool_null('MFCLRTMB_VERBOSE_EVAL'),",
    "  openmp_threads = env_int('MFCLRTMB_OPENMP_THREADS', 1L),",
    "  openmp_autopar = truthy(env_chr('MFCLRTMB_OPENMP_AUTOPAR', 'false')),",
    "  process_per_control = env_bool_null('MFCLRTMB_PROCESS_PER_CONTROL'),",
    "  process_log = env_bool_null('MFCLRTMB_PROCESS_LOG'),",
    "  process_time = env_bool_null('MFCLRTMB_PROCESS_TIME'),",
    "  low_memory = env_bool_null('MFCLRTMB_LOW_MEMORY'),",
    "  verbose_memory = env_bool_null('MFCLRTMB_VERBOSE_MEMORY'),",
    "  native_parity_check = truthy(env_chr('MFCLRTMB_NATIVE_PARITY_CHECK', 'false')),",
    "  native_program_path = env_chr('MFCLRTMB_NATIVE_PROGRAM_PATH', Sys.getenv('PROGRAM_PATH', '/home/mfcl/mfclo64')),",
    "  native_parity_objective_tolerance = suppressWarnings(as.numeric(env_chr('MFCLRTMB_NATIVE_PARITY_OBJECTIVE_TOLERANCE', '1e-5'))),",
    "  native_parity_gradient = truthy(env_chr('MFCLRTMB_NATIVE_PARITY_GRADIENT', 'true'), TRUE),",
    "  native_parity_fail = truthy(env_chr('MFCLRTMB_NATIVE_PARITY_FAIL', 'false'))",
    ")",
    "if (!is.null(result$summary)) {",
    "  cat('\\n[stepwise-mfclrtmb] phase summary\\n')",
    "  print(result$summary)",
    "}",
    "cat('\\n[stepwise-mfclrtmb] done\\n')"
  ), runner, useBytes = TRUE)

  script_env <- c(
    MFCLRTMB_CASE_DIR = normalizePath(model_dir, mustWork = TRUE),
    MFCLRTMB_OUTPUT_DIR = normalizePath(model_dir, mustWork = TRUE),
    MFCLRTMB_ROOT = root_name,
    MFCLRTMB_DOITALL_FILE = normalizePath(script, mustWork = TRUE)
  )
  env_names <- c(
    "MFCLRTMB_START_PHASE",
    "MFCLRTMB_RESUME",
    "MFCLRTMB_MAX_PHASE",
    "MFCLRTMB_START_PAR",
    "MFCLRTMB_START_CONTROL_PAR",
    "MFCLRTMB_RUN_OPTIMIZATION",
    "MFCLRTMB_OPTIMIZER",
    "MFCLRTMB_MAXFN",
    "MFCLRTMB_STRICT_SWITCHES",
    "MFCLRTMB_WRITE_MFCL_FILES",
    "MFCLRTMB_RUN_POST_SWITCHES",
    "MFCLRTMB_EXACT_REPORT",
    "MFCLRTMB_WRITE_OBJECTIVE_TRACE",
    "MFCLRTMB_WRITE_PROGRESS",
    "MFCLRTMB_VERBOSE",
    "MFCLRTMB_VERBOSE_EVAL",
    "MFCLRTMB_OPENMP_THREADS",
    "MFCLRTMB_OPENMP_AUTOPAR",
    "MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS",
    "MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD",
    "MFCLRTMB_PROCESS_PER_CONTROL",
    "MFCLRTMB_PROCESS_LOG",
    "MFCLRTMB_PROCESS_TIME",
    "MFCLRTMB_LOW_MEMORY",
    "MFCLRTMB_VERBOSE_MEMORY",
    "MFCLRTMB_NATIVE_PARITY_CHECK",
    "MFCLRTMB_NATIVE_PARITY_OBJECTIVE_TOLERANCE",
    "MFCLRTMB_NATIVE_PARITY_GRADIENT",
    "MFCLRTMB_NATIVE_PARITY_FAIL",
    "MFCLRTMB_NATIVE_PROGRAM_PATH"
  )
  extra <- Sys.getenv(env_names, unset = NA_character_)
  extra <- extra[!is.na(extra) & nzchar(extra)]
  script_env <- c(script_env, extra)
  env_assign <- paste(
    sprintf("%s=%s", names(script_env), shQuote(unname(script_env))),
    collapse = " "
  )
  command <- sprintf("set -o pipefail; %s Rscript %s", env_assign, shQuote(runner))
  if (isTRUE(live_log)) {
    command <- sprintf("%s 2>&1 | tee %s >&2", command, shQuote(log_file))
    return(system2("bash", c("-c", command), wait = TRUE))
  }
  system2("bash", c("-c", command), stdout = log_file, stderr = log_file, wait = TRUE)
}

run_mfclrtmb_single_par <- function(model_dir,
                                    frq,
                                    input_par,
                                    output_par,
                                    log_file,
                                    live_log = TRUE) {
  if (!requireNamespace("mfclrtmb", quietly = TRUE)) {
    stop(
      "RUN_MODE=mfclrtmb_par needs the mfclrtmb R package. ",
      "Install it locally or include mfclrtmb in KFLOW_REPO_RUNTIME_PACKAGES.",
      call. = FALSE
    )
  }
  root_name <- sub("[.]frq$", "", basename(frq))
  input_path <- file.path(model_dir, input_par)
  output_path <- file.path(model_dir, output_par)
  if (!file.exists(input_path)) {
    stop("RTMB single-par input not found: ", input_par, call. = FALSE)
  }
  if (!same_path(input_path, output_path)) {
    ok <- file.copy(input_path, output_path, overwrite = TRUE, copy.date = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not stage RTMB single-par output file: ", output_par, call. = FALSE)
    }
  }

  runner <- tempfile("mfclrtmb-single-par-", fileext = ".R")
  success_marker <- tempfile("mfclrtmb-single-par-ok-")
  on.exit(unlink(c(runner, success_marker)), add = TRUE)
  writeLines(c(
    "truthy <- function(x, default = FALSE) {",
    "  if (is.null(x) || !nzchar(x)) return(default)",
    "  tolower(trimws(x)) %in% c('1', 'true', 'yes', 'y', 'on')",
    "}",
    "env_chr <- function(name, default = NULL) {",
    "  x <- Sys.getenv(name, unset = '')",
    "  if (!nzchar(x)) default else x",
    "}",
    "env_int <- function(name, default = NULL) {",
    "  x <- env_chr(name)",
    "  if (is.null(x)) return(default)",
    "  y <- suppressWarnings(as.integer(x))",
    "  if (is.na(y)) stop(name, ' must be an integer', call. = FALSE)",
    "  y",
    "}",
    "env_bool_null <- function(name) {",
    "  x <- env_chr(name)",
    "  if (is.null(x)) return(NULL)",
    "  truthy(x)",
    "}",
    "suppressPackageStartupMessages(library(mfclrtmb))",
    "cat('[stepwise-mfclrtmb] package: ', as.character(utils::packageVersion('mfclrtmb')), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] direct par eval\\n')",
    "cat('[stepwise-mfclrtmb] case_dir: ', Sys.getenv('MFCLRTMB_CASE_DIR'), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] par: ', Sys.getenv('MFCLRTMB_PAR'), '\\n', sep = '')",
    "fit <- mfclrtmb::mfclrtmb_run(",
    "  case_dir = Sys.getenv('MFCLRTMB_CASE_DIR'),",
    "  root = Sys.getenv('MFCLRTMB_ROOT'),",
    "  par = Sys.getenv('MFCLRTMB_PAR'),",
    "  output_dir = Sys.getenv('MFCLRTMB_OUTPUT_DIR'),",
    "  run_optimization = FALSE,",
    "  write_outputs = TRUE,",
    "  write_payload = FALSE,",
    "  write_mfcl_files = truthy(env_chr('MFCLRTMB_WRITE_MFCL_FILES', 'true'), TRUE),",
    "  copy_inputs = FALSE,",
    "  copy_support_files = FALSE,",
    "  build_report = TRUE,",
    "  exact_report = truthy(env_chr('MFCLRTMB_EXACT_REPORT', 'true'), TRUE),",
    "  run_sdreport = FALSE,",
    "  verbose = truthy(env_chr('MFCLRTMB_VERBOSE', 'true'), TRUE),",
    "  openmp_threads = env_int('MFCLRTMB_OPENMP_THREADS', 1L),",
    "  openmp_autopar = truthy(env_chr('MFCLRTMB_OPENMP_AUTOPAR', 'false'))",
    ")",
    "cat('[stepwise-mfclrtmb] objective: ', format(fit$fit$objective, digits = 16), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] max_gradient: ', format(fit$fit$max_gradient, digits = 16), '\\n', sep = '')",
    "cat('[stepwise-mfclrtmb] done\\n')",
    "writeLines('ok', Sys.getenv('MFCLRTMB_SUCCESS_MARKER'))"
  ), runner, useBytes = TRUE)

  script_env <- c(
    MFCLRTMB_CASE_DIR = normalizePath(model_dir, mustWork = TRUE),
    MFCLRTMB_OUTPUT_DIR = normalizePath(model_dir, mustWork = TRUE),
    MFCLRTMB_ROOT = root_name,
    MFCLRTMB_PAR = normalizePath(output_path, mustWork = TRUE),
    MFCLRTMB_SUCCESS_MARKER = success_marker
  )
  env_names <- c(
    "MFCLRTMB_WRITE_MFCL_FILES",
    "MFCLRTMB_EXACT_REPORT",
    "MFCLRTMB_VERBOSE",
    "MFCLRTMB_OPENMP_THREADS",
    "MFCLRTMB_OPENMP_AUTOPAR"
  )
  extra <- Sys.getenv(env_names, unset = NA_character_)
  extra <- extra[!is.na(extra) & nzchar(extra)]
  script_env <- c(script_env, extra)
  env_assign <- paste(
    sprintf("%s=%s", names(script_env), shQuote(unname(script_env))),
    collapse = " "
  )
  command <- sprintf("set -o pipefail; %s Rscript %s", env_assign, shQuote(runner))
  if (isTRUE(live_log)) {
    command <- sprintf("%s 2>&1 | tee %s >&2", command, shQuote(log_file))
    status <- system2("bash", c("-c", command), wait = TRUE)
  } else {
    status <- system2("bash", c("-c", command), stdout = log_file, stderr = log_file, wait = TRUE)
  }
  if (is.null(status)) status <- 0L
  status <- suppressWarnings(as.integer(status[[1L]]))
  if (!is.finite(status)) status <- 1L
  if (identical(status, 0L) && !file.exists(success_marker)) {
    message("  mfclrtmb direct par eval did not write success marker")
    status <- 1L
  }
  status
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

smoke_switch_args <- function(iterations = 1L) {
  report <- truthy(env("STEPWISE_SINGLE_PAR_REPORT", "true"), TRUE)
  report_flag <- as.integer(isTRUE(report))
  switches <- c(
    1, 1, as.integer(iterations),
    1, 189, report_flag,
    1, 190, report_flag,
    1, 188, report_flag,
    1, 187, report_flag,
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

run_rtmb_parity_check <- function(model_dir, frq, final_par, native_footer) {
  if (!truthy(env("STEPWISE_RTMB_PARITY_CHECK", env("STEPWISE_PARITY_CHECK", "false")), FALSE)) {
    return(NULL)
  }
  if (!requireNamespace("mfclrtmb", quietly = TRUE)) {
    stop(
      "STEPWISE_RTMB_PARITY_CHECK=true needs the mfclrtmb R package. ",
      "Include mfclrtmb in KFLOW_REPO_RUNTIME_PACKAGES.",
      call. = FALSE
    )
  }

  root_name <- sub("[.]frq$", "", basename(frq))
  check_dir <- tempfile("rtmb-parity-")
  dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)
  keep_work <- truthy(env("STEPWISE_PARITY_KEEP_WORK", "false"), FALSE)
  on.exit({
    if (!isTRUE(keep_work)) unlink(check_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)
  tolerance <- suppressWarnings(as.numeric(env("STEPWISE_RTMB_PARITY_OBJECTIVE_TOLERANCE", "1e-5")))
  if (!is.finite(tolerance)) tolerance <- 1e-5
  parity_openmp_threads <- suppressWarnings(as.integer(env("MFCLRTMB_OPENMP_THREADS", "1")))
  if (!is.finite(parity_openmp_threads) || parity_openmp_threads < 1L) parity_openmp_threads <- 1L
  mfclrtmb_fit_formals <- tryCatch(
    names(formals(get("mfclrtmb_fit", envir = asNamespace("mfclrtmb")))),
    error = function(e) character(0L)
  )
  rtmb_args <- list(
    case_dir = model_dir,
    root = root_name,
    par = normalizePath(final_par, winslash = "/", mustWork = TRUE),
    output_dir = check_dir,
    run_optimization = FALSE,
    write_outputs = FALSE,
    write_payload = FALSE,
    write_mfcl_files = FALSE,
    copy_inputs = FALSE,
    copy_support_files = FALSE,
    exact_report = FALSE,
    run_sdreport = FALSE,
    verbose = FALSE,
    openmp_threads = parity_openmp_threads,
    openmp_autopar = truthy(env("MFCLRTMB_OPENMP_AUTOPAR", "false"), FALSE)
  )
  if ("build_report" %in% mfclrtmb_fit_formals) {
    rtmb_args$build_report <- FALSE
  }

  message("  rtmb parity: evaluating native final par with mfclrtmb no-optim")
  started <- Sys.time()
  result <- tryCatch(
    do.call(mfclrtmb::mfclrtmb_run, rtmb_args),
    error = function(e) e
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  failed <- inherits(result, "error")

  rtmb_objective <- if (failed) {
    NA_real_
  } else {
    suppressWarnings(as.numeric(result$fit$objective[[1L]]))
  }
  rtmb_max_gradient <- if (failed) {
    NA_real_
  } else {
    suppressWarnings(as.numeric(result$fit$max_gradient[[1L]]))
  }
  native_objective <- suppressWarnings(as.numeric(native_footer[["objective"]]))
  native_max_gradient <- suppressWarnings(as.numeric(native_footer[["max_gradient"]]))
  objective_delta <- rtmb_objective - native_objective
  objective_abs_delta <- abs(objective_delta)
  objective_ok <- is.finite(objective_abs_delta) && objective_abs_delta <= tolerance
  status <- if (isTRUE(objective_ok)) "match" else "mismatch"
  if (failed || !is.finite(rtmb_objective)) status <- "rtmb_objective_unavailable"

  out <- data.frame(
    check_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    check_direction = "native_final_par_with_rtmb",
    program_path = "mfclrtmb::mfclrtmb_run",
    program_md5 = "",
    root = root_name,
    final_par = normalizePath(final_par, winslash = "/", mustWork = FALSE),
    rtmb_objective = rtmb_objective,
    rtmb_max_gradient = rtmb_max_gradient,
    native_objective = native_objective,
    native_gradient_objective = native_objective,
    native_max_gradient = native_max_gradient,
    native_gradient_mode = "final-par-footer",
    rtmb_gradient_mode = "mfclrtmb_run_no_optimization",
    objective_delta = objective_delta,
    objective_abs_delta = objective_abs_delta,
    objective_tolerance = tolerance,
    objective_ok = objective_ok,
    status = status,
    objective_status = if (failed) 1L else 0L,
    gradient_status = if (failed || !is.finite(rtmb_max_gradient)) 1L else 0L,
    elapsed_seconds = elapsed,
    error_message = if (failed) conditionMessage(result) else "",
    work_dir = if (isTRUE(keep_work)) normalizePath(check_dir, winslash = "/", mustWork = FALSE) else "",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  utils::write.csv(out, file.path(model_dir, "native-parity-check.csv"), row.names = FALSE)
  if (isTRUE(keep_work)) {
    utils::write.csv(out, file.path(check_dir, "summary.csv"), row.names = FALSE)
  }
  message(sprintf(
    "  rtmb parity %s: native=%.12g rtmb=%.12g delta=%.6g",
    status,
    native_objective,
    rtmb_objective,
    objective_delta
  ))

  if (truthy(env("STEPWISE_RTMB_PARITY_FAIL", "false"), FALSE) && !isTRUE(objective_ok)) {
    stop(
      "RTMB parity check failed: objective delta ",
      format(objective_delta, digits = 12),
      " exceeds tolerance ",
      format(tolerance, digits = 6),
      call. = FALSE
    )
  }
  out
}

run_native_parity_check <- function(model_dir, frq, final_par, rtmb_footer, program) {
  if (!truthy(env("STEPWISE_NATIVE_PARITY_CHECK", env("STEPWISE_PARITY_CHECK", "false")), FALSE)) {
    return(NULL)
  }
  if (!requireNamespace("mfclrtmb", quietly = TRUE) ||
      !("run_original_mfcl_short_eval" %in% getNamespaceExports("mfclrtmb"))) {
    stop(
      "STEPWISE_NATIVE_PARITY_CHECK=true needs mfclrtmb::run_original_mfcl_short_eval. ",
      "Include mfclrtmb in KFLOW_REPO_RUNTIME_PACKAGES.",
      call. = FALSE
    )
  }

  root_name <- sub("[.]frq$", "", basename(frq))
  keep_work <- truthy(env("STEPWISE_PARITY_KEEP_WORK", "false"), FALSE)
  check_dir <- if (isTRUE(keep_work)) {
    file.path(model_dir, "native-parity-work")
  } else {
    tempfile("native-parity-")
  }
  on.exit({
    if (!isTRUE(keep_work)) unlink(check_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)
  tolerance <- suppressWarnings(as.numeric(env(
    "STEPWISE_NATIVE_PARITY_OBJECTIVE_TOLERANCE",
    env("STEPWISE_RTMB_PARITY_OBJECTIVE_TOLERANCE", "1e-5")
  )))
  if (!is.finite(tolerance)) tolerance <- 1e-5
  phase_switch <- suppressWarnings(as.integer(env("STEPWISE_NATIVE_PARITY_PHASE_SWITCH", "1")))
  if (!is.finite(phase_switch)) phase_switch <- 1L
  timeout <- suppressWarnings(as.numeric(env("STEPWISE_NATIVE_PARITY_TIMEOUT", "0")))
  if (!is.finite(timeout)) timeout <- 0
  native_report <- truthy(env("STEPWISE_NATIVE_PARITY_REPORT", "true"), TRUE)

  message("  native parity: evaluating rtmb final par with native MFCL short eval")
  short_eval_args <- list(
    exe = program,
    source_dir = model_dir,
    root = root_name,
    in_par = final_par,
    out_par = "native-parity.par",
    dest_dir = check_dir,
    overwrite = TRUE,
    report = native_report,
    phase_switch = phase_switch,
    timeout = timeout
  )
  short_eval_formals <- tryCatch(
    names(formals(mfclrtmb::run_original_mfcl_short_eval)),
    error = function(e) character()
  )
  if ("write_par" %in% short_eval_formals) {
    short_eval_args$write_par <- TRUE
  }
  started <- Sys.time()
  result <- tryCatch(
    do.call(mfclrtmb::run_original_mfcl_short_eval, short_eval_args),
    error = function(e) e
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  failed <- inherits(result, "error")

  native_footer <- c(objective = NA_real_, max_gradient = NA_real_)
  stdout_objective <- NA_real_
  if (!failed && isTRUE(result$ok) && file.exists(result$out_par)) {
    native_footer <- par_footer(result$out_par)
  }
  stdout_file <- if (!failed && !is.null(result$case$work_dir)) {
    file.path(result$case$work_dir, "mfcl_switch.stdout")
  } else {
    ""
  }
  if (nzchar(stdout_file) && file.exists(stdout_file)) {
    stdout_summary <- tryCatch(mfclrtmb::read_mfcl_stdout_summary(stdout_file), error = function(e) NULL)
    stdout_objective <- suppressWarnings(as.numeric(tryCatch(stdout_summary$last[["total_function"]], error = function(e) NA_real_)))
  }
  stderr_file <- if (!failed && !is.null(result$stderr)) result$stderr else ""
  tail_text <- function(path, n = 12L) {
    if (!nzchar(path) || !file.exists(path)) return("")
    lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) character())
    lines <- tail(lines, n)
    paste(lines, collapse = " | ")
  }
  native_error_message <- if (failed) {
    conditionMessage(result)
  } else if (!isTRUE(result$ok)) {
    paste(
      paste0("status=", suppressWarnings(as.integer(result$status %||% NA_integer_))),
      paste0("out_par_exists=", file.exists(result$out_par %||% "")),
      paste0("stderr_tail=", tail_text(stderr_file)),
      paste0("stdout_tail=", tail_text(stdout_file)),
      sep = "; "
    )
  } else {
    ""
  }

  native_objective <- suppressWarnings(as.numeric(native_footer[["objective"]]))
  if (!is.finite(native_objective)) native_objective <- stdout_objective
  native_max_gradient <- suppressWarnings(as.numeric(native_footer[["max_gradient"]]))
  rtmb_objective <- suppressWarnings(as.numeric(rtmb_footer[["objective"]]))
  rtmb_max_gradient <- suppressWarnings(as.numeric(rtmb_footer[["max_gradient"]]))
  objective_delta <- rtmb_objective - native_objective
  objective_abs_delta <- abs(objective_delta)
  objective_ok <- is.finite(objective_abs_delta) && objective_abs_delta <= tolerance
  status <- if (isTRUE(objective_ok)) "match" else "mismatch"
  if (failed || !isTRUE(result$ok) || !is.finite(native_objective)) status <- "native_objective_unavailable"

  program_md5 <- if (file.exists(program)) {
    tryCatch(as.character(tools::md5sum(program)[[1L]]), error = function(e) "")
  } else {
    ""
  }
  out <- data.frame(
    check_time = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    check_direction = "rtmb_final_par_with_native",
    program_path = program,
    program_md5 = program_md5,
    root = root_name,
    final_par = normalizePath(final_par, winslash = "/", mustWork = FALSE),
    rtmb_objective = rtmb_objective,
    rtmb_max_gradient = rtmb_max_gradient,
    native_objective = native_objective,
    native_gradient_objective = native_objective,
    native_max_gradient = native_max_gradient,
    native_gradient_mode = "run_original_mfcl_short_eval",
    rtmb_gradient_mode = "final-par-footer",
    objective_delta = objective_delta,
    objective_abs_delta = objective_abs_delta,
    objective_tolerance = tolerance,
    objective_ok = objective_ok,
    status = status,
    objective_status = if (failed) 1L else suppressWarnings(as.integer(result$status %||% 0L)),
    gradient_status = if (!is.finite(native_max_gradient)) 1L else 0L,
    elapsed_seconds = elapsed,
    error_message = native_error_message,
    work_dir = if (isTRUE(keep_work)) normalizePath(check_dir, winslash = "/", mustWork = FALSE) else "",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  utils::write.csv(out, file.path(model_dir, "native-parity-check.csv"), row.names = FALSE)
  if (isTRUE(keep_work)) {
    utils::write.csv(out, file.path(check_dir, "summary.csv"), row.names = FALSE)
  }
  message(sprintf(
    "  native parity %s: rtmb=%.12g native=%.12g delta=%.6g",
    status,
    rtmb_objective,
    native_objective,
    objective_delta
  ))

  if (truthy(env("STEPWISE_NATIVE_PARITY_FAIL", "false"), FALSE) && !isTRUE(objective_ok)) {
    stop(
      "Native parity check failed: objective delta ",
      format(objective_delta, digits = 12),
      " exceeds tolerance ",
      format(tolerance, digits = 6),
      call. = FALSE
    )
  }
  out
}

read_step_table <- function(path, steps_root) {
  if (file.exists(path)) {
    cfg_env <- new.env(parent = globalenv())
    source(path, local = cfg_env)
    if (!exists("stepwise_models", envir = cfg_env, inherits = FALSE)) {
      stop("job-config.R must define stepwise_models.", call. = FALSE)
    }
    table <- get("stepwise_models", envir = cfg_env, inherits = FALSE)
    if (!is.data.frame(table)) stop("stepwise_models must be a data frame.", call. = FALSE)
  } else {
    dirs <- sort(list.dirs(steps_root, recursive = FALSE, full.names = FALSE))
    dirs <- dirs[grepl("^[0-9][0-9]-", dirs)]
    table <- data.frame(step_id = dirs, stringsAsFactors = FALSE)
  }
  if (!"step_id" %in% names(table)) stop("job-config.R must include a step_id column.", call. = FALSE)
  table$step_id <- trimws(as.character(table$step_id))
  table <- table[nzchar(table$step_id), , drop = FALSE]
  if (!nrow(table)) stop("No step rows found in job-config.R.", call. = FALSE)
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

par_source_roots <- function(root, work_dir) {
  roots <- c(
    env("STEPWISE_PAR_SOURCE_DIR", ""),
    env("PAR_SOURCE_DIR", ""),
    env("KFLOW_INPUT_DIR", ""),
    env("INPUT_DIR", ""),
    file.path(root, "inputs"),
    file.path(work_dir, "inputs")
  )
  roots <- unique(normalizePath(roots[nzchar(roots) & dir.exists(roots)], winslash = "/", mustWork = FALSE))
  roots
}

job_ref_tokens <- function(job_ref = "") {
  job_ref <- trimws(as.character(job_ref %||% ""))
  if (!nzchar(job_ref)) return(character())
  number <- suppressWarnings(as.integer(gsub("^#", "", job_ref)))
  tokens <- c(job_ref, gsub("^#", "", job_ref))
  if (is.finite(number)) {
    tokens <- c(tokens, sprintf("%06d", number), sprintf("job-%06d", number), paste0("job-", number))
  }
  unique(tokens[nzchar(tokens)])
}

find_previous_job_par <- function(step_id, job_ref = "", root, work_dir) {
  # RUN_MODE=job_par: prefer the attached/input job's final.par when possible.
  roots <- par_source_roots(root, work_dir)
  if (!length(roots)) return("")
  candidates <- unlist(lapply(roots, function(path) {
    list.files(path, pattern = "^([0-9]+|final)[.]par$", recursive = TRUE, full.names = TRUE)
  }), use.names = FALSE)
  candidates <- unique(normalizePath(candidates[file.exists(candidates)], winslash = "/", mustWork = FALSE))
  if (!length(candidates)) return("")

  step_pattern <- paste0("(^|/)", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", step_id), "(/|$)")
  candidates <- candidates[grepl(step_pattern, candidates)]
  if (!length(candidates)) return("")

  tokens <- job_ref_tokens(job_ref)
  if (length(tokens)) {
    token_pattern <- paste(gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", tokens), collapse = "|")
    path_matches <- candidates[grepl(token_pattern, candidates, ignore.case = TRUE)]
    if (length(path_matches)) {
      candidates <- path_matches
    }
  }

  info <- file.info(candidates)
  score <- ifelse(basename(candidates) == "final.par", 1000L, 0L)
  numbers <- suppressWarnings(as.integer(tools::file_path_sans_ext(basename(candidates))))
  score <- score + ifelse(is.na(numbers), 0L, pmin(numbers, 999L))
  candidates[order(score, info$mtime, candidates)][[length(candidates)]]
}

find_previous_job_payload <- function(step_id, job_ref = "", root, work_dir) {
  roots <- par_source_roots(root, work_dir)
  if (!length(roots)) return("")
  candidates <- unlist(lapply(roots, function(path) {
    list.files(path, pattern = "^model_payload[.]rds$", recursive = TRUE, full.names = TRUE)
  }), use.names = FALSE)
  candidates <- unique(normalizePath(candidates[file.exists(candidates)], winslash = "/", mustWork = FALSE))
  if (!length(candidates)) return("")

  step_pattern <- paste0("(^|/)", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", step_id), "(/|$)")
  candidates <- candidates[grepl(step_pattern, candidates)]
  if (!length(candidates)) return("")

  tokens <- job_ref_tokens(job_ref)
  if (length(tokens)) {
    token_pattern <- paste(gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", tokens), collapse = "|")
    path_matches <- candidates[grepl(token_pattern, candidates, ignore.case = TRUE)]
    if (length(path_matches)) {
      candidates <- path_matches
    }
  }

  info <- file.info(candidates)
  candidates[order(info$mtime, candidates)][[length(candidates)]]
}

restore_payload_par <- function(payload_file, dest) {
  payload <- tryCatch(readRDS(payload_file), error = function(e) e)
  if (inherits(payload, "error")) {
    stop("Could not read compact payload par from ", payload_file, ": ", conditionMessage(payload), call. = FALSE)
  }
  artifact <- tryCatch(payload$artifacts$files$par, error = function(e) NULL)
  bytes <- tryCatch(artifact$bytes, error = function(e) NULL)
  if (is.null(artifact) || is.null(bytes) || !is.raw(bytes)) {
    stop("Compact payload does not contain a par artifact: ", payload_file, call. = FALSE)
  }
  compression <- tryCatch(as.character(artifact$compression[[1L]]), error = function(e) "none")
  if (!nzchar(compression) || is.na(compression)) compression <- "none"
  if (!identical(compression, "none")) {
    bytes <- tryCatch(memDecompress(bytes, type = compression), error = function(e) e)
    if (inherits(bytes, "error") || is.null(bytes)) {
      stop("Could not decompress par artifact from ", payload_file, call. = FALSE)
    }
  }
  writeBin(bytes, dest)
  if (!file.exists(dest) || file.info(dest)$size <= 0) {
    stop("Could not restore previous-job.par from compact payload: ", payload_file, call. = FALSE)
  }
  invisible(dest)
}

stage_previous_job_par <- function(model_dir, step_id, job_ref, root, work_dir) {
  source_par <- find_previous_job_par(step_id, job_ref = job_ref, root = root, work_dir = work_dir)
  dest <- file.path(model_dir, "previous-job.par")
  if (nzchar(source_par) && file.exists(source_par)) {
    ok <- file.copy(source_par, dest, overwrite = TRUE, copy.date = TRUE)
    if (!isTRUE(ok)) stop("Could not stage previous-job.par from ", source_par, call. = FALSE)
    return(list(input_par = basename(dest), source_par = source_par))
  }

  source_payload <- find_previous_job_payload(step_id, job_ref = job_ref, root = root, work_dir = work_dir)
  if (nzchar(source_payload) && file.exists(source_payload)) {
    restore_payload_par(source_payload, dest)
    return(list(input_par = basename(dest), source_par = paste0(source_payload, ":par")))
  }

  if (!nzchar(source_par) || !file.exists(source_par)) {
    stop(
      "RUN_MODE=job_par needs a previous Kflow output par for ", step_id,
      if (nzchar(job_ref)) paste0(" from job ", job_ref) else "",
      ". Attach that job as an input job, or set STEPWISE_PAR_SOURCE_DIR to a folder containing outputs/models/",
      step_id, "/final.par or a compact model_payload.rds with a par artifact.",
      call. = FALSE
    )
  }
}

expected_final_par_for_run <- function(run_mode, run_script_name, cfg) {
  expected <- cfg$EXPECTED_FINAL_PAR %||% cfg$FINAL_PAR %||% ""
  if (!nzchar(expected) && is_doitall_like_mode(run_mode) && identical(basename(run_script_name), "doitall.sh")) {
    expected <- "11.par"
  }
  expected
}

select_final_par <- function(model_dir, step_id, run_mode, run_script_name, cfg) {
  expected <- expected_final_par_for_run(run_mode, run_script_name, cfg)
  if (nzchar(expected)) {
    final_par <- file.path(model_dir, expected)
    if (!file.exists(final_par)) {
      canonical <- canonical_par_files(model_dir)
      ignored <- noncanonical_par_like_files(model_dir)
      stop(
        "MFCL did not create expected final par ", expected, " for ", step_id,
        ". Existing canonical par files: ",
        if (length(canonical)) paste(canonical, collapse = ", ") else "none",
        ". Ignored non-final par-like files: ",
        if (length(ignored)) paste(ignored, collapse = ", ") else "none",
        ". Check mfcl.log for the first MFCL failure.",
        call. = FALSE
      )
    }
    return(expected)
  }
  best <- best_par(model_dir)
  if (!nzchar(best)) {
    ignored <- noncanonical_par_like_files(model_dir)
    stop(
      "MFCL did not create a canonical final par file for ", step_id,
      ". Ignored non-final par-like files: ",
      if (length(ignored)) paste(ignored, collapse = ", ") else "none",
      ".",
      call. = FALSE
    )
  }
  best
}

build_payload <- function(model_dir, step_id) {
  # Try current payload builders first; fail clearly if no payload is produced.
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
    has_rep_object <- !is.null(tryCatch(payload$data$RepOut, error = function(e) NULL))
    has_rep_artifact <- !is.null(tryCatch(payload$artifacts$files$rep$bytes, error = function(e) NULL))
    if (!isTRUE(has_rep_object || has_rep_artifact)) {
      stop("model_payload.rds for ", step_id, " does not contain RepOut data or a rep artifact.", call. = FALSE)
    }
    likelihood_components <- tryCatch(payload$data$LikelihoodComponents, error = function(e) NULL)
    if (is.null(likelihood_components)) {
      likelihood_components <- tryCatch(payload$LikelihoodComponents, error = function(e) NULL)
    }
    if (is.null(likelihood_components) || !NROW(likelihood_components)) {
      warning(
        "model_payload.rds for ", step_id,
        " does not contain likelihood components; objective component tables ",
        "will show only values available from the final par file.",
        call. = FALSE
      )
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
save_final_par <- truthy(env("STEPWISE_SAVE_FINAL_PAR", "false"), default = FALSE)
save_raw_mfcl_inputs <- truthy(env("STEPWISE_SAVE_RAW_MFCL_INPUTS", "false"), default = FALSE)
step_select <- strsplit(env("STEP_SELECT", ""), ",", fixed = TRUE)[[1]]
step_select <- trimws(step_select[nzchar(trimws(step_select))])
default_input_dir <- env("DEFAULT_INPUT_DIR", "")

config_path <- env("CONFIG_R", "job-config.R")
step_table <- read_step_table(file.path(root, config_path), file.path(root, "steps"))
if (length(step_select) && !any(tolower(step_select) %in% c("all", "*"))) {
  unknown <- setdiff(step_select, step_table$step_id)
  if (length(unknown)) stop("Unknown STEP_SELECT value(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  step_table <- step_table[step_table$step_id %in% step_select, , drop = FALSE]
}
if (!nrow(step_table)) stop("No step folders selected.", call. = FALSE)

region_map_helper <- file.path(root, "R", "write_bet_region_map_assets.R")
if (file.exists(region_map_helper)) {
  source(region_map_helper, local = TRUE)
}

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  step_table,
  file.path(out_dir, "selected-steps.csv"),
  row.names = FALSE
)

copy_region_map_asset <- function(output_dir, source_name, target_name = source_name, fallback_writer = NULL) {
  shared_geojson <- file.path(root, "assets", "maps", source_name)
  target_geojson <- file.path(output_dir, target_name)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(shared_geojson)) {
    ok <- file.copy(shared_geojson, target_geojson, overwrite = TRUE, copy.date = TRUE)
    if (!ok) stop("Failed to copy shared region map asset: ", source_name, call. = FALSE)
    return(invisible(TRUE))
  }
  if (is.function(fallback_writer)) {
    fallback_writer(output_dir, stem = tools::file_path_sans_ext(target_name))
    return(invisible(TRUE))
  }
  invisible(FALSE)
}

region_map_asset_name_for_count <- function(region_count) {
  switch(as.character(suppressWarnings(as.integer(region_count))),
    "5" = "bet-2026-five-region.geojson",
    "9" = "bet-2023-nine-region.geojson",
    ""
  )
}

region_map_writer_for_count <- function(region_count) {
  region_count <- suppressWarnings(as.integer(region_count))
  if (identical(region_count, 5L) && exists("write_bet_region_map_assets", mode = "function")) {
    return(write_bet_region_map_assets)
  }
  if (identical(region_count, 9L) && exists("write_bet_nine_region_map_assets", mode = "function")) {
    return(write_bet_nine_region_map_assets)
  }
  NULL
}

copy_model_region_map_assets <- function(step_out, region_count) {
  asset_name <- region_map_asset_name_for_count(region_count)
  if (!nzchar(asset_name)) {
    return("")
  }
  ok <- copy_region_map_asset(
    step_out,
    asset_name,
    target_name = "bet.region_map.geojson",
    fallback_writer = region_map_writer_for_count(region_count)
  )
  target <- file.path(step_out, "bet.region_map.geojson")
  if (isTRUE(ok) && file.exists(target)) {
    return(target)
  }
  ""
}

portable_output_path <- function(path, output_dir) {
  if (!nzchar(path)) return("")
  path_norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  output_norm <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  prefix <- paste0(output_norm, "/")
  if (startsWith(path_norm, prefix)) {
    return(substring(path_norm, nchar(prefix) + 1L))
  }
  path
}

copy_root_region_map_assets <- function(output_dir, region_counts) {
  region_counts <- suppressWarnings(as.integer(region_counts))
  region_counts <- sort(unique(region_counts[is.finite(region_counts)]))
  asset_names <- vapply(region_counts, region_map_asset_name_for_count, character(1))
  asset_names <- asset_names[nzchar(asset_names)]
  if (!length(asset_names)) {
    return(character())
  }
  region_map_dir <- file.path(output_dir, "region-map")
  copied <- character()
  for (i in seq_along(asset_names)) {
    ok <- copy_region_map_asset(
      region_map_dir,
      asset_names[[i]],
      target_name = asset_names[[i]],
      fallback_writer = region_map_writer_for_count(region_counts[[i]])
    )
    target <- file.path(region_map_dir, asset_names[[i]])
    if (isTRUE(ok) && file.exists(target)) {
      copied <- c(copied, target)
    }
  }
  copied
}

model_rows <- list()
saved_par_rows <- list()
build_payloads <- truthy(env("STEPWISE_BUILD_PAYLOAD", "true"), default = TRUE)
for (i in seq_len(nrow(step_table))) {
  step_id <- step_table$step_id[[i]]
  step_dir <- file.path(root, "steps", step_id)
  if (!dir.exists(step_dir)) stop("Step folder not found: steps/", step_id, call. = FALSE)
  cfg <- read_config(file.path(step_dir, "config.env"))
  cfg <- modifyList(cfg, row_to_config(step_table, i))
  cfg <- apply_env_overrides(cfg, c("RUN_MODE", "INPUT_PAR", "FRQ", "OUTPUT_PAR", "PAR_SOURCE_JOB"))
  step_id <- basename(step_dir)
  if (!truthy(cfg$ENABLED %||% "true", default = TRUE)) {
    message("Skipping disabled step ", step_id)
    next
  }
  label <- cfg$MODEL_LABEL %||% step_id
  source_dir <- cfg$SOURCE_DIR %||% ""
  input_subdir <- cfg$INPUT_SUBDIR %||% default_input_dir
  run_mode <- mode_key(cfg$RUN_MODE %||% "last_par")
  input_par <- cfg$INPUT_PAR %||% "latest"
  output_par <- cfg$OUTPUT_PAR %||% ""
  requested_run_mode <- run_mode
  requested_input_par <- input_par
  par_source_job <- cfg$PAR_SOURCE_JOB %||% env("STEPWISE_PAR_SOURCE_JOB", "")
  par_source_par <- ""
  par_fallback <- FALSE
  par_fallback_reason <- ""
  run_script_name <- cfg$RUN_SCRIPT %||% "doitall.sh"
  step_program <- cfg$MFCL_PROGRAM_PATH %||% cfg$PROGRAM_PATH %||% program
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
  run_engine <- if (is_mfclrtmb_mode(run_mode)) "mfclrtmb" else "mfcl"
  display_label <- model_display_label(label, run_engine, step_program, step_id = step_id)
  log_file <- file.path(model_dir, "mfcl.log")
  message("Running ", step_id, " (", display_label, ")")
  message("  source: ", relative_display_path(model_source, root))
  message("  mode:   ", run_mode)
  message("  engine: ", engine_label(run_engine, step_program))
  if (!is_mfclrtmb_mode(run_mode)) {
    message("  mfcl:   ", step_program)
  }
  if (is_job_par_mode(run_mode)) {
    staged <- stage_previous_job_par(model_dir, step_id, par_source_job, root = root, work_dir = work_dir)
    input_par <- staged$input_par
    par_source_par <- staged$source_par
    run_mode <- "single_par"
    if (!nzchar(output_par)) output_par <- "final.par"
    message(
      "  previous job par: ",
      relative_display_path(par_source_par, root),
      if (nzchar(par_source_job)) paste0(" (requested job ", par_source_job, ")") else ""
    )
  }
  if (is_mfclrtmb_doitall_mode(run_mode) && nzchar(par_source_job)) {
    staged <- stage_previous_job_par(model_dir, step_id, par_source_job, root = root, work_dir = work_dir)
    input_par <- staged$input_par
    par_source_par <- staged$source_par
    Sys.setenv(MFCLRTMB_START_PAR = file.path(model_dir, staged$input_par))
    message(
      "  previous job par: ",
      relative_display_path(par_source_par, root),
      " -> MFCLRTMB_START_PAR",
      if (nzchar(par_source_job)) paste0(" (requested job ", par_source_job, ")") else ""
    )
  }
  if (is_mfclrtmb_par_mode(run_mode) && nzchar(par_source_job)) {
    staged <- stage_previous_job_par(model_dir, step_id, par_source_job, root = root, work_dir = work_dir)
    input_par <- staged$input_par
    par_source_par <- staged$source_par
    if (!nzchar(output_par)) output_par <- "final.par"
    message(
      "  previous job par: ",
      relative_display_path(par_source_par, root),
      " -> ", output_par,
      if (nzchar(par_source_job)) paste0(" (requested job ", par_source_job, ")") else ""
    )
  }
  if (!is_doitall_like_mode(run_mode)) {
    needs_latest_par <- is_latest_par_mode(run_mode) &&
      (!nzchar(input_par) || identical(tolower(input_par), "latest") || run_mode %in% c("last", "latest", "last_par", "latest_par"))
    if (needs_latest_par) {
      input_par <- best_par(model_dir)
    }
    if (!nzchar(input_par)) {
      par_fallback <- TRUE
      par_fallback_reason <- "no .par file was found"
    } else if (!file.exists(file.path(model_dir, input_par))) {
      par_fallback <- TRUE
      par_fallback_reason <- paste0("requested .par file was not found: ", input_par)
    }
    if (isTRUE(par_fallback)) {
      if (is_mfclrtmb_par_mode(run_mode)) {
        stop(
          "RUN_MODE=", requested_run_mode, " needs an existing .par file",
          if (nzchar(par_fallback_reason)) paste0("; ", par_fallback_reason) else "",
          call. = FALSE
        )
      }
      message(
        "[stepwise-par] ", step_id,
        " requested RUN_MODE=", requested_run_mode,
        if (nzchar(requested_input_par)) paste0(" INPUT_PAR=", requested_input_par) else "",
        ", but ", par_fallback_reason,
        "; falling back to RUN_MODE=doitall."
      )
      run_mode <- "doitall"
      input_par <- ""
      output_par <- ""
    }
  }
  old <- setwd(model_dir)
  model_run_started_at <- Sys.time()
  status <- tryCatch({
    if (is_doitall_mode(run_mode)) {
      message("  script: ", run_script_name)
      run_script(file.path(model_dir, run_script_name), program = step_program, log_file = log_file, live_log = mfcl_live_log)
    } else if (is_mfclrtmb_doitall_mode(run_mode)) {
      message("  script: ", run_script_name)
      run_mfclrtmb_doitall(model_dir, frq = frq, script = file.path(model_dir, run_script_name), log_file = log_file, live_log = mfcl_live_log)
    } else if (is_mfclrtmb_par_mode(run_mode)) {
      if (!nzchar(output_par)) output_par <- "final.par"
      message("  input:  ", frq, " + ", input_par)
      message("  output: ", output_par)
      run_mfclrtmb_single_par(
        model_dir = model_dir,
        frq = frq,
        input_par = input_par,
        output_par = output_par,
        log_file = log_file,
        live_log = mfcl_live_log
      )
    } else {
      if (!nzchar(output_par)) output_par <- next_par_name(input_par)
      message("  input:  ", frq, " + ", input_par)
      message("  output: ", output_par)
      args <- c(frq, input_par, output_par, smoke_switch_args())
      run_mfcl(step_program, args, log_file = log_file, live_log = mfcl_live_log)
    }
  }, finally = setwd(old))
  model_run_finished_at <- Sys.time()
  model_run_elapsed_seconds <- as.numeric(difftime(model_run_finished_at, model_run_started_at, units = "secs"))
  parsed_fit_seconds <- if (identical(run_engine, "mfclrtmb")) parse_mfclrtmb_fit_elapsed_seconds(log_file) else NA_real_
  model_fit_elapsed_seconds <- if (is.finite(parsed_fit_seconds)) parsed_fit_seconds else model_run_elapsed_seconds
  if (is.finite(model_fit_elapsed_seconds) &&
      is.finite(model_run_elapsed_seconds) &&
      model_fit_elapsed_seconds > model_run_elapsed_seconds) {
    message(
      "  fit time exceeded model runner wall time; using runner wall time: ",
      format_elapsed_time(model_run_elapsed_seconds)
    )
    model_fit_elapsed_seconds <- model_run_elapsed_seconds
  }
  if (!identical(status, 0L)) stop("MFCL failed for ", step_id, " with status ", status, call. = FALSE)

  final_output_par <- if (is_doitall_like_mode(run_mode)) {
    select_final_par(model_dir, step_id, run_mode, run_script_name, cfg)
  } else {
    output_par
  }
  final_par <- file.path(model_dir, final_output_par)
  if (!nzchar(final_output_par) || !file.exists(final_par)) {
    stop("MFCL did not create a final par file for ", step_id, call. = FALSE)
  }
  message("  final par: ", final_output_par)
  saved_final_par <- ""
  if (isTRUE(save_final_par)) {
    saved_final_par <- file.path(step_dir, "model", basename(final_output_par))
    dir.create(dirname(saved_final_par), recursive = TRUE, showWarnings = FALSE)
    ok <- file.copy(final_par, saved_final_par, overwrite = TRUE, copy.date = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not save final par for reuse: ", relative_display_path(saved_final_par, root), call. = FALSE)
    }
    message("  saved par: ", relative_display_path(saved_final_par, root))
    saved_par_rows[[length(saved_par_rows) + 1L]] <- data.frame(
      step_id = step_id,
      model_label = display_label,
      base_model_label = label,
      requested_run_mode = requested_run_mode,
      run_mode = run_mode,
      requested_input_par = requested_input_par,
      input_par = input_par,
      output_par = final_output_par,
      saved_par = relative_display_path(saved_final_par, root),
      par_fallback = par_fallback,
      par_fallback_reason = par_fallback_reason,
      stringsAsFactors = FALSE
    )
  }

  footer <- par_footer(final_par)
  if (identical(run_engine, "mfclrtmb")) {
    run_native_parity_check(
      model_dir = model_dir,
      frq = frq,
      final_par = final_par,
      rtmb_footer = footer,
      program = env("MFCLRTMB_NATIVE_PROGRAM_PATH", step_program)
    )
  } else {
    run_rtmb_parity_check(
      model_dir = model_dir,
      frq = frq,
      final_par = final_par,
      native_footer = footer
    )
  }

  if (isTRUE(build_payloads)) {
    message("  building model_payload.rds")
    payload_status <- build_payload(model_dir, step_id)
    message("  payload: ", payload_status)
  } else {
    payload_status <- "skipped by STEPWISE_BUILD_PAYLOAD=false"
    message("  payload: ", payload_status)
  }
  payload_file <- file.path(model_dir, "model_payload.rds")
  requested_region_count <- suppressWarnings(as.integer(cfg$REGION_COUNT %||% NA_integer_))
  detected_region_count <- if (exists("detect_frq_region_count", mode = "function")) {
    detect_frq_region_count(file.path(model_dir, frq))
  } else {
    NA_integer_
  }
  region_count <- if (is.finite(detected_region_count)) detected_region_count else requested_region_count
  run_metadata <- list(
    model_label = display_label,
    base_model_label = label,
    plot_label = display_label,
    model_token = display_label,
    job_key = cfg$JOB_KEY %||% "",
    step_id = step_id,
    run_engine = run_engine,
    engine_label = engine_label(run_engine, step_program),
    run_mode = run_mode,
    requested_run_mode = requested_run_mode,
    mfcl_program_path = step_program,
    region_count = region_count,
    kflow_memory = env("KFLOW_JOB_MEMORY", cfg$KFLOW_MEMORY %||% ""),
    model_run_started_at = model_run_started_at,
    model_run_finished_at = model_run_finished_at,
    model_run_elapsed_seconds = model_run_elapsed_seconds,
    model_fit_elapsed_seconds = model_fit_elapsed_seconds,
    model_run_time = format_elapsed_time(model_fit_elapsed_seconds)
  )
  if (file.exists(payload_file)) {
    write_payload_metadata(payload_file, model_dir, run_metadata)
  }

  step_out <- file.path(out_dir, "models", step_id)
  dir.create(step_out, recursive = TRUE, showWarnings = FALSE)
  raw_mfcl_inputs_dir <- ""
  raw_mfcl_inputs_saved <- FALSE
  if (isTRUE(save_raw_mfcl_inputs)) {
    raw_mfcl_inputs_dir <- file.path(step_out, "mfcl-inputs")
    raw_mfcl_inputs_saved <- copy_raw_mfcl_inputs(model_source, raw_mfcl_inputs_dir)
    if (!isTRUE(raw_mfcl_inputs_saved)) {
      warning("Could not save raw MFCL inputs for ", step_id, call. = FALSE)
      raw_mfcl_inputs_dir <- ""
    }
  }
  keep <- unique(c(
    "model_payload.rds",
    "model_payload_manifest.json",
    "model_payload_manifest.csv",
    "model_info.rds",
    "model-registry.csv",
    "fishery_map.R",
    "tag_rep_map.R",
    "phase-plan.csv",
    "phase-summary.csv",
    "phase-progress.csv",
    "phase-process-summary.csv",
    "doitall-switches.csv",
    "post-switch-summary.csv",
    "native-parity-check.csv"
  ))
  for (file in keep) {
    src <- file.path(model_dir, file)
    if (file.exists(src)) {
      if (dir.exists(src)) {
        file.copy(src, step_out, overwrite = TRUE, recursive = TRUE, copy.date = TRUE)
      } else {
        file.copy(src, file.path(step_out, basename(file)), overwrite = TRUE, copy.date = TRUE)
      }
    }
  }
  region_map_asset_path <- copy_model_region_map_assets(step_out, region_count)
  region_map_assets <- nzchar(region_map_asset_path) && file.exists(region_map_asset_path)
  summary <- data.frame(
    step_id = step_id,
    major_step = cfg$MAJOR_STEP %||% "",
    substep = cfg$SUBSTEP %||% "",
    change_axis = cfg$CHANGE_AXIS %||% "",
    model_label = display_label,
    base_model_label = label,
    model_source = relative_display_path(model_source, root),
    run_engine = run_engine,
    engine_label = engine_label(run_engine, step_program),
    mfcl_program_path = step_program,
    run_mode = run_mode,
    requested_run_mode = requested_run_mode,
    input_par = input_par,
    requested_input_par = requested_input_par,
    par_source_job = par_source_job,
    par_source_par = if (nzchar(par_source_par)) relative_display_path(par_source_par, root) else "",
    frq = frq,
    output_par = final_output_par,
    final_par = "model_payload.rds:par",
    saved_par = if (nzchar(saved_final_par)) relative_display_path(saved_final_par, root) else "",
    par_fallback = par_fallback,
    par_fallback_reason = par_fallback_reason,
    objective = footer[["objective"]],
    max_gradient = footer[["max_gradient"]],
    model_run_elapsed_seconds = model_run_elapsed_seconds,
    model_fit_elapsed_seconds = model_fit_elapsed_seconds,
    model_run_time = format_elapsed_time(model_fit_elapsed_seconds),
    kflow_memory = env("KFLOW_JOB_MEMORY", cfg$KFLOW_MEMORY %||% ""),
    payload = file.exists(file.path(step_out, "model_payload.rds")),
    raw_mfcl_inputs_saved = raw_mfcl_inputs_saved,
    raw_mfcl_inputs = if (raw_mfcl_inputs_saved) portable_output_path(raw_mfcl_inputs_dir, out_dir) else "",
    region_count = region_count,
    region_map_assets = region_map_assets,
    region_map_asset = if (region_map_assets) portable_output_path(region_map_asset_path, out_dir) else "",
    payload_status = payload_status,
    stringsAsFactors = FALSE
  )
  model_rows[[length(model_rows) + 1L]] <- summary
}

model_index <- bind_rows_fill(model_rows)
write.csv(model_index, file.path(out_dir, "model-index.csv"), row.names = FALSE)
root_region_map_assets <- copy_root_region_map_assets(out_dir, model_index$region_count)
if (length(root_region_map_assets)) {
  message("Wrote root region-map assets: ", paste(basename(root_region_map_assets), collapse = ", "))
}
saved_par_index <- bind_rows_fill(saved_par_rows)
if (!nrow(saved_par_index)) {
  saved_par_index <- data.frame(
    step_id = character(),
    model_label = character(),
    requested_run_mode = character(),
    run_mode = character(),
    requested_input_par = character(),
    input_par = character(),
    output_par = character(),
    saved_par = character(),
    par_fallback = logical(),
    par_fallback_reason = character(),
    stringsAsFactors = FALSE
  )
}
write.csv(saved_par_index, file.path(out_dir, "saved-pars.csv"), row.names = FALSE)
