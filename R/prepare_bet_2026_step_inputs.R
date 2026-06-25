root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
input_repo_names <- c(
  "ofp-sam-2026-BET-YFT-frq-build",
  "ofp-sam-2026-BET-YFT-build-ini",
  "ofp-sam-2026-BET-YFT-tag-prep",
  "ofp-sam-2026-BET-YFT-age-length-build"
)
input_root_env <- Sys.getenv("BET_2026_INPUT_ROOT", "")
input_root_candidates <- if (nzchar(input_root_env)) {
  input_root_env
} else {
  c(
    file.path(dirname(root), "input-repos"),
    dirname(root),
    file.path(dirname(root), "bet_2026_input_repos")
  )
}
has_input_repos <- function(path) {
  all(dir.exists(file.path(path, input_repo_names)))
}
input_root_hit <- input_root_candidates[vapply(input_root_candidates, has_input_repos, logical(1))]
if (!length(input_root_hit)) {
  stop(
    "Could not find BET 2026 input repos. Set BET_2026_INPUT_ROOT to a folder containing: ",
    paste(input_repo_names, collapse = ", "),
    call. = FALSE
  )
}
input_root <- normalizePath(input_root_hit[[1L]], winslash = "/", mustWork = TRUE)

frq_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build", "BET")
ini_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini", "BET")
tag_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep", "BET")
age_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build", "BET")
reg_scaling_source <- file.path(frq_root, "bet.2026.reg_scaling")
reg_scaling_active_start_period <- 53L
reg_scaling_active_end_period <- 72L
reg_scaling_active_years <- "1965-1969"

fixm_age_par_value <- "-2.54917483258212e+00"

input_repo_roots <- c(
  "ofp-sam-2026-BET-YFT-frq-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build"),
  "ofp-sam-2026-BET-YFT-build-ini" = file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini"),
  "ofp-sam-2026-BET-YFT-tag-prep" = file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep"),
  "ofp-sam-2026-BET-YFT-age-length-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build")
)

git_value <- function(repo, args) {
  if (!dir.exists(file.path(repo, ".git"))) return("")
  value <- tryCatch(
    system2("git", c("-C", repo, args), stdout = TRUE, stderr = NULL),
    error = function(e) character()
  )
  if (!length(value)) "" else value[[1L]]
}

git_commit <- function(repo) {
  git_value(repo, c("rev-parse", "--short", "HEAD"))
}

git_subject <- function(repo) {
  git_value(repo, c("log", "-1", "--pretty=%s"))
}

source_commit_for_path <- function(path) {
  if (!nzchar(path)) return("")
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  input_prefix <- paste0(normalizePath(input_root, winslash = "/", mustWork = TRUE), "/")
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  if (startsWith(norm, input_prefix)) {
    parts <- strsplit(substring(norm, nchar(input_prefix) + 1L), "/", fixed = TRUE)[[1L]]
    repo <- file.path(input_root, parts[[1L]])
    return(git_commit(repo))
  }
  if (startsWith(norm, root_prefix) || grepl("^steps/", path)) {
    return(git_commit(root))
  }
  ""
}

input_repo_revision_table <- function() {
  data.frame(
    repo = names(input_repo_roots),
    commit = vapply(input_repo_roots, git_commit, character(1)),
    subject = vapply(input_repo_roots, git_subject, character(1)),
    stringsAsFactors = FALSE
  )
}

region_map_helper <- file.path(root, "R", "write_bet_region_map_assets.R")
if (file.exists(region_map_helper)) {
  source(region_map_helper, local = TRUE)
}

write_shared_region_map_assets <- function() {
  if (!exists("write_bet_region_map_assets", mode = "function")) return(invisible(FALSE))
  write_bet_region_map_assets(
    file.path(root, "assets", "maps"),
    stem = "bet-2026-five-region"
  )
  if (exists("write_bet_nine_region_map_assets", mode = "function")) {
    write_bet_nine_region_map_assets(
      file.path(root, "assets", "maps"),
      stem = "bet-2023-nine-region"
    )
  }
  invisible(TRUE)
}

write_shared_region_map_assets()

public_source_path <- function(path) {
  if (!nzchar(path)) return(path)
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  input_prefix <- paste0(normalizePath(input_root, winslash = "/", mustWork = TRUE), "/")
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

copy_if_exists <- function(from, to) {
  if (file.exists(from)) copy_one(from, to)
}

remove_model_par_files <- function(model_dir) {
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
  flags <- parse_doitall_parest_flags(doitall_path, 77:81)
  window <- regional_scaling_period_window(flags, n_periods)
  weight <- format_flag_value(flags[["77"]])
  cv_note <- if (identical(weight, "50")) {
    "; the inline control comment records this as approximately CV 0.1"
  } else {
    ""
  }
  c(
    paste(
      "`bet.reg_scaling` is read by MFCL starting in PHASE 5 because",
      paste0("`parest_flags(77)=", weight, "`; flags 77-81 configure the"),
      "regional-scaling MVN prior."
    ),
    paste0(
      "The regional-scaling penalty weight is ", weight,
      " (`parest_flags(77)=", weight, "`)", cv_note, "."
    ),
    paste(
      "The active `bet.reg_scaling` window is periods",
      paste0(window$start, "-", window$end),
      paste0("(", active_years, ") because the global CPUE"),
      "covariance matrices were estimated from data fitted over 1965 through the end of 1969, the period with the highest spatial-temporal coverage."
    ),
    paste(
      "For the", paste0(n_periods, "-period"), "full-2024 models,",
      paste0("`parest_flags(79)=", format_flag_value(flags[["79"]]), "`"),
      "means",
      paste0("`", n_periods, " - ", format_flag_value(flags[["79"]]), " + 1 = ", window$start, "`"),
      "and",
      paste0("`parest_flags(80)=", format_flag_value(flags[["80"]]), "`"),
      "means",
      paste0("`", n_periods, " - ", format_flag_value(flags[["80"]]), " = ", window$end, "`,"),
      "so the regional-scaling prior is limited to that covariance-estimation window."
    ),
    paste(
      "PHASE 1-4 retain the current CPUE_scaling setup: index fisheries",
      "29-33 share CPUE group 29, share selectivity group 25, and keep",
      "the 2026 index-fishery sigma settings."
    ),
    paste(
      "PHASE 5 switches to Prior_reg_biomass: index CPUE groups become",
      "29-33, fish flag 94 is set to 0, and index selectivity groups",
      "become 25-29."
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

frq_record_start <- function(lines) {
  age_i <- grep("age_nage", lines, fixed = TRUE)
  if (length(age_i) != 1L) stop("Expected one age_nage line", call. = FALSE)
  age_i + 2L
}

is_frq_record <- function(line) {
  grepl("^[[:space:]]*[0-9]{4}[[:space:]]", line)
}

frq_year <- function(line) {
  as.integer(read_words(line)[[1]])
}

chop_frq <- function(from, to, max_year = 2021L) {
  lines <- readLines(from, warn = FALSE)
  start <- frq_record_start(lines)
  header <- lines[seq_len(start - 1L)]
  records <- lines[start:length(lines)]
  keep <- vapply(records, function(line) {
    if (!is_frq_record(line)) return(TRUE)
    frq_year(line) <= max_year
  }, logical(1))
  records <- records[keep]
  n_records <- sum(vapply(records, is_frq_record, logical(1)))

  dline <- grep("Datasets / LFIntervals", header, fixed = TRUE)
  if (length(dline) != 1L) {
    stop("Expected one Datasets / LFIntervals line in ", from, call. = FALSE)
  }
  header[[dline + 1L]] <- replace_first_word(header[[dline + 1L]], n_records)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(header, records), to, useBytes = TRUE)
  invisible(to)
}

frq_record_fishery <- function(line) {
  words <- read_words(line)
  if (length(words) < 4L) return(NA_integer_)
  suppressWarnings(as.integer(words[[4L]]))
}

frq_record_key <- function(line) {
  words <- read_words(line)
  if (length(words) < 5L) return("")
  paste(words[1:5], collapse = "|")
}

replace_frq_index_cpue_records <- function(path, cpue_source, max_year = NA_integer_,
                                           index_fisheries = 29:33) {
  eol <- file_eol(path)
  target_lines <- readLines(path, warn = FALSE)
  source_lines <- readLines(cpue_source, warn = FALSE)

  source_records <- source_lines[vapply(source_lines, function(line) {
    if (!is_frq_record(line)) return(FALSE)
    fishery <- frq_record_fishery(line)
    year_ok <- is.na(max_year) || frq_year(line) <= max_year
    year_ok && fishery %in% index_fisheries
  }, logical(1))]
  source_keys <- vapply(source_records, frq_record_key, character(1))
  if (anyDuplicated(source_keys)) {
    dup <- source_keys[duplicated(source_keys)][[1L]]
    stop("Duplicate CPUE source frq record key in ", cpue_source, ": ", dup, call. = FALSE)
  }
  source_map <- stats::setNames(source_records, source_keys)

  replaced <- 0L
  missing <- character()
  for (i in seq_along(target_lines)) {
    if (!is_frq_record(target_lines[[i]])) next
    fishery <- frq_record_fishery(target_lines[[i]])
    if (!fishery %in% index_fisheries) next
    key <- frq_record_key(target_lines[[i]])
    if (!key %in% names(source_map)) {
      missing <- c(missing, key)
      next
    }
    target_lines[[i]] <- source_map[[key]]
    replaced <- replaced + 1L
  }
  if (length(missing)) {
    stop(
      "Missing ", length(missing), " CPUE source records in ", cpue_source,
      ". First missing key: ", missing[[1L]],
      call. = FALSE
    )
  }
  writeLines(target_lines, path, sep = eol, useBytes = TRUE)
  replaced
}

first_data_line_after <- function(lines, marker_i) {
  for (i in seq.int(marker_i + 1L, length(lines))) {
    txt <- trimws(lines[[i]])
    if (!nzchar(txt) || startsWith(txt, "#")) next
    return(i)
  }
  stop("Could not find data line after line ", marker_i, call. = FALSE)
}

tag_release_table <- function(path) {
  lines <- readLines(path, warn = FALSE)
  marker <- grep("^# *[0-9]+ +- RELEASE REGION", lines)
  if (!length(marker)) {
    stop("Could not find tag release blocks in ", path, call. = FALSE)
  }
  do.call(rbind, lapply(seq_along(marker), function(i) {
    title <- trimws(sub("^#[[:space:]]*", "", lines[[marker[[i]]]]))
    program <- sub(".*Tag_program[[:space:]]+", "", title)
    if (identical(program, title)) program <- ""
    words <- read_words(lines[[marker[[i]] + 1L]])
    if (length(words) < 3L) {
      stop("Malformed tag release row in ", path, " after line ", marker[[i]], call. = FALSE)
    }
    data.frame(
      tag_group = i,
      release_region = as.integer(words[[1L]]),
      release_year = as.integer(words[[2L]]),
      release_month = as.integer(words[[3L]]),
      tag_program = program,
      stringsAsFactors = FALSE
    )
  }))
}

ini_matrix_row_indices <- function(lines, marker) {
  idx <- which(trimws(lines) == marker)
  if (length(idx) != 1L) stop("Expected one ", marker, " block", call. = FALSE)
  comment_idx <- grep("^#", trimws(lines))
  next_comment <- comment_idx[comment_idx > idx]
  if (!length(next_comment)) stop("Could not find end of ", marker, " block", call. = FALSE)
  row_idx <- seq.int(idx + 1L, next_comment[[1L]] - 1L)
  row_idx[nzchar(trimws(lines[row_idx]))]
}

repair_tag_reporting_matrices <- function(path, tag_path,
                                          reference_ini = "",
                                          reference_tag = "") {
  markers <- c(
    "# tag fish rep",
    "# tag fish rep group flags",
    "# tag_fish_rep active flags",
    "# tag_fish_rep target",
    "# tag_fish_rep penalty"
  )
  lines <- readLines(path, warn = FALSE)
  row_counts <- vapply(markers, function(marker) {
    length(ini_matrix_row_indices(lines, marker))
  }, integer(1))
  if (length(unique(row_counts)) != 1L) {
    stop(
      "Tag reporting-rate matrices have inconsistent row counts in ",
      path, ": ", paste(paste(markers, row_counts, sep = "="), collapse = ", "),
      call. = FALSE
    )
  }

  releases <- tag_release_table(tag_path)
  expected_rows <- nrow(releases) + 1L
  current_rows <- row_counts[[1L]]
  if (current_rows == expected_rows) return("")
  if (current_rows > expected_rows) {
    stop(
      "Tag reporting-rate matrices in ", path, " have ", current_rows,
      " rows, but ", tag_path, " has ", nrow(releases),
      " release groups plus one pooled row.",
      call. = FALSE
    )
  }

  missing_rows <- expected_rows - current_rows
  if (current_rows < 2L) {
    stop("Cannot repair tag reporting-rate matrices with fewer than two rows in ", path, call. = FALSE)
  }
  existing_release_rows <- current_rows - 1L
  missing_release_groups <- releases$tag_group[seq.int(existing_release_rows + 1L, nrow(releases))]
  missing_releases <- releases[match(missing_release_groups, releases$tag_group), , drop = FALSE]
  missing_keys <- paste(
    missing_releases$tag_program,
    missing_releases$release_region,
    missing_releases$release_year,
    missing_releases$release_month,
    sep = "|"
  )

  if (!nzchar(reference_ini) || !nzchar(reference_tag) ||
      !file.exists(reference_ini) || !file.exists(reference_tag)) {
    stop(
      "Tag reporting-rate matrices in ", path, " are missing ", missing_rows,
      " rows, but no reference ini/tag was available to fill them.",
      call. = FALSE
    )
  }
  reference_releases <- tag_release_table(reference_tag)
  reference_keys <- paste(
    reference_releases$tag_program,
    reference_releases$release_region,
    reference_releases$release_year,
    reference_releases$release_month,
    sep = "|"
  )
  reference_match <- match(missing_keys, reference_keys)
  if (anyNA(reference_match)) {
    first_missing <- missing_releases[which(is.na(reference_match))[[1L]], , drop = FALSE]
    stop(
      "Could not find a reference tag reporting-rate row for missing release group ",
      first_missing$tag_group, " (", first_missing$tag_program, " region ",
      first_missing$release_region, ", ", first_missing$release_year, "-",
      first_missing$release_month, ") in ", reference_tag, ".",
      call. = FALSE
    )
  }

  for (marker in rev(markers)) {
    row_idx <- ini_matrix_row_indices(lines, marker)
    rows <- lines[row_idx]
    split_rows <- strsplit(trimws(rows), "[[:space:]]+")
    widths <- unique(lengths(split_rows))
    if (length(widths) != 1L) {
      stop("Uneven matrix width in ", path, " at ", marker, call. = FALSE)
    }
    width <- widths[[1L]]
    reference_row_idx <- ini_matrix_row_indices(readLines(reference_ini, warn = FALSE), marker)
    reference_lines <- readLines(reference_ini, warn = FALSE)
    reference_rows <- reference_lines[reference_row_idx]
    pad_rows <- reference_rows[reference_match]
    pad_widths <- unique(lengths(strsplit(trimws(pad_rows), "[[:space:]]+")))
    if (length(pad_widths) != 1L || !identical(pad_widths[[1L]], width)) {
      stop(
        "Reference matrix width does not match ", path, " at ", marker,
        " when filling missing tag reporting rows.",
        call. = FALSE
      )
    }
    new_rows <- c(rows[seq_len(length(rows) - 1L)], pad_rows, rows[[length(rows)]])
    before <- if (row_idx[[1L]] > 1L) lines[seq_len(row_idx[[1L]] - 1L)] else character()
    after_start <- row_idx[[length(row_idx)]] + 1L
    after <- if (after_start <= length(lines)) lines[after_start:length(lines)] else character()
    lines <- c(before, new_rows, after)
  }

  writeLines(lines, path, sep = file_eol(path), useBytes = TRUE)
  paste0(
    "filled ", missing_rows, " missing tag reporting-rate matrix rows before the pooled row",
    " for release groups ", compact_ints(missing_release_groups),
    " by matching tag program/region/year/month rows from ",
    basename(reference_ini)
  )
}

is_tag_flags_marker <- function(line) {
  grepl("^#[[:space:]]*tag[[:space:]]+flags[[:space:]]*$", line)
}

ensure_ini_tag_flags <- function(path, n_tag_groups, default_mixing_period = 2L,
                                 tag_path = NULL, terminal_year = NA_integer_) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep("^# ini version number$", trimws(lines))
  if (length(marker) != 1L) {
    stop("Expected one # ini version number marker in ", path, call. = FALSE)
  }
  version_i <- first_data_line_after(lines, marker)
  tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
  notes <- character()

  if (!length(tag_marker)) {
    age_marker <- grep("^# number of age classes$", trimws(lines))
    if (length(age_marker) != 1L) {
      stop("Expected one # number of age classes marker in ", path, call. = FALSE)
    }
    age_value_i <- first_data_line_after(lines, age_marker)
    flag_row <- paste(c(default_mixing_period, 1L, rep(0L, 8L)), collapse = " ")
    flag_block <- c("# tag flags", rep(flag_row, n_tag_groups))
    lines[[version_i]] <- "1007"
    lines <- c(lines[seq_len(age_value_i)], flag_block, lines[(age_value_i + 1L):length(lines)])
    notes <- c(notes, paste0(
      "inserted MFCL 1007 tag flags for ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods and reporting rates excluded during mixing"
    ))
    tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
  }

  if (length(tag_marker) != 1L) {
    stop("Expected one # tag flags block in ", path, call. = FALSE)
  }
  if (!identical(lines[[tag_marker]], "# tag flags")) {
    lines[[tag_marker]] <- "# tag flags"
    notes <- c(notes, "normalized tag flags marker")
  }
  next_comment <- which(seq_along(lines) > tag_marker & grepl("^[[:space:]]*#", lines))
  if (!length(next_comment)) {
    stop("Could not find the end of # tag flags in ", path, call. = FALSE)
  }
  flag_idx <- seq.int(tag_marker + 1L, next_comment[[1L]] - 1L)
  flag_idx <- flag_idx[nzchar(trimws(lines[flag_idx]))]
  if (length(flag_idx) < n_tag_groups) {
    missing_flags <- n_tag_groups - length(flag_idx)
    flag_row <- paste(c(default_mixing_period, 1L, rep(0L, 8L)), collapse = " ")
    insert_before <- next_comment[[1L]]
    lines <- c(
      lines[seq_len(insert_before - 1L)],
      rep(flag_row, missing_flags),
      lines[insert_before:length(lines)]
    )
    notes <- c(notes, paste0(
      "padded existing MFCL 1007 tag flags from ", length(flag_idx),
      " to ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods and reporting rates excluded during mixing"
    ))
    tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
    next_comment <- which(seq_along(lines) > tag_marker & grepl("^[[:space:]]*#", lines))
    flag_idx <- seq.int(tag_marker + 1L, next_comment[[1L]] - 1L)
    flag_idx <- flag_idx[nzchar(trimws(lines[flag_idx]))]
  }
  if (length(flag_idx) != n_tag_groups) {
    stop(
      "Expected ", n_tag_groups, " tag flag rows in ", path,
      " but found ", length(flag_idx), ".",
      call. = FALSE
    )
  }

  zero_fixed <- 0L
  terminal_fixed <- integer()
  terminal_groups <- integer()
  if (!is.na(terminal_year) && !is.null(tag_path) && file.exists(tag_path)) {
    releases <- tag_release_table(tag_path)
    terminal_groups <- releases$tag_group[releases$release_year >= terminal_year]
  }

  for (i in flag_idx) {
    words <- read_words(lines[[i]])
    if (length(words) != 10L) {
      stop("Malformed tag flag row in ", path, " at line ", i, call. = FALSE)
    }
    tag_group <- i - tag_marker
    if (as.integer(words[[1L]]) < 1L) {
      words[[1L]] <- "1"
      zero_fixed <- zero_fixed + 1L
    }
    if (tag_group %in% terminal_groups && as.integer(words[[1L]]) > 1L) {
      words[[1L]] <- "1"
      terminal_fixed <- c(terminal_fixed, tag_group)
    }
    lines[[i]] <- paste(words, collapse = " ")
  }

  if (!identical(lines[[version_i]], "1007")) {
    lines[[version_i]] <- "1007"
    notes <- c(notes, "set ini version to 1007 for explicit tag flags")
  }
  if (zero_fixed) {
    notes <- c(notes, paste0(
      "raised ", zero_fixed,
      " zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0"
    ))
  }
  if (length(terminal_fixed)) {
    notes <- c(notes, paste0(
      "set terminal-year tag release groups ",
      paste(terminal_fixed, collapse = ","),
      " to 1 mixing period so chopped terminal-year models do not exceed the terminal period"
    ))
  }
  if (length(notes)) {
    writeLines(lines, path, sep = eol, useBytes = TRUE)
    return(paste(notes, collapse = "; "))
  }
  invisible("")
}

ensure_ini_tag_shed_rates <- function(path, n_tag_groups) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep(
    "^#[[:space:]]*tag[[:space:]]+shed[[:space:]]+rate[[:space:]]*$",
    trimws(lines)
  )
  if (length(marker) != 1L) {
    stop("Expected one # tag shed rate block in ", path, call. = FALSE)
  }
  value_i <- first_data_line_after(lines, marker)
  values <- read_words(lines[[value_i]])
  if (length(values) == n_tag_groups) return(invisible(""))

  old_count <- length(values)
  note <- ""
  if (old_count < n_tag_groups) {
    values <- c(values, rep("0", n_tag_groups - old_count))
    note <- paste0(
      "padded tag shed-rate vector from ", old_count, " to ",
      n_tag_groups, " release groups with zero shed rates"
    )
  } else {
    extra <- values[seq.int(n_tag_groups + 1L, old_count)]
    if (any(suppressWarnings(as.numeric(extra)) != 0)) {
      stop(
        "Tag shed-rate vector in ", path, " has ", old_count,
        " values for ", n_tag_groups,
        " release groups, and the extra values are not all zero.",
        call. = FALSE
      )
    }
    values <- values[seq_len(n_tag_groups)]
    note <- paste0(
      "trimmed tag shed-rate vector from ", old_count, " to ",
      n_tag_groups, " release groups"
    )
  }

  lines[[value_i]] <- paste(values, collapse = " ")
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  note
}

frq_header_counts <- function(lines, path = "<frq>") {
  header_i <- grep("^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+", lines)
  if (!length(header_i)) {
    stop("Could not find MFCL frq header counts in ", path, call. = FALSE)
  }
  words <- read_words(lines[[header_i[[1L]]]])
  if (length(words) < 4L) {
    stop("Malformed MFCL frq header counts in ", path, call. = FALSE)
  }
  list(
    n_regions = as.integer(words[[1L]]),
    n_fisheries = as.integer(words[[2L]]),
    n_tag_groups = as.integer(words[[4L]])
  )
}

set_frq_tag_group_count <- function(path, n_tag_groups) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  header_i <- grep("^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+", lines)
  if (!length(header_i)) {
    stop("Could not find MFCL frq header counts in ", path, call. = FALSE)
  }
  words <- read_words(lines[[header_i[[1L]]]])
  if (length(words) < 4L) {
    stop("Malformed MFCL frq header counts in ", path, call. = FALSE)
  }
  if (identical(as.integer(words[[4L]]), as.integer(n_tag_groups))) {
    return(invisible(FALSE))
  }
  words[[4L]] <- as.character(as.integer(n_tag_groups))
  lines[[header_i[[1L]]]] <- paste(words, collapse = " ")
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

file_eol <- function(path) {
  size <- file.info(path)$size
  if (is.na(size) || size <= 1L) return("\n")
  raw <- readBin(path, what = "raw", n = size)
  bytes <- as.integer(raw)
  if (any(bytes[-length(bytes)] == 13L & bytes[-1L] == 10L)) "\r\n" else "\n"
}

tag_group_count_from_tag <- function(path) {
  lines <- readLines(path, warn = FALSE)
  header <- grep("^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+", lines)
  if (!length(header)) {
    stop("Could not find tag release-group header in ", path, call. = FALSE)
  }
  count <- suppressWarnings(as.integer(read_words(lines[[header[[1L]]]])[[1L]]))
  if (!is.finite(count) || count < 1L) {
    stop("Malformed tag release-group count in ", path, call. = FALSE)
  }
  count
}

ensure_ini_1007_compatibility <- function(path, tag_path, total_population_scalar = 25L,
                                          default_mixing_period = 2L) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  notes <- character()

  version_marker <- grep("^# ini version number$", trimws(lines))
  if (length(version_marker) != 1L) {
    stop("Expected one # ini version number marker in ", path, call. = FALSE)
  }
  version_i <- first_data_line_after(lines, version_marker)
  if (!identical(trimws(lines[[version_i]]), "1007")) {
    lines[[version_i]] <- "1007"
    notes <- c(notes, "set ini version to 1007")
  }

  n_tag_groups <- tag_group_count_from_tag(tag_path)
  tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
  if (!length(tag_marker)) {
    age_marker <- grep("^# number of age classes$", trimws(lines))
    if (length(age_marker) != 1L) {
      stop("Expected one # number of age classes marker in ", path, call. = FALSE)
    }
    age_value_i <- first_data_line_after(lines, age_marker)
    flag_row <- paste(c(default_mixing_period, 1L, rep(0L, 8L)), collapse = " ")
    lines <- c(
      lines[seq_len(age_value_i)],
      "# tag flags",
      rep(flag_row, n_tag_groups),
      lines[(age_value_i + 1L):length(lines)]
    )
    notes <- c(notes, paste0(
      "inserted MFCL 1007 tag flags for ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods and reporting rates excluded during mixing"
    ))
  }

  shed_marker <- grep("^#[[:space:]]*tag[[:space:]]+shed[[:space:]]+rate[[:space:]]*$", trimws(lines))
  if (!length(shed_marker)) {
    rep_marker <- grep("^# tag fish rep$", trimws(lines))
    if (length(rep_marker) != 1L) {
      stop("Expected one # tag fish rep marker in ", path, call. = FALSE)
    }
    lines <- c(
      lines[seq_len(rep_marker - 1L)],
      "# tag shed rate",
      paste(rep("0", n_tag_groups), collapse = " "),
      lines[rep_marker:length(lines)]
    )
    notes <- c(notes, paste0("inserted zero tag shed-rate vector for ", n_tag_groups, " release groups"))
  }

  total_marker <- grep("^#[[:space:]]*Total population scaling factor [(]LN[(]R0[)][)]$", trimws(lines))
  if (!length(total_marker)) {
    mort_marker <- grep("^# natural mortality [(]per year[)]$", trimws(lines))
    if (length(mort_marker) != 1L) {
      stop("Expected one # natural mortality (per year) marker in ", path, call. = FALSE)
    }
    lines <- c(
      lines[seq_len(mort_marker - 1L)],
      "# Total population scaling factor (LN(R0))",
      as.character(as.integer(total_population_scalar)),
      lines[mort_marker:length(lines)]
    )
    notes <- c(notes, paste0(
      "inserted MFCL 1007 total-population scalar default ",
      as.integer(total_population_scalar)
    ))
  }

  richards_marker <- grep("^#[[:space:]]*Richards$", trimws(lines))
  if (!length(richards_marker)) {
    k_marker <- grep("^# K [(]per year[)]$", trimws(lines))
    if (length(k_marker) != 1L) {
      stop("Expected one # K (per year) marker in ", path, call. = FALSE)
    }
    k_value_i <- first_data_line_after(lines, k_marker)
    lines <- c(
      lines[seq_len(k_value_i)],
      "# Richards",
      "0",
      lines[(k_value_i + 1L):length(lines)]
    )
    notes <- c(notes, "inserted MFCL 1007 Richards growth parameter default 0")
  }

  if (length(notes)) {
    writeLines(lines, path, sep = eol, useBytes = TRUE)
  }
  paste(notes, collapse = "; ")
}

ensure_frq_fishery_region_locations <- function(path, index_regions = 1:5) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  counts <- frq_header_counts(lines, path)
  marker <- grep("Region in which each fishery is located", lines, fixed = TRUE)
  if (length(marker) != 1L) {
    stop("Expected one fishery-region line marker in ", path, call. = FALSE)
  }
  location_i <- first_data_line_after(lines, marker)
  values <- read_words(lines[[location_i]])
  if (length(values) == counts$n_fisheries) {
    return(invisible(FALSE))
  }
  if (length(values) + length(index_regions) != counts$n_fisheries) {
    stop(
      "Fishery-region count mismatch in ", path, ": found ", length(values),
      " values for ", counts$n_fisheries, " fisheries.",
      call. = FALSE
    )
  }
  if (counts$n_regions != length(index_regions)) {
    stop(
      "Cannot infer index fishery regions for ", path, ": found ",
      counts$n_regions, " regions but ", length(index_regions),
      " index region codes were provided.",
      call. = FALSE
    )
  }
  lines[[location_i]] <- paste(c(values, as.character(index_regions)), collapse = " ")
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

frq_dataset_shape <- function(lines, path = "<frq>") {
  dline <- grep("Datasets / LFIntervals", lines, fixed = TRUE)
  if (length(dline) != 1L) {
    stop("Expected one Datasets / LFIntervals line in ", path, call. = FALSE)
  }
  words <- read_words(lines[[dline + 1L]])
  if (length(words) < 6L) {
    stop("Malformed Datasets / LFIntervals line in ", path, call. = FALSE)
  }
  list(
    n_lf = as.integer(words[[2L]]),
    n_wf = as.integer(words[[6L]])
  )
}

normalize_frq_absent_lf_records <- function(path) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  shape <- frq_dataset_shape(lines, path)
  start <- frq_record_start(lines)
  both_len <- 7L + shape$n_lf + shape$n_wf
  lf_only_len <- 8L + shape$n_lf
  wf_only_len <- 8L + shape$n_wf
  no_comp_len <- 9L
  changed <- 0L

  for (i in seq.int(start, length(lines))) {
    if (!is_frq_record(lines[[i]])) next
    words <- read_words(lines[[i]])
    if (!identical(words[[8L]], "-1")) next

    if (length(words) == both_len) {
      # The first LF bin is already the absent-LF sentinel (-1). Drop the stray
      # remaining LF bins so MFCL reads the following WF bins as one record.
      words <- c(words[1:8], words[(8L + shape$n_lf):length(words)])
      expected_len <- wf_only_len
    } else if (length(words) == lf_only_len) {
      # Same issue, but with no WF block after the stray LF bins.
      words <- c(words[1:8], words[[length(words)]])
      expected_len <- no_comp_len
    } else {
      next
    }

    if (length(words) != expected_len) {
      stop("Unexpected normalized record length in ", path, " at line ", i, call. = FALSE)
    }
    lines[[i]] <- paste(words, collapse = " ")
    changed <- changed + 1L
  }

  if (changed) {
    writeLines(lines, path, sep = eol, useBytes = TRUE)
  }
  invisible(changed)
}

format_mfcl_number <- function(x) {
  format(x, digits = 15L, scientific = FALSE, trim = TRUE)
}

effort_creep_multiplier <- function(year, base_year = 1952L,
                                    transition_year = 1976L,
                                    early_rate = 0.01,
                                    late_rate = 0.005) {
  early_years <- pmax(0L, pmin(year, transition_year) - base_year)
  late_years <- pmax(0L, year - transition_year)
  1 + early_rate * early_years + late_rate * late_years
}

write_frq_with_effort_creep <- function(from, to, index_fisheries = 29:33,
                                        base_year = 1952L,
                                        transition_year = 1976L,
                                        early_rate = 0.01,
                                        late_rate = 0.005) {
  lines <- readLines(from, warn = FALSE)
  for (i in seq_along(lines)) {
    if (!is_frq_record(lines[[i]])) next
    words <- read_words(lines[[i]])
    if (length(words) < 6L) next
    fishery <- as.integer(words[[4]])
    if (!fishery %in% index_fisheries) next
    effort <- suppressWarnings(as.numeric(words[[6]]))
    if (is.na(effort) || effort <= 0) next
    year <- as.integer(words[[1]])
    creep_multiplier <- effort_creep_multiplier(
      year,
      base_year = base_year,
      transition_year = transition_year,
      early_rate = early_rate,
      late_rate = late_rate
    )
    words[[6]] <- format_mfcl_number(effort * creep_multiplier)
    lines[[i]] <- paste(words, collapse = " ")
  }
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, to, useBytes = TRUE)
  invisible(to)
}

extract_ini_matrix <- function(path, marker) {
  lines <- readLines(path, warn = FALSE)
  idx <- grep(paste0("^", marker, "$"), trimws(lines))
  if (length(idx) != 1L) stop("Expected one ", marker, " in ", path, call. = FALSE)
  comment_idx <- grep("^#", trimws(lines))
  end <- comment_idx[comment_idx > idx][[1]] - 1L
  mat_lines <- lines[(idx + 1L):end]
  mat_lines <- mat_lines[nzchar(trimws(mat_lines))]
  rows <- strsplit(trimws(mat_lines), "[[:space:]]+")
  ncols <- unique(lengths(rows))
  if (length(ncols) != 1L) {
    stop("Uneven matrix width in ", path, " at ", marker, call. = FALSE)
  }
  matrix(as.numeric(unlist(rows)), ncol = ncols, byrow = TRUE)
}

parse_tag_release_map <- function(path) {
  lines <- readLines(path, warn = FALSE)
  release_header <- grep("#[[:space:]]+[0-9]+ - RELEASE REGION", lines)
  out <- lapply(release_header, function(i) {
    title <- trimws(sub("^#[[:space:]]*", "", lines[[i]]))
    group <- as.integer(sub("^([0-9]+).*", "\\1", title))
    program <- sub(".*Tag_program[[:space:]]+", "", title)
    vals <- read_words(lines[[i + 1L]])
    data.frame(
      release_group = group,
      release_region = as.integer(vals[[1]]),
      release_year = as.integer(vals[[2]]),
      release_month = as.integer(vals[[3]]),
      tag_program = program,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

compact_ints <- function(x) {
  x <- sort(unique(as.integer(x)))
  x <- x[!is.na(x)]
  if (!length(x)) return("")
  breaks <- c(TRUE, diff(x) != 1L)
  starts <- x[breaks]
  ends <- c(x[which(breaks)[-1L] - 1L], x[length(x)])
  paste(ifelse(starts == ends, starts, paste0(starts, "-", ends)), collapse = ",")
}

format_unique_values <- function(x) {
  x <- unique(as.vector(x))
  x <- x[!is.na(x)]
  if (!length(x)) return("")
  paste(format(x, digits = 10L, scientific = FALSE, trim = TRUE), collapse = ",")
}

write_generated_tag_rep_map <- function(model_dir) {
  ini <- file.path(model_dir, "bet.ini")
  tag <- file.path(model_dir, "bet.tag")
  flags <- extract_ini_matrix(ini, "# tag fish rep group flags")
  fishery_env <- new.env(parent = baseenv())
  fishery_map_path <- file.path(model_dir, "fishery_map.R")
  if (file.exists(fishery_map_path)) {
    sys.source(fishery_map_path, envir = fishery_env)
  }
  fishery_map <- fishery_env$fishery_map
  if (is.null(fishery_map)) {
    fishery_map <- data.frame(
      fishery = seq_len(ncol(flags)),
      fishery_name = paste0("fishery-", seq_len(ncol(flags))),
      stringsAsFactors = FALSE
    )
  }
  rep_init <- extract_ini_matrix(ini, "# tag fish rep")
  active_flags <- extract_ini_matrix(ini, "# tag_fish_rep active flags")
  rep_target <- extract_ini_matrix(ini, "# tag_fish_rep target")
  rep_penalty <- extract_ini_matrix(ini, "# tag_fish_rep penalty")
  matrix_dims <- vapply(
    list(rep_init, flags, active_flags, rep_target, rep_penalty),
    function(x) paste(dim(x), collapse = "x"),
    character(1)
  )
  if (length(unique(matrix_dims)) != 1L) {
    stop("Tag reporting-rate matrices have inconsistent dimensions in ", ini, call. = FALSE)
  }
  releases <- parse_tag_release_map(tag)
  if (nrow(flags) != nrow(releases) + 1L) {
    stop(
      "Tag reporting matrix in ", ini, " has ", nrow(flags),
      " rows, but ", tag, " has ", nrow(releases),
      " release groups and requires one pooled row (expected ",
      nrow(releases) + 1L, ").",
      call. = FALSE
    )
  }
  release_event_rows <- nrow(releases)
  event_rows <- data.frame(
    tag_event_row = seq_len(nrow(flags)),
    event_type = ifelse(seq_len(nrow(flags)) <= release_event_rows, "release", "pooled"),
    release_group = c(
      releases$release_group,
      NA_integer_
    ),
    stringsAsFactors = FALSE
  )
  groups <- sort(unique(as.integer(flags)))
  groups <- groups[!is.na(groups)]
  group_rows <- lapply(groups, function(g) {
    pos <- which(flags == g, arr.ind = TRUE)
    idx <- flags == g
    fishery_ids <- sort(unique(pos[, "col"]))
    fishery_matches <- match(fishery_ids, fishery_map$fishery)
    fishery_names <- fishery_map$fishery_name[fishery_matches]
    fishery_names <- fishery_names[!is.na(fishery_names)]
    tag_group_names <- if ("tag_recapture_name" %in% names(fishery_map)) {
      unique(fishery_map$tag_recapture_name[fishery_matches])
    } else character()
    tag_group_names <- tag_group_names[!is.na(tag_group_names)]
    release_rows <- sort(unique(pos[, "row"][pos[, "row"] <= release_event_rows]))
    release_subset <- releases[release_rows, , drop = FALSE]
    pooled <- any(pos[, "row"] > release_event_rows)
    programs <- unique(c(release_subset$tag_program, if (pooled) "pooled"))
    programs <- programs[nzchar(programs)]
    program_label <- paste(programs, collapse = "/")
    fishery_label <- if (length(tag_group_names)) {
      paste(tag_group_names, collapse = "/")
    } else {
      paste(fishery_ids, collapse = ",")
    }
    data.frame(
      tag_rep_group = g,
      tag_rep_name = paste0("group-", g, ": ", program_label, " / ", fishery_label),
      fisheries = compact_ints(pos[, "col"]),
      fishery_names = paste(fishery_names, collapse = "; "),
      tag_recapture_names = paste(tag_group_names, collapse = "; "),
      event_rows = compact_ints(pos[, "row"]),
      release_groups = compact_ints(release_rows),
      tag_programs = program_label,
      release_regions = compact_ints(release_subset$release_region),
      release_years = compact_ints(release_subset$release_year),
      active = any(active_flags[idx] != 0),
      initial_values = format_unique_values(rep_init[idx]),
      target_values = format_unique_values(rep_target[idx]),
      penalty_values = format_unique_values(rep_penalty[idx]),
      stringsAsFactors = FALSE
    )
  })
  tag_rep <- do.call(rbind, group_rows)

  out <- c(
    "# Generated by R/prepare_bet_2026_step_inputs.R from bet.ini and bet.tag.",
    "# Tag reporting-rate matrices follow the MFCL manual and SAM 12 June 2026 presentation.",
    "# Audit lookup only: MFCL reads these reporting-rate matrices from bet.ini.",
    "# Rows are tag release/reporting events available in the ini matrices; columns are fisheries.",
    sprintf(
      "tag_rep_matrix <- matrix(c(%s), nrow = %d, ncol = %d, byrow = TRUE)",
      paste(as.integer(t(flags)), collapse = ", "),
      nrow(flags),
      ncol(flags)
    ),
    "",
    sprintf(
      "tag_rep_active_matrix <- matrix(c(%s), nrow = %d, ncol = %d, byrow = TRUE)",
      paste(as.integer(t(active_flags)), collapse = ", "),
      nrow(active_flags),
      ncol(active_flags)
    ),
    "",
    paste0("tag_rep_map <- ", paste(deparse(tag_rep), collapse = "\n")),
    "",
    paste0("tag_release_map <- ", paste(deparse(releases), collapse = "\n")),
    "",
    paste0("tag_event_map <- ", paste(deparse(event_rows), collapse = "\n")),
    ""
  )
  writeLines(out, file.path(model_dir, "tag_rep_map.R"), useBytes = TRUE)
}

write_manifest <- function(step_dir, entries) {
  manifest <- do.call(rbind, lapply(entries, function(x) {
    data.frame(
      role = x$role,
      file = x$file,
      source = public_source_path(x$source),
      source_commit = source_commit_for_path(x$source),
      note = x$note,
      stringsAsFactors = FALSE
    )
  }))
  write.csv(manifest, file.path(step_dir, "input_manifest.csv"), row.names = FALSE)
}

write_readme <- function(step_dir, title, summary, bullets, inputs, controls,
                         outstanding = character(), status,
                         run_notes = character(),
                         source_revisions = NULL) {
  bullet_lines <- paste0("- ", bullets)
  input_lines <- paste0("- `", names(inputs), "`: ", unname(inputs))
  source_revision_lines <- if (is.data.frame(source_revisions) && nrow(source_revisions)) {
    c(
      "",
      "## Source Revisions",
      "",
      paste0(
        "- `", source_revisions$repo, "`: `", source_revisions$commit, "`",
        ifelse(nzchar(source_revisions$subject), paste0(" - ", source_revisions$subject), "")
      )
    )
  } else {
    character()
  }
  control_lines <- paste0("- ", controls)
  run_note_lines <- if (length(run_notes)) {
    c("", "## Run Note", "", paste0("- ", run_notes))
  } else {
    character()
  }
  outstanding_lines <- if (length(outstanding)) {
    paste0("- ", outstanding)
  } else {
    "- No extra unresolved build items for this transition beyond fitting diagnostics."
  }
  lines <- c(
    paste0("# ", title),
    "",
    summary,
    "",
    "## What Changed",
    "",
    bullet_lines,
    "",
    "## Inputs",
    "",
    input_lines,
    source_revision_lines,
    "",
    "## Control Notes",
    "",
    control_lines,
    run_note_lines,
    "",
    "## Outstanding Checks",
    "",
    outstanding_lines,
    "",
    "## Status",
    "",
    status
  )
  writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
}

replace_one_line <- function(lines, pattern, replacement) {
  hit <- grep(pattern, lines)
  if (length(hit) != 1L) {
    stop("Expected one doitall line matching: ", pattern, call. = FALSE)
  }
  lines[[hit]] <- replacement
  lines
}

apply_size_based_selectivity <- function(lines) {
  replace_one_line(
    lines,
    "^[[:space:]]*-999[[:space:]]+26[[:space:]]+2[[:space:]]",
    "  -999 26 3  # use length-based selectivity"
  )
}

apply_opr <- function(lines, year_effect = 69L, season_effect = 1L,
                      region_effect = 50L, region_season_effect = 50L,
                      terminal_year_constraint = 2L) {
  phase3 <- grep("^[[:space:]]*2[[:space:]]+70[[:space:]]+1[[:space:]]", lines)
  if (length(phase3) != 1L) {
    stop("Expected one phase-3 recruitment flag block for OPR", call. = FALSE)
  }
  old_block <- lines[phase3:(phase3 + 2L)]
  expected <- c("2[[:space:]]+70[[:space:]]+1",
                "2[[:space:]]+71[[:space:]]+1",
                "2[[:space:]]+178[[:space:]]+1")
  if (!all(mapply(grepl, expected, old_block))) {
    stop("Unexpected phase-3 recruitment flag block for OPR", call. = FALSE)
  }
  new_block <- c(
    "# OPR settings. BET OPR screening rank-1 model: 69-01-50-50.",
    "  1 149 0   # turn off recruitment-deviation penalty for OPR",
    "  1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR",
    "  1 400 0   # clear fixed terminal recruitment-deviate block for OPR",
    "  2 177 0   # turn off old total-pop scaling for OPR",
    "  2 32 0    # turn off overall population scaling parameter for OPR",
    "  2 113 0   # keep scaling init pop off during OPR transfer",
    sprintf("  1 155 %d  # orthogonal polynomial recruitment - year effect", year_effect),
    sprintf("  1 217 %d   # orthogonal polynomial recruitment - season effect", season_effect),
    sprintf("  1 216 %d  # orthogonal polynomial recruitment - region effect", region_effect),
    sprintf("  1 218 %d  # orthogonal polynomial recruitment - region-season interaction effect", region_season_effect),
    sprintf("  1 202 %d   # OPR end window: last %d real years use lower-degree/constant-end basis", terminal_year_constraint, terminal_year_constraint),
    "  1 210 0   # OPR region end window: 0 inherits parest_flag(202)",
    "  1 212 0   # OPR season end window: 0 inherits parest_flag(202)",
    "  1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)",
    "  2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients",
    "  2 70 0    # turn off mean+deviate regional recruitment time series",
    "  2 71 0    # turn off regional recruitment distribution deviations",
    "  2 178 0   # turn off regional recruitment sum-product constraint",
    "  -100000 1 0  # turn off time-invariant recruitment distribution, region 1",
    "  -100000 2 0  # turn off time-invariant recruitment distribution, region 2",
    "  -100000 3 0  # turn off time-invariant recruitment distribution, region 3",
    "  -100000 4 0  # turn off time-invariant recruitment distribution, region 4",
    "  -100000 5 0  # turn off time-invariant recruitment distribution, region 5"
  )
  lines <- c(lines[seq_len(phase3 - 1L)], new_block, lines[(phase3 + 3L):length(lines)])

  phase3_cmd <- grep("<<PHASE3$", lines)
  phase3_end <- grep("^PHASE3$", lines)
  if (length(phase3_cmd) != 1L || length(phase3_end) != 1L || phase3_cmd >= phase3_end) {
    stop("Expected exactly one PHASE3 block after OPR insertion", call. = FALSE)
  }
  phase3_eval <- phase3_cmd + grep(
    "^[[:space:]]*1[[:space:]]+1[[:space:]]+[0-9]+([[:space:]]|$)",
    lines[(phase3_cmd + 1L):(phase3_end - 1L)]
  )
  if (length(phase3_eval) != 1L) {
    stop("Expected one PHASE3 function-evaluation line for OPR", call. = FALSE)
  }
  lines[[phase3_eval]] <- "  1 1 500  # function evaluations from the OPR screening doitall example"

  region_flags <- grep("^[[:space:]]*-100000[[:space:]]+[1-5][[:space:]]+1([[:space:]]|$)", lines)
  if (!length(region_flags)) {
    stop("Expected time-invariant recruitment distribution flags", call. = FALSE)
  }
  for (i in region_flags) {
    words <- read_words(lines[[i]])
    words[[3]] <- "0"
    lines[[i]] <- paste0("  ", paste(words, collapse = " "))
  }
  lines
}

apply_data_weighting <- function(lines) {
  lf <- grep("-999 49 20", lines, fixed = TRUE)
  wf <- grep("-999 50 20", lines, fixed = TRUE)
  if (length(lf) != 1L || length(wf) != 1L) {
    stop("Expected one global LF and WF divisor line", call. = FALSE)
  }
  lines[[lf]] <- sub("-999 49 20", "-999 49 40", lines[[lf]], fixed = TRUE)
  lines[[wf]] <- sub("-999 50 20", "-999 50 40", lines[[wf]], fixed = TRUE)
  lines[[lf]] <- sub("divide LF sample sizes by 20", "divide LF sample sizes by 40", lines[[lf]], fixed = TRUE)
  lines[[wf]] <- sub("divide WF sample sizes by 20", "divide WF sample sizes by 40", lines[[wf]], fixed = TRUE)
  lines
}

apply_regional_scaling_phase5 <- function(lines, weight = 50L,
                                          use_mean = TRUE,
                                          use_mvn = TRUE,
                                          periods_from_end = 240L,
                                          end_periods_from_end = 220L,
                                          start_period = 53L,
                                          end_period = 72L) {
  if (any(grepl("Regional-scaling MVN prior.", lines, fixed = TRUE))) {
    return(lines)
  }
  if (any(grepl("^[[:space:]]*1[[:space:]]+77[[:space:]]+", lines))) {
    stop("Regional-scaling flags already exist before the PHASE 5 insert", call. = FALSE)
  }
  start <- grep("<<PHASE5", lines, fixed = TRUE)
  if (length(start) != 1L) {
    stop("Expected one PHASE5 heredoc start before inserting regional scaling flags", call. = FALSE)
  }
  end <- which(seq_along(lines) > start & trimws(lines) == "PHASE5")
  if (length(end) != 1L) {
    stop("Expected one PHASE5 heredoc end before inserting regional scaling flags", call. = FALSE)
  }
  block <- c(
    "# Regional-scaling MVN prior.",
    "# PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass.",
    "# Ungroup index CPUE likelihood and remove grouped-sigma override.",
    "  -29 99 29  -29 94 0  # Index R1",
    "  -30 99 30  -30 94 0  # Index R2",
    "  -31 99 31  -31 94 0  # Index R3",
    "  -32 99 32  -32 94 0  # Index R4",
    "  -33 99 33  -33 94 0  # Index R5",
    "# Ungroup index selectivity for the regional-scaling prior.",
    "  -29 24 25  # Index R1",
    "  -30 24 26  # Index R2",
    "  -31 24 27  # Index R3",
    "  -32 24 28  # Index R4",
    "  -33 24 29  # Index R5",
    "# MFCL reads bet.reg_scaling when parest flag 77 is > 0.",
    sprintf("  1 77 %d   # MVN regional-scaling penalty weight; CV about 0.1", as.integer(weight)),
    sprintf("  1 78 %d    # use mean regional-scaling target", as.integer(isTRUE(use_mean))),
    sprintf(
      "  1 79 %d  # start regional-scaling prior at period %d; 1965-1969 CPUE covariance window",
      as.integer(periods_from_end),
      as.integer(start_period)
    ),
    sprintf(
      "  1 80 %d  # end regional-scaling prior at period %d; 1965-1969 CPUE covariance window",
      as.integer(end_periods_from_end),
      as.integer(end_period)
    ),
    sprintf("  1 81 %d    # use multivariate-normal regional-scaling penalty", as.integer(isTRUE(use_mvn)))
  )
  c(lines[seq_len(end - 1L)], block, lines[end:length(lines)])
}

apply_regional_index_selectivity_map <- function(path) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  if (any(grepl("Regional-scaling Prior_reg_biomass variants unshare index selectivity", lines, fixed = TRUE))) {
    return(invisible(FALSE))
  }
  marker <- grep(
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]",
    lines,
    fixed = TRUE
  )
  if (length(marker) != 1L) {
    stop("Expected one selectivity-name assignment in ", path, call. = FALSE)
  }
  block <- c(
    "",
    "# Regional-scaling Prior_reg_biomass variants unshare index selectivity groups.",
    "# In doitall this switch starts in PHASE 5; PHASE 1-4 retain the",
    "# current CPUE_scaling setup with one shared index selectivity group.",
    "fishery_map$selectivity_group[29:33] <- 25:29",
    "selectivity_names[25:29] <- paste0(\"Index R\", 1:5)",
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]"
  )
  lines <- c(lines[seq_len(marker)], block, lines[(marker + 1L):length(lines)])
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

apply_phase10_11_convergence_switch <- function(lines) {
  block <- c(
    "",
    "phase10_11_convergence=${BET_PHASE10_11_CONVERGENCE:--3}",
    "case \"$phase10_11_convergence\" in",
    "  -[0-9]|-[0-9][0-9]|[0-9]|[0-9][0-9]) ;;",
    "  *)",
    "    echo \"BET_PHASE10_11_CONVERGENCE must be numeric, e.g. -3 for quick runs or -5 for strict runs.\" >&2",
    "    exit 1",
    "    ;;",
    "esac",
    "echo \"PHASE 10/11 convergence criterion: $phase10_11_convergence\""
  )
  if (!any(grepl("^phase10_11_convergence=", lines))) {
    guard_start <- grep("^if \\[ -z \"\\$program_path\" \\]; then$", lines)
    if (length(guard_start) != 1L) {
      stop("Expected one PROGRAM_PATH guard in doitall.sh", call. = FALSE)
    }
    guard_end <- which(seq_along(lines) > guard_start & trimws(lines) == "fi")
    if (!length(guard_end)) {
      stop("Expected PROGRAM_PATH guard terminator in doitall.sh", call. = FALSE)
    }
    lines <- append(lines, block, after = guard_end[[1]])
  }

  replace_phase <- function(lines, phase) {
    start <- grep(paste0("<<PHASE", phase), lines, fixed = TRUE)
    if (length(start) != 1L) {
      stop("Expected one PHASE", phase, " heredoc start in doitall.sh", call. = FALSE)
    }
    end <- which(seq_along(lines) > start & trimws(lines) == paste0("PHASE", phase))
    if (length(end) != 1L) {
      stop("Expected one PHASE", phase, " heredoc end in doitall.sh", call. = FALSE)
    }
    block_i <- seq.int(start, end)
    hit <- block_i[grepl("^[[:space:]]*1[[:space:]]+50[[:space:]]+", lines[block_i])]
    if (length(hit) != 1L) {
      stop("Expected one convergence line in PHASE", phase, " of doitall.sh", call. = FALSE)
    }
    lines[[hit]] <-
      "  1 50 $phase10_11_convergence  # convergence criteria; default quick -3, set BET_PHASE10_11_CONVERGENCE=-5 for strict"
    lines
  }

  lines <- replace_phase(lines, 10L)
  lines <- replace_phase(lines, 11L)
  lines
}

write_doitall <- function(from, to, mix_from_ini = FALSE,
                          size_based_selectivity = FALSE,
                          opr = FALSE,
                          data_weighting = FALSE,
                          regional_scaling = FALSE,
                          regional_scaling_periods = 292L,
                          regional_scaling_start_period = reg_scaling_active_start_period,
                          regional_scaling_end_period = reg_scaling_active_end_period) {
  lines <- readLines(from, warn = FALSE)
  if (!any(grepl("^set -eu$", lines))) {
    lines <- append(lines, "set -eu", after = 1L)
  }
  lines <- apply_phase10_11_convergence_switch(lines)
  if (isTRUE(mix_from_ini)) {
    target <- grep("-9999 1 2", lines, fixed = TRUE)
    if (length(target)) {
      lines[[target[[1]]]] <-
        "# Mixing periods are read from bet.ini tag flags for this step."
    }
  }
  if (isTRUE(size_based_selectivity)) {
    lines <- apply_size_based_selectivity(lines)
  }
  if (isTRUE(opr)) {
    lines <- apply_opr(lines)
  }
  if (isTRUE(data_weighting)) {
    lines <- apply_data_weighting(lines)
  }
  if (isTRUE(regional_scaling)) {
    lines <- apply_regional_scaling_phase5(
      lines,
      periods_from_end = regional_scaling_periods - regional_scaling_start_period + 1L,
      end_periods_from_end = regional_scaling_periods - regional_scaling_end_period,
      start_period = regional_scaling_start_period,
      end_period = regional_scaling_end_period
    )
  }
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
}

make_step <- function(step_id, frq_source, ini_source, tag_source, age_source,
                      frq_chop_year = NA_integer_, mix_from_ini = FALSE,
                      frq_tag_groups = NA_integer_,
                      frq_transform = NULL, index_cpue_source = "",
                      doitall_edits = list(),
                      reg_scaling_source = "",
                      title, summary, bullets, input_notes, control_notes,
                      run_notes = character(),
                      outstanding = character(),
                      status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  remove_model_par_files(model_dir)

  frq_out <- file.path(model_dir, "bet.frq")
  if (identical(frq_transform, "effort_creep")) {
    if (!is.na(frq_chop_year)) {
      stop("Effort-creep transform is only implemented for full-year frq files", call. = FALSE)
    }
    write_frq_with_effort_creep(frq_source, frq_out)
    frq_note <- "copied with agreed effort-creep multiplier applied to index fisheries 29-33: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024"
  } else if (is.na(frq_chop_year)) {
    copy_one(frq_source, frq_out)
    frq_note <- "copied without year chopping"
  } else {
    chop_frq(frq_source, frq_out, max_year = frq_chop_year)
    frq_note <- paste0("chopped to records with year <= ", frq_chop_year)
  }
  if (nzchar(index_cpue_source)) {
    replaced_cpue <- replace_frq_index_cpue_records(
      frq_out,
      index_cpue_source,
      max_year = frq_chop_year,
      index_fisheries = 29:33
    )
    frq_note <- paste0(
      frq_note,
      "; replaced ", replaced_cpue,
      " CPUE/index records for fisheries 29-33 with records from ",
      basename(index_cpue_source)
    )
  }
  n_normalized <- normalize_frq_absent_lf_records(frq_out)
  if (n_normalized) {
    frq_note <- paste0(
      frq_note,
      "; normalized ", n_normalized,
      " records with stray absent-LF bins"
    )
  }
  fixed_fishery_regions <- ensure_frq_fishery_region_locations(frq_out)
  if (isTRUE(fixed_fishery_regions)) {
    frq_note <- paste0(
      frq_note,
      "; completed the fishery-region location line for all fisheries, including index fisheries"
    )
  }
  if (!is.na(frq_tag_groups) && set_frq_tag_group_count(frq_out, frq_tag_groups)) {
    frq_note <- paste0(
      frq_note,
      "; reset frq tag-group header to ", frq_tag_groups,
      " to match the selected tag input"
    )
  }
  frq_counts <- frq_header_counts(readLines(frq_out, warn = FALSE), frq_out)
  ini_out <- file.path(model_dir, "bet.ini")
  tag_out <- file.path(model_dir, "bet.tag")
  copy_one(ini_source, ini_out)
  copy_one(tag_source, tag_out)
  tag_rep_repair_note <- repair_tag_reporting_matrices(
    ini_out,
    tag_out,
    reference_ini = if (exists("regfish_ini_source")) regfish_ini_source else "",
    reference_tag = if (exists("regfish_tag_source")) regfish_tag_source else ""
  )
  apply_fixm_m(ini_out)
  ini_tag_note <- ensure_ini_tag_flags(
    ini_out,
    frq_counts$n_tag_groups,
    tag_path = tag_out,
    terminal_year = frq_chop_year
  )
  ini_shed_note <- ensure_ini_tag_shed_rates(ini_out, frq_counts$n_tag_groups)
  ini_notes <- c("FixM M row applied", tag_rep_repair_note, ini_tag_note, ini_shed_note)
  ini_note <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  visible_ini_notes <- c(tag_rep_repair_note, ini_tag_note, ini_shed_note)
  visible_ini_notes <- visible_ini_notes[nzchar(visible_ini_notes)]
  if (length(visible_ini_notes) && "bet.ini" %in% names(input_notes)) {
    input_notes[["bet.ini"]] <- paste(
      c(input_notes[["bet.ini"]], visible_ini_notes),
      collapse = "; "
    )
  }
  copy_one(age_source, file.path(model_dir, "bet.age_length"))
  has_reg_scaling <- nzchar(reg_scaling_source)
  if (has_reg_scaling) {
    copy_one(reg_scaling_source, file.path(model_dir, "bet.reg_scaling"))
    regional_scaling_periods <- length(readLines(reg_scaling_source, warn = FALSE))
    if (!"bet.reg_scaling" %in% names(input_notes)) {
      input_notes[["bet.reg_scaling"]] <-
        "`bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions"
    }
  }
  control_notes <- c(
    control_notes,
    "Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.",
    "Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.",
    "`age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  )
  copy_one(file.path(root, "steps", "03-RegFish", "model", "mfcl.cfg"), file.path(model_dir, "mfcl.cfg"))
  fishery_map_out <- file.path(model_dir, "fishery_map.R")
  copy_one(file.path(root, "steps", "03-RegFish", "model", "fishery_map.R"), fishery_map_out)
  if (has_reg_scaling) {
    apply_regional_index_selectivity_map(fishery_map_out)
  }
  write_generated_tag_rep_map(model_dir)
  write_doitall(
    file.path(root, "steps", "03-RegFish", "model", "doitall.sh"),
    file.path(model_dir, "doitall.sh"),
    mix_from_ini = mix_from_ini,
    size_based_selectivity = isTRUE(doitall_edits$size_based_selectivity),
    opr = isTRUE(doitall_edits$opr),
    data_weighting = isTRUE(doitall_edits$data_weighting),
    regional_scaling = has_reg_scaling,
    regional_scaling_periods = if (has_reg_scaling) regional_scaling_periods else 292L
  )
  reg_scaling_flags <- NULL
  reg_scaling_window <- NULL
  if (has_reg_scaling) {
    doitall_out <- file.path(model_dir, "doitall.sh")
    reg_scaling_flags <- parse_doitall_parest_flags(doitall_out, 77:81)
    reg_scaling_window <- regional_scaling_period_window(reg_scaling_flags, regional_scaling_periods)
    control_notes <- c(
      control_notes,
      regional_scaling_control_notes(doitall_out, regional_scaling_periods, reg_scaling_active_years)
    )
  }

  entries <- list(
    list(role = "frq", file = "bet.frq", source = frq_source, note = frq_note),
    list(role = "ini", file = "bet.ini", source = ini_source, note = ini_note),
    list(role = "tag", file = "bet.tag", source = tag_source, note = "tag reporting map regenerated from ini/tag; five MFCL reporting-rate matrices parsed"),
    list(role = "age_length", file = "bet.age_length", source = age_source, note = "CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = "steps/03-RegFish/model/doitall.sh", note = paste(c(
      ifelse(mix_from_ini, "mixing override removed", "03-RegFish 5-region controls retained"),
      if (has_reg_scaling) paste0(
        "regional scaling Prior_reg_biomass switch applied in PHASE 5 with ",
        "flags 77=", format_flag_value(reg_scaling_flags[["77"]]),
        ", 78=", format_flag_value(reg_scaling_flags[["78"]]),
        ", 79=", format_flag_value(reg_scaling_flags[["79"]]),
        ", 80=", format_flag_value(reg_scaling_flags[["80"]]),
        ", 81=", format_flag_value(reg_scaling_flags[["81"]]),
        "; active periods ", reg_scaling_window$start, "-", reg_scaling_window$end,
        " (", reg_scaling_active_years, ")"
      ),
      if (has_reg_scaling) "index CPUE/selectivity groups unshared from PHASE 5",
      "doitall exits immediately on MFCL command failure",
      if (isTRUE(doitall_edits$size_based_selectivity)) "fish flag 26 set to 3",
      if (isTRUE(doitall_edits$opr)) "OPR recruitment flags applied",
      if (isTRUE(doitall_edits$data_weighting)) "global LF/WF divisors set to 40"
    ), collapse = "; "))
  )
  if (nzchar(index_cpue_source)) {
    entries <- append(entries, list(list(
      role = "frq_cpue",
      file = "bet.frq",
      source = index_cpue_source,
      note = "CPUE/index fishery records 29-33 retained from the 2023 new-structure frq while non-index size/catch records come from the 2026 frq source"
    )), after = 1L)
  }
  if (has_reg_scaling) {
    entries <- append(entries, list(list(
      role = "reg_scaling",
      file = "bet.reg_scaling",
      source = reg_scaling_source,
      note = "global CPUE regional-scaling matrix for MFCL parest flags 77-81"
    )), after = 4L)
  }
  write_manifest(step_dir, entries)
  outstanding <- c(
    outstanding,
    "Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs."
  )
  write_readme(
    step_dir = step_dir,
    title = title,
    summary = summary,
    bullets = bullets,
    inputs = c(input_notes, "input_manifest.csv" = "machine-readable source/input notes"),
    controls = control_notes,
    outstanding = outstanding,
    status = status,
    run_notes = run_notes,
    source_revisions = input_repo_revision_table()
  )
}

for (base_step in c("01-Diag23", "02-FixM", "03-RegFish")) {
  base_doitall <- file.path(root, "steps", base_step, "model", "doitall.sh")
  remove_model_par_files(file.path(root, "steps", base_step, "model"))
  write_doitall(base_doitall, base_doitall)
}

base_ini_1007_notes <- lapply(c("01-Diag23", "02-FixM"), function(base_step) {
  ensure_ini_1007_compatibility(
    file.path(root, "steps", base_step, "model", "bet.ini"),
    file.path(root, "steps", base_step, "model", "bet.tag")
  )
})
names(base_ini_1007_notes) <- c("01-Diag23", "02-FixM")

write_readme(
  file.path(root, "steps", "01-Diag23"),
  "01 Diag23",
  "2023 diagnostic BET model structure, retained as the starting point for the 2026 stepwise transition.",
  c(
    "Uses the inherited 9-region, 41-fishery inputs ending in 2021.",
    "Natural mortality setup is the pre-FixM diagnostic baseline.",
    "`bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the diagnostic values.",
    "Run mode is `doitall` so the model can be built from `bet.ini` with the bundled control script."
  ),
  c(
    "bet.frq" = "2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021",
    "bet.ini" = "2023 diagnostic ini before the FixM M-scale row change; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0",
    "bet.tag" = "2023 diagnostic tag input",
    "bet.age_length" = "2023 diagnostic CAAL input"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "The step output includes `bet-2023-nine-region.geojson` as a display-only MFCL Shiny map asset; it does not change MFCL inputs.",
    "`bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.",
    "Survey index fishery sigma settings are the BET 2023 region-specific values.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "This is a baseline reference step; no 2026 input updates are intended here.",
    "Run diagnostics should confirm the archived 2023 behavior before interpreting later deltas."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

write_readme(
  file.path(root, "steps", "02-FixM"),
  "02 FixM",
  "2023 diagnostic structure with the FixM M-scale row applied.",
  c(
    "Same 9-region, 41-fishery input structure as 01-Diag23.",
    "The M-related age parameter row is set to `-2.54917483258212e+00 -1 ...`.",
    "`bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the FixM diagnostic values.",
    "This is the M source used when preparing later 5-region inputs."
  ),
  c(
    "bet.frq" = "same structural input as 01-Diag23, terminal year 2021",
    "bet.ini" = "FixM version of the diagnostic ini; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0",
    "bet.tag" = "same tag structure as 01-Diag23",
    "bet.age_length" = "same CAAL structure as 01-Diag23"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "This step is used as the reference for the M row copied into 03+.",
    "The step output includes `bet-2023-nine-region.geojson` as a display-only MFCL Shiny map asset; it does not change MFCL inputs.",
    "`bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "Confirm the FixM M row reproduces the intended fixed-M diagnostic before comparing against 03+.",
    "No fishery, tag, CAAL, or CPUE update is intended in this step."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
regfish_frq_source <- file.path(frq_root, "bet.2023.new.structure.frq")
regfish_ini_source <- file.path(ini_root, "bet.2023.new.structure.ini")
regfish_tag_source <- file.path(tag_root, "bet.2023.new.structure-low.recaps.removed.tag")
regfish_dir <- file.path(root, "steps", "03-RegFish")
regfish_model_dir <- file.path(regfish_dir, "model")
remove_model_par_files(regfish_model_dir)
copy_one(regfish_frq_source, file.path(regfish_model_dir, "bet.frq"))
copy_one(regfish_ini_source, file.path(regfish_model_dir, "bet.ini"))
copy_one(regfish_tag_source, file.path(regfish_model_dir, "bet.tag"))
copy_one(old_age, file.path(regfish_model_dir, "bet.age_length"))
n_normalized_03 <- normalize_frq_absent_lf_records(file.path(regfish_model_dir, "bet.frq"))
ensure_frq_fishery_region_locations(file.path(regfish_model_dir, "bet.frq"))
apply_fixm_m(file.path(regfish_model_dir, "bet.ini"))
frq_counts_03 <- frq_header_counts(
  readLines(file.path(regfish_model_dir, "bet.frq"), warn = FALSE),
  file.path(regfish_model_dir, "bet.frq")
)
ini_tag_note_03 <- ensure_ini_tag_flags(
  file.path(regfish_model_dir, "bet.ini"),
  frq_counts_03$n_tag_groups
)
write_generated_tag_rep_map(regfish_model_dir)
write_manifest(regfish_dir, list(
  list(
    role = "frq",
    file = "bet.frq",
    source = regfish_frq_source,
    note = paste0(
      "5-region 2021-terminal new-structure frq; old CPUE/global index approach retained",
      if (n_normalized_03) paste0("; normalized ", n_normalized_03, " records with stray absent-LF bins") else ""
    )
  ),
  list(
    role = "ini",
    file = "bet.ini",
    source = regfish_ini_source,
    note = paste(c("FixM M row applied", ini_tag_note_03)[nzchar(c("FixM M row applied", ini_tag_note_03))], collapse = "; ")
  ),
  list(
    role = "tag",
    file = "bet.tag",
    source = regfish_tag_source,
    note = "low-recapture-removed 2023 new-structure tag input; tag reporting map regenerated from ini/tag"
  ),
  list(
    role = "age_length",
    file = "bet.age_length",
    source = old_age,
    note = "old CAAL / age_length reassigned to the new fisheries"
  )
))

write_readme(
  file.path(root, "steps", "03-RegFish"),
  "03 RegFish",
  "First 5-region / 33-fishery BET input step, ending in 2021.",
  c(
    "Uses the latest `bet.2023.new.structure.*` source inputs from the 2026 input build repos.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Uses `bet.2023.new.structure.frq` exactly as the 2021-terminal new-region/new-fishery frequency source, including the old CPUE/global index approach.",
    "Uses the old CAAL data re-assigned to the new fisheries.",
    paste0(
      "Uses the old/restructured tag setup with ", frq_counts_03$n_tag_groups,
      " release groups and ", frq_counts_03$n_tag_groups + 1L,
      " tag-event rows including pooled tags."
    ),
    "Regenerates `tag_rep_map.R` from the five MFCL reporting-rate matrices in `bet.ini` plus release metadata in `bet.tag`.",
    paste0("Normalizes ", n_normalized_03, " old records that had an absent-LF sentinel followed by stray LF bins."),
    "Applies the 2026 CPUE index sigma settings for index fisheries 29-33.",
    "Applies FixM M row while retaining the 5-region `.ini` structure.",
    "Inserts default MFCL 1007 tag flags for the pre-mix step: 2 mixing periods and reporting rates excluded during mixing."
  ),
  c(
    "bet.frq" = "`bet.2023.new.structure.frq`; 5-region, 33-fishery structure, terminal year 2021, old CPUE/global index approach retained",
    "bet.ini" = "`bet.2023.new.structure.ini`; FixM M row applied and explicit default tag flags inserted if needed",
    "bet.tag" = paste0(
      "`bet.2023.new.structure-low.recaps.removed.tag`; ",
      frq_counts_03$n_tag_groups,
      " release-group tag input with low recap groups removed"
    ),
    "bet.age_length" = "`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries",
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "5-region fishery/tag/selectivity controls are remapped in `doitall.sh`.",
    "Index fisheries 29-33 use sigmas 0.28, 0.20, 0.22, 0.21, and 0.24.",
    "The `-9999 1 2` all-release mixing-period setting is retained for this pre-mix step.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.",
    paste0("The ", n_normalized_03, " normalized absent-LF records should be reviewed against the upstream frq-build script so the source generator can eventually emit MFCL-ready records."),
    "The upstream non-mix `.ini` files are labelled 1007 but can have non-standard or short tag-flag blocks; generated inputs now normalize and pad explicit tag flags for MFCL >=2.2.7.5.",
    "Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here.",
  source_revisions = input_repo_revision_table()
)

regfish_ini <- file.path(root, "steps", "03-RegFish", "model", "bet.ini")
regfish_tag <- file.path(root, "steps", "03-RegFish", "model", "bet.tag")
full_plus_frq <- file.path(frq_root, "bet.2026.wt.as.len.plus.len.frq")
wt_as_len_frq <- file.path(frq_root, "bet.2026.wt.as.len.frq")
full_2024_alignment_run_notes <- c(
  "The first full-2024 Kflow attempt failed during MFCL `-makepar`, before any fit output was available. The logged fatal sequence was `initial_tag_year(2) 157`, `Error reading region_flags`, and `Bounds error reading pmature(34) in par file value is 0`; downstream payload creation then failed because no MFCL output folder existed.",
  "The failure was traced to using the 2026 `.frq/.tag` release-group count with a source `bet.2026.ini` whose tag controls were shorter: the selected `.frq` and `.tag` had 98 release groups, while the ini tag flags and tag shed-rate vector only covered 91 groups and the tag reporting-rate matrices were missing the 7 new release rows.",
  "Generated inputs now repair only the `.ini` alignment: missing tag reporting-rate rows 92-98 are filled by matching tag program, region, year, and month from `bet.2023.new.structure.ini`; explicit MFCL 1007 tag flags are padded to 98 rows; and `# tag shed rate` is padded from 91 to 98 zero shed rates.",
  "The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows were deleted to suppress warnings.",
  "After the alignment repair, `mfclo64 bet.frq bet.ini 00.par -makepar` exits 0 and creates `00.par` for 06-Full2024 and 07-CAAL2026 in the `tuna-flow:v1.10` image."
)
mix_period_alignment_run_notes <- c(
  "These steps were audited after the 06/07 full-2024 failure because they use the same 98-release 2026 `.frq` and `.tag` family.",
  "The mix-period ini family already carries release-group-specific tag controls, so the generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive the mixing-period settings.",
  "Generation still validates the same release-group alignment checks as 06/07: tag flags, tag shed rate, and the five tag reporting-rate matrices must match the 98 selected release groups plus the pooled reporting row where appropriate.",
  "Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0; this is an ini-control normalization, not a deletion of tag data.",
  "Local `mfclo64 bet.frq bet.ini 00.par -makepar` smoke tests now exit 0 and create `00.par` for 08-MixPeriod02 through 12-DataWeight40 in the `tuna-flow:v1.10` image."
)

make_step(
  step_id = "04-WtAsLen21",
  frq_source = wt_as_len_frq,
  ini_source = regfish_ini,
  tag_source = regfish_tag,
  age_source = old_age,
  frq_chop_year = 2021L,
  frq_tag_groups = frq_counts_03$n_tag_groups,
  index_cpue_source = regfish_frq_source,
  title = "04 WtAsLen21",
  summary = "Transition step using 2026 weights-as-lengths size/catch data chopped to 2021, while retaining the 2023 new-structure CPUE/index records.",
  bullets = c(
    "Builds a hybrid `bet.frq`: non-index records come from `bet.2026.wt.as.len.frq` chopped to year <= 2021, while index fisheries 29-33 are replaced with CPUE records from `bet.2023.new.structure.frq`.",
    "This isolates the weights-to-lengths transition without also switching the CPUE/index data to the 2026 regional index series.",
    paste0("Keeps the 03-RegFish ", frq_counts_03$n_tag_groups, "-release tag/ini structure because this step remains a 2021-terminal comparison."),
    paste0("Resets the chopped `.frq` tag-group header from the 2026 source count to ", frq_counts_03$n_tag_groups, " to match the selected tag file."),
    "Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.",
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = paste0(
      "hybrid of `bet.2026.wt.as.len.frq` chopped to 2021 for non-index size/catch records, plus index fisheries 29-33 copied from `bet.2023.new.structure.frq`; tag-group header reset to ",
      frq_counts_03$n_tag_groups
    ),
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    paste0(
      "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish ",
      frq_counts_03$n_tag_groups,
      "-release tag set."
    )
  ),
  run_notes = c(
    "The first implementation chopped the 2026 `.frq` directly, which also carried the 2026 CPUE/index records. The corrected transition keeps the 2023 new-structure CPUE/index records for fisheries 29-33.",
    "Kflow failed when this 2021-chopped `.frq` was paired with the full 2026 tag/ini family; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    paste0(
      "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's ",
      frq_counts_03$n_tag_groups,
      "-release setup, and the chopped `.frq` tag-group header is reset to ",
      frq_counts_03$n_tag_groups,
      "."
    ),
    "No tag release or recapture rows were deleted to silence warnings; this step only changes which already-prepared input family is paired with the chopped 2026 size/catch records.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "After fitting, compare directly with 03-RegFish to isolate the effect of converting weights to lengths while CPUE/index data are held constant.",
    "Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage."
  )
)

make_step(
  step_id = "05-WtAsLenPlusLen21",
  frq_source = full_plus_frq,
  ini_source = regfish_ini,
  tag_source = regfish_tag,
  age_source = old_age,
  frq_chop_year = 2021L,
  frq_tag_groups = frq_counts_03$n_tag_groups,
  index_cpue_source = regfish_frq_source,
  title = "05 WtAsLenPlusLen21",
  summary = "Transition step using 2026 weights-as-lengths plus observed lengths chopped to 2021, while retaining the 2023 new-structure CPUE/index records.",
  bullets = c(
    "Builds a hybrid `bet.frq`: non-index records come from `bet.2026.wt.as.len.plus.len.frq` chopped to year <= 2021, while index fisheries 29-33 are replaced with CPUE records from `bet.2023.new.structure.frq`.",
    "This isolates the plus-length size-composition transition without also switching the CPUE/index data to the 2026 regional index series.",
    "Maintains the old CAAL input while moving the size-composition frequency file to the plus-length variant.",
    paste0("Keeps the 03-RegFish ", frq_counts_03$n_tag_groups, "-release tag/ini structure because this step remains a 2021-terminal comparison."),
    paste0("Resets the chopped `.frq` tag-group header from the 2026 source count to ", frq_counts_03$n_tag_groups, " to match the selected tag file."),
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = paste0(
      "hybrid of `bet.2026.wt.as.len.plus.len.frq` chopped to 2021 for non-index size/catch records, plus index fisheries 29-33 copied from `bet.2023.new.structure.frq`; tag-group header reset to ",
      frq_counts_03$n_tag_groups
    ),
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    paste0(
      "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish ",
      frq_counts_03$n_tag_groups,
      "-release tag set."
    )
  ),
  run_notes = c(
    "The first implementation chopped the 2026 `.frq` directly, which also carried the 2026 CPUE/index records. The corrected transition keeps the 2023 new-structure CPUE/index records for fisheries 29-33.",
    "Kflow failed when this 2021-chopped `.frq` was paired with the full 2026 tag/ini family; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    paste0(
      "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's ",
      frq_counts_03$n_tag_groups,
      "-release setup, and the chopped `.frq` tag-group header is reset to ",
      frq_counts_03$n_tag_groups,
      "."
    ),
    "No tag release or recapture rows were deleted to silence warnings; this step only changes which already-prepared input family is paired with the chopped 2026 size/catch records.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "After fitting, compare directly with 04-WtAsLen21 to isolate the effect of adding observed lengths while CPUE/index data are held constant."
  )
)

make_step(
  step_id = "06-Full2024",
  frq_source = full_plus_frq,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = old_age,
  reg_scaling_source = reg_scaling_source,
  title = "06 Full2024",
  summary = "Full 2024 data step with weights-as-lengths plus lengths, new regional CPUE/index inputs, and 2026 tag reporting priors.",
  bullets = c(
    "Uses `bet.2026.wt.as.len.plus.len.frq` without year chopping.",
    "Moves from the 2021-chopped transition steps to the full 2024 frequency/catch/size series.",
    "Keeps old CAAL for this step, matching the plan's 'no change to CAAL file' instruction.",
    "Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group mixing period remains fixed at 2 for this pre-mix step."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c(
    "Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.",
    "This step intentionally keeps old CAAL so the CAAL update is isolated in 07-CAAL2026."
  )
)

make_step(
  step_id = "07-CAAL2026",
  frq_source = full_plus_frq,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  title = "07 CAAL2026",
  summary = "Full 2024 data step with the updated 2026 CAAL / age_length input.",
  bullets = c(
    "Uses the same full 2024 `.frq`, 2026 `.ini`, and 2026 `.tag` as 06-Full2024.",
    "Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.",
    "The 2026 age_length file has 181 records through 2024 and includes Japan/SPC new age data.",
    "Applies the FixM M row to the 2026 ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group mixing period remains fixed at 2 for this pre-mix step."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c(
    "After fitting, compare CAAL likelihood and age residuals against 06-Full2024.",
    "Confirm the 2026 CAAL source remains the chosen final CAAL file before later sensitivity runs."
  )
)

make_step(
  step_id = "08-MixPeriod02",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  title = "08 MixPeriod02",
  summary = "Release-group-specific tag mixing periods using the 0.2 KS diagnostic cutoff.",
  bullets = c(
    "Uses `bet.2026.mix-0.2.ini` from the ini-build repo.",
    "Keeps the full 2024 `.frq`, 2026 tag file, and updated 2026 CAAL.",
    "Applies the FixM M row to the mix-period ini.",
    "Removes the inherited `-9999 1 2` line from `doitall.sh` so the release-group-specific tag flags in the ini are not overwritten."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override is removed.",
    "All other 03-RegFish 5-region fishery, tag recapture, selectivity, and CPUE sigma controls are retained."
  ),
  run_notes = mix_period_alignment_run_notes,
  outstanding = c(
    "Confirm that the 0.2 KS mix-period ini is the main 12-step path; the 0.15 version remains a sensitivity candidate.",
    "After fitting, inspect tag residuals and release-group behavior before tuning tag-reporting assumptions further."
  )
)

make_step(
  step_id = "09-SizeBasedSel",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE),
  title = "09 SizeBasedSel",
  summary = "Size-based selectivity step after the main 0.2 KS tag mixing-period setup.",
  bullets = c(
    "Uses the same full 2024 `.frq`, `bet.2026.mix-0.2.ini`, 2026 tag file, and updated 2026 CAAL as 08-MixPeriod02.",
    "Sets fish flag 26 from 2 to 3 in `doitall.sh`, following the YFT 2026 length-based selectivity note.",
    "Keeps the extraction-fishery selectivity mapping and fishery-specific constraints from 03-RegFish, while index fisheries unshare from PHASE 5 under regional scaling."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override remains removed.",
    "`-999 26 3` is applied for size-based selectivity."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The extra step-specific change after the mix-period audit is limited to fish flag 26: `doitall.sh` sets `-999 26 3` for the size-based selectivity experiment."
  ),
  outstanding = c(
    "Confirm with the modelling group that BET should use the same flag-26 setting as the YFT 2026 size-based selectivity experiment.",
    "Not yet reviewed after fitting: upper-age selectivity constraints inherited from 03-RegFish, especially `24.PL.ALL.WEST.3`."
  )
)

make_step(
  step_id = "10-OPR",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE),
  title = "10 OPR",
  summary = "Orthogonal polynomial recruitment step using the best-ranked BET OPR screening setting.",
  bullets = c(
    "Uses the same input files as 09-SizeBasedSel.",
    "Applies the BIGEYE AIC rank-1 OPR screening model: `69-01-50-50`.",
    "The OPR comparison was run on the BET 4R model, but this step carries the best-ranked setting into the current 5-region stepwise path.",
    "OPR controls are applied in PHASE 3 of `doitall.sh`, so early phases still use the pre-OPR recruitment setup before the transfer."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "`-999 26 3` is retained from 09-SizeBasedSel.",
    "PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.",
    "`1 149 0`, `1 398 0`, `1 400 0`, `2 177 0`, `2 32 0`, and `2 113 0` are applied at PHASE 3 for the OPR transfer, matching the OPR screening `doitall` example except for obsolete `parest_flag(221)`.",
    "`1 155 69` sets the OPR year effect from the `69-01-50-50` setting. `parest_flag(221)` is not set because current MFCL treats it as an obsolete/commented-out legacy year-effect override; the active source reads the year degree from `parest_flag(155)`.",
    "`1 217 1`, `1 216 50`, and `1 218 50` set season, region, and region-season interaction effects.",
    "`1 202 2` sets the OPR end window to the last 2 real years, where the orthogonal-polynomial basis is held at the lower-degree/constant-end form. `1 210 0`, `1 212 0`, and `1 214 0` do not turn that off; in current MFCL, zero means the region, season, and region-season effects inherit `parest_flag(202)`. Use `-1` to turn an end window off.",
    "`2 30 1` is deliberately retained at the OPR phase because current MFCL requires `age_flag(30)=1` to activate the OPR polynomial coefficients.",
    "`2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.",
    "PHASE 3 uses 500 function evaluations, matching the OPR screening `doitall` example."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The step-specific OPR change follows the BET OPR screening: the BET 4R rank-1 AIC setting `69-01-50-50` is carried into this 5-region path. The README records that this is an applied transfer from the 4R screening, not a separate 5-region OPR search.",
    "The OPR transfer keeps `2 30 1` because current MFCL does not activate the OPR recruitment-polynomial coefficients without it; the step turns off `2 70`, `2 71`, `2 178`, and the `-100000 1:5` regional recruitment-distribution flags."
  ),
  outstanding = c(
    "After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result.",
    "If diagnostics disagree with the 4R screening, revisit the other BET-ranked OPR options."
  )
)

make_step(
  step_id = "11-EffortCreep",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE),
  title = "11 EffortCreep",
  summary = "Minimum effort-creep scenario applied to the regional index fisheries.",
  bullets = c(
    "Uses 10-OPR controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.",
    "Retains the `69-01-50-50` OPR setting selected from the BET 4R OPR screening.",
    "The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.",
    "Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "10-OPR `doitall.sh` controls are retained, including the explicit `2 30 1` OPR activation safeguard.",
    "No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The effort-creep `.frq` is generated from the full 2024 plus-length source by changing only positive effort values for index fisheries 29-33; extraction fisheries and size-composition records are left as in the source file.",
    "The implemented multiplier is 1.00 in 1952, 1.24 in 1976, and 1.48 in 2024; this applies the agreed piecewise effort-creep scenario rather than extending the 1%/yr rate through the full time series."
  ),
  outstanding = c(
    "After fitting, review the index residuals and implied CPUE scaling against 10-OPR to confirm this agreed effort-creep scenario behaves as expected."
  )
)

make_step(
  step_id = "12-DataWeight40",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE, data_weighting = TRUE),
  title = "12 DataWeight40",
  summary = "Initial manual strategic data-weighting step with stronger global size-composition downweighting.",
  bullets = c(
    "Uses the same effort-creep `.frq`, mix-period `.ini`, tag, and CAAL as 11-EffortCreep.",
    "Keeps size-based selectivity and the `69-01-50-50` OPR controls from 10-OPR.",
    "Changes global LF and WF sample-size divisors from 20 to 40 in `doitall.sh`."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "10-OPR `doitall.sh` controls are retained, including the explicit `2 30 1` OPR activation safeguard.",
    "`-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.",
    "Fishery-specific divisor-40 settings inherited from 03-RegFish are retained."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The step-specific data-weighting change is limited to the global LF/WF sample-size divisors: `-999 49 40` and `-999 50 40` replace the divisor-20 settings. This was documented as an initial runnable weighting scenario, not a final tuned weighting scheme."
  ),
  outstanding = c(
    "This is a first runnable manual weighting scenario, not a final tuned weighting scheme.",
    "Not yet implemented: alternative divisor scenarios or targeted CAAL/size weighting after diagnostics."
  )
)
