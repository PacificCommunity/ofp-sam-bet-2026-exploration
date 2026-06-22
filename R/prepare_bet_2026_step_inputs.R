root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
input_root <- "/home/kyuhank/Desktop/SPC/bet_2026_input_repos"

frq_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build", "BET")
ini_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini", "BET")
tag_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep", "BET")
age_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build", "BET")
reg_scaling_source <- file.path(frq_root, "bet.2026.reg_scaling")

fixm_age_par_value <- "-2.54917483258212e+00"

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
    words <- read_words(lines[[marker[[i]] + 1L]])
    if (length(words) < 3L) {
      stop("Malformed tag release row in ", path, " after line ", marker[[i]], call. = FALSE)
    }
    data.frame(
      tag_group = i,
      release_region = as.integer(words[[1L]]),
      release_year = as.integer(words[[2L]]),
      release_month = as.integer(words[[3L]])
    )
  }))
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
  tag_marker <- grep("^# tag flags$", trimws(lines))
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
    tag_marker <- grep("^# tag flags$", trimws(lines))
  }

  if (length(tag_marker) != 1L) {
    stop("Expected one # tag flags block in ", path, call. = FALSE)
  }
  next_comment <- which(seq_along(lines) > tag_marker & grepl("^[[:space:]]*#", lines))
  if (!length(next_comment)) {
    stop("Could not find the end of # tag flags in ", path, call. = FALSE)
  }
  flag_idx <- seq.int(tag_marker + 1L, next_comment[[1L]] - 1L)
  flag_idx <- flag_idx[nzchar(trimws(lines[flag_idx]))]
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

write_frq_with_effort_creep <- function(from, to, index_fisheries = 29:33,
                                        base_year = 1952L, annual_rate = 0.01) {
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
    creep_multiplier <- 1 + annual_rate * (year - base_year)
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
    stop("Expected tag reporting matrix rows to equal release groups + pooled row in ", ini, call. = FALSE)
  }
  event_rows <- data.frame(
    tag_event_row = seq_len(nrow(flags)),
    event_type = ifelse(seq_len(nrow(flags)) <= nrow(releases), "release", "pooled"),
    release_group = c(releases$release_group, rep(NA_integer_, nrow(flags) - nrow(releases))),
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
    release_rows <- sort(unique(pos[, "row"][pos[, "row"] <= nrow(releases)]))
    release_subset <- releases[release_rows, , drop = FALSE]
    pooled <- any(pos[, "row"] > nrow(releases))
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
    "# Tag reporting-rate matrices follow MFCL manual and tag_rep_rates.pptx.",
    "# Rows are tag release events plus one pooled row; columns are fisheries.",
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
      source = x$source,
      note = x$note,
      stringsAsFactors = FALSE
    )
  }))
  write.csv(manifest, file.path(step_dir, "input_manifest.csv"), row.names = FALSE)
}

write_readme <- function(step_dir, title, summary, bullets, inputs, controls,
                         outstanding = character(), status,
                         run_notes = character()) {
  bullet_lines <- paste0("- ", bullets)
  input_lines <- paste0("- `", names(inputs), "`: ", unname(inputs))
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
    status,
    ""
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

apply_opr <- function(lines, n_regions = 5L, year_effect = 70L,
                      season_effect = 3L) {
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
    "# OPR settings. John's suggestion: switch to OPR in PHASE 3.",
    "  1 149 0   # turn off recruitment-deviation penalty for OPR",
    "  1 398 0   # terminal recruitment arithmetic mean under OPR setup",
    "  2 177 0   # turn off old total-pop scaling for OPR",
    "  2 32 0    # turn off overall population scaling parameter for OPR",
    sprintf("  1 155 %d  # orthogonal polynomial recruitment - year effect", year_effect),
    sprintf("  1 216 %d   # orthogonal polynomial recruitment - region effect", n_regions - 1L),
    sprintf("  1 217 %d   # orthogonal polynomial recruitment - season effect", season_effect),
    "  1 218 0   # orthogonal polynomial recruitment - no region:season interaction",
    "  2 70 0    # turn off mean+deviate regional recruitment time series",
    "  2 71 0    # turn off regional recruitment distribution deviations",
    "  2 178 0   # turn off regional recruitment sum-product constraint"
  )
  lines <- c(lines[seq_len(phase3 - 1L)], new_block, lines[(phase3 + 3L):length(lines)])

  region_flags <- grep("^[[:space:]]*-100000[[:space:]]+[1-5][[:space:]]+1([[:space:]]|$)", lines)
  if (length(region_flags) != n_regions) {
    stop("Expected ", n_regions, " time-invariant recruitment distribution flags", call. = FALSE)
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

apply_regional_scaling <- function(lines, n_periods = 292L,
                                   weight = 1L,
                                   use_mean = TRUE,
                                   use_mvn = TRUE) {
  target <- grep("# Recruitment and initial population settings", lines, fixed = TRUE)
  if (length(target) != 1L) {
    stop("Expected one recruitment settings marker before inserting regional scaling flags", call. = FALSE)
  }
  if (any(grepl("^[[:space:]]*1[[:space:]]+77[[:space:]]+", lines))) {
    return(lines)
  }
  block <- c(
    "# Regional scaling penalty from the 2026 global CPUE regional-scaling input.",
    "# MFCL reads bet.reg_scaling when parest flag 77 is > 0.",
    "  1 77 1    # regional scaling penalty weight; initial plan-v2 value, revisit after diagnostics",
    "  1 78 1    # use mean regional scaling target",
    sprintf("  1 79 %d  # use all %d full-2024 quarterly periods in bet.reg_scaling", n_periods, n_periods),
    "  1 80 0    # end at terminal model period",
    "  1 81 1    # use multivariate-normal regional scaling penalty"
  )
  block[[3L]] <- sub("1 77 1", paste("1 77", as.integer(weight)), block[[3L]], fixed = TRUE)
  block[[4L]] <- sub("1 78 1", paste("1 78", as.integer(isTRUE(use_mean))), block[[4L]], fixed = TRUE)
  block[[7L]] <- sub("1 81 1", paste("1 81", as.integer(isTRUE(use_mvn))), block[[7L]], fixed = TRUE)
  c(lines[seq_len(target - 1L)], block, lines[target:length(lines)])
}

apply_regional_index_selectivity <- function(lines) {
  comment <- grep(
    "# The old 29 groups become 25 groups here: 24 extraction groups \\+ 1 index group\\.",
    lines
  )
  if (length(comment) == 1L) {
    lines <- c(
      lines[seq_len(comment - 1L)],
      "# Regional-scaling steps use 29 selectivity groups: 24 extraction groups + 5 index groups.",
      "# Index fisheries are not forced to share selectivity; bet.reg_scaling supplies the CPUE regional-scaling penalty.",
      lines[(comment + 1L):length(lines)]
    )
  }

  for (fishery in 29:33) {
    idx <- grep(
      sprintf("^[[:space:]]*-%d[[:space:]]+24[[:space:]]+[0-9]+", fishery),
      lines
    )
    if (length(idx) != 1L) {
      stop("Expected one selectivity-group line for index fishery ", fishery, call. = FALSE)
    }
    group <- fishery - 4L
    region <- fishery - 28L
    lines[[idx]] <- sprintf("  -%d 24 %d  # Index R%d; unshared for regional scaling", fishery, group, region)
  }
  lines
}

apply_regional_index_selectivity_map <- function(path) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  if (any(grepl("Regional-scaling model variants unshare index selectivity", lines, fixed = TRUE))) {
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
    "# Regional-scaling model variants unshare index selectivity groups.",
    "# The five CPUE index fisheries keep independent selectivity groups because",
    "# bet.reg_scaling provides the cross-region scaling penalty.",
    "fishery_map$selectivity_group[29:33] <- 25:29",
    "selectivity_names[25:29] <- paste0(\"Index R\", 1:5)",
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]"
  )
  lines <- c(lines[seq_len(marker)], block, lines[(marker + 1L):length(lines)])
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

write_doitall <- function(from, to, mix_from_ini = FALSE,
                          size_based_selectivity = FALSE,
                          opr = FALSE,
                          data_weighting = FALSE,
                          regional_scaling = FALSE,
                          regional_scaling_periods = 292L) {
  lines <- readLines(from, warn = FALSE)
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
    lines <- apply_regional_scaling(lines, n_periods = regional_scaling_periods)
    lines <- apply_regional_index_selectivity(lines)
  }
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
}

make_step <- function(step_id, frq_source, ini_source, tag_source, age_source,
                      frq_chop_year = NA_integer_, mix_from_ini = FALSE,
                      frq_tag_groups = NA_integer_,
                      frq_transform = NULL, doitall_edits = list(),
                      reg_scaling_source = "",
                      title, summary, bullets, input_notes, control_notes,
                      run_notes = character(),
                      outstanding = character(),
                      status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  frq_out <- file.path(model_dir, "bet.frq")
  if (identical(frq_transform, "effort_creep")) {
    if (!is.na(frq_chop_year)) {
      stop("Effort-creep transform is only implemented for full-year frq files", call. = FALSE)
    }
    write_frq_with_effort_creep(frq_source, frq_out)
    frq_note <- "copied with 1% per year effort-creep multiplier applied to index fisheries 29-33"
  } else if (is.na(frq_chop_year)) {
    copy_one(frq_source, frq_out)
    frq_note <- "copied without year chopping"
  } else {
    chop_frq(frq_source, frq_out, max_year = frq_chop_year)
    frq_note <- paste0("chopped to records with year <= ", frq_chop_year)
  }
  n_normalized <- normalize_frq_absent_lf_records(frq_out)
  if (n_normalized) {
    frq_note <- paste0(
      frq_note,
      "; normalized ", n_normalized,
      " records with stray absent-LF bins"
    )
  }
  ensure_frq_fishery_region_locations(frq_out)
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
  apply_fixm_m(ini_out)
  ini_tag_note <- ensure_ini_tag_flags(
    ini_out,
    frq_counts$n_tag_groups,
    tag_path = tag_out,
    terminal_year = frq_chop_year
  )
  ini_notes <- c("FixM M row applied", ini_tag_note)
  ini_note <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  if (nzchar(ini_tag_note) && "bet.ini" %in% names(input_notes)) {
    input_notes[["bet.ini"]] <- paste(input_notes[["bet.ini"]], ini_tag_note, sep = "; ")
  }
  copy_one(age_source, file.path(model_dir, "bet.age_length"))
  has_reg_scaling <- nzchar(reg_scaling_source)
  if (has_reg_scaling) {
    copy_one(reg_scaling_source, file.path(model_dir, "bet.reg_scaling"))
    if (!"bet.reg_scaling" %in% names(input_notes)) {
      input_notes[["bet.reg_scaling"]] <-
        "`bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions"
    }
    control_notes <- c(
      control_notes,
      "`bet.reg_scaling` is read by MFCL because `parest_flags(77)>0`; flags 77-81 are set in `doitall.sh`.",
      "Index fisheries 29-33 are assigned separate selectivity groups 25-29 in regional-scaling steps; 03-05 retain the old single index selectivity group."
    )
  }
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
    regional_scaling = has_reg_scaling
  )

  entries <- list(
    list(role = "frq", file = "bet.frq", source = frq_source, note = frq_note),
    list(role = "ini", file = "bet.ini", source = ini_source, note = ini_note),
    list(role = "tag", file = "bet.tag", source = tag_source, note = "tag reporting map regenerated from ini/tag; five MFCL reporting-rate matrices parsed"),
    list(role = "age_length", file = "bet.age_length", source = age_source, note = "CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = "steps/03-RegFish/model/doitall.sh", note = paste(c(
      ifelse(mix_from_ini, "mixing override removed", "03-RegFish 5-region controls retained"),
      if (has_reg_scaling) "regional scaling penalty flags 77-81 applied",
      if (has_reg_scaling) "index fishery selectivity groups 25-29 unshared",
      if (isTRUE(doitall_edits$size_based_selectivity)) "fish flag 26 set to 3",
      if (isTRUE(doitall_edits$opr)) "OPR recruitment flags applied",
      if (isTRUE(doitall_edits$data_weighting)) "global LF/WF divisors set to 40"
    ), collapse = "; "))
  )
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
    "Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs."
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
    run_notes = run_notes
  )
}

write_readme(
  file.path(root, "steps", "01-Diag23"),
  "01 Diag23",
  "2023 diagnostic BET model structure, retained as the starting point for the 2026 stepwise transition.",
  c(
    "Uses the inherited 9-region, 41-fishery inputs ending in 2021.",
    "Natural mortality setup is the pre-FixM diagnostic baseline.",
    "Run mode is `doitall` so the model can be built from `bet.ini` with the bundled control script."
  ),
  c(
    "bet.frq" = "2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021",
    "bet.ini" = "2023 diagnostic ini before the FixM M-scale row change",
    "bet.tag" = "2023 diagnostic tag input",
    "bet.age_length" = "2023 diagnostic CAAL input"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "Survey index fishery sigma settings are the BET 2023 region-specific values."
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
    "This is the M source used when preparing later 5-region inputs."
  ),
  c(
    "bet.frq" = "same structural input as 01-Diag23, terminal year 2021",
    "bet.ini" = "FixM version of the diagnostic ini",
    "bet.tag" = "same tag structure as 01-Diag23",
    "bet.age_length" = "same CAAL structure as 01-Diag23"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "This step is used as the reference for the M row copied into 03+."
  ),
  c(
    "Confirm the FixM M row reproduces the intended fixed-M diagnostic before comparing against 03+.",
    "No fishery, tag, CAAL, or CPUE update is intended in this step."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

normalize_frq_absent_lf_records(file.path(root, "steps", "03-RegFish", "model", "bet.frq"))
ensure_frq_fishery_region_locations(file.path(root, "steps", "03-RegFish", "model", "bet.frq"))
apply_fixm_m(file.path(root, "steps", "03-RegFish", "model", "bet.ini"))
frq_counts_03 <- frq_header_counts(readLines(file.path(root, "steps", "03-RegFish", "model", "bet.frq"), warn = FALSE),
                                   file.path(root, "steps", "03-RegFish", "model", "bet.frq"))
ini_tag_note_03 <- ensure_ini_tag_flags(file.path(root, "steps", "03-RegFish", "model", "bet.ini"),
                                        frq_counts_03$n_tag_groups)
write_generated_tag_rep_map(file.path(root, "steps", "03-RegFish", "model"))

write_readme(
  file.path(root, "steps", "03-RegFish"),
  "03 RegFish",
  "First 5-region / 33-fishery BET input step, ending in 2021.",
  c(
    "Uses `bet.2023.new.structure.*` source inputs from the 2026 input build repos.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Uses the old CAAL data re-assigned to the new fisheries.",
    "Uses the old/restructured tag setup with 90 release groups and 91 tag-event rows including pooled tags.",
    "Regenerates `tag_rep_map.R` from the five MFCL reporting-rate matrices in `bet.ini` plus release metadata in `bet.tag`.",
    "Normalizes 84 old records that had an absent-LF sentinel followed by stray LF bins: 67 with WF data and 17 with no composition data.",
    "Applies Arni's 19/06/2026 CPUE index sigma suggestions for index fisheries 29-33.",
    "Applies FixM M row while retaining the 5-region `.ini` structure.",
    "Inserts default MFCL 1007 tag flags for the pre-mix step: 2 mixing periods and reporting rates excluded during mixing."
  ),
  c(
    "bet.frq" = "5-region, 33-fishery structure, terminal year 2021",
    "bet.ini" = "5-region ini with FixM M row and explicit default tag flags",
    "bet.tag" = "90 release-group tag input with low recap groups removed",
    "bet.age_length" = "old CAAL / age_length re-assigned to new fisheries"
  ),
  c(
    "5-region fishery/tag/selectivity controls are remapped in `doitall.sh`.",
    "Index fisheries 29-33 use sigmas 0.28, 0.20, 0.22, 0.21, and 0.24.",
    "The `-9999 1 2` all-release mixing-period setting is retained for this pre-mix step."
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.",
    "The 84 normalized absent-LF records should be reviewed against the upstream frq-build script so the source generator can eventually emit MFCL-ready records.",
    "The upstream non-mix `.ini` files are labelled 1007 but omit `# tag flags`; generated 03-07 inputs now insert explicit default tag flags for MFCL >=2.2.7.5.",
    "Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
regfish_ini <- file.path(root, "steps", "03-RegFish", "model", "bet.ini")
regfish_tag <- file.path(root, "steps", "03-RegFish", "model", "bet.tag")
full_plus_frq <- file.path(frq_root, "bet.2026.wt.as.len.plus.len.frq")
wt_as_len_frq <- file.path(frq_root, "bet.2026.wt.as.len.frq")

make_step(
  step_id = "04-WtAsLen21",
  frq_source = wt_as_len_frq,
  ini_source = regfish_ini,
  tag_source = regfish_tag,
  age_source = old_age,
  frq_chop_year = 2021L,
  frq_tag_groups = 90L,
  title = "04 WtAsLen21",
  summary = "Transition step using the 2026 weights-as-lengths frequency file, chopped back to the 2023 terminal year.",
  bullets = c(
    "Derived `bet.frq` from `bet.2026.wt.as.len.frq` by keeping records with year <= 2021 and updating the dataset count.",
    "Keeps the 03-RegFish 90-release tag/ini structure because this step remains a 2021-terminal comparison.",
    "Resets the chopped `.frq` tag-group header from 91 to 90 to match the selected tag file.",
    "Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.",
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.frq`, chopped to 2021 with tag-group header reset to 90",
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 90-release tag set."
  ),
  run_notes = c(
    "Kflow failed when this 2021-chopped `.frq` was paired with the 2026 91-release `.ini/.tag`; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's 90-release setup, and the chopped `.frq` tag-group header is reset from 91 to 90.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "Confirm the 2021 chop of the 2026 weights-as-lengths `.frq` gives the intended transition-only comparison.",
    "Confirm with the modelling group that 04 should isolate the frequency-file transition while holding the 03-RegFish tag/ini structure.",
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
  frq_tag_groups = 90L,
  title = "05 WtAsLenPlusLen21",
  summary = "Transition step using weights converted to lengths plus observed lengths, still chopped to 2021.",
  bullets = c(
    "Derived `bet.frq` from `bet.2026.wt.as.len.plus.len.frq` by keeping records with year <= 2021.",
    "Maintains the old CAAL input while moving the size-composition frequency file to the plus-length variant.",
    "Keeps the 03-RegFish 90-release tag/ini structure because this step remains a 2021-terminal comparison.",
    "Resets the chopped `.frq` tag-group header from 91 to 90 to match the selected tag file.",
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, chopped to 2021 with tag-group header reset to 90",
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 90-release tag set."
  ),
  run_notes = c(
    "Kflow failed when this 2021-chopped `.frq` was paired with the 2026 91-release `.ini/.tag`; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's 90-release setup, and the chopped `.frq` tag-group header is reset from 91 to 90.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "Confirm the 2021 chop of the plus-length `.frq` matches the stepwise plan's 2023-terminal comparison.",
    "Confirm with the modelling group that 05 should isolate the plus-length transition while holding the 03-RegFish tag/ini structure.",
    "Compare against 04-WtAsLen21 to isolate the effect of adding observed lengths."
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
    "Keeps the extraction-fishery selectivity mapping and fishery-specific constraints from 03-RegFish, while index fisheries remain unshared under regional scaling."
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
  summary = "Orthogonal polynomial recruitment step after size-based selectivity.",
  bullets = c(
    "Uses the same input files as 09-SizeBasedSel.",
    "Applies OPR controls in PHASE 3 of `doitall.sh`, following John's suggestion to keep early phases on mean-plus-deviate recruitment.",
    "Uses OPR year effect 70, region effect 4, season effect 3, and no region-season interaction."
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
    "`1 149 0`, `1 398 0`, `2 177 0`, and `2 32 0` are applied at PHASE 3 for the OPR transfer.",
    "`1 155 70`, `1 216 4`, `1 217 3`, and `1 218 0` activate OPR year, region, season, and no region-season interaction.",
    "`2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase."
  ),
  outstanding = c(
    "OPR year-effect dimension 70 follows the YFT 2026 experiment and should be revisited if the BET team chooses 50 or 30 instead.",
    "Not yet implemented: optional OPR region-season interaction (`1 218`) if diagnostics suggest it is needed."
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
    "The transform follows the available single-region eff-creep file pattern: effort is multiplied by `1 + 0.01 * (year - 1952)`.",
    "Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "10-OPR `doitall.sh` controls are retained.",
    "No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`."
  ),
  outstanding = c(
    "Confirm that this 1 percent per year linear creep is the intended BET spatial minimum-effort-creep scenario.",
    "Not yet checked against a separately generated 5-region effort-creep `.frq` because the input repo currently exposes only the single-region eff-creep output."
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
    "Keeps size-based selectivity and OPR controls from 10-OPR.",
    "Changes global LF and WF sample-size divisors from 20 to 40 in `doitall.sh`."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "`-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.",
    "Fishery-specific divisor-40 settings inherited from 03-RegFish are retained."
  ),
  outstanding = c(
    "This is a first runnable manual weighting scenario, not a final tuned weighting scheme.",
    "Not yet implemented: alternative divisor scenarios or targeted CAAL/size weighting after diagnostics."
  )
)
