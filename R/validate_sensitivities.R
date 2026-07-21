## Validate the focused mix-0.15 unconstrained G7OSHL regional-scaling design.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)
config <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config)
models <- config$stepwise_models

expected_ids <- sprintf("S%03d", 1:32)
actual_ids <- sub("-.*$", "", models$step_id)
if (!is.data.frame(models) || nrow(models) != 32L ||
    !identical(actual_ids, expected_ids) || anyDuplicated(models$step_id)) {
  fail("Expected contiguous model IDs S001:S032")
}
normal_rows <- models$lf_likelihood == "normal"
dm_rows <- models$lf_likelihood == "dm_no_re"
if (sum(normal_rows) != 16L || sum(dm_rows) != 16L ||
    any(models$age_length_variant != "SUB075") ||
    any(models$cutoff_code != "NOCUT") ||
    any(grepl("CUT[0-9]+", models$step_id))) {
  fail("Expected sixteen normal and sixteen DM SUB075 NOCUT models")
}
if (!identical(models$regional_scaling_weight, rep(c(50L, 11L, 1L, 0L), 8L))) {
  fail("Each model family must use REGW50, REGW11, REGW1, and REGW0")
}
if (!identical(models$tag_flag2, rep(rep(c(0L, 1L), each = 4L), 4L))) {
  fail("TAGF2 settings do not match the focused design")
}
expected_reporting_prior <- c(
  rep("manual_8_10", 16L),
  rep("Tom_Peatman_2026_PTTP", 16L)
)
if (!"reporting_rate_prior" %in% names(models) ||
    !identical(as.character(models$reporting_rate_prior), expected_reporting_prior)) {
  fail("Expected sixteen manual_8_10 and sixteen Tom_Peatman_2026_PTTP models")
}
if (any(models$lf_downweight_factor[normal_rows] != 10L) ||
    any(models$lf_size_divisor[normal_rows] != 200L) ||
    any(!is.na(models$lf_downweight_factor[dm_rows])) ||
    any(!is.na(models$lf_size_divisor[dm_rows])) ||
    any(models$dm_grouping[dm_rows] != "G7OSHL") ||
    any(models$dm_nmax[dm_rows] != 10L)) {
  fail("Normal DW10 or DM G7OSHL Nmax10 metadata are incorrect")
}

sensitivity_root <- file.path(root, "sensitivity")
model_dirs <- list.files(sensitivity_root, pattern = "^S[0-9]{3}-", full.names = FALSE)
if (!setequal(model_dirs, models$step_id) || length(model_dirs) != 32L) {
  fail("Generated sensitivity folders do not match job-config.R")
}

sha256_file <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  if (!length(output)) fail("Could not calculate SHA-256 for ", path)
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
expected_age_sha <- "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c"
expected_ini_sha <- "b8a43730e7808c0f2d0f07924a2e175910294ce63a1359c2585b44f9e5e2dad6"
expected_tag_sha <- "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f"
ini_source <- file.path(root, "reference-inputs", "bet.2026.mix-0.15.ini")
if (!file.exists(ini_source) || !identical(sha256_file(ini_source), expected_ini_sha)) {
  fail("Pinned bet.2026.mix-0.15.ini source is missing or has the wrong SHA-256")
}
source_ini_lines <- readLines(ini_source, warn = FALSE)
source_tag_start <- grep("^# tag flags[[:space:]]*$", source_ini_lines)
if (length(source_tag_start) != 1L || source_tag_start + 98L > length(source_ini_lines)) {
  fail("Pinned mix-0.15 INI tag block is missing or incomplete")
}
source_tag_rows <- source_tag_start + seq_len(98L)
source_tag_fields <- strsplit(trimws(source_ini_lines[source_tag_rows]), "[[:space:]]+")
if (any(lengths(source_tag_fields) != 10L) ||
    any(vapply(source_tag_fields, function(x) x[[2L]] != "1", logical(1)))) {
  fail("Pinned mix-0.15 INI does not contain the expected TAGF2ON source block")
}
duplicate_fisheries <- c(1L, 2L, 4L, 6L, 7L, 8L, 10L, 29L:33L)

ini_section_rows <- function(lines, heading) {
  start <- grep(paste0("^[[:space:]]*", heading, "[[:space:]]*$"), lines)
  if (length(start) != 1L) fail("Missing or duplicated INI section: ", heading)
  later_headers <- which(seq_along(lines) > start & grepl("^[[:space:]]*#", lines))
  finish <- if (length(later_headers)) later_headers[[1L]] - 1L else length(lines)
  rows <- seq.int(start + 1L, finish)
  rows[nzchar(trimws(lines[rows])) & !grepl("^#", trimws(lines[rows]))]
}

ini_section_matrix <- function(lines, heading) {
  rows <- ini_section_rows(lines, heading)
  fields <- strsplit(trimws(lines[rows]), "[[:space:]]+")
  if (length(fields) != 99L || any(lengths(fields) != 33L)) {
    fail("Expected a 99 x 33 matrix in INI section ", heading)
  }
  matrix(
    as.numeric(unlist(fields, use.names = FALSE)),
    nrow = 99L, ncol = 33L, byrow = TRUE
  )
}

canonical_prior_ini <- function(lines) {
  for (heading in c("# tag fish rep", "# tag_fish_rep target", "# tag_fish_rep penalty")) {
    rows <- ini_section_rows(lines, heading)
    lines[rows] <- paste0("<", gsub("[^A-Za-z0-9]+", "_", heading), "_ROW_", seq_along(rows), ">")
  }
  lines
}

expected_prior_rows <- list(
  manual_8_10 = data.frame(
    group = c(7L, 10L, 11L, 14L, 17L, 18L, 29L, 30L),
    mean = c(0.586, 0.586, 0, 0.4962, 0.52015, 0.52015, 0.5, 0),
    target = c(58.6, 58.6, 0, 49.62, 52.015, 52.015, 50, 0),
    penalty = c(8, 8, 0, 10, 10, 10, 1, 0)
  ),
  Tom_Peatman_2026_PTTP = data.frame(
    group = c(7L, 10L, 11L, 14L, 17L, 18L, 29L, 30L),
    mean = c(0.4962, 0.5121, 0, 0.4962, 0.5121, 0.5282, 0.5, 0),
    target = c(49.62, 51.21, 0, 49.62, 51.21, 52.82, 50, 0),
    penalty = c(354.5, 739.2, 0, 354.5, 739.2, 231.2, 1, 0)
  )
)

expected_tag_labels <- c(
  "RTTP / PS.2", "RTTP / PS.WEST.3", "RTTP / PS.EAST.4",
  "PTTP/pooled / PS.2", "PTTP/pooled / PS.WEST.3",
  "PTTP/pooled / PS.EAST.4", "JPTP / PS.WEST.3", "JPTP / PS.EAST.4"
)
expected_tag_fisheries <- list(
  `7` = c(19L, 20L), `10` = c(25L, 27L), `11` = c(26L, 28L),
  `14` = c(19L, 20L), `17` = c(25L, 27L), `18` = c(26L, 28L),
  `29` = c(25L, 27L), `30` = c(26L, 28L)
)

tag_map_structure <- function(path) {
  text <- readLines(path, warn = FALSE)
  for (label in expected_tag_labels) {
    if (!any(grepl(label, text, fixed = TRUE))) {
      fail(path, ": missing reporting-rate label ", label)
    }
  }
  # Strip only the three prior-value vectors; all group metadata stays exact.
  text <- paste(text, collapse = "\n")
  text <- gsub(
    paste0(
      "(?s)initial_values = c\\(.*?\\), target_values = c\\(.*?\\), ",
      "penalty_values = c\\(.*?\\)(?=, row.names)"
    ),
    paste0(
      "initial_values = <PRIOR_MEANS>, target_values = <PRIOR_TARGETS>, ",
      "penalty_values = <PRIOR_PENALTIES>"
    ),
    text, perl = TRUE
  )
  gsub("[[:space:]]+", " ", text)
}

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  model_dir <- file.path(sensitivity_root, row$step_id, "model")
  required <- c(
    "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
    "bet.reg_scaling.full", "doitall.sh", "fishery_map.R", "tag_rep_map.R"
  )
  if (!all(file.exists(file.path(model_dir, required)))) {
    fail(row$step_id, ": missing required model input")
  }
  if (!identical(sha256_file(file.path(model_dir, "bet.age_length")), expected_age_sha)) {
    fail(row$step_id, ": age-length input is not SUB075")
  }
  if (!identical(sha256_file(file.path(model_dir, "bet.tag")), expected_tag_sha)) {
    fail(row$step_id, ": tag input is not the pinned low-recaptures-removed file")
  }
  if (file.exists(file.path(model_dir, "lf_cutoff_audit.csv"))) {
    fail(row$step_id, ": NOCUT model contains a cutoff audit")
  }

  ini_lines <- readLines(file.path(model_dir, "bet.ini"), warn = FALSE)
  tag_start <- grep("^# tag flags[[:space:]]*$", ini_lines)
  if (length(tag_start) != 1L || tag_start + 98L > length(ini_lines)) {
    fail(row$step_id, ": tag flag block is missing or incomplete")
  }
  tag_rows <- strsplit(trimws(ini_lines[tag_start + seq_len(98L)]), "[[:space:]]+")
  tag_flag2 <- suppressWarnings(vapply(tag_rows, function(x) as.integer(x[[2L]]), 0L))
  if (anyNA(tag_flag2) || any(tag_flag2 != row$tag_flag2)) {
    fail(row$step_id, ": tag_flags(:,2) does not match the model identity")
  }
  model_tag_rows <- tag_start + seq_len(98L)
  for (j in seq_len(98L)) {
    if (length(tag_rows[[j]]) != length(source_tag_fields[[j]]) ||
        !identical(tag_rows[[j]][-2L], source_tag_fields[[j]][-2L])) {
      fail(row$step_id, ": INI differs from mix-0.15 beyond tag flag column 2 at row ", j)
    }
  }
  if (row$reporting_rate_prior == "manual_8_10") {
    if (!identical(ini_lines[-model_tag_rows], source_ini_lines[-source_tag_rows])) {
      fail(row$step_id, ": manual-prior INI differs from mix-0.15 outside tag flag column 2")
    }
  } else {
    model_canonical <- canonical_prior_ini(ini_lines)
    source_canonical <- canonical_prior_ini(source_ini_lines)
    model_tag_rows_canonical <- grep("^# tag flags[[:space:]]*$", model_canonical) + seq_len(98L)
    source_tag_rows_canonical <- grep("^# tag flags[[:space:]]*$", source_canonical) + seq_len(98L)
    for (j in seq_len(98L)) {
      model_fields <- strsplit(trimws(model_canonical[model_tag_rows_canonical[[j]]]), "[[:space:]]+")[[1L]]
      source_fields <- strsplit(trimws(source_canonical[source_tag_rows_canonical[[j]]]), "[[:space:]]+")[[1L]]
      model_fields[[2L]] <- "<TAGF2>"
      source_fields[[2L]] <- "<TAGF2>"
      model_canonical[model_tag_rows_canonical[[j]]] <- paste(model_fields, collapse = " ")
      source_canonical[source_tag_rows_canonical[[j]]] <- paste(source_fields, collapse = " ")
    }
    if (!identical(model_canonical, source_canonical)) {
      fail(row$step_id, ": PTTP26 INI differs outside allowed reporting-prior and TAGF2 fields")
    }
  }
  expected_prior <- expected_prior_rows[[row$reporting_rate_prior]]
  reporting_groups <- ini_section_matrix(ini_lines, "# tag fish rep group flags")
  means <- ini_section_matrix(ini_lines, "# tag fish rep")
  targets <- ini_section_matrix(ini_lines, "# tag_fish_rep target")
  penalties <- ini_section_matrix(ini_lines, "# tag_fish_rep penalty")
  for (k in seq_len(nrow(expected_prior))) {
    group <- expected_prior$group[[k]]
    cells <- which(reporting_groups == group, arr.ind = TRUE)
    if (!nrow(cells)) {
      fail(row$step_id, ": reporting-rate group ", group, " has no INI cells")
    }
    actual_fisheries <- sort(unique(cells[, "col"]))
    if (!identical(actual_fisheries, expected_tag_fisheries[[as.character(group)]])) {
      fail(row$step_id, ": reporting-rate group ", group,
           " is assigned to unexpected fisheries: ", paste(actual_fisheries, collapse = ","))
    }
    if (any(abs(means[cells] - expected_prior$mean[[k]]) > 1e-8) ||
        any(abs(targets[cells] - expected_prior$target[[k]]) > 1e-8) ||
        any(abs(penalties[cells] - expected_prior$penalty[[k]]) > 1e-8)) {
      fail(row$step_id, ": reporting-rate group ", group,
           " mean, target, or penalty does not match ", row$reporting_rate_prior)
    }
  }
  invisible(tag_map_structure(file.path(model_dir, "tag_rep_map.R")))

  lines <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
  if (any(grepl("^[[:space:]]*-[0-9]+[[:space:]]+16[[:space:]]+1([[:space:]]|$)", lines))) {
    fail(row$step_id, ": a fishery still has the removed flag 16=1 constraint")
  }
  flag77 <- grep("^[[:space:]]*1[[:space:]]+77[[:space:]]+", lines, value = TRUE)
  expected77 <- paste0("^[[:space:]]*1[[:space:]]+77[[:space:]]+", row$regional_scaling_weight, "([[:space:]]|$)")
  if (length(flag77) != 1L || !grepl(expected77, flag77)) {
    fail(row$step_id, ": parest flag 77 does not match REGW identity")
  }
  for (control in c("1 78 1", "1 79 240", "1 80 220", "1 81 1")) {
    pattern <- paste0("^[[:space:]]*", gsub(" ", "[[:space:]]+", control), "([[:space:]]|$)")
    if (sum(grepl(pattern, lines)) != 1L) {
      fail(row$step_id, ": missing regional-scaling control ", control)
    }
  }
  if (sum(grepl("^[[:space:]]*-999[[:space:]]+49[[:space:]]+20([[:space:]]|$)", lines)) != 1L ||
      sum(grepl("^[[:space:]]*-999[[:space:]]+50[[:space:]]+20([[:space:]]|$)", lines)) != 1L) {
    fail(row$step_id, ": global LF/WF divisor 20 is not unique")
  }
  for (fishery in duplicate_fisheries) {
    pattern <- sprintf(
      "^[[:space:]]*-%d[[:space:]]+49[[:space:]]+40[[:space:]]+-%d[[:space:]]+50[[:space:]]+40([[:space:]]|$)",
      fishery, fishery
    )
    if (sum(grepl(pattern, lines)) != 1L) {
      fail(row$step_id, ": inherited duplicate-use divisor 40 missing for F", fishery)
    }
  }

  if (row$lf_likelihood == "normal") {
    if (sum(grepl("^[[:space:]]*1[[:space:]]+141[[:space:]]+3([[:space:]]|$)", lines)) != 1L ||
        any(grepl("^[[:space:]]*1[[:space:]]+342[[:space:]]+", lines))) {
      fail(row$step_id, ": robust-normal likelihood controls are incorrect")
    }
    for (fishery in 21:23) {
      pattern <- sprintf("^[[:space:]]*-%d[[:space:]]+49[[:space:]]+200([[:space:]]|$)", fishery)
      if (sum(grepl(pattern, lines)) != 1L) {
        fail(row$step_id, ": DW10 divisor 200 missing for F", fishery)
      }
    }
  } else {
    if (sum(grepl("^[[:space:]]*1[[:space:]]+141[[:space:]]+11([[:space:]]|$)", lines)) != 1L ||
        sum(grepl("^[[:space:]]*1[[:space:]]+342[[:space:]]+10([[:space:]]|$)", lines)) != 1L ||
        sum(grepl("^[[:space:]]*-[0-9]+[[:space:]]+68[[:space:]]+", lines)) != 33L ||
        sum(grepl("^[[:space:]]*-999[[:space:]]+89[[:space:]]+1([[:space:]]|$)", lines)) != 1L ||
        any(grepl("^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+200([[:space:]]|$)", lines))) {
      fail(row$step_id, ": DM G7OSHL-CEST Nmax10 controls are incorrect")
    }
    expected_groups <- integer(33L)
    expected_groups[c(1:4, 6:8, 10:11)] <- 1L
    expected_groups[c(5, 9)] <- 2L
    expected_groups[c(12, 19:20, 25:28)] <- 3L
    expected_groups[17:18] <- 4L
    expected_groups[14:15] <- 5L
    expected_groups[c(13, 16, 21:24)] <- 6L
    expected_groups[29:33] <- 7L
    for (fishery in 1:33) {
      pattern <- sprintf(
        "^[[:space:]]*-%d[[:space:]]+68[[:space:]]+%d([[:space:]]|$)",
        fishery, expected_groups[[fishery]]
      )
      if (sum(grepl(pattern, lines)) != 1L) {
        fail(row$step_id, ": incorrect G7OSHL group for F", fishery)
      }
    }
  }
}

model_file <- function(step_id, filename) {
  file.path(sensitivity_root, step_id, "model", filename)
}
canonical_regw_doitall <- function(step_id) {
  lines <- readLines(model_file(step_id, "doitall.sh"), warn = FALSE)
  regw_row <- grep("^[[:space:]]*1[[:space:]]+77[[:space:]]+", lines)
  if (length(regw_row) != 1L) {
    fail(step_id, ": cannot canonicalize parest flag 77")
  }
  lines[regw_row] <- "<PAREST_FLAG_77>"
  lines
}
compare_binary_files <- function(left_id, right_id, filenames, context) {
  for (filename in filenames) {
    left_hash <- sha256_file(model_file(left_id, filename))
    right_hash <- sha256_file(model_file(right_id, filename))
    if (!identical(left_hash, right_hash)) {
      fail(context, ": unexpected difference in ", filename, " between ",
           left_id, " and ", right_id)
    }
  }
}
compare_tag_ini <- function(off_id, on_id) {
  off <- readLines(model_file(off_id, "bet.ini"), warn = FALSE)
  on <- readLines(model_file(on_id, "bet.ini"), warn = FALSE)
  off_start <- grep("^# tag flags[[:space:]]*$", off)
  on_start <- grep("^# tag flags[[:space:]]*$", on)
  if (length(off_start) != 1L || length(on_start) != 1L ||
      length(off) != length(on)) {
    fail("Cannot compare tag INI pair ", off_id, " and ", on_id)
  }
  off_rows <- off_start + seq_len(98L)
  on_rows <- on_start + seq_len(98L)
  if (!identical(off[-off_rows], on[-on_rows])) {
    fail("INI fields outside the tag block differ between ", off_id, " and ", on_id)
  }
  off_fields <- strsplit(trimws(off[off_rows]), "[[:space:]]+")
  on_fields <- strsplit(trimws(on[on_rows]), "[[:space:]]+")
  for (j in seq_len(98L)) {
    if (length(off_fields[[j]]) != length(on_fields[[j]]) ||
        !identical(off_fields[[j]][-2L], on_fields[[j]][-2L]) ||
        off_fields[[j]][[2L]] != "0" || on_fields[[j]][[2L]] != "1") {
      fail("Tag INI pair differs beyond flag column 2 at row ", j, ": ",
           off_id, " versus ", on_id)
    }
  }
}

# Within each likelihood/tag family, REGW is the only doitall difference.
family_key <- paste(
  models$reporting_rate_prior, models$lf_likelihood, models$tag_flag2,
  sep = ":"
)
for (indices in split(seq_len(nrow(models)), family_key)) {
  reference <- canonical_regw_doitall(models$step_id[[indices[[1L]]]])
  for (index in indices[-1L]) {
    candidate <- canonical_regw_doitall(models$step_id[[index]])
    if (!identical(reference, candidate)) {
      fail("Unexpected doitall difference within REGW family: ",
           models$step_id[[indices[[1L]]]], " versus ", models$step_id[[index]])
    }
  }
}

common_pair_files <- c(
  "bet.frq", "bet.tag", "bet.age_length", "bet.reg_scaling",
  "bet.reg_scaling.full", "fishery_map.R", "tag_rep_map.R"
)
for (prior in unique(models$reporting_rate_prior)) {
  for (likelihood in c("normal", "dm_no_re")) {
    for (weight in c(50L, 11L, 1L, 0L)) {
    off <- models$step_id[
      models$reporting_rate_prior == prior &
        models$lf_likelihood == likelihood & models$tag_flag2 == 0L &
        models$regional_scaling_weight == weight
    ]
    on <- models$step_id[
      models$reporting_rate_prior == prior &
        models$lf_likelihood == likelihood & models$tag_flag2 == 1L &
        models$regional_scaling_weight == weight
    ]
    if (length(off) != 1L || length(on) != 1L) {
      fail("Missing matched TAGF2 pair for ", likelihood, " REGW", weight)
    }
    if (!identical(
      readLines(model_file(off, "doitall.sh"), warn = FALSE),
      readLines(model_file(on, "doitall.sh"), warn = FALSE)
    )) {
      fail("TAGF2 pair has different doitall files: ", off, " versus ", on)
    }
    compare_tag_ini(off, on)
    compare_binary_files(off, on, common_pair_files, "TAGF2 pair")
    }
  }
}

# Normal and DM counterparts retain exactly the same non-doitall model inputs.
matched_likelihood_files <- c("bet.ini", common_pair_files)
for (prior in unique(models$reporting_rate_prior)) {
  for (tag_value in 0:1) {
    for (weight in c(50L, 11L, 1L, 0L)) {
    normal <- models$step_id[
      models$reporting_rate_prior == prior &
        models$lf_likelihood == "normal" & models$tag_flag2 == tag_value &
        models$regional_scaling_weight == weight
    ]
    dm <- models$step_id[
      models$reporting_rate_prior == prior &
        models$lf_likelihood == "dm_no_re" & models$tag_flag2 == tag_value &
        models$regional_scaling_weight == weight
    ]
    if (length(normal) != 1L || length(dm) != 1L) {
      fail("Missing matched normal/DM pair for TAGF2=", tag_value,
           " REGW", weight)
    }
    compare_binary_files(normal, dm, matched_likelihood_files, "Normal/DM pair")
    }
  }
}

# Manual and PTTP26 counterparts may differ only in reporting-prior fields.
cross_prior_files <- setdiff(common_pair_files, "tag_rep_map.R")
for (likelihood in c("normal", "dm_no_re")) {
  for (tag_value in 0:1) {
    for (weight in c(50L, 11L, 1L, 0L)) {
      manual <- models$step_id[
        models$reporting_rate_prior == "manual_8_10" &
          models$lf_likelihood == likelihood & models$tag_flag2 == tag_value &
          models$regional_scaling_weight == weight
      ]
      pttp <- models$step_id[
        models$reporting_rate_prior == "Tom_Peatman_2026_PTTP" &
          models$lf_likelihood == likelihood & models$tag_flag2 == tag_value &
          models$regional_scaling_weight == weight
      ]
      if (length(manual) != 1L || length(pttp) != 1L) {
        fail("Missing manual/PTTP26 counterpart for ", likelihood,
             " TAGF2=", tag_value, " REGW", weight)
      }
      compare_binary_files(manual, pttp, cross_prior_files, "Manual/PTTP26 pair")
      if (!identical(
        readLines(model_file(manual, "doitall.sh"), warn = FALSE),
        readLines(model_file(pttp, "doitall.sh"), warn = FALSE)
      )) {
        fail("Manual/PTTP26 pair has different doitall files: ", manual, " versus ", pttp)
      }
      if (!identical(
        canonical_prior_ini(readLines(model_file(manual, "bet.ini"), warn = FALSE)),
        canonical_prior_ini(readLines(model_file(pttp, "bet.ini"), warn = FALSE))
      )) {
        fail("Manual/PTTP26 pair differs outside allowed INI prior fields: ",
             manual, " versus ", pttp)
      }
      if (!identical(
        tag_map_structure(model_file(manual, "tag_rep_map.R")),
        tag_map_structure(model_file(pttp, "tag_rep_map.R"))
      )) {
        fail("Manual/PTTP26 tag group names or memberships differ: ",
             manual, " versus ", pttp)
      }
    }
  }
}

cat(paste0(
  "Validated thirty-two SUB075 mix-0.15 NOCUT REGW50/11/1/0 models, including ",
  "no flag 16=1, exact G7OSHL DM Nmax10 grouping, pinned low-recapture tags, ",
  "matched TAGF2 pairs, and manual/PTTP26 reporting-rate prior families.\n"
))
