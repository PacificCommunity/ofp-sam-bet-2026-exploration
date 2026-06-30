## Build an updated stepwise output bundle by attaching completed check outputs
## to a previous stepwise/model output. This does not mutate old Kflow archives.

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) return(y)
  if (length(x) == 1L && is.na(x)) return(y)
  if (length(x) == 1L && !nzchar(as.character(x))) return(y)
  x
}

env <- function(name, default = "") {
  value <- Sys.getenv(name, unset = NA_character_)
  if (is.na(value) || !nzchar(value)) default else value
}

split_values <- function(value, default = character()) {
  if (is.null(value) || !length(value) || !nzchar(as.character(value[[1L]]))) {
    return(default)
  }
  out <- unlist(strsplit(as.character(value), "[,[:space:]]+", perl = TRUE), use.names = FALSE)
  out[nzchar(out)]
}

truthy <- function(value, default = FALSE) {
  if (is.null(value) || !length(value) || !nzchar(as.character(value[[1L]]))) {
    return(isTRUE(default))
  }
  tolower(trimws(as.character(value[[1L]]))) %in% c("1", "true", "yes", "y", "on")
}

row_value <- function(row, name, default = "") {
  if (!name %in% names(row)) return(default)
  value <- row[[name]]
  if (is.null(value) || !length(value) || is.na(value[[1L]])) return(default)
  as.character(value[[1L]])
}

is_absolute_path <- function(path) grepl("^(/|[A-Za-z]:[\\\\/])", path)

normalize_loose <- function(path) normalizePath(path, winslash = "/", mustWork = FALSE)

copy_dir <- function(from, to) {
  if (!dir.exists(from)) stop("Directory not found: ", from, call. = FALSE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  entries <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(entries)) {
    ok <- file.copy(entries, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
    if (!all(ok)) stop("Could not copy all files from ", from, call. = FALSE)
  }
  invisible(normalize_loose(to))
}

copy_dir_contents <- function(from, to) {
  if (!dir.exists(from)) stop("Directory not found: ", from, call. = FALSE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  entries <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(entries)) {
    ok <- file.copy(entries, to, recursive = TRUE, overwrite = TRUE, copy.date = TRUE)
    if (!all(ok)) stop("Could not copy all files from ", from, call. = FALSE)
  }
  invisible(normalize_loose(to))
}

portable_output_path <- function(path, output_dir) {
  if (is.na(path) || !nzchar(path)) return(path)
  path <- as.character(path)
  if (!is_absolute_path(path)) return(path)
  path_norm <- normalize_loose(path)
  output_norm <- normalize_loose(output_dir)
  prefix <- paste0(output_norm, "/")
  if (startsWith(path_norm, prefix)) {
    return(substring(path_norm, nchar(prefix) + 1L))
  }
  for (marker in c("/outputs/", "/output/")) {
    pos <- regexpr(marker, path_norm, fixed = TRUE)[[1L]]
    if (pos > 0L) {
      rel <- substring(path_norm, pos + nchar(marker))
      if (file.exists(file.path(output_dir, rel))) return(rel)
    }
  }
  path
}

rebase_model_index_paths <- function(model_index, output_dir) {
  cols <- intersect(c("region_map_asset"), names(model_index))
  for (col in cols) {
    model_index[[col]] <- vapply(model_index[[col]], portable_output_path, character(1), output_dir = output_dir)
  }
  model_index
}

read_csv_safe <- function(path) {
  tryCatch(read.csv(path, stringsAsFactors = FALSE, check.names = FALSE), error = function(e) data.frame())
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

diagnostic_dir_names <- function() {
  c("jitter", "retro", "hessian", "profile", "selftest", "aspm", "projection")
}

normalize_check_type <- function(value) {
  value <- gsub("-", "_", tolower(as.character(value %||% "")))
  sub("_merge$", "", value)
}

default_input_root <- function() {
  explicit <- env("MODEL_INPUT_ROOT", "")
  if (nzchar(explicit)) return(explicit)
  candidates <- c(
    env("KFLOW_INPUT_DIR", ""),
    "inputs",
    "input",
    file.path("work", "inputs"),
    "."
  )
  hit <- candidates[nzchar(candidates) & dir.exists(candidates)]
  if (length(hit)) hit[[1L]] else "."
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

job_dirs <- function(root, refs) {
  refs <- split_values(refs)
  if (!length(refs)) return(character())
  if (!dir.exists(root)) return(character())
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  out <- character()
  for (ref in refs) {
    exact <- file.path(root, ref)
    if (dir.exists(exact)) {
      out <- c(out, exact)
      next
    }
    tokens <- job_ref_tokens(ref)
    hits <- dirs[vapply(basename(dirs), function(name) {
      any(startsWith(name, tokens)) || any(tokens %in% strsplit(name, "[-_]", perl = TRUE)[[1L]])
    }, logical(1))]
    out <- c(out, hits)
  }
  unique(normalize_loose(out[dir.exists(out)]))
}

candidate_key <- function(row) {
  values <- c(
    row$step_id %||% "",
    row$model_label %||% "",
    row$job_key %||% "",
    row$model_key %||% "",
    row$model_name %||% "",
    basename(row$model_dir %||% ""),
    basename(row$source_dir %||% ""),
    basename(row$model_source %||% "")
  )
  values <- values[nzchar(values)]
  if (length(values)) values[[1L]] else paste0("model-", row$candidate_id %||% "")
}

discover_index_candidates <- function(root) {
  index_files <- list.files(root, pattern = "^model-index[.]csv$", recursive = TRUE, full.names = TRUE)
  rows <- list()
  for (index in index_files) {
    dat <- read_csv_safe(index)
    if (!nrow(dat)) next
    base <- dirname(index)
    for (i in seq_len(nrow(dat))) {
      row <- dat[i, , drop = FALSE]
      step_id <- as.character(row$step_id %||% "")
      model_dir <- as.character(row$model_dir %||% "")
      compact_dir <- if (nzchar(model_dir)) {
        if (is_absolute_path(model_dir)) model_dir else file.path(base, model_dir)
      } else if (nzchar(step_id)) {
        file.path(base, "models", step_id)
      } else {
        base
      }
      rows[[length(rows) + 1L]] <- data.frame(
        candidate_type = "indexed",
        candidate_id = length(rows) + 1L,
        index_file = normalize_loose(index),
        output_root = normalize_loose(base),
        compact_dir = normalize_loose(compact_dir),
        stringsAsFactors = FALSE,
        row,
        check.names = FALSE
      )
    }
  }
  bind_rows_fill(rows)
}

discover_model_outputs <- function(root) {
  rows <- discover_index_candidates(root)
  if (!nrow(rows)) return(rows)
  rows$model_key <- vapply(seq_len(nrow(rows)), function(i) candidate_key(rows[i, , drop = FALSE]), character(1))
  rows
}

matches_selector <- function(row, selector) {
  if (!nzchar(selector) || tolower(selector) %in% c("all", "*")) return(TRUE)
  fields <- c("step_id", "model_label", "job_key", "model_key", "model_name", "model_source", "source_dir", "compact_dir")
  values <- unlist(row[intersect(fields, names(row))], use.names = FALSE)
  values <- unique(as.character(values[!is.na(values)]))
  basenames <- basename(values[nzchar(values)])
  values <- unique(c(values, basenames))
  if (selector %in% values) return(TRUE)
  any(grepl(selector, values, ignore.case = TRUE, fixed = TRUE))
}

candidate_score <- function(row) {
  compact_dir <- normalize_loose(as.character(row$compact_dir %||% ""))
  index_file <- normalize_loose(as.character(row$index_file %||% ""))
  model_dir <- gsub("\\\\", "/", as.character(row$model_dir %||% ""))
  payload_role <- as.character(row$payload_role %||% "")
  score <- 0
  if (truthy(row$attached_checks %||% "", FALSE)) score <- score + 100
  if (grepl("(^|/)outputs/models/[^/]+$", compact_dir)) score <- score + 80
  if (grepl("(^|/)models/[^/]+$", model_dir)) score <- score + 60
  if (grepl("(^|/)outputs/model-index[.]csv$", index_file)) score <- score + 40
  if (identical(payload_role, "check_model_root")) score <- score - 20
  if (grepl("(^|/)outputs/checks/", compact_dir)) score <- score - 10
  score
}

select_base_output <- function(candidates, selector) {
  if (!nrow(candidates)) {
    stop("No base model outputs found. Provide STEPWISE_BASE_INPUT_JOB or MODEL_INPUT_ROOT.", call. = FALSE)
  }
  keep <- vapply(seq_len(nrow(candidates)), function(i) {
    matches_selector(candidates[i, , drop = FALSE], selector)
  }, logical(1))
  hits <- candidates[keep, , drop = FALSE]
  if (!nrow(hits)) {
    stop("No base output matched selector ", shQuote(selector), call. = FALSE)
  }
  hits$.candidate_score <- vapply(seq_len(nrow(hits)), function(i) candidate_score(hits[i, , drop = FALSE]), numeric(1))
  hits <- hits[order(-hits$.candidate_score, hits$candidate_id), , drop = FALSE]
  hits[1L, , drop = FALSE]
}

candidate_check_types <- function(row) {
  compact_dir <- as.character(row$compact_dir %||% "")
  values <- c(row$attached_check_type %||% "", row$check_type %||% "", row$merged_check_type %||% "")
  manifest <- file.path(compact_dir, "check_manifest.csv")
  if (file.exists(manifest)) {
    dat <- read_csv_safe(manifest)
    if (nrow(dat)) values <- c(values, dat$check_type %||% "")
  }
  dirs <- diagnostic_dir_names()[dir.exists(file.path(compact_dir, diagnostic_dir_names()))]
  values <- c(values, dirs)
  unique(normalize_check_type(values[nzchar(values)]))
}

main <- function() {
  message("[stepwise] updating previous output bundle with completed check outputs")
  input_root <- normalize_loose(default_input_root())
  output_dir <- env("OUTPUT_DIR", "outputs")
  base_ref <- env("STEPWISE_BASE_INPUT_JOB", env("MODEL_BASE_INPUT_JOB", env("BASE_MODEL_JOB", "")))
  check_refs <- env("STEPWISE_CHECK_INPUT_JOBS", env("CHECK_INPUT_JOBS", ""))
  selector <- env("STEPWISE_ATTACH_SELECTOR", env("MODEL_SELECTOR", env("STEP_SELECT", "")))
  attach_types <- normalize_check_type(split_values(env("ATTACH_CHECK_TYPES", "")))
  attach_types <- attach_types[nzchar(attach_types)]

  if (!nzchar(base_ref)) {
    refs <- split_values(env("KFLOW_INPUT_JOBS", ""))
    if (length(refs)) base_ref <- refs[[1L]]
  }
  if (!nzchar(base_ref)) {
    stop("STEPWISE_BASE_INPUT_JOB is required for RUN_MODE=attach_outputs.", call. = FALSE)
  }

  base_roots <- job_dirs(input_root, base_ref)
  if (!length(base_roots)) {
    stop("Base input job directory was not found: ", base_ref, call. = FALSE)
  }
  base_candidates <- bind_rows_fill(lapply(base_roots, discover_model_outputs))
  base_selected <- select_base_output(base_candidates, selector)
  base_output_root <- as.character(base_selected$output_root %||% "")
  if (!nzchar(base_output_root) || !dir.exists(base_output_root)) {
    stop("Selected base output root was not found.", call. = FALSE)
  }

  copy_dir_contents(base_output_root, output_dir)
  model_index_path <- file.path(output_dir, "model-index.csv")
  model_index <- read_csv_safe(model_index_path)
  if (!nrow(model_index)) {
    model_index <- read_csv_safe(as.character(base_selected$index_file %||% ""))
  }
  if (!nrow(model_index)) {
    stop("Base output did not contain model-index.csv.", call. = FALSE)
  }
  model_index <- rebase_model_index_paths(model_index, output_dir)

  if (!nzchar(check_refs)) {
    refs <- split_values(env("KFLOW_INPUT_JOBS", ""))
    check_refs <- paste(setdiff(refs, base_ref), collapse = " ")
  }
  check_roots <- job_dirs(input_root, check_refs)
  if (!length(check_roots)) {
    stop("No check input job directories found. Set STEPWISE_CHECK_INPUT_JOBS.", call. = FALSE)
  }

  check_candidates <- bind_rows_fill(lapply(check_roots, function(root) {
    dat <- discover_model_outputs(root)
    if (nrow(dat)) dat$input_root <- normalize_loose(root)
    dat
  }))
  if (!nrow(check_candidates)) {
    stop("No model-like check outputs found in input jobs.", call. = FALSE)
  }
  check_candidates$.candidate_score <- vapply(seq_len(nrow(check_candidates)), function(i) {
    row <- check_candidates[i, , drop = FALSE]
    candidate_score(row) + 10 * sum(dir.exists(file.path(as.character(row$compact_dir %||% ""), diagnostic_dir_names())))
  }, numeric(1))
  check_candidates <- check_candidates[order(check_candidates$input_root, -check_candidates$.candidate_score), , drop = FALSE]
  check_candidates <- check_candidates[!duplicated(check_candidates$input_root), , drop = FALSE]

  attached_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  attached_rows <- list()
  for (i in seq_len(nrow(check_candidates))) {
    row <- check_candidates[i, , drop = FALSE]
    source_dir <- as.character(row$compact_dir %||% "")
    if (!nzchar(source_dir) || !dir.exists(source_dir)) next
    if (!matches_selector(row, selector)) next
    row_key <- as.character(row$model_key %||% row$step_id %||% basename(source_dir))
    target_model_rows <- model_index[vapply(seq_len(nrow(model_index)), function(j) {
      matches_selector(model_index[j, , drop = FALSE], row_key)
    }, logical(1)), , drop = FALSE]
    if (!nrow(target_model_rows)) {
      target_model_rows <- model_index[vapply(seq_len(nrow(model_index)), function(j) {
        matches_selector(model_index[j, , drop = FALSE], selector)
      }, logical(1)), , drop = FALSE]
    }
    if (!nrow(target_model_rows)) next
    target_model_dir <- row_value(target_model_rows, "model_dir")
    if (!nzchar(target_model_dir)) target_model_dir <- file.path("models", row_value(target_model_rows, "step_id", row_key))
    target_dir <- if (is_absolute_path(target_model_dir)) target_model_dir else file.path(output_dir, target_model_dir)
    if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)

    copied <- character()
    for (name in diagnostic_dir_names()) {
      source <- file.path(source_dir, name)
      if (!dir.exists(source)) next
      if (length(attach_types) && !normalize_check_type(name) %in% attach_types) next
      target <- file.path(target_dir, name)
      copy_dir(source, target)
      copied <- c(copied, name)
    }
    if (!length(copied)) next
    attached_rows[[length(attached_rows) + 1L]] <- data.frame(
      model_key = row_value(target_model_rows, "model_key", row_value(target_model_rows, "step_id", row_key)),
      step_id = row_value(target_model_rows, "step_id", row_key),
      check_type = paste(copied, collapse = " "),
      source_input_root = normalize_loose(row$input_root %||% ""),
      source_check_dir = normalize_loose(source_dir),
      attached_model_dir = normalize_loose(target_dir),
      attached_at = attached_at,
      stringsAsFactors = FALSE
    )
  }

  attached <- bind_rows_fill(attached_rows)
  if (!nrow(attached)) {
    stop("No diagnostic folders were attached.", call. = FALSE)
  }
  write.csv(attached, file.path(output_dir, "attached-checks-index.csv"), row.names = FALSE)
  for (dir in unique(attached$attached_model_dir)) {
    write.csv(attached[attached$attached_model_dir == dir, , drop = FALSE],
              file.path(dir, "attached-checks-index.csv"), row.names = FALSE)
    saveRDS(attached[attached$attached_model_dir == dir, , drop = FALSE],
            file.path(dir, "attached-checks-index.rds"), compress = "xz")
  }

  model_index$attached_checks <- vapply(seq_len(nrow(model_index)), function(i) {
    row <- model_index[i, , drop = FALSE]
    any(vapply(seq_len(nrow(attached)), function(j) matches_selector(row, attached$model_key[[j]]), logical(1)))
  }, logical(1))
  model_index$attached_check_type <- vapply(seq_len(nrow(model_index)), function(i) {
    row <- model_index[i, , drop = FALSE]
    hits <- attached[vapply(seq_len(nrow(attached)), function(j) matches_selector(row, attached$model_key[[j]]), logical(1)), , drop = FALSE]
    if (!nrow(hits)) "" else paste(unique(unlist(strsplit(hits$check_type, "\\s+"))), collapse = " ")
  }, character(1))
  model_index$attached_at <- ifelse(model_index$attached_checks, attached_at, "")
  write.csv(model_index, model_index_path, row.names = FALSE)

  manifest <- data.frame(
    schema = "ofp-sam.stepwise.updated-output-bundle.v1",
    created_at = attached_at,
    base_input_job = base_ref,
    check_input_jobs = check_refs,
    selector = selector,
    check_types = paste(unique(unlist(strsplit(attached$check_type, "\\s+"))), collapse = " "),
    n_check_sources = nrow(attached),
    stringsAsFactors = FALSE
  )
  write.csv(manifest, file.path(output_dir, "attached-model-bundle.csv"), row.names = FALSE)
  saveRDS(as.list(manifest), file.path(output_dir, "attached-model-bundle.rds"), compress = "xz")
  message("[stepwise] updated output bundle written under ", normalize_loose(output_dir))
}

main()
