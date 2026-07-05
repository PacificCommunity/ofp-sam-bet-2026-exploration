## Shared file, provenance, and regional-scaling helpers ---------------------

write_shared_region_map_assets <- function() {
  if (!exists("write_bet_region_map_assets", mode = "function")) return(invisible(FALSE))
  write_bet_region_map_assets(
    file.path(root, "assets", "maps"),
    stem = "bet-2026-five-region",
    map_label = "BET 2026 5-region"
  )
  if (exists("write_bet_nine_region_map_assets", mode = "function")) {
    write_bet_nine_region_map_assets(
      file.path(root, "assets", "maps"),
      stem = "bet-2023-nine-region",
      map_label = "BET 2023 9-region"
    )
  }
  invisible(TRUE)
}


public_source_path <- function(path) {
  if (!nzchar(path)) return(path)
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  input_prefix <- paste0(normalizePath(input_root, winslash = "/", mustWork = TRUE), "/")
  if (exists("input_repo_roots", inherits = TRUE)) {
    for (repo_name in names(input_repo_roots)) {
      repo_root <- normalizePath(input_repo_roots[[repo_name]], winslash = "/", mustWork = FALSE)
      repo_prefix <- paste0(repo_root, "/")
      if (startsWith(norm, repo_prefix)) {
        rel <- substring(norm, nchar(repo_prefix) + 1L)
        repo_parent <- if (startsWith(repo_root, input_prefix)) "input-repos" else "external-repos"
        return(file.path(repo_parent, repo_name, rel))
      }
    }
  }
  if (startsWith(norm, root_prefix)) {
    return(substring(norm, nchar(root_prefix) + 1L))
  }
  if (startsWith(norm, input_prefix)) {
    return(file.path("input-repos", substring(norm, nchar(input_prefix) + 1L)))
  }
  norm
}

copy_one <- function(from, to) {
  if (!file.exists(from)) stop("Missing source file: ", from, call. = FALSE)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(from, to, overwrite = TRUE, copy.date = TRUE)
  if (!ok) stop("Failed to copy ", from, " to ", to, call. = FALSE)
  invisible(to)
}

copy_regional_scaling_window <- function(from, to, start_period, end_period) {
  if (!file.exists(from)) stop("Missing source file: ", from, call. = FALSE)
  lines <- readLines(from, warn = FALSE)
  if (start_period < 1L || end_period < start_period || end_period > length(lines)) {
    stop(
      "Invalid regional-scaling window ", start_period, "-", end_period,
      " for ", basename(from), " with ", length(lines), " rows.",
      call. = FALSE
    )
  }
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines[start_period:end_period], to, useBytes = TRUE)
  invisible(to)
}

copy_if_exists <- function(from, to) {
  if (file.exists(from)) copy_one(from, to)
}

remove_model_par_files <- function(model_dir) {
  # `.par` files are run products; keep model folders input-only in git.
  if (!dir.exists(model_dir)) return(invisible(character()))
  paths <- list.files(
    model_dir,
    pattern = "([.]par[0-9]*$|^final[.]par$)",
    full.names = TRUE,
    recursive = FALSE
  )
  if (length(paths)) {
    unlink(paths, force = TRUE)
  }
  invisible(paths)
}

format_flag_value <- function(value) {
  value <- suppressWarnings(as.numeric(value))
  if (!is.finite(value)) return("NA")
  if (abs(value - round(value)) < .Machine$double.eps^0.5) {
    return(as.character(as.integer(round(value))))
  }
  format(value, trim = TRUE, scientific = FALSE)
}

parse_doitall_parest_flags <- function(path, flag_ids) {
  flag_ids <- as.character(flag_ids)
  flags <- stats::setNames(rep(NA_real_, length(flag_ids)), flag_ids)
  if (!file.exists(path)) return(flags)
  lines <- readLines(path, warn = FALSE)
  lines <- sub("#.*$", "", lines)
  for (line in lines) {
    words <- strsplit(trimws(line), "[[:space:]]+")[[1]]
    if (length(words) < 3L || !identical(words[[1L]], "1")) next
    flag_id <- words[[2L]]
    if (!flag_id %in% names(flags)) next
    value <- suppressWarnings(as.numeric(words[[3L]]))
    if (is.finite(value)) flags[[flag_id]] <- value
  }
  flags
}

regional_scaling_period_window <- function(flags, n_periods) {
  flag79 <- flags[["79"]]
  flag80 <- flags[["80"]]
  period_start <- if (is.finite(flag79) && flag79 > 0) {
    as.integer(n_periods - round(flag79) + 1L)
  } else {
    1L
  }
  period_end <- if (is.finite(flag80) && flag80 > 0) {
    as.integer(n_periods - round(flag80))
  } else {
    as.integer(n_periods)
  }
  period_start <- max(1L, min(as.integer(n_periods), period_start))
  period_end <- max(1L, min(as.integer(n_periods), period_end))
  list(start = period_start, end = period_end)
}

regional_scaling_control_notes <- function(doitall_path, n_periods, active_years) {
  # Parse generated doitall flags back into README notes to avoid drift.
  flags <- parse_doitall_parest_flags(doitall_path, 77:81)
  window <- regional_scaling_period_window(flags, n_periods)
  weight <- format_flag_value(flags[["77"]])
  cv_note <- if (identical(weight, "50")) {
    " (approximately CV 0.1)"
  } else {
    ""
  }
  c(
    paste(
      "`bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the",
      paste0("regional-scaling MVN prior with weight ", weight, cv_note, ".")
    ),
    paste(
      "The active prior window is periods",
      paste0(window$start, "-", window$end),
      paste0("(", active_years, "), derived from parest flags 79-80 for the"),
      paste0(n_periods, "-period model.")
    ),
    paste(
      "PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass",
      "with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29."
    )
  )
}

read_words <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1]]
}

replace_first_word <- function(line, value) {
  words <- read_words(line)
  words[[1]] <- value
  paste(words, collapse = " ")
}

apply_fixm_m <- function(path) {
  lines <- readLines(path, warn = FALSE)
  age_i <- grep("^# age_pars$", trimws(lines))
  if (length(age_i) != 1L) {
    stop("Expected one # age_pars block in ", path, call. = FALSE)
  }
  block <- seq.int(age_i + 1L, min(length(lines), age_i + 12L))
  words <- strsplit(trimws(lines[block]), "[[:space:]]+")
  m_row <- which(vapply(words, function(x) {
    length(x) >= 2L && identical(x[[2]], "-1") &&
      grepl("^-2[.]6(0+)?$", x[[1]])
  }, logical(1)))
  if (!length(m_row)) {
    already <- which(vapply(words, function(x) {
      length(x) >= 2L && identical(x[[1]], fixm_age_par_value) &&
        identical(x[[2]], "-1")
    }, logical(1)))
    if (!length(already)) {
      stop("Could not find FixM M row in ", path, call. = FALSE)
    }
    return(invisible(FALSE))
  }
  target <- block[[m_row[[1]]]]
  lines[[target]] <- replace_first_word(lines[[target]], fixm_age_par_value)
  writeLines(lines, path, useBytes = TRUE)
  invisible(TRUE)
}
