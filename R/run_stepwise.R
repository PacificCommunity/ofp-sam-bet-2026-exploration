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
  if (grepl("2023_diagnostic|diagnostic", basename(program), ignore.case = TRUE)) {
    return("native MFCL old")
  }
  "native MFCL"
}

engine_token <- function(run_engine) {
  "native"
}

step_display_token <- function(step_id) {
  token <- sub("-.*$", "", trimws(as.character(step_id %||% "")))
  if (nzchar(token)) token else "model"
}

strip_engine_suffix <- function(label) {
  sub(
    "\\s*\\((native MFCL old|native MFCL|MFCL)\\)\\s*$",
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

is_doitall_like_mode <- function(run_mode) {
  is_doitall_mode(run_mode)
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
  run_engine <- "mfcl"
  display_label <- model_display_label(label, run_engine, step_program, step_id = step_id)
  log_file <- file.path(model_dir, "mfcl.log")
  message("Running ", step_id, " (", display_label, ")")
  message("  source: ", relative_display_path(model_source, root))
  message("  mode:   ", run_mode)
  message("  engine: ", engine_label(run_engine, step_program))
  message("  mfcl:   ", step_program)
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
  model_fit_elapsed_seconds <- model_run_elapsed_seconds
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
    "post-switch-summary.csv"
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
