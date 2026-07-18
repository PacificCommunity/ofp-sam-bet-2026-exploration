# Reproducible harmonization of the MFCL tag-reporting prior for Group 17.
#
# MFCL applies only the first positive reporting-rate penalty encountered for a
# reporting group. Every positive Group 17 cell must therefore carry the same
# target and penalty to make the prior independent of release/fishery ordering.

TAG_REPORTING_GROUP17 <- 17L
TAG_REPORTING_GROUP17_TARGET <- 52.015
TAG_REPORTING_GROUP17_PENALTY <- 336.854
TAG_REPORTING_GROUP17_MEAN <- 0.52015
TAG_REPORTING_GROUP17_SD <- 0.038527

group17_stop <- function(...) {
  stop(paste0(...), call. = FALSE)
}

read_ini_matrix_section <- function(lines, header, path) {
  header_line <- which(trimws(lines) == header)
  if (length(header_line) != 1L) {
    group17_stop(path, ": expected exactly one ", header, " section")
  }

  later_headers <- which(
    seq_along(lines) > header_line &
      grepl("^[[:space:]]*#", lines)
  )
  if (!length(later_headers)) {
    group17_stop(path, ": no section follows ", header)
  }

  line_indices <- seq.int(header_line + 1L, later_headers[[1L]] - 1L)
  line_indices <- line_indices[nzchar(trimws(lines[line_indices]))]
  if (!length(line_indices)) {
    group17_stop(path, ": empty ", header, " section")
  }

  token_rows <- strsplit(trimws(lines[line_indices]), "[[:space:]]+")
  widths <- lengths(token_rows)
  if (length(unique(widths)) != 1L || widths[[1L]] < 1L) {
    group17_stop(path, ": ragged ", header, " matrix")
  }

  values <- suppressWarnings(as.numeric(unlist(token_rows, use.names = FALSE)))
  if (any(!is.finite(values))) {
    group17_stop(path, ": non-numeric value in ", header)
  }

  list(
    header = header,
    line_indices = line_indices,
    tokens = token_rows,
    values = matrix(
      values,
      nrow = length(token_rows),
      ncol = widths[[1L]],
      byrow = TRUE
    )
  )
}

pair_matches <- function(target, penalty, expected_target, expected_penalty) {
  abs(target - expected_target) < 1e-8 &&
    abs(penalty - expected_penalty) < 1e-8
}

audit_group17_positive_pair <- function(groups, targets, penalties, path) {
  positive <- groups == TAG_REPORTING_GROUP17 & penalties > 0
  if (!any(positive)) {
    group17_stop(path, ": Group 17 has no positive reporting-rate penalty")
  }

  pairs <- unique(data.frame(
    target = targets[positive],
    penalty = penalties[positive]
  ))
  if (nrow(pairs) != 1L) {
    rendered <- paste(
      sprintf("(%s, %s)", pairs$target, pairs$penalty),
      collapse = ", "
    )
    group17_stop(
      path,
      ": Group 17 retains multiple positive target/penalty pairs: ",
      rendered
    )
  }
  if (!pair_matches(
    pairs$target[[1L]],
    pairs$penalty[[1L]],
    TAG_REPORTING_GROUP17_TARGET,
    TAG_REPORTING_GROUP17_PENALTY
  )) {
    group17_stop(
      path,
      ": Group 17 positive pair is not the approved (",
      TAG_REPORTING_GROUP17_TARGET,
      ", ",
      TAG_REPORTING_GROUP17_PENALTY,
      ")"
    )
  }

  sum(positive)
}

replace_matrix_cells <- function(lines, section, cells, value) {
  for (row in unique(cells[, "row"])) {
    columns <- cells[cells[, "row"] == row, "col"]
    tokens <- section$tokens[[row]]
    tokens[columns] <- value
    lines[section$line_indices[[row]]] <- paste(tokens, collapse = " ")
  }
  lines
}

count_fixed <- function(lines, value) {
  matches <- regmatches(lines, gregexpr(value, lines, fixed = TRUE))
  sum(lengths(matches))
}

prepare_tag_rep_map <- function(path) {
  lines <- readLines(path, warn = FALSE)
  old_target <- "\"51.21,52.82\""
  old_penalty <- "\"739.2,231.2\""
  new_target <- "\"52.015\""
  new_penalty <- "\"336.854\""

  old_counts <- c(
    target = count_fixed(lines, old_target),
    penalty = count_fixed(lines, old_penalty)
  )
  new_counts <- c(
    target = count_fixed(lines, new_target),
    penalty = count_fixed(lines, new_penalty)
  )

  if (identical(unname(old_counts), c(1L, 1L))) {
    lines <- gsub(old_target, new_target, lines, fixed = TRUE)
    lines <- gsub(old_penalty, new_penalty, lines, fixed = TRUE)
  } else if (!identical(unname(old_counts), c(0L, 0L)) ||
             any(new_counts < 1L)) {
    group17_stop(
      path,
      ": reporting-map Group 17 summary is neither the archived candidates ",
      "nor the approved harmonized pair"
    )
  }

  if (count_fixed(lines, old_target) != 0L ||
      count_fixed(lines, old_penalty) != 0L ||
      count_fixed(lines, new_target) < 1L ||
      count_fixed(lines, new_penalty) < 1L) {
    group17_stop(path, ": failed to harmonize the Group 17 reporting-map summary")
  }

  lines
}

csv_quote <- function(value) {
  paste0("\"", gsub("\"", "\"\"", value, fixed = TRUE), "\"")
}

append_manifest_note <- function(lines, role, marker, note, path) {
  row <- grep(paste0("^\"", role, "\","), lines)
  if (length(row) != 1L) {
    group17_stop(path, ": expected one manifest role ", role)
  }
  if (grepl(marker, lines[[row]], fixed = TRUE)) {
    return(lines)
  }
  if (!grepl("\"$", lines[[row]])) {
    group17_stop(path, ": malformed manifest row for ", role)
  }
  lines[[row]] <- paste0(
    substr(lines[[row]], 1L, nchar(lines[[row]]) - 1L),
    " ",
    note,
    "\""
  )
  lines
}

prepare_manifest <- function(path, positive_cell_count) {
  lines <- readLines(path, warn = FALSE)
  marker <- "Group 17 harmonization:"
  lines <- append_manifest_note(
    lines,
    "ini",
    marker,
    paste0(
      marker,
      " generated bet.ini copies replace every positive Group 17 target/penalty ",
      "cell with 52.015/336.854; the archived ini hash above describes the ",
      "pre-transform source."
    ),
    path
  )
  lines <- append_manifest_note(
    lines,
    "tag_reporting_map",
    marker,
    paste0(
      marker,
      " target_values and penalty_values report the same approved ",
      "52.015/336.854 pair."
    ),
    path
  )

  audit_role <- "tag_reporting_group17_prior_audit"
  audit_row <- paste(vapply(
    c(
      audit_role,
      "tag_reporting_group17_prior_audit.csv",
      "notes/tag-reporting-group17-prior.md",
      "",
      paste0(
        "Generator audit of ",
        positive_cell_count,
        " positive Group 17 event-row/fishery cells. Generation fails unless ",
        "all resolve to the single target/penalty pair 52.015/336.854."
      )
    ),
    csv_quote,
    character(1)
  ), collapse = ",")

  existing <- grep(paste0("^\"", audit_role, "\","), lines)
  if (length(existing) > 1L) {
    group17_stop(path, ": duplicate ", audit_role, " manifest rows")
  }
  if (length(existing) == 1L) {
    lines[[existing]] <- audit_row
  } else {
    lines <- c(lines, audit_row)
  }
  lines
}

prepare_group17_model <- function(model_id, sensitivity_root) {
  model_dir <- file.path(sensitivity_root, model_id, "model")
  ini_path <- file.path(model_dir, "bet.ini")
  map_path <- file.path(model_dir, "tag_rep_map.R")
  manifest_path <- file.path(sensitivity_root, model_id, "input_manifest.csv")

  required <- c(ini_path, map_path, manifest_path)
  missing <- required[!file.exists(required)]
  if (length(missing)) {
    group17_stop(model_id, ": missing generated file(s): ", paste(missing, collapse = ", "))
  }

  ini_lines <- readLines(ini_path, warn = FALSE)
  groups <- read_ini_matrix_section(
    ini_lines,
    "# tag fish rep group flags",
    ini_path
  )
  targets <- read_ini_matrix_section(
    ini_lines,
    "# tag_fish_rep target",
    ini_path
  )
  penalties <- read_ini_matrix_section(
    ini_lines,
    "# tag_fish_rep penalty",
    ini_path
  )

  dimensions <- lapply(
    list(groups$values, targets$values, penalties$values),
    dim
  )
  if (!identical(dimensions[[1L]], dimensions[[2L]]) ||
      !identical(dimensions[[1L]], dimensions[[3L]])) {
    group17_stop(ini_path, ": reporting matrices have inconsistent dimensions")
  }

  group17_cells <- groups$values == TAG_REPORTING_GROUP17
  if (!any(group17_cells)) {
    group17_stop(ini_path, ": reporting Group 17 is absent")
  }
  if (any(penalties$values[group17_cells] <= 0)) {
    group17_stop(
      ini_path,
      ": reporting Group 17 contains a non-positive penalty cell"
    )
  }

  old_targets <- targets$values
  old_penalties <- penalties$values
  source_pairs <- unique(data.frame(
    target = old_targets[group17_cells],
    penalty = old_penalties[group17_cells]
  ))
  allowed <- vapply(seq_len(nrow(source_pairs)), function(index) {
    pair_matches(
      source_pairs$target[[index]],
      source_pairs$penalty[[index]],
      51.21,
      739.2
    ) ||
      pair_matches(
        source_pairs$target[[index]],
        source_pairs$penalty[[index]],
        52.82,
        231.2
      ) ||
      pair_matches(
        source_pairs$target[[index]],
        source_pairs$penalty[[index]],
        TAG_REPORTING_GROUP17_TARGET,
        TAG_REPORTING_GROUP17_PENALTY
      )
  }, logical(1))
  if (any(!allowed)) {
    unexpected <- source_pairs[!allowed, , drop = FALSE]
    group17_stop(
      ini_path,
      ": unexpected Group 17 source pair(s): ",
      paste(
        sprintf("(%s, %s)", unexpected$target, unexpected$penalty),
        collapse = ", "
      )
    )
  }

  targets_after <- old_targets
  penalties_after <- old_penalties
  targets_after[group17_cells] <- TAG_REPORTING_GROUP17_TARGET
  penalties_after[group17_cells] <- TAG_REPORTING_GROUP17_PENALTY
  if (!identical(targets_after[!group17_cells], old_targets[!group17_cells]) ||
      !identical(penalties_after[!group17_cells], old_penalties[!group17_cells])) {
    group17_stop(ini_path, ": non-Group-17 values changed during harmonization")
  }

  positive_cell_count <- audit_group17_positive_pair(
    groups$values,
    targets_after,
    penalties_after,
    ini_path
  )
  cells <- which(group17_cells, arr.ind = TRUE)
  cells <- cells[order(cells[, "row"], cells[, "col"]), , drop = FALSE]
  old_cell_targets <- old_targets[cbind(cells[, "row"], cells[, "col"])]
  old_cell_penalties <- old_penalties[cbind(cells[, "row"], cells[, "col"])]

  ini_lines <- replace_matrix_cells(
    ini_lines,
    targets,
    cells,
    "52.015"
  )
  ini_lines <- replace_matrix_cells(
    ini_lines,
    penalties,
    cells,
    "336.854"
  )

  candidate <- ifelse(
    abs(old_cell_targets - 51.21) < 1e-8 &
      abs(old_cell_penalties - 739.2) < 1e-8,
    "West",
    ifelse(
      abs(old_cell_targets - 52.82) < 1e-8 &
        abs(old_cell_penalties - 231.2) < 1e-8,
      "East",
      "harmonized"
    )
  )
  audit <- data.frame(
    tag_event_row = cells[, "row"],
    event_type = ifelse(cells[, "row"] == 99L, "pooled", "release"),
    fishery = cells[, "col"],
    reporting_group = TAG_REPORTING_GROUP17,
    source_candidate = candidate,
    old_target = old_cell_targets,
    old_penalty = old_cell_penalties,
    old_mean = old_cell_targets / 100,
    old_sd = sqrt(1 / (2 * old_cell_penalties)),
    new_target = TAG_REPORTING_GROUP17_TARGET,
    new_penalty = TAG_REPORTING_GROUP17_PENALTY,
    new_mean = TAG_REPORTING_GROUP17_MEAN,
    new_sd = TAG_REPORTING_GROUP17_SD,
    stringsAsFactors = FALSE
  )

  list(
    model_id = model_id,
    ini_path = ini_path,
    ini_lines = ini_lines,
    map_path = map_path,
    map_lines = prepare_tag_rep_map(map_path),
    manifest_path = manifest_path,
    manifest_lines = prepare_manifest(manifest_path, positive_cell_count),
    audit_path = file.path(
      model_dir,
      "tag_reporting_group17_prior_audit.csv"
    ),
    audit = audit,
    positive_cell_count = positive_cell_count
  )
}

atomic_write_lines <- function(lines, path) {
  temporary <- tempfile(
    pattern = paste0(".", basename(path), "-"),
    tmpdir = dirname(path)
  )
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  writeLines(lines, temporary, useBytes = TRUE)
  if (!file.rename(temporary, path)) {
    group17_stop("Could not atomically replace ", path)
  }
}

atomic_write_csv <- function(value, path) {
  temporary <- tempfile(
    pattern = paste0(".", basename(path), "-"),
    tmpdir = dirname(path)
  )
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)
  write.csv(value, temporary, row.names = FALSE, na = "")
  if (!file.rename(temporary, path)) {
    group17_stop("Could not atomically replace ", path)
  }
}

harmonize_tag_reporting_group17_tree <- function(
    sensitivity_root,
    model_ids,
    expected_model_count = 97L) {
  if (length(model_ids) != expected_model_count ||
      anyDuplicated(model_ids)) {
    group17_stop(
      "Group 17 harmonization expected ",
      expected_model_count,
      " unique models; found ",
      length(unique(model_ids))
    )
  }

  prepared <- lapply(
    model_ids,
    prepare_group17_model,
    sensitivity_root = sensitivity_root
  )
  cell_counts <- vapply(
    prepared,
    function(model) model$positive_cell_count,
    integer(1)
  )
  if (length(unique(cell_counts)) != 1L) {
    group17_stop(
      "Group 17 positive-cell counts differ across generated models: ",
      paste(unique(cell_counts), collapse = ", ")
    )
  }

  for (model in prepared) {
    atomic_write_lines(model$ini_lines, model$ini_path)
    atomic_write_lines(model$map_lines, model$map_path)
    atomic_write_lines(model$manifest_lines, model$manifest_path)
    atomic_write_csv(model$audit, model$audit_path)
  }

  data.frame(
    model_id = model_ids,
    positive_cell_count = cell_counts,
    target = TAG_REPORTING_GROUP17_TARGET,
    penalty = TAG_REPORTING_GROUP17_PENALTY,
    stringsAsFactors = FALSE
  )
}
