## FRQ/INI/tag compatibility and audit helpers -------------------------------

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
  # Keep tag-reporting matrices synchronized with the release groups in bet.tag.
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

copy_tag_reporting_matrices <- function(path, source_ini) {
  # Copy only the reporting-rate matrices, leaving tag flags and all other
  # controls in the target ini unchanged.
  markers <- c(
    "# tag fish rep",
    "# tag fish rep group flags",
    "# tag_fish_rep active flags",
    "# tag_fish_rep target",
    "# tag_fish_rep penalty"
  )
  if (!nzchar(source_ini) || !file.exists(source_ini)) {
    stop("Missing tag reporting-rate source ini: ", source_ini, call. = FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  source_lines <- readLines(source_ini, warn = FALSE)
  changed <- character()
  for (marker in markers) {
    row_idx <- ini_matrix_row_indices(lines, marker)
    source_row_idx <- ini_matrix_row_indices(source_lines, marker)
    rows <- lines[row_idx]
    source_rows <- source_lines[source_row_idx]
    if (length(rows) != length(source_rows)) {
      stop(
        "Cannot copy ", marker, " from ", source_ini, " to ", path,
        ": row counts differ (", length(source_rows), " vs ", length(rows), ").",
        call. = FALSE
      )
    }
    target_widths <- unique(lengths(strsplit(trimws(rows), "[[:space:]]+")))
    source_widths <- unique(lengths(strsplit(trimws(source_rows), "[[:space:]]+")))
    if (length(target_widths) != 1L || length(source_widths) != 1L ||
        !identical(target_widths[[1L]], source_widths[[1L]])) {
      stop(
        "Cannot copy ", marker, " from ", source_ini, " to ", path,
        ": matrix widths differ.",
        call. = FALSE
      )
    }
    if (!identical(trimws(rows), trimws(source_rows))) {
      lines[row_idx] <- source_rows
      changed <- c(changed, marker)
    }
  }

  if (!length(changed)) return(invisible(""))
  writeLines(lines, path, sep = file_eol(path), useBytes = TRUE)
  paste0(
    "copied ", length(changed),
    " tag reporting-rate matrix block(s) from ", basename(source_ini),
    " without changing tag_flags"
  )
}

repair_tag_reporting_grouped_initial_values <- function(path) {
  # Native MFCL requires every cell in a reporting-rate group to have the same
  # active flag and starting value. If the upstream grouping is intentional,
  # preserve the group flags and harmonize only the starting RR value. Targets
  # and penalties are left unchanged.
  markers <- c(
    rep = "# tag fish rep",
    group = "# tag fish rep group flags",
    active = "# tag_fish_rep active flags"
  )
  lines <- readLines(path, warn = FALSE)
  row_idx <- lapply(markers, function(marker) ini_matrix_row_indices(lines, marker))
  rows <- lapply(row_idx, function(idx) strsplit(trimws(lines[idx]), "[[:space:]]+"))
  widths <- lapply(rows, function(x) unique(lengths(x)))
  if (any(lengths(widths) != 1L) || length(unique(unlist(widths, use.names = FALSE))) != 1L) {
    stop("Tag reporting-rate matrices have inconsistent widths in ", path, call. = FALSE)
  }
  row_counts <- vapply(rows, length, integer(1))
  if (length(unique(row_counts)) != 1L) {
    stop("Tag reporting-rate matrices have inconsistent row counts in ", path, call. = FALSE)
  }

  to_matrix <- function(x, mode = c("numeric", "integer")) {
    mode <- match.arg(mode)
    value <- unlist(x, use.names = FALSE)
    value <- if (identical(mode, "integer")) as.integer(value) else as.numeric(value)
    matrix(value, nrow = length(x), byrow = TRUE)
  }
  rep <- to_matrix(rows$rep, "numeric")
  group <- to_matrix(rows$group, "integer")
  active <- to_matrix(rows$active, "integer")
  if (!identical(dim(rep), dim(group)) || !identical(dim(rep), dim(active))) {
    stop("Tag reporting-rate matrices have inconsistent dimensions in ", path, call. = FALSE)
  }

  changes <- list()
  for (g in sort(unique(as.vector(group[group > 0L])))) {
    cells <- which(group == g, arr.ind = TRUE)
    if (!nrow(cells)) next
    cells <- cells[order(cells[, "row"], cells[, "col"]), , drop = FALSE]
    active_values <- unique(active[cells])
    if (length(active_values) > 1L) {
      stop(
        "Tag reporting-rate group ", g,
        " has mixed active flags in ", path,
        ". This needs a group-flag fix, not an initial-value-only repair.",
        call. = FALSE
      )
    }
    values <- rep[cells]
    unique_values <- unique(round(values, 12))
    if (length(unique_values) <= 1L) next

    replacement <- rows$rep[[cells[[1L, "row"]]]][[cells[[1L, "col"]]]]
    changes[[length(changes) + 1L]] <- data.frame(
      group = g,
      replacement = replacement,
      old_values = paste(format(sort(unique(values)), scientific = FALSE, trim = TRUE), collapse = ","),
      n_cells = nrow(cells),
      fisheries = compact_ints(cells[, "col"]),
      release_rows = compact_ints(cells[, "row"]),
      stringsAsFactors = FALSE
    )
    for (i in seq_len(nrow(cells))) {
      rows$rep[[cells[[i, "row"]]]][[cells[[i, "col"]]]] <- replacement
    }
  }
  if (!length(changes)) return(invisible(""))

  lines[row_idx$rep] <- vapply(rows$rep, paste, collapse = " ", character(1))
  writeLines(lines, path, sep = file_eol(path), useBytes = TRUE)

  changed <- do.call(rbind, changes)
  paste0(
    "harmonized initial RR values only in ", nrow(changed),
    " tag reporting-rate group(s) so grouped starts are native-MFCL compatible; ",
    "group flags, targets, and penalties unchanged"
  )
}

validate_tag_reporting_grouped_initial_values <- function(path) {
  rep <- extract_ini_matrix(path, "# tag fish rep")
  group <- extract_ini_matrix(path, "# tag fish rep group flags")
  active <- extract_ini_matrix(path, "# tag_fish_rep active flags")
  if (!identical(dim(rep), dim(group)) || !identical(dim(rep), dim(active))) {
    stop("Tag reporting-rate matrices have inconsistent dimensions in ", path, call. = FALSE)
  }
  bad <- list()
  for (g in sort(unique(as.vector(group[group > 0])))) {
    cells <- which(group == g, arr.ind = TRUE)
    keys <- unique(paste(active[cells], round(rep[cells], 12), sep = "|"))
    if (length(keys) > 1L) {
      bad[[length(bad) + 1L]] <- paste0(
        "group ", g, " has ", length(keys),
        " active/RR combinations across fisheries ",
        compact_ints(cells[, "col"])
      )
    }
  }
  if (length(bad)) {
    stop(
      "Native MFCL-incompatible tag reporting-rate group initials in ",
      path, ": ", paste(bad, collapse = "; "),
      call. = FALSE
    )
  }
  invisible("")
}

tag_recapture_table <- function(path) {
  lines <- readLines(path, warn = FALSE)
  release_header <- grep("#[[:space:]]+[0-9]+ - RELEASE REGION", lines)
  if (!length(release_header)) {
    stop("Could not find tag release blocks in ", path, call. = FALSE)
  }

  out <- list()
  out_i <- 0L
  for (h_i in seq_along(release_header)) {
    start <- release_header[[h_i]]
    end <- if (h_i < length(release_header)) release_header[[h_i + 1L]] - 1L else length(lines)
    title <- trimws(sub("^#[[:space:]]*", "", lines[[start]]))
    release_group <- as.integer(sub("^([0-9]+).*", "\\1", title))
    rec_marker <- grep(
      "^#[[:space:]]*LENGTH RELEASE[[:space:]]+FISHERY[[:space:]]+RECAP YEAR",
      lines[start:end]
    )
    if (!length(rec_marker)) next
    rec_start <- start + rec_marker[[1L]]
    if (rec_start > end) next
    candidates <- lines[rec_start:end]
    candidates <- candidates[nzchar(trimws(candidates))]
    candidates <- candidates[!startsWith(trimws(candidates), "#")]
    if (!length(candidates)) next
    for (line in candidates) {
      words <- read_words(line)
      if (length(words) < 5L) next
      values <- suppressWarnings(as.integer(words[1:5]))
      if (anyNA(values)) next
      out_i <- out_i + 1L
      out[[out_i]] <- data.frame(
        release_group = release_group,
        release_length = values[[1L]],
        recap_fishery = values[[2L]],
        recap_year = values[[3L]],
        recap_month = values[[4L]],
        recap_number = values[[5L]],
        stringsAsFactors = FALSE
      )
    }
  }

  if (!length(out)) {
    return(data.frame(
      release_group = integer(),
      release_length = integer(),
      recap_fishery = integer(),
      recap_year = integer(),
      recap_month = integer(),
      recap_number = integer(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, out)
}

repair_positive_tag_recapture_reporting_rates <- function(path, tag_path,
                                                          target_fishery,
                                                          source_fishery) {
  # If a tag file contains positive recaptures for a fishery, the matching
  # reporting-rate cells in the ini must not be left as inactive zero cells.
  # This targeted repair is used for BET 2026 canneries recaptures assigned to
  # fishery 19, borrowing the matching purse-seine fishery 21 RR setup.
  markers <- c(
    rep = "# tag fish rep",
    group = "# tag fish rep group flags",
    active = "# tag_fish_rep active flags",
    target = "# tag_fish_rep target",
    penalty = "# tag_fish_rep penalty"
  )
  target_fishery <- as.integer(target_fishery)
  source_fishery <- as.integer(source_fishery)
  if (!is.finite(target_fishery) || !is.finite(source_fishery) ||
      target_fishery < 1L || source_fishery < 1L) {
    stop("target_fishery and source_fishery must be positive integers", call. = FALSE)
  }

  recaps <- tag_recapture_table(tag_path)
  affected <- sort(unique(recaps$release_group[
    recaps$recap_fishery == target_fishery & recaps$recap_number > 0L
  ]))
  if (!length(affected)) return(invisible(""))

  lines <- readLines(path, warn = FALSE)
  row_idx <- lapply(markers, function(marker) ini_matrix_row_indices(lines, marker))
  row_counts <- vapply(row_idx, length, integer(1))
  if (length(unique(row_counts)) != 1L) {
    stop(
      "Tag reporting-rate matrices have inconsistent row counts in ",
      path, ": ", paste(paste(markers, row_counts, sep = "="), collapse = ", "),
      call. = FALSE
    )
  }
  if (max(affected) > row_counts[[1L]]) {
    stop(
      "Positive tag recaptures refer to release group ", max(affected),
      " but reporting-rate matrices in ", path, " have only ",
      row_counts[[1L]], " rows.",
      call. = FALSE
    )
  }

  rows <- lapply(row_idx, function(idx) strsplit(trimws(lines[idx]), "[[:space:]]+"))
  widths <- vapply(rows, function(x) unique(lengths(x)), integer(1))
  if (any(widths < max(target_fishery, source_fishery))) {
    stop(
      "Reporting-rate matrices in ", path, " do not include fishery ",
      max(target_fishery, source_fishery), ".",
      call. = FALSE
    )
  }

  value_at <- function(marker_name, release_group, fishery) {
    suppressWarnings(as.numeric(rows[[marker_name]][[release_group]][[fishery]]))
  }
  needs_repair <- affected[vapply(affected, function(g) {
    any(c(
      value_at("rep", g, target_fishery) == 0,
      value_at("active", g, target_fishery) == 0,
      value_at("target", g, target_fishery) == 0,
      value_at("penalty", g, target_fishery) == 0
    ), na.rm = TRUE)
  }, logical(1))]
  if (!length(needs_repair)) return(invisible(""))

  bad_source <- needs_repair[vapply(needs_repair, function(g) {
    any(c(
      value_at("rep", g, source_fishery) == 0,
      value_at("active", g, source_fishery) == 0,
      value_at("target", g, source_fishery) == 0,
      value_at("penalty", g, source_fishery) == 0
    ), na.rm = TRUE)
  }, logical(1))]
  if (length(bad_source)) {
    stop(
      "Cannot repair fishery ", target_fishery,
      " reporting rates from fishery ", source_fishery,
      " because the source cells are incomplete for release group(s) ",
      compact_ints(bad_source), ".",
      call. = FALSE
    )
  }

  for (marker_name in names(markers)) {
    for (g in needs_repair) {
      rows[[marker_name]][[g]][[target_fishery]] <-
        rows[[marker_name]][[g]][[source_fishery]]
    }
    lines[row_idx[[marker_name]]] <- vapply(
      rows[[marker_name]],
      paste,
      collapse = " ",
      character(1)
    )
  }

  writeLines(lines, path, sep = file_eol(path), useBytes = TRUE)
  paste0(
    "filled fishery ", target_fishery,
    " reporting-rate cells for positive tag recaptures from fishery ",
    source_fishery,
    " settings in release groups ", compact_ints(needs_repair)
  )
}

validate_positive_tag_recapture_reporting_rates <- function(path, tag_path) {
  recaps <- tag_recapture_table(tag_path)
  recaps <- recaps[recaps$recap_number > 0L, , drop = FALSE]
  if (!nrow(recaps)) return(invisible(""))

  rep <- extract_ini_matrix(path, "# tag fish rep")
  active <- extract_ini_matrix(path, "# tag_fish_rep active flags")
  target <- extract_ini_matrix(path, "# tag_fish_rep target")
  penalty <- extract_ini_matrix(path, "# tag_fish_rep penalty")
  dims <- vapply(list(rep, active, target, penalty), function(x) paste(dim(x), collapse = "x"), character(1))
  if (length(unique(dims)) != 1L) {
    stop("Tag reporting-rate matrices have inconsistent dimensions in ", path, call. = FALSE)
  }
  outside <- recaps$release_group > nrow(rep) | recaps$recap_fishery > ncol(rep)
  if (any(outside)) {
    first <- recaps[which(outside)[[1L]], , drop = FALSE]
    stop(
      "Positive tag recapture references release group ", first$release_group,
      " / fishery ", first$recap_fishery,
      " outside reporting-rate matrix dimensions in ", path, ".",
      call. = FALSE
    )
  }

  idx <- cbind(recaps$release_group, recaps$recap_fishery)
  incomplete <- rep[idx] == 0 | active[idx] == 0 | target[idx] == 0 | penalty[idx] == 0
  if (any(incomplete)) {
    bad <- unique(recaps[incomplete, c("release_group", "recap_fishery")])
    first <- bad$release_group[[1L]]
    first_fishery <- bad$recap_fishery[[1L]]
    stop(
      "Positive tag recaptures have incomplete reporting-rate cells in ",
      path, ". First release group/fishery: ", first, "/", first_fishery,
      ". All affected pairs: ",
      paste(paste(bad$release_group, bad$recap_fishery, sep = "/"), collapse = ", "),
      call. = FALSE
    )
  }
  invisible("")
}

is_tag_flags_marker <- function(line) {
  grepl("^#[[:space:]]*tag[[:space:]]+flags[[:space:]]*$", line)
}

ini_tag_flag_row <- function(mixing_periods, retain_reporting_rates_during_mixing = TRUE) {
  # Column 2 is tag_flags(it,2): 0 keeps reporting rates in predicted tag
  # catches during mixing periods, matching the 2023 assessment setup; 1
  # follows MFCL 1007 sources that exclude reporting rates during mixing.
  reporting_flag <- if (isTRUE(retain_reporting_rates_during_mixing)) 0L else 1L
  paste(c(as.integer(mixing_periods), reporting_flag, rep(0L, 8L)), collapse = " ")
}

ensure_ini_tag_flags <- function(path, n_tag_groups, default_mixing_period = 2L,
                                 tag_path = NULL, terminal_year = NA_integer_,
                                 retain_reporting_rates_during_mixing = TRUE,
                                 force_mixing_period = NA_integer_) {
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
    flag_row <- ini_tag_flag_row(
      default_mixing_period,
      retain_reporting_rates_during_mixing = retain_reporting_rates_during_mixing
    )
    flag_block <- c("# tag flags", rep(flag_row, n_tag_groups))
    lines[[version_i]] <- "1007"
    lines <- c(lines[seq_len(age_value_i)], flag_block, lines[(age_value_i + 1L):length(lines)])
    notes <- c(notes, paste0(
      "inserted MFCL 1007 tag-control rows for ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods"
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
    flag_row <- ini_tag_flag_row(
      default_mixing_period,
      retain_reporting_rates_during_mixing = retain_reporting_rates_during_mixing
    )
    insert_before <- next_comment[[1L]]
    lines <- c(
      lines[seq_len(insert_before - 1L)],
      rep(flag_row, missing_flags),
      lines[insert_before:length(lines)]
    )
    notes <- c(notes, paste0(
      "padded existing MFCL 1007 tag-control rows from ", length(flag_idx),
      " to ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods"
    ))
    tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
    next_comment <- which(seq_along(lines) > tag_marker & grepl("^[[:space:]]*#", lines))
    flag_idx <- seq.int(tag_marker + 1L, next_comment[[1L]] - 1L)
    flag_idx <- flag_idx[nzchar(trimws(lines[flag_idx]))]
  }
  if (length(flag_idx) > n_tag_groups) {
    drop_idx <- flag_idx[seq.int(n_tag_groups + 1L, length(flag_idx))]
    kept_last <- trimws(lines[[flag_idx[[n_tag_groups]]]])
    extra_rows <- trimws(lines[drop_idx])
    if (!all(vapply(extra_rows, identical, logical(1), kept_last))) {
      stop(
        "Found ", length(flag_idx), " tag flag rows in ", path,
        " but only ", n_tag_groups, " release groups are expected, and the ",
        "extra rows are not identical to the final kept tag flag row. ",
        "Refusing to trim tag flags without an explicit release-group mapping.",
        call. = FALSE
      )
    }
    keep <- rep(TRUE, length(lines))
    keep[drop_idx] <- FALSE
    lines <- lines[keep]
    notes <- c(notes, paste0(
      "trimmed extra MFCL 1007 tag-control rows from ", length(flag_idx),
      " to ", n_tag_groups,
      " release groups"
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
  forced_mixing_fixed <- 0L
  reporting_rate_fixed <- 0L
  desired_reporting_flag <- if (isTRUE(retain_reporting_rates_during_mixing)) "0" else "1"
  desired_mixing_period <- if (is.na(force_mixing_period)) {
    NA_character_
  } else {
    as.character(as.integer(force_mixing_period))
  }
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
    if (!is.na(desired_mixing_period) && !identical(words[[1L]], desired_mixing_period)) {
      words[[1L]] <- desired_mixing_period
      forced_mixing_fixed <- forced_mixing_fixed + 1L
    } else if (as.integer(words[[1L]]) < 1L) {
      words[[1L]] <- "1"
      zero_fixed <- zero_fixed + 1L
    }
    if (tag_group %in% terminal_groups && as.integer(words[[1L]]) > 1L) {
      words[[1L]] <- "1"
      terminal_fixed <- c(terminal_fixed, tag_group)
    }
    if (!identical(words[[2L]], desired_reporting_flag)) {
      words[[2L]] <- desired_reporting_flag
      reporting_rate_fixed <- reporting_rate_fixed + 1L
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
  if (forced_mixing_fixed) {
    notes <- c(notes, paste0(
      "set tag_flags(it,1)=", desired_mixing_period, " for ",
      forced_mixing_fixed,
      " release groups so all tag release groups use the same mixing period"
    ))
  }
  if (reporting_rate_fixed) {
    notes <- c(notes, paste0(
      "normalized MFCL 1007 tag-control rows for ", reporting_rate_fixed,
      " release groups"
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

set_total_population_scalar <- function(path, value) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep(
    "^#[[:space:]]*Total population scaling factor [(]LN[(]R0[)][)]$",
    trimws(lines)
  )
  if (!length(marker)) {
    mort_marker <- grep("^# natural mortality [(]per year[)]$", trimws(lines))
    if (length(mort_marker) != 1L) {
      stop("Expected one # natural mortality (per year) marker in ", path, call. = FALSE)
    }
    formatted <- as.character(as.integer(value))
    lines <- c(
      lines[seq_len(mort_marker - 1L)],
      "# Total population scaling factor (LN(R0))",
      formatted,
      lines[mort_marker:length(lines)]
    )
    writeLines(lines, path, sep = eol, useBytes = TRUE)
    return(paste0("inserted total population scaling factor LN(R0)=", formatted))
  }
  if (length(marker) != 1L) {
    stop("Expected one # Total population scaling factor (LN(R0)) marker in ", path, call. = FALSE)
  }
  value_i <- first_data_line_after(lines, marker)
  formatted <- as.character(as.integer(value))
  old <- trimws(lines[[value_i]])
  if (identical(old, formatted)) {
    return(invisible(""))
  }
  lines[[value_i]] <- formatted
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  paste0("set total population scaling factor LN(R0) from ", old, " to ", formatted)
}

set_length_weight_parameters <- function(path, values) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep("^#[[:space:]]*Length-weight parameters[[:space:]]*$", trimws(lines))
  if (length(marker) != 1L) {
    stop("Expected one # Length-weight parameters marker in ", path, call. = FALSE)
  }
  value_i <- first_data_line_after(lines, marker)
  values <- as.character(values)
  if (length(values) != 2L || any(!nzchar(values))) {
    stop("Length-weight parameters must contain exactly two values", call. = FALSE)
  }
  old <- trimws(lines[[value_i]])
  formatted <- paste(values, collapse = " ")
  if (identical(old, formatted)) {
    return(invisible(""))
  }
  old_values <- suppressWarnings(as.numeric(read_words(old)))
  new_values <- suppressWarnings(as.numeric(values))
  numeric_same <- length(old_values) == length(new_values) &&
    all(is.finite(old_values)) &&
    all(is.finite(new_values)) &&
    isTRUE(all.equal(old_values, new_values, tolerance = 1e-12, check.attributes = FALSE))
  lines[[value_i]] <- formatted
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  if (numeric_same) {
    return(invisible(""))
  }
  paste0("set Length-weight parameters from `", old, "` to `", formatted, "`")
}

set_age_length_effective_sample_size <- function(path, value = 0.75) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep("^#[[:space:]]*effective sample size[[:space:]]*$", trimws(lines))
  if (length(marker) != 1L) {
    stop("Expected one # effective sample size marker in ", path, call. = FALSE)
  }
  value_i <- first_data_line_after(lines, marker)
  values <- read_words(lines[[value_i]])
  if (!length(values)) {
    stop("Missing effective sample size values in ", path, call. = FALSE)
  }

  count_marker <- grep("^#[[:space:]]*num age length records[[:space:]]*$", trimws(lines))
  if (length(count_marker) == 1L) {
    count_i <- first_data_line_after(lines, count_marker)
    expected <- suppressWarnings(as.integer(read_words(lines[[count_i]])[[1L]]))
    if (is.finite(expected) && expected != length(values)) {
      stop(
        "Expected ", expected, " age_length effective sample sizes in ", path,
        " but found ", length(values), ".",
        call. = FALSE
      )
    }
  }

  formatted <- format(value, trim = TRUE, scientific = FALSE)
  lines[[value_i]] <- paste(rep(formatted, length(values)), collapse = " ")
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  paste0(
    "set age_length effective sample size to ", formatted,
    " for ", length(values), " records"
  )
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
                                          default_mixing_period = 2L,
                                          retain_reporting_rates_during_mixing = TRUE) {
  # Bring inherited 1003-format inputs up to the fields expected by MFCL 1007.
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
    flag_row <- ini_tag_flag_row(
      default_mixing_period,
      retain_reporting_rates_during_mixing = retain_reporting_rates_during_mixing
    )
    lines <- c(
      lines[seq_len(age_value_i)],
      "# tag flags",
      rep(flag_row, n_tag_groups),
      lines[(age_value_i + 1L):length(lines)]
    )
    notes <- c(notes, paste0(
      "inserted MFCL 1007 tag-control rows for ", n_tag_groups,
      " release groups with ", default_mixing_period,
      " mixing periods"
    ))
  }

  tag_marker <- which(vapply(lines, is_tag_flags_marker, logical(1)))
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
  reporting_rate_fixed <- 0L
  desired_reporting_flag <- if (isTRUE(retain_reporting_rates_during_mixing)) "0" else "1"
  for (i in flag_idx) {
    words <- read_words(lines[[i]])
    if (length(words) != 10L) {
      stop("Malformed tag flag row in ", path, " at line ", i, call. = FALSE)
    }
    if (!identical(words[[2L]], desired_reporting_flag)) {
      words[[2L]] <- desired_reporting_flag
      lines[[i]] <- paste(words, collapse = " ")
      reporting_rate_fixed <- reporting_rate_fixed + 1L
    }
  }
  if (reporting_rate_fixed) {
    notes <- c(notes, paste0(
      "normalized MFCL 1007 tag-control rows for ", reporting_rate_fixed,
      " release groups"
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
  # Apply the documented index-fishery effort multiplier while preserving rows.
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
  # Write an audit table from the actual `.ini` reporting-rate matrices.
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
  out <- vapply(out, function(line) {
    parts <- strsplit(line, "\n", fixed = TRUE)[[1]]
    paste(sub("[ \t]+$", "", parts), collapse = "\n")
  }, character(1))
  while (length(out) && !nzchar(out[[length(out)]])) {
    out <- out[-length(out)]
  }
  writeLines(out, file.path(model_dir, "tag_rep_map.R"), useBytes = TRUE)
}
