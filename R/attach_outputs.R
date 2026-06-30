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

relative_output_path <- function(path, root) {
  if (is.na(path) || !nzchar(path)) return(path)
  path_norm <- normalize_loose(path)
  root_norm <- normalize_loose(root)
  prefix <- paste0(root_norm, "/")
  if (identical(path_norm, root_norm)) return(".")
  if (startsWith(path_norm, prefix)) substring(path_norm, nchar(prefix) + 1L) else path_norm
}

rebase_model_index_paths <- function(model_index, output_dir) {
  cols <- intersect(c("region_map_asset"), names(model_index))
  for (col in cols) {
    model_index[[col]] <- vapply(model_index[[col]], portable_output_path, character(1), output_dir = output_dir)
  }
  model_index
}

pluck <- function(x, ..., default = NULL) {
  keys <- c(...)
  for (key in keys) {
    if (!is.list(x) || is.null(x[[key]])) return(default)
    x <- x[[key]]
  }
  x
}

scalar_chr <- function(x, default = NA_character_) {
  if (is.null(x) || !length(x) || is.na(x[[1L]])) return(default)
  as.character(x[[1L]])
}

scalar_int <- function(x, default = NA_integer_) {
  if (is.null(x) || !length(x) || is.na(x[[1L]])) return(default)
  value <- suppressWarnings(as.integer(x[[1L]]))
  if (!length(value) || is.na(value)) default else value
}

scalar_lgl <- function(x, default = NA) {
  if (is.null(x) || !length(x) || is.na(x[[1L]])) return(default)
  value <- suppressWarnings(as.logical(x[[1L]]))
  if (!length(value) || is.na(value)) default else value
}

read_neigenvalues <- function(hessian_dir) {
  path <- file.path(hessian_dir, "neigenvalues")
  if (!file.exists(path)) return(NULL)
  vals <- suppressWarnings(scan(path, what = numeric(), quiet = TRUE, nmax = 2))
  if (length(vals) < 2L) return(NULL)
  list(n_negative_eigenvalues = as.integer(vals[[1L]]), n_total_eigenvalues = as.integer(vals[[2L]]))
}

read_hessian_parameter_labels <- function(model_dir) {
  candidates <- unique(c(
    file.path(model_dir, "xinit.rpt"),
    file.path(model_dir, "indepvar.rpt"),
    file.path(model_dir, "hessian", "xinit.rpt"),
    file.path(model_dir, "hessian", "indepvar.rpt")
  ))
  candidates <- candidates[file.exists(candidates)]
  if (!length(candidates)) return(NULL)
  tbl <- tryCatch(
    read.table(candidates[[1L]], header = FALSE, fill = TRUE, quote = "", comment.char = "", stringsAsFactors = FALSE),
    error = function(e) NULL
  )
  if (is.null(tbl) || !is.data.frame(tbl) || ncol(tbl) < 2L || nrow(tbl) == 0L) return(NULL)
  index <- suppressWarnings(as.integer(tbl[[1L]]))
  label <- apply(tbl[, seq.int(2L, ncol(tbl)), drop = FALSE], 1L, function(x) {
    paste(as.character(x[!is.na(x) & nzchar(as.character(x))]), collapse = " ")
  })
  out <- data.frame(Parameter.Index = index, Parameter.Label = label, stringsAsFactors = FALSE)
  out <- out[is.finite(out$Parameter.Index) & nzchar(out$Parameter.Label), , drop = FALSE]
  if (!nrow(out)) NULL else out[!duplicated(out$Parameter.Index), , drop = FALSE]
}

parameter_labels_match_hessian <- function(model_dir) {
  labels <- read_hessian_parameter_labels(model_dir)
  if (is.null(labels) || !nrow(labels)) return(FALSE)
  neig <- read_neigenvalues(file.path(model_dir, "hessian"))
  if (is.null(neig)) return(TRUE)
  n_total <- suppressWarnings(as.integer(neig$n_total_eigenvalues[[1L]]))
  if (!is.finite(n_total) || n_total <= 0L) return(TRUE)
  isTRUE(max(labels$Parameter.Index, na.rm = TRUE) == n_total)
}

resolve_model_source_dir <- function(model_row) {
  candidates <- c(
    row_value(model_row, "model_source"),
    row_value(model_row, "source_dir"),
    if (nzchar(row_value(model_row, "step_id"))) file.path("steps", row_value(model_row, "step_id"), "model") else "",
    if (nzchar(row_value(model_row, "model_key"))) file.path("steps", row_value(model_row, "model_key"), "model") else ""
  )
  candidates <- unique(candidates[nzchar(candidates)])
  for (path in candidates) {
    candidate <- if (is_absolute_path(path)) path else file.path(getwd(), path)
    if (dir.exists(candidate)) return(normalize_loose(candidate))
  }
  ""
}

copy_generated_parameter_labels <- function(work_dir, model_dir) {
  copied <- FALSE
  copied_paths <- character()
  for (name in c("xinit.rpt", "indepvar.rpt")) {
    source <- file.path(work_dir, name)
    if (!file.exists(source)) next
    target <- file.path(model_dir, name)
    file.copy(source, target, overwrite = TRUE, copy.date = TRUE)
    copied_paths <- c(copied_paths, target)
    copied <- TRUE
  }
  matched <- copied && parameter_labels_match_hessian(model_dir)
  if (copied && !matched) unlink(copied_paths, force = TRUE)
  matched
}

ensure_hessian_parameter_labels <- function(model_dir, model_row) {
  if (parameter_labels_match_hessian(model_dir)) return(FALSE)
  if (!truthy(env("STEPWISE_GENERATE_HESSIAN_LABELS", "true"), TRUE)) return(FALSE)

  final_par <- file.path(model_dir, "final.par")
  if (!file.exists(final_par)) {
    message("[stepwise] Hessian parameter labels not generated: final.par is missing")
    return(FALSE)
  }

  model_source <- resolve_model_source_dir(model_row)
  if (!nzchar(model_source)) {
    message("[stepwise] Hessian parameter labels not generated: model source directory was not found")
    return(FALSE)
  }

  frq <- row_value(model_row, "frq", env("FRQ", "bet.frq"))
  frq_path <- file.path(model_source, frq)
  if (!file.exists(frq_path)) {
    frq_hits <- list.files(model_source, pattern = "[.]frq$", full.names = FALSE)
    if (length(frq_hits)) {
      frq <- frq_hits[[1L]]
      frq_path <- file.path(model_source, frq)
    }
  }
  if (!file.exists(frq_path)) {
    message("[stepwise] Hessian parameter labels not generated: no .frq file in ", model_source)
    return(FALSE)
  }

  program <- env("PROGRAM_PATH", "/home/mfcl/mfclo64")
  if (!nzchar(program) || !file.exists(program)) {
    program_found <- Sys.which(basename(program))
    if (nzchar(program_found)) program <- program_found
  }
  if (!nzchar(program) || !file.exists(program)) {
    message("[stepwise] Hessian parameter labels not generated: PROGRAM_PATH was not found")
    return(FALSE)
  }

  work_dir <- tempfile("stepwise-hessian-labels-")
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(work_dir, recursive = TRUE, force = TRUE), add = TRUE)
  copy_dir_contents(model_source, work_dir)
  file.copy(final_par, file.path(work_dir, "final.par"), overwrite = TRUE, copy.date = TRUE)

  log_file <- file.path(work_dir, "mfcl-label-report.log")
  timeout <- suppressWarnings(as.integer(env("STEPWISE_LABEL_GENERATION_TIMEOUT", "300")))
  use_timeout <- is.finite(timeout) && timeout > 0L && nzchar(Sys.which("timeout"))
  command <- if (use_timeout) Sys.which("timeout") else program
  args <- c(frq, "final.par", "label.par", "-file", "-")
  if (use_timeout) args <- c(as.character(timeout), program, args)

  message("[stepwise] generating Hessian parameter labels from ", frq, " and final.par")
  old_wd <- getwd()
  setwd(work_dir)
  on.exit(setwd(old_wd), add = TRUE)
  status <- suppressWarnings(system2(
    command,
    args,
    stdout = log_file,
    stderr = log_file,
    input = c("  1 1 0", "  1 246 1")
  ))
  status <- suppressWarnings(as.integer(status %||% 0L))
  generated <- copy_generated_parameter_labels(work_dir, model_dir)
  if (!generated) {
    if (is.finite(status) && status != 0L) {
      message("[stepwise] MFCL label generation exited with status ", status, " and no matching xinit.rpt")
    } else {
      message("[stepwise] MFCL label generation did not produce a matching xinit.rpt")
    }
    return(FALSE)
  }
  if (is.finite(status) && status != 0L) {
    message("[stepwise] MFCL label generation exited with status ", status, " after writing xinit.rpt")
  }
  TRUE
}

read_hessian_nonpositive_parameters <- function(model_dir, top_n = 40L) {
  hessian_dir <- file.path(model_dir, "hessian")
  path <- file.path(hessian_dir, "neigenvalues")
  neig <- read_neigenvalues(hessian_dir)
  if (is.null(neig) || !file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  n_negative <- suppressWarnings(as.integer(neig$n_negative_eigenvalues[[1L]]))
  n_total <- suppressWarnings(as.integer(neig$n_total_eigenvalues[[1L]]))
  if (!is.finite(n_negative) || n_negative <= 0L || !is.finite(n_total) || n_total <= 0L) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  values <- suppressWarnings(scan(path, what = numeric(), quiet = TRUE, skip = 1L))
  row_width <- n_total + 1L
  if (!length(values)) return(data.frame(stringsAsFactors = FALSE))
  if (length(values) %% row_width == 0L) {
    mat <- matrix(values, ncol = row_width, byrow = TRUE)
    eigenvalues <- mat[, 1L]
    vectors <- mat[, -1L, drop = FALSE]
  } else if (length(values) %% n_total == 0L) {
    mat <- matrix(values, ncol = n_total, byrow = TRUE)
    eigenvalues <- rep(NA_real_, nrow(mat))
    vectors <- mat
  } else {
    return(data.frame(stringsAsFactors = FALSE))
  }
  n_rows <- min(n_negative, nrow(vectors))
  labels <- read_hessian_parameter_labels(model_dir)
  label_lookup <- if (!is.null(labels) && nrow(labels)) {
    stats::setNames(as.character(labels$Parameter.Label), as.character(labels$Parameter.Index))
  } else {
    NULL
  }
  top_n <- suppressWarnings(as.integer(top_n[[1L]]))
  if (!is.finite(top_n) || top_n <= 0L) top_n <- 40L
  rows <- lapply(seq_len(n_rows), function(i) {
    loading <- as.numeric(vectors[i, ])
    keep <- is.finite(loading)
    if (!any(keep)) return(NULL)
    idx <- seq_along(loading)[keep]
    loading <- loading[keep]
    total_sq <- sum(loading^2, na.rm = TRUE)
    ord <- order(abs(loading), decreasing = TRUE)
    ord <- ord[seq_len(min(length(ord), top_n))]
    idx <- idx[ord]
    loading <- loading[ord]
    label <- if (!is.null(label_lookup)) unname(label_lookup[as.character(idx)]) else rep(NA_character_, length(idx))
    missing_label <- is.na(label) | !nzchar(label)
    label[missing_label] <- paste0("Parameter ", idx[missing_label])
    data.frame(
      Eigen.Direction = i,
      Eigenvalue = eigenvalues[[i]],
      Parameter.Index = as.integer(idx),
      Parameter.Label = label,
      Loading = loading,
      Abs.Loading = abs(loading),
      Contribution.Percent = if (is.finite(total_sq) && total_sq > 0) (loading^2 / total_sq) * 100 else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[vapply(rows, function(x) is.data.frame(x) && nrow(x), logical(1))]
  if (!length(rows)) data.frame(stringsAsFactors = FALSE) else do.call(rbind, rows)
}

first_existing_column <- function(tbl, candidates) {
  hits <- intersect(candidates, names(tbl))
  if (!length(hits)) return(NULL)
  tbl[[hits[[1L]]]]
}

read_hessian_parameter_uncertainty <- function(model_dir, hinfo = NULL) {
  parameter_table <- tryCatch(hinfo$diagnostics$parameter_table, error = function(e) NULL)
  if (!is.data.frame(parameter_table) || !nrow(parameter_table)) {
    se_values <- tryCatch(hinfo$standard_errors$values, error = function(e) NULL)
    se_values <- suppressWarnings(as.numeric(se_values))
    if (!length(se_values)) return(data.frame(stringsAsFactors = FALSE))
    parameter_table <- NULL
  } else {
    se_values <- numeric()
  }

  if (!is.null(parameter_table)) {
    n <- nrow(parameter_table)
    idx <- suppressWarnings(as.integer(first_existing_column(
      parameter_table,
      c("Parameter.Index", "idx", "index", "parameter_index")
    )))
    label <- as.character(first_existing_column(
      parameter_table,
      c("Parameter.Label", "par", "parameter", "parameter_label")
    ))
    variance <- suppressWarnings(as.numeric(first_existing_column(
      parameter_table,
      c("Variance", "variance", "var_nonpos_diag", "hess_inv_diag")
    )))
    se <- suppressWarnings(as.numeric(first_existing_column(
      parameter_table,
      c("SE", "se", "se_nonpos", "std_error")
    )))
    pos_variance <- suppressWarnings(as.numeric(first_existing_column(
      parameter_table,
      c("Positivised.Variance", "positivised_variance", "var_pos_diag", "var_pos_from_cov_diag")
    )))
    pos_se <- suppressWarnings(as.numeric(first_existing_column(
      parameter_table,
      c("Positivised.SE", "positivised_se", "se_pos")
    )))
  } else {
    n <- length(se_values)
    idx <- seq_len(n)
    label <- rep(NA_character_, n)
    se <- se_values
    variance <- se_values^2
    pos_variance <- rep(NA_real_, n)
    pos_se <- rep(NA_real_, n)
  }

  if (!length(idx)) idx <- seq_len(n)
  if (!length(label)) label <- rep(NA_character_, n)
  if (!length(variance)) variance <- rep(NA_real_, n)
  if (!length(se)) se <- rep(NA_real_, n)
  if (!length(pos_variance)) pos_variance <- rep(NA_real_, n)
  if (!length(pos_se)) pos_se <- rep(NA_real_, n)

  labels <- read_hessian_parameter_labels(model_dir)
  if (!is.null(labels) && nrow(labels)) {
    lookup <- stats::setNames(as.character(labels$Parameter.Label), as.character(labels$Parameter.Index))
    fill <- is.na(label) | !nzchar(trimws(label))
    label[fill] <- unname(lookup[as.character(idx[fill])])
  }
  missing_label <- is.na(label) | !nzchar(trimws(label))
  label[missing_label] <- paste0("Parameter ", idx[missing_label])

  h_status <- scalar_chr(pluck(hinfo, "eigen", "hessian_status"), NA_character_)
  out <- data.frame(
    Parameter.Index = idx,
    Parameter.Label = label,
    Variance = variance,
    SE = se,
    Positivised.Variance = pos_variance,
    Positivised.SE = pos_se,
    Hessian.Status = h_status,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  keep <- is.finite(out$Variance) | is.finite(out$SE) |
    is.finite(out$Positivised.Variance) | is.finite(out$Positivised.SE)
  out <- out[keep, , drop = FALSE]
  if (!nrow(out)) data.frame(stringsAsFactors = FALSE) else out
}

hessian_status_from_neigen <- function(n_negative, n_total) {
  if (!is.finite(n_negative) || !is.finite(n_total) || n_total <= 0) {
    return(list(status = "Unknown", reliability = "UNKNOWN", is_pdh = NA))
  }
  if (n_negative <= 0L) {
    return(list(status = "PDH", reliability = "HIGH", is_pdh = TRUE))
  }
  if ((n_negative / n_total) < 0.01) {
    return(list(status = "Near-PDH", reliability = "MODERATE", is_pdh = FALSE))
  }
  list(status = "Non-PDH", reliability = "LOW", is_pdh = FALSE)
}

hessian_summary_from_dir <- function(model_dir) {
  hessian_dir <- file.path(model_dir, "hessian")
  hinfo_file <- file.path(hessian_dir, "hessian_info.rds")
  neig <- read_neigenvalues(hessian_dir)
  hinfo <- if (file.exists(hinfo_file)) tryCatch(readRDS(hinfo_file), error = function(e) NULL) else NULL

  n_negative <- scalar_int(pluck(hinfo, "eigen", "n_negative_eigenvalues"), NA_integer_)
  n_total <- scalar_int(pluck(hinfo, "eigen", "n_total_eigenvalues"), NA_integer_)
  if ((!is.finite(n_negative) || !is.finite(n_total)) && !is.null(neig)) {
    n_negative <- neig$n_negative_eigenvalues
    n_total <- neig$n_total_eigenvalues
  }
  status <- hessian_status_from_neigen(n_negative, n_total)

  is_pdh <- scalar_lgl(pluck(hinfo, "diagnostics", "summary", "pdh", "is_pdh"), NA)
  if (is.na(is_pdh)) is_pdh <- scalar_lgl(pluck(hinfo, "diagnostics", "summary", "is_pdh"), status$is_pdh)
  is_spd <- scalar_lgl(pluck(hinfo, "diagnostics", "summary", "positivised_cov_is_spd"), NA)
  if (is.na(is_spd)) is_spd <- scalar_lgl(pluck(hinfo, "diagnostics", "summary", "is_spd"), NA)
  hessian_ok <- scalar_lgl(pluck(hinfo, "diagnostics", "summary", "hessian_ok"), NA)
  if (is.na(hessian_ok) && !is.na(is_pdh)) {
    hessian_ok <- if (!is.na(is_spd)) isTRUE(is_pdh) && isTRUE(is_spd) else isTRUE(is_pdh)
  }

  hessian_file <- file.path(hessian_dir, paste0(scalar_chr(pluck(hinfo, "meta", "root_name"), "bet"), ".hes"))
  if (!file.exists(hessian_file)) hessian_file <- NA_character_
  if (!file.exists(hinfo_file) && is.null(neig) && is.na(hessian_file)) return(NULL)

  list(
    requested = TRUE,
    attempted = TRUE,
    run_ok = TRUE,
    error = NA_character_,
    info_file = if (file.exists(hinfo_file)) normalize_loose(hinfo_file) else NA_character_,
    hessian_file = if (!is.na(hessian_file)) normalize_loose(hessian_file) else NA_character_,
    hessian_range = NULL,
    is_pdh = is_pdh,
    is_spd = is_spd,
    hessian_ok = hessian_ok,
    n_negative_eigenvalues = n_negative,
    n_total_eigenvalues = n_total,
    hessian_status = scalar_chr(pluck(hinfo, "eigen", "hessian_status"), status$status),
    reliability = scalar_chr(pluck(hinfo, "eigen", "reliability"), status$reliability),
    nonpositive_parameters = read_hessian_nonpositive_parameters(model_dir),
    parameter_uncertainty = read_hessian_parameter_uncertainty(model_dir, hinfo)
  )
}

update_model_payload_hessian <- function(model_dir) {
  payload_file <- file.path(model_dir, "model_payload.rds")
  if (!file.exists(payload_file)) return(FALSE)
  summary <- hessian_summary_from_dir(model_dir)
  if (is.null(summary)) return(FALSE)
  payload <- tryCatch(readRDS(payload_file), error = function(e) NULL)
  if (is.null(payload) || !is.list(payload)) return(FALSE)
  if (!is.null(payload$data) && is.list(payload$data)) {
    if (is.null(payload$data$info) || !is.list(payload$data$info)) payload$data$info <- list()
    payload$data$info$hessian <- summary
  } else {
    if (is.null(payload$info) || !is.list(payload$info)) payload$info <- list()
    payload$info$hessian <- summary
  }
  saveRDS(payload, payload_file, compress = "xz")
  TRUE
}

check_artifact_role <- function(path) {
  name <- basename(path)
  if (identical(name, "model_payload.rds")) return("model_payload")
  if (identical(name, "profile_payload.rds")) return("profile_payload")
  if (identical(name, "jitter_result.rds")) return("jitter_result")
  if (identical(name, "hessian_info.rds")) return("hessian_info")
  if (grepl("_runs[.]rds$", name)) return("check_runs")
  if (grepl("(index|manifest)[.](csv|rds|json)$", name, ignore.case = TRUE)) return("index")
  "artifact"
}

collect_attached_check_artifacts <- function(model_dir, check_types = diagnostic_dir_names()) {
  rows <- list()
  for (check_type in check_types) {
    root <- file.path(model_dir, check_type)
    if (!dir.exists(root)) next
    files <- list.files(root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
    if (!length(files)) next
    info <- file.info(files)
    files <- files[!is.na(info$isdir) & !info$isdir]
    keep <- grepl(
      "^(model_payload|profile_payload|jitter_result|selftest_runs|aspm_runs|hessian_info|retro_info)[.]rds$",
      basename(files)
    ) | grepl("(index|manifest)[.](csv|rds|json)$", basename(files), ignore.case = TRUE)
    files <- files[keep]
    if (!length(files)) next
    rows[[length(rows) + 1L]] <- data.frame(
      check_type = check_type,
      artifact_role = vapply(files, check_artifact_role, character(1)),
      artifact_file = normalize_loose(files),
      artifact_relative_file = vapply(files, relative_output_path, character(1), root = model_dir),
      artifact_folder = normalize_loose(dirname(files)),
      artifact_relative_folder = vapply(dirname(files), relative_output_path, character(1), root = model_dir),
      bytes = suppressWarnings(as.numeric(file.info(files)$size)),
      stringsAsFactors = FALSE
    )
  }
  bind_rows_fill(rows)
}

attached_check_counts <- function(model_dir, check_types, artifacts) {
  rows <- lapply(check_types, function(check_type) {
    root <- file.path(model_dir, check_type)
    output_dirs <- if (dir.exists(root)) list.dirs(root, recursive = TRUE, full.names = TRUE) else character()
    output_dirs <- output_dirs[output_dirs != root]
    a <- if (is.data.frame(artifacts) && nrow(artifacts)) {
      artifacts[artifacts$check_type == check_type, , drop = FALSE]
    } else {
      data.frame()
    }
    data.frame(
      check_type = check_type,
      n_output_dirs = length(output_dirs),
      n_artifacts = nrow(a),
      n_payload_artifacts = sum(a$artifact_role %in% c("model_payload", "profile_payload", "jitter_result"), na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_fill(rows)
}

attached_checks_summary_from_dir <- function(model_dir,
                                             copied = diagnostic_dir_names(),
                                             attached_row = NULL,
                                             attached_at = "") {
  check_types <- unique(normalize_check_type(copied))
  check_types <- check_types[nzchar(check_types) & dir.exists(file.path(model_dir, check_types))]
  index_file <- file.path(model_dir, "attached-checks-index.csv")
  attached_index <- if (file.exists(index_file)) read_csv_safe(index_file) else data.frame()
  if (is.data.frame(attached_row) && nrow(attached_row)) {
    attached_index <- bind_rows_fill(list(attached_index, attached_row))
  }
  artifacts <- collect_attached_check_artifacts(model_dir, check_types)
  if (!length(check_types) && !nrow(attached_index) && !nrow(artifacts)) return(NULL)
  list(
    schema = "ofp-sam.attached_checks.v1",
    updated_at = attached_at %||% format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    check_types = check_types,
    index = attached_index,
    counts = attached_check_counts(model_dir, check_types, artifacts),
    artifacts = artifacts
  )
}

update_model_payload_attached_checks <- function(model_dir,
                                                 copied = diagnostic_dir_names(),
                                                 attached_row = NULL,
                                                 attached_at = "") {
  payload_file <- file.path(model_dir, "model_payload.rds")
  if (!file.exists(payload_file)) return(FALSE)
  summary <- attached_checks_summary_from_dir(
    model_dir,
    copied = copied,
    attached_row = attached_row,
    attached_at = attached_at
  )
  if (is.null(summary)) return(FALSE)
  payload <- tryCatch(readRDS(payload_file), error = function(e) NULL)
  if (is.null(payload) || !is.list(payload)) return(FALSE)
  if (!is.null(payload$data) && is.list(payload$data)) {
    if (is.null(payload$data$info) || !is.list(payload$data$info)) payload$data$info <- list()
    payload$data$info$attached_checks <- summary
  } else {
    if (is.null(payload$info) || !is.list(payload$info)) payload$info <- list()
    payload$info$attached_checks <- summary
  }
  saveRDS(payload, payload_file, compress = "xz")
  TRUE
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
    parameter_labels_generated <- if ("hessian" %in% copied) {
      ensure_hessian_parameter_labels(target_dir, target_model_rows[1L, , drop = FALSE])
    } else {
      FALSE
    }
    parameter_labels_available <- if ("hessian" %in% copied) parameter_labels_match_hessian(target_dir) else FALSE
    payload_hessian_updated <- if ("hessian" %in% copied) update_model_payload_hessian(target_dir) else FALSE
    attached_row <- data.frame(
      model_key = row_value(target_model_rows, "model_key", row_value(target_model_rows, "step_id", row_key)),
      step_id = row_value(target_model_rows, "step_id", row_key),
      check_type = paste(copied, collapse = " "),
      payload_hessian_updated = payload_hessian_updated,
      payload_checks_updated = FALSE,
      parameter_labels_available = parameter_labels_available,
      parameter_labels_generated = parameter_labels_generated,
      source_input_root = normalize_loose(row$input_root %||% ""),
      source_check_dir = normalize_loose(source_dir),
      attached_model_dir = normalize_loose(target_dir),
      attached_at = attached_at,
      stringsAsFactors = FALSE
    )
    attached_rows[[length(attached_rows) + 1L]] <- attached_row
  }

  attached <- bind_rows_fill(attached_rows)
  if (!nrow(attached)) {
    stop("No diagnostic folders were attached.", call. = FALSE)
  }

  for (dir in unique(attached$attached_model_dir)) {
    rows <- attached[attached$attached_model_dir == dir, , drop = FALSE]
    copied_for_dir <- unique(unlist(strsplit(paste(rows$check_type, collapse = " "), "\\s+")))
    copied_for_dir <- copied_for_dir[nzchar(copied_for_dir)]
    payload_checks_updated <- update_model_payload_attached_checks(
      dir,
      copied = copied_for_dir,
      attached_row = rows,
      attached_at = attached_at
    )
    attached$payload_checks_updated[attached$attached_model_dir == dir] <- payload_checks_updated
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
