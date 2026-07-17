## Rebuild the 17 x 5 BET 2026 MFCL LF and age-length sensitivity folders.
##
## Every cell retains the exact effort-crept FRQ archived by Kflow Job 5319.
## Tag-group controls, display metadata, and regional-scaling inputs are
## refreshed from the reviewed stepwise branch; tag data come from the latest
## tag-prep main branch. The script
## never reapplies effort creep. Normal-likelihood cells change only observed
## LF bins for cutoff cells, parest flag 313, and fishery-49 overrides for
## F21/F22/F23. The DM sensitivities additionally change only documented LF
## DM-noRE controls and fishery grouping/activation flags. All index LF is
## retained; option 11 cannot reproduce the normal models' fixed flag-49
## duplicate-use correction.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stepwise_refresh_ref <- "experiment/tag-grouping-reg-scaling-2026"
stepwise_refresh_commit <- "26c74dc6f303faa951b1ab331d7de14ea20b7489"
tag_prep_commit <- "79733c429b320e84ed5047aa6c932c8f19dab187"
tag_prep_source <- "PacificCommunity/ofp-sam-2026-BET-YFT-tag-prep"
age_length_source_repo <-
  "https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build"
age_length_source_commit <- "96a06d21ef3c666f39ce456d3a6818b6c17324c4"
required_project_files <- c(
  "job-config.R",
  file.path("R", "prepare_common.R"),
  file.path("R", "prepare_mfcl_inputs.R")
)
missing_project_files <- required_project_files[
  !file.exists(file.path(root, required_project_files))
]
if (length(missing_project_files)) {
  stop(
    "Run this script from the exploration root; missing: ",
    paste(missing_project_files, collapse = ", "),
    call. = FALSE
  )
}

sys.source(file.path(root, "R", "prepare_common.R"), envir = environment())
sys.source(file.path(root, "R", "prepare_mfcl_inputs.R"), envir = environment())

config_env <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config_env)
models <- config_env$stepwise_models

reference_input_dir <- file.path(root, "reference-inputs", "job-5319", "mfcl-inputs")
reference_required <- c(
  "bet.age_length",
  "bet.frq",
  "bet.ini",
  "bet.reg_scaling",
  "bet.reg_scaling.full",
  "bet.tag",
  "doitall.sh",
  "fishery_map.R",
  "mfcl.cfg",
  "tag_rep_map.R"
)
expected_reference_sha256 <- "a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc"
expected_frq_sha256 <-
  "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"
expected_ini_sha256 <-
  "3c9503e0762547762bab20b26997c3a4e627b0965b1d88418d71a1a17f40bb11"
expected_tag_sha256 <-
  "3f1b836a844ec2ca8e70fc5814d94c5a1ebc37ff4a5571c1dc1f6b83e477dfe8"

fail <- function(...) stop(paste0(...), call. = FALSE)

sha256_file <- function(path) {
  output <- suppressWarnings(system2(
    "sha256sum",
    c("--", path),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    fail("sha256sum failed for ", path, ": ", paste(output, collapse = " "))
  }
  if (!length(output)) fail("sha256sum returned no output for ", path)
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

reference_input_set_sha256 <- function(input_dir) {
  files <- sort(list.files(input_dir, all.files = FALSE, no.. = TRUE))
  hashes <- vapply(file.path(input_dir, files), sha256_file, character(1))
  manifest <- tempfile("reference-inputs-sha256-")
  on.exit(unlink(manifest), add = TRUE)
  writeLines(sprintf("%s  %s", hashes, files), manifest, useBytes = TRUE)
  sha256_file(manifest)
}

if (!dir.exists(reference_input_dir)) {
  fail("Missing refreshed reference-input directory: ", reference_input_dir)
}
reference_files <- sort(list.files(reference_input_dir, all.files = FALSE, no.. = TRUE))
if (!identical(reference_files, sort(reference_required))) {
  fail(
    "Reference bundle must contain exactly: ",
    paste(sort(reference_required), collapse = ", ")
  )
}
reference_sha256 <- reference_input_set_sha256(reference_input_dir)
frq_sha256 <- sha256_file(file.path(reference_input_dir, "bet.frq"))
ini_sha256 <- sha256_file(file.path(reference_input_dir, "bet.ini"))
tag_sha256 <- sha256_file(file.path(reference_input_dir, "bet.tag"))
if (!identical(reference_sha256, expected_reference_sha256)) {
  fail("Refreshed reference input-set SHA-256 mismatch: ", reference_sha256)
}
if (!identical(frq_sha256, expected_frq_sha256)) {
  fail("Job 5319 archived bet.frq SHA-256 mismatch: ", frq_sha256)
}
if (!identical(ini_sha256, expected_ini_sha256)) {
  fail("Refreshed bet.ini SHA-256 mismatch: ", ini_sha256)
}
if (!identical(tag_sha256, expected_tag_sha256)) {
  fail("Refreshed bet.tag SHA-256 mismatch: ", tag_sha256)
}

if (!is.data.frame(models) || nrow(models) != 85L ||
    anyDuplicated(models$step_id) || any(!models$enabled)) {
  fail("job-config.R must define exactly 85 unique enabled sensitivity cells")
}
if (!all(models$run_mode == "doitall") ||
    !all(models$regional_scaling_weight == 50L)) {
  fail("Every sensitivity must use doitall and regional-scaling weight 50")
}
normal_rows <- models$lf_likelihood == "normal"
if (!all(
  models$lf_size_divisor[normal_rows] ==
    20L * models$lf_downweight_factor[normal_rows]
)) {
  fail("Every F21/F22/F23 LF divisor must equal 20 times its targeted downweight factor")
}
if (!all(models$lf_likelihood %in% c("normal", "dm_nore"))) {
  fail("LF likelihood must be normal or dm_nore")
}
dm_rows <- models$lf_likelihood == "dm_nore"
expected_age_levels <- c("BASE075", "REG075", "REG100", "SUB075", "SUB100")
age_level_counts <- table(factor(models$age_length_variant, levels = expected_age_levels))
if (!identical(as.integer(age_level_counts), rep(17L, 5L)) ||
    anyDuplicated(models[, c("base_sensitivity", "age_length_variant")])) {
  fail("Age-length factorial must contain each of 17 base configurations once at all five levels")
}
base_rows <- models$age_length_variant == "BASE075"
if (!identical(as.character(models$step_id[base_rows]), sprintf("S%03d-%s", 1:17, sub(
  "^S[0-9]{3}-", "", models$base_sensitivity[base_rows]
)))) {
  fail("BASE075 identities must remain S001:S017")
}
inherit_columns <- c(
  "run_mode", "region_count", "regional_scaling_weight",
  "tail_compression_percent", "cutoff_cm", "cutoff_code",
  "lf_downweight_factor", "lf_size_divisor", "lf_likelihood",
  "dm_grouping", "dm_estimate_relative_sample_size"
)
base_by_id <- models[base_rows, c("base_sensitivity", inherit_columns), drop = FALSE]
for (level in expected_age_levels[-1L]) {
  level_rows <- models$age_length_variant == level
  level_models <- models[level_rows, c("base_sensitivity", inherit_columns), drop = FALSE]
  level_models <- level_models[match(base_by_id$base_sensitivity, level_models$base_sensitivity), , drop = FALSE]
  rownames(level_models) <- NULL
  rownames(base_by_id) <- NULL
  if (!identical(level_models, base_by_id)) {
    fail("Age-length level ", level, " does not inherit every base configuration exactly")
  }
}
source_rows <- !duplicated(models$age_length_variant)
source_models <- models[source_rows, , drop = FALSE]
source_models <- source_models[match(expected_age_levels, source_models$age_length_variant), , drop = FALSE]
if (anyNA(source_models$age_length_source_path) ||
    any(source_models$age_length_variant == "BASE100")) {
  fail("Age-length sources must define exactly the reviewed five levels without BASE100")
}
for (i in seq_len(nrow(source_models))) {
  source_path <- file.path(root, source_models$age_length_source_path[[i]])
  if (!file.exists(source_path)) fail("Missing age-length source: ", source_path)
  if (!identical(sha256_file(source_path), source_models$age_length_sha256[[i]])) {
    fail("Age-length source SHA-256 mismatch: ", source_path)
  }
}
expected_dm_ids <- c(
  "S010-DM-G4-CEST-NOCUT",
  "S011-DM-G1-C0-NOCUT",
  "S012-DM-G1-CEST-NOCUT",
  "S013-DM-G2-C0-NOCUT",
  "S014-DM-G2-CEST-NOCUT",
  "S015-DM-G4-C0-NOCUT",
  "S016-DM-G4-CEST-CUT70",
  "S017-DM-G4-CEST-CUT90"
)
expected_dm_grouping <- c(
  "gear4", "gear1", "gear1", "gear2", "gear2", "gear4", "gear4", "gear4"
)
expected_dm_c_estimated <- c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, TRUE)
expected_dm_cutoff <- c(rep(NA_real_, 6L), 70, 90)
base_dm_rows <- dm_rows & base_rows
if (sum(dm_rows) != 40L ||
    sum(base_dm_rows) != 8L ||
    !identical(as.character(models$step_id[base_dm_rows]), expected_dm_ids) ||
    !identical(as.character(models$dm_grouping[base_dm_rows]), expected_dm_grouping) ||
    !identical(
      as.logical(models$dm_estimate_relative_sample_size[base_dm_rows]),
      expected_dm_c_estimated
    ) ||
    !identical(as.numeric(models$cutoff_cm[base_dm_rows]), expected_dm_cutoff) ||
    any(!is.na(models$lf_downweight_factor[dm_rows])) ||
    any(!is.na(models$lf_size_divisor[dm_rows])) ||
    any(models$tail_compression_percent[dm_rows] != 0L)) {
  fail("DM sensitivities must match the reviewed G1/G2/G4, C0/CEST, and cutoff design")
}

fishery_map_env <- new.env(parent = globalenv())
sys.source(
  file.path(reference_input_dir, "fishery_map.R"),
  envir = fishery_map_env
)
reference_fishery_map <- fishery_map_env$fishery_map
if (!is.data.frame(reference_fishery_map) ||
    !identical(reference_fishery_map$fishery, 1:33)) {
  fail("Reference fishery_map.R must define fisheries 1:33 in order")
}
dm_group_ids_for <- function(grouping) {
  grouping <- as.character(grouping[[1L]])
  fishery <- reference_fishery_map$fishery
  ids <- switch(
    grouping,
    gear1 = rep(1L, length(fishery)),
    gear2 = ifelse(fishery <= 28L, 1L, 2L),
    gear4 = ifelse(
      reference_fishery_map$group == "LL",
      1L,
      ifelse(
        grepl("^PS", reference_fishery_map$group),
        2L,
        ifelse(
          reference_fishery_map$group %in% c("PL", "HL", "MISC"),
          3L,
          ifelse(reference_fishery_map$group == "Index", 4L, NA_integer_)
        )
      )
    ),
    fail("Unknown DM grouping: ", grouping)
  )
  ids <- as.integer(ids)
  if (anyNA(ids)) fail("Every fishery must map to a reviewed DM group")
  names(ids) <- fishery
  ids
}

dm_group_names_for <- function(grouping) {
  switch(
    as.character(grouping[[1L]]),
    gear1 = "All LF",
    gear2 = c("Extraction", "Index"),
    gear4 = c("Longline", "Purse seine", "Other extraction", "Index"),
    fail("Unknown DM grouping")
  )
}

expected_dm_group_counts <- list(
  gear1 = 33L,
  gear2 = c(28L, 5L),
  gear4 = c(11L, 9L, 8L, 5L)
)
for (grouping in names(expected_dm_group_counts)) {
  ids <- dm_group_ids_for(grouping)
  counts <- as.integer(table(factor(ids, levels = seq_along(expected_dm_group_counts[[grouping]]))))
  if (!identical(counts, expected_dm_group_counts[[grouping]])) {
    fail("Unexpected fishery counts for ", grouping)
  }
}

sensitivity_root <- file.path(root, "sensitivity")
forbidden_dirs <- c(
  file.path(root, "steps"),
  file.path(root, ".generation-staging"),
  file.path(sensitivity_root, "steps"),
  file.path(sensitivity_root, "staging"),
  file.path(sensitivity_root, ".generation-staging")
)
if (any(dir.exists(forbidden_dirs))) {
  fail("Sensitivity generation requires no steps or staging directories")
}
dir.create(sensitivity_root, recursive = TRUE, showWarnings = FALSE)
existing_entries <- list.files(sensitivity_root, full.names = TRUE, no.. = TRUE)
existing_dirs <- basename(existing_entries[file.info(existing_entries)$isdir %in% TRUE])
extra_dirs <- setdiff(existing_dirs, models$step_id)
if (length(extra_dirs)) {
  fail("Refusing to remove unexpected sensitivity folders: ", paste(extra_dirs, collapse = ", "))
}

copy_exact <- function(from, to) {
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(
    from,
    to,
    overwrite = TRUE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (!isTRUE(copied)) fail("Failed to copy ", from, " to ", to)
  invisible(to)
}

cutoff_sentence <- function(cutoff_cm) {
  if (is.finite(cutoff_cm)) {
    sprintf(
      paste0(
        "For F21/F22/F23, observed LF counts in bins with midpoint above the ",
        "%.0f cm cutoff are set to zero."
      ),
      cutoff_cm
    )
  } else {
    "For F21/F22/F23, observed LF counts are unchanged; no cutoff is applied."
  }
}

cutoff_provenance <- function(cutoff_cm) {
  if (is.finite(cutoff_cm) && cutoff_cm == 90) {
    paste(
      "The 90 cm threshold reproduces the historical treatment documented in",
      "WCPFC-SC19-2023/SA-WP-05 for the corresponding Indonesia, Philippines,",
      "and Vietnam domestic small-fish length compositions; 90 cm is retained",
      "and only bins with midpoint greater than 90 cm are zeroed."
    )
  } else {
    "This model retains its previously selected cutoff treatment."
  }
}

replace_flag_value <- function(line, actor, flag, value) {
  pattern <- sprintf(
    "^([[:space:]]*%s[[:space:]]+%s[[:space:]]+)([^[:space:]#]+)(.*)$",
    actor,
    flag
  )
  match <- regmatches(line, regexec(pattern, line, perl = TRUE))[[1L]]
  if (length(match) != 4L) {
    fail("Could not replace flag ", actor, "/", flag, " in archived doitall.sh")
  }
  paste0(match[[2L]], value, match[[4L]])
}

write_sensitivity_doitall <- function(
    to,
    tail_percent,
    divisor,
    lf_likelihood,
    dm_grouping,
    dm_estimate_relative_sample_size) {
  source_path <- file.path(reference_input_dir, "doitall.sh")
  lines <- readLines(source_path, warn = FALSE)
  tc_hit <- grep("^[[:space:]]*1[[:space:]]+313[[:space:]]+", lines)
  if (length(tc_hit) != 1L) fail("Archived doitall.sh must contain one 1/313 flag")
  lines[[tc_hit]] <- replace_flag_value(
    lines[[tc_hit]],
    actor = 1L,
    flag = 313L,
    value = as.integer(tail_percent)
  )

  target_existing <- grep(
    "^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+",
    lines
  )
  if (length(target_existing)) {
    fail("Archived doitall.sh unexpectedly contains F21/F22/F23 flag-49 overrides")
  }
  global_49 <- grep("^[[:space:]]*-999[[:space:]]+49[[:space:]]+", lines)
  if (length(global_49) != 1L) fail("Archived doitall.sh must contain one global flag-49 line")
  if (!identical(lf_likelihood, "dm_nore")) {
    override_lines <- sprintf(
      "  -%d 49 %d  # sensitivity-only F%d LF effective-sample-size divisor",
      21:23,
      as.integer(divisor),
      21:23
    )
    lines <- append(lines, override_lines, after = global_49)
  }

  if (identical(lf_likelihood, "dm_nore")) {
    if (!dm_grouping %in% c("gear1", "gear2", "gear4")) {
      fail("DM sensitivity requires a reviewed gear1, gear2, or gear4 mapping")
    }
    dm_group_ids <- dm_group_ids_for(dm_grouping)
    dm_group_names <- dm_group_names_for(dm_grouping)
    lf_likelihood_hit <- grep(
      "^[[:space:]]*1[[:space:]]+141[[:space:]]+", lines
    )
    lf_preprocess_hit <- grep(
      "^[[:space:]]*1[[:space:]]+311[[:space:]]+", lines
    )
    if (length(lf_likelihood_hit) != 1L || length(lf_preprocess_hit) != 1L) {
      fail("Archived doitall.sh must contain one LF likelihood and one LF tail-compression switch")
    }
    lines[[lf_likelihood_hit]] <-
      "  1 141 11    # LF Dirichlet-multinomial likelihood without random effects"
    lines[[lf_preprocess_hit]] <- paste(
      "  1 311 1",
      "# retain LF preprocessing gate so the inherited N < 50 filter remains active"
    )
    if (any(grepl("^[[:space:]]*1[[:space:]]+(320|342)[[:space:]]+", lines))) {
      fail("Archived doitall.sh unexpectedly contains DM parest flags 320 or 342")
    }
    lf_likelihood_hit <- grep(
      "^[[:space:]]*1[[:space:]]+141[[:space:]]+", lines
    )
    lines <- append(
      lines,
      c(
        "  1 320 0     # no DM-specific LF tail compression",
        "  1 342 1000  # DM-noRE maximum LF effective sample size"
      ),
      after = lf_likelihood_hit
    )

    if (any(grepl("^[[:space:]]*-[0-9]+[[:space:]]+(68|69|89)[[:space:]]+", lines))) {
      fail("Archived doitall.sh unexpectedly contains LF DM fishery flags")
    }
    dm_group_lines <- sprintf(
      "  -%d 68 %d  # DM LF group: %s",
      as.integer(names(dm_group_ids)),
      dm_group_ids,
      dm_group_names[dm_group_ids]
    )
    global_49 <- grep("^[[:space:]]*-999[[:space:]]+49[[:space:]]+", lines)
    insertion_point <- global_49
    lines <- append(
      lines,
      c(
        dm_group_lines,
        "  -999 69 1  # estimate group-specific DM LF scalar exponent",
        "  -999 89 0  # stage relative sample-size exponent as fixed at zero"
      ),
      after = insertion_point
    )

    if (isTRUE(dm_estimate_relative_sample_size)) {
      phase2_open <- grep("<<PHASE2[[:space:]]*$", lines)
      if (length(phase2_open) != 1L) {
        fail("Archived doitall.sh must contain exactly one PHASE2 opening command")
      }
      lines <- append(
        lines,
        "  -999 89 1  # estimate group-specific DM LF relative sample-size exponent",
        after = phase2_open
      )
    }
  }
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}

write_model_manifest <- function(step_dir, row, treatment, has_cutoff) {
  reference_source <- file.path(
    "reference-inputs", "job-5319", "mfcl-inputs"
  )
  anchor_note <- paste0(
    "Byte-identical to the retained Job 5319 anchor in the refreshed reference ",
    "bundle; reference-set SHA-256 ", expected_reference_sha256, "."
  )
  refresh_note <- paste0(
    "Refreshed from PacificCommunity/ofp-sam-bet-2026-stepwise@",
    stepwise_refresh_commit, " (", stepwise_refresh_ref, ")."
  )
  is_dm <- identical(as.character(row$lf_likelihood), "dm_nore")
  is_s010 <- identical(as.character(row$step_id), "S010-DM-G4-CEST-NOCUT")
  frq_note <- paste(
    paste0(
      "Exact retained Job 5319 effort-crept bet.frq; SHA-256 ",
      expected_frq_sha256, "."
    ),
    treatment,
    cutoff_provenance(as.numeric(row$cutoff_cm)),
    if (has_cutoff && is_dm) {
      paste(
        "Counts are not transferred; retained LF categories use MFCL option 11;",
        "MFCL internally normalizes retained counts; an all-zero LF vector",
        "becomes one -1 whole-sample sentinel."
      )
    } else if (has_cutoff) {
      paste(
        "Counts are not transferred; LF categories remain in the MFCL option-3",
        "likelihood; MFCL internally renormalizes retained counts; an all-zero",
        "LF vector becomes one -1 whole-sample sentinel."
      )
    } else {
      "No FRQ transform is applied."
    },
    "Effort creep is not reapplied."
  )
  if (is_dm && !has_cutoff) {
    frq_note <- paste(
      frq_note,
      "All extraction and index LF observations are retained byte-for-byte.",
      "The normal-likelihood flag-49 extra /2 correction is inert under",
      "option 11 and therefore is not reproduced in this DM sensitivity."
    )
  } else if (is_dm) {
    frq_note <- paste(
      frq_note,
      "All F29/F30/F31/F32/F33 index LF observations are retained unchanged.",
      "Only the established F21/F22/F23 upper-bin cutoff transform is applied.",
      "The normal-likelihood flag-49 extra /2 correction is inert under",
      "option 11 and therefore is not reproduced in this DM sensitivity."
    )
  }
  if (is_s010) {
    doitall_note <- paste(
      "Retained Job 5319 doitall sequence with LF likelihood option 11;",
      "the LF preprocessing gate and N < 50 filter retained; percentage and",
      "DM-specific LF tail compression disabled; DM maximum",
      "effective sample size 1000; all extraction and index LF retained in four",
      "reviewed fishery groups; group-specific scalar and relative sample-size",
      "exponents estimated. Inherited flag-49 lines remain in the control file",
      "but are inert under DM-noRE, so the normal models' fixed extra /2 is not",
      "reproduced. The separate index group makes this a deliberate DM",
      "self-weighting/overdispersion sensitivity, not an exact duplicate-use correction."
    )
  } else if (is_dm) {
    group_count <- switch(as.character(row$dm_grouping), gear1 = 1L, gear2 = 2L, gear4 = 4L)
    c_note <- if (isTRUE(row$dm_estimate_relative_sample_size[[1L]])) {
      "the relative sample-size exponent is fixed at zero in PHASE1 and estimated from PHASE2"
    } else {
      "the relative sample-size exponent remains fixed at MFCL default zero in every phase"
    }
    cutoff_note <- if (has_cutoff) {
      sprintf(
        "the established F21/F22/F23 cutoff above %.0f cm is applied",
        as.numeric(row$cutoff_cm)
      )
    } else {
      "no LF cutoff is applied"
    }
    doitall_note <- paste(
      "Retained Job 5319 doitall sequence with LF likelihood option 11;",
      "the LF preprocessing gate and N < 50 filter retained; percentage and",
      "DM-specific LF tail compression disabled; DM maximum effective sample",
      "size 1000;", group_count, "reviewed LF group(s); group-specific scalar",
      "exponents estimated from PHASE1;", paste0(c_note, ";"), paste0(cutoff_note, "."),
      "Inherited flag-49 lines are inert under DM-noRE, so the normal models'",
      "fixed extra /2 is not reproduced. These are deliberate DM",
      "grouping/overdispersion sensitivities, not exact duplicate-use corrections."
    )
  } else {
    doitall_note <- sprintf(
      paste0(
        "Retained Job 5319 doitall control sequence except parest flag ",
        "313=%d and three new flag-49 overrides for F21/F22/F23, each with ",
        "divisor %d; inherited settings for every other fishery are unchanged."
      ),
      as.integer(row$tail_compression_percent),
      as.integer(row$lf_size_divisor)
    )
  }

  manifest_sources <- file.path(
    reference_source,
    c(
      "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
      "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
      "tag_rep_map.R"
    )
  )
  manifest_source_commits <- c(
    "", stepwise_refresh_commit, tag_prep_commit, "",
    stepwise_refresh_commit, stepwise_refresh_commit, "", "",
    stepwise_refresh_commit, stepwise_refresh_commit
  )
  age_length_note <- anchor_note
  if (!identical(as.character(row$age_length_variant), "BASE075")) {
    manifest_sources[[4L]] <- as.character(row$age_length_source_path)
    manifest_source_commits[[4L]] <- age_length_source_commit
    age_length_note <- paste(
      "Exact", as.character(row$age_length_variant), "age-length input from",
      paste0(age_length_source_repo, "@", age_length_source_commit, ";"),
      paste0("original file ", as.character(row$age_length_source_file), ";"),
      paste0("SHA-256 ", as.character(row$age_length_sha256), ".")
    )
  }

  manifest <- data.frame(
    role = c(
      "frq", "ini", "tag", "age_length", "reg_scaling",
      "reg_scaling_full", "doitall", "mfcl_config", "fishery_map",
      "tag_reporting_map"
    ),
    file = c(
      "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
      "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
      "tag_rep_map.R"
    ),
    source = manifest_sources,
    source_commit = manifest_source_commits,
    note = c(
      frq_note,
      paste(
        refresh_note,
        paste0("Tag-control ini SHA-256 ", expected_ini_sha256, ";"),
        "all 98 tag_flags(:,2) values remain 0."
      ),
      paste(
        paste0("Latest tag data from ", tag_prep_source, "@", tag_prep_commit, " (main);"),
        paste0("tag SHA-256 ", expected_tag_sha256, "; byte-identical to PDH 13-DataWeighting.")
      ),
      age_length_note,
      paste(
        refresh_note,
        "MFCL-ready active matrix, exactly full-source rows 53:72 (20x5); fixed weight 50."
      ),
      paste(
        refresh_note,
        "Complete 292x5 sensitivity source retained for alternative period windows; not read by MFCL."
      ),
      doitall_note,
      anchor_note,
      paste(refresh_note, "Updated fishery names used by MFCLShiny."),
      paste(refresh_note, "Updated reporting-group map matching bet.ini and bet.tag.")
    ),
    stringsAsFactors = FALSE
  )
  if (has_cutoff) {
    manifest <- rbind(
      manifest,
      data.frame(
        role = "frq_transform_audit",
        file = "lf_cutoff_audit.csv",
        source = file.path(reference_source, "bet.frq"),
        source_commit = NA_character_,
        note = paste(
          treatment,
          "The audit reconciles removed counts, affected records, all-zero LF sentinels, and minimum-sample crossings."
        ),
        stringsAsFactors = FALSE
      )
    )
  }
  utils::write.csv(
    manifest,
    file.path(step_dir, "input_manifest.csv"),
    row.names = FALSE,
    na = ""
  )
}

add_age_length_readme <- function(lines, row) {
  if (identical(as.character(row$age_length_variant), "BASE075")) return(lines)
  status_line <- grep("^Status:", lines)
  if (length(status_line) != 1L) fail("Generated model README must contain one status line")
  section <- c(
    "",
    "## Age-length variant",
    "",
    paste0("Semantic level: `", as.character(row$age_length_variant), "`."),
    paste0("Paired base sensitivity: `", as.character(row$base_sensitivity), "`."),
    paste0("Model input: `", as.character(row$age_length_source_path), "`."),
    paste0("Source repository: ", age_length_source_repo, "."),
    paste0("Source commit: `", age_length_source_commit, "`."),
    paste0("Source file: `", as.character(row$age_length_source_file), "`."),
    paste0("SHA-256: `", as.character(row$age_length_sha256), "`."),
    paste(
      "Every other model input and all inherited normal/DM/cutoff controls are",
      "identical to the paired BASE075 sensitivity."
    )
  )
  append(lines, section, after = status_line[[1L]] - 2L)
}

write_model_readme <- function(step_dir, row, treatment, audit = NULL) {
  is_dm <- identical(as.character(row$lf_likelihood), "dm_nore")
  is_s010 <- identical(as.character(row$step_id), "S010-DM-G4-CEST-NOCUT")
  if (is_s010) {
    lines <- c(
      paste0("# ", as.character(row$job_title)),
      "",
      "This model is the LF Dirichlet-multinomial-noRE pilot in the BET 2026 sensitivity set.",
      "",
      "## Design",
      "",
      "| Control | Setting |",
      "| --- | --- |",
      "| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |",
      "| LF groups | Longline; purse seine; other extraction; index |",
      "| Group scalar exponent | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |",
      "| Relative sample-size exponent | Starts at MFCL default zero; estimated from PHASE2 with fish flag 89 |",
      "| DM maximum effective sample size | 1000 |",
      "| LF tail compression | Disabled |",
      "| LF cutoff | None |",
      "| LF weighting | All extraction and index LF retained; separate index DM group; self-scaling |",
      "| Regional-scaling penalty weight | 50 |",
      "",
      "The four DM groups are generated from `fishery_map.R`, not from display order alone.",
      "All extraction and index LF observations and the retained Job 5319 effort-creep treatment are unchanged.",
      "The existing minimum input sample-size filter of 50 remains active through the LF preprocessing gate.",
      "There are no WF observations; no DM weight-frequency parameter is activated.",
      "",
      "## Interpretation",
      "",
      paste(
        "The normal-likelihood models use flag 49 to apply an extra /2 to LF",
        "streams used as both extraction and index data. MFCL option 11 ignores",
        "flag 49 and has no fixed 0.5 LF-contribution control, so that correction",
        "cannot be reproduced here."
      ),
      paste(
        "S010 deliberately retains both LF representations and estimates the",
        "index fisheries as a separate DM group. It is a self-weighting and",
        "overdispersion sensitivity, not an exact duplicate-use correction;",
        "aggregation differences between the two representations may remain."
      ),
      "MFCL estimates one scalar exponent and one relative sample-size exponent per group.",
      "The `dmsizemult` output must be used to inspect fitted effective sample sizes; raw objective values are not directly ranked against the normal-likelihood models.",
      "Convergence, Hessian PDH, LF residuals, index fits, and key quantities must be considered together.",
      "",
      "## Provenance",
      "",
      paste0("The reference input-set SHA-256 is `", expected_reference_sha256, "`."),
      paste0("The retained Job 5319 effort-crept `bet.frq` SHA-256 is `", expected_frq_sha256, "`; effort creep is not reapplied."),
      paste0("The refreshed tag-control `.ini` comes from stepwise commit `", stepwise_refresh_commit, "`."),
      paste0("The tag data come from tag-prep commit `", tag_prep_commit, "`."),
      "No MFCL source or executable is changed.",
      "",
      "Status: generated and ready for validation; Kflow has not been submitted."
    )
    lines <- add_age_length_readme(lines, row)
    writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
    return(invisible(step_dir))
  }
  if (is_dm) {
    grouping <- as.character(row$dm_grouping)
    grouping_text <- switch(
      grouping,
      gear1 = "G1: F1:F33 in one pooled LF group",
      gear2 = "G2: extraction F1:F28 in group 1; index F29:F33 in group 2",
      gear4 = paste(
        "G4: longline F1:F11; purse seine F12/F17:F20/F25:F28;",
        "other extraction F13:F16/F21:F24; index F29:F33"
      )
    )
    c_text <- if (isTRUE(row$dm_estimate_relative_sample_size[[1L]])) {
      "CEST: c is fixed at zero in PHASE1 and estimated from PHASE2"
    } else {
      "C0: c remains fixed at MFCL default zero in every phase"
    }
    cutoff_value <- as.numeric(row$cutoff_cm)
    cutoff_text <- if (is.finite(cutoff_value)) {
      sprintf("Established F21/F22/F23 upper-bin cutoff above %.0f cm", cutoff_value)
    } else {
      "None"
    }
    audit_line <- if (is.data.frame(audit)) {
      paste(
        sprintf(
          "F%d removed %s counts from %d records (%d all-zero LF sentinels)",
          audit$fishery,
          format(audit$removed_count, digits = 15L, trim = TRUE),
          audit$affected_records,
          audit$emptied_records
        ),
        collapse = "; "
      )
    } else {
      "No LF transform is applied; bet.frq is byte-identical to the Job 5319 archive."
    }
    lines <- c(
      paste0("# ", as.character(row$job_title)),
      "",
      "This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.",
      "",
      "## Design",
      "",
      "| Control | Setting |",
      "| --- | --- |",
      "| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |",
      paste0("| LF grouping | ", grouping_text, " |"),
      "| Group scalar exponent d | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |",
      paste0("| Relative sample-size exponent c | ", c_text, " |"),
      "| DM maximum effective sample size | 1000 |",
      "| LF preprocessing | Enabled; inherited N < 50 filter retained |",
      "| LF tail compression | Percentage and DM-specific compression disabled |",
      paste0("| LF cutoff | ", cutoff_text, " |"),
      "| Index LF | F29:F33 retained unchanged |",
      "| Regional-scaling penalty weight | 50 |",
      "",
      "## Interpretation",
      "",
      paste(
        "The normal-likelihood models use flag 49 to apply an extra /2 to LF",
        "streams used as both extraction and index data. MFCL option 11 ignores",
        "flag 49 and has no fixed 0.5 LF-contribution control, so that correction",
        "cannot be reproduced in these models."
      ),
      paste(
        "Both extraction and index LF representations are retained. Grouping and",
        "DM overdispersion are the sensitivity axes; they are not exact",
        "duplicate-use corrections and do not model correlation introduced by",
        "aggregation differences between representations."
      ),
      if (is.finite(cutoff_value)) {
        paste(
          treatment,
          "This is exactly the established transform used by the corresponding",
          "normal-likelihood cutoff model; no index or other fishery LF is changed."
        )
      } else {
        "No LF cutoff transform is applied."
      },
      "",
      "## Provenance and audit",
      "",
      paste0("The reference input-set SHA-256 is `", expected_reference_sha256, "`."),
      paste0("The retained Job 5319 effort-crept `bet.frq` SHA-256 is `", expected_frq_sha256, "`; effort creep is not reapplied."),
      audit_line,
      paste0("The refreshed tag-control `.ini` comes from stepwise commit `", stepwise_refresh_commit, "`."),
      paste0("The tag data come from tag-prep commit `", tag_prep_commit, "`."),
      "No MFCL source or executable is changed.",
      "",
      "Status: generated and ready for validation; Kflow has not been submitted."
    )
    lines <- add_age_length_readme(lines, row)
    writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
    return(invisible(step_dir))
  }
  cutoff_value <- as.numeric(row$cutoff_cm)
  cutoff_label <- if (is.finite(cutoff_value)) {
    sprintf("above %.0f cm", cutoff_value)
  } else {
    "none"
  }
  audit_line <- if (is.data.frame(audit)) {
    paste(
      sprintf(
        "F%d removed %s counts from %d records (%d all-zero LF sentinels)",
        audit$fishery,
        format(audit$removed_count, digits = 15L, trim = TRUE),
        audit$affected_records,
        audit$emptied_records
      ),
      collapse = "; "
    )
  } else {
    "No cutoff audit is required because bet.frq is byte-identical to the Job 5319 archive."
  }
  lines <- c(
    paste0("# ", as.character(row$job_title)),
    "",
    "This is one model in the curated BET 2026 TC1 LF sensitivity set.",
    "",
    "## Design",
    "",
    "| Control | Setting |",
    "| --- | --- |",
    sprintf("| Global MFCL LF tail compression | %d%% |", as.integer(row$tail_compression_percent)),
    sprintf("| F21/F22/F23 observed LF upper-bin zeroing | %s |", cutoff_label),
    sprintf("| F21/F22/F23 LF likelihood downweight | %dx; flag-49 divisor %d |", as.integer(row$lf_downweight_factor), as.integer(row$lf_size_divisor)),
    "| Regional-scaling penalty weight | 50 |",
    "",
    "## Observed LF semantics",
    "",
    treatment,
    cutoff_provenance(cutoff_value),
    paste(
      "The bins remain as categories in the MFCL option-3 LF likelihood, and",
      "MFCL internally renormalizes retained counts. Counts are not transferred.",
      "An all-zero LF vector is represented by one `-1` whole-sample sentinel;",
      "record metadata and weight-frequency data remain unchanged."
    ),
    "",
    "## Provenance and controls",
    "",
    paste0(
      "The refreshed reference bundle has input-set SHA-256 `",
      expected_reference_sha256, "`."
    ),
    paste0(
      "The retained Job 5319 effort-crept `bet.frq` has SHA-256 `", expected_frq_sha256,
      "`; effort creep is not reapplied."
    ),
    paste(
      "`bet.ini`, `fishery_map.R`, and `tag_rep_map.R` are refreshed",
      paste0("from stepwise commit `", stepwise_refresh_commit, "`;"),
      "the 98 `tag_flags(:,2)` values remain 0."
    ),
    paste0(
      "`bet.tag` is the latest tag-prep main file at commit `",
      tag_prep_commit, "` and is byte-identical to PDH 13-DataWeighting."
    ),
    paste(
      "`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and",
      "`bet.reg_scaling.full` retains the complete 292x5 sensitivity source.",
      "The active matrix is exactly full-source rows 53:72."
    ),
    paste(
      "The `doitall.sh` changes are limited to flag 313 and three new",
      "F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls",
      "remain unchanged."
    ),
    "No MFCL source or executable is changed.",
    "",
    "## Cutoff audit",
    "",
    audit_line,
    "",
    "Status: generated and ready for validation; Kflow has not been submitted."
  )
  lines <- add_age_length_readme(lines, row)
  writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
}

regional_active_lines <- readLines(
  file.path(reference_input_dir, "bet.reg_scaling"), warn = FALSE
)
regional_full_lines <- readLines(
  file.path(reference_input_dir, "bet.reg_scaling.full"), warn = FALSE
)
regional_active_fields <- lengths(strsplit(trimws(regional_active_lines), "[[:space:]]+"))
regional_full_fields <- lengths(strsplit(trimws(regional_full_lines), "[[:space:]]+"))
if (length(regional_active_lines) != 20L || any(regional_active_fields != 5L)) {
  fail("Reference bet.reg_scaling must be exactly 20x5")
}
if (length(regional_full_lines) != 292L || any(regional_full_fields != 5L)) {
  fail("Reference bet.reg_scaling.full must be exactly 292x5")
}
if (!identical(regional_active_lines, regional_full_lines[53:72])) {
  fail("Reference bet.reg_scaling must equal bet.reg_scaling.full rows 53:72")
}

staging_root <- tempfile("sensitivity-staging-", tmpdir = root)
backup_root <- tempfile("sensitivity-backup-", tmpdir = root)
dir.create(staging_root, recursive = TRUE, showWarnings = FALSE)
on.exit({
  if (dir.exists(staging_root)) unlink(staging_root, recursive = TRUE, force = TRUE)
  if (dir.exists(backup_root) && !dir.exists(sensitivity_root)) {
    file.rename(backup_root, sensitivity_root)
  }
}, add = TRUE)

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  step_id <- as.character(row$step_id)
  step_dir <- file.path(staging_root, step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  for (file in c(
    "bet.frq", "bet.ini", "bet.tag", "bet.reg_scaling",
    "bet.reg_scaling.full", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
  )) {
    copy_exact(
      file.path(reference_input_dir, file),
      file.path(model_dir, file)
    )
  }
  copy_exact(
    file.path(root, as.character(row$age_length_source_path)),
    file.path(model_dir, "bet.age_length")
  )

  cutoff_cm <- as.numeric(row$cutoff_cm)
  cutoff_audit <- NULL
  if (is.finite(cutoff_cm)) {
    cutoff_audit <- apply_lf_upper_cutoffs(
      file.path(model_dir, "bet.frq"),
      max_bin_by_fishery = stats::setNames(rep(cutoff_cm, 3L), c("21", "22", "23"))
    )
    cutoff_audit$transform <- "lf_upper_cutoff"
    utils::write.csv(
      cutoff_audit,
      file.path(model_dir, "lf_cutoff_audit.csv"),
      row.names = FALSE,
      na = ""
    )
  }

  write_sensitivity_doitall(
    file.path(model_dir, "doitall.sh"),
    tail_percent = as.integer(row$tail_compression_percent),
    divisor = as.integer(row$lf_size_divisor),
    lf_likelihood = as.character(row$lf_likelihood),
    dm_grouping = as.character(row$dm_grouping),
    dm_estimate_relative_sample_size =
      isTRUE(row$dm_estimate_relative_sample_size[[1L]])
  )
  treatment <- cutoff_sentence(cutoff_cm)
  write_model_manifest(
    step_dir,
    row,
    treatment,
    has_cutoff = is.finite(cutoff_cm)
  )
  write_model_readme(step_dir, row, treatment, cutoff_audit)
}

if (!file.rename(sensitivity_root, backup_root)) {
  fail("Could not move the existing sensitivity tree to its atomic backup")
}
if (!file.rename(staging_root, sensitivity_root)) {
  file.rename(backup_root, sensitivity_root)
  fail("Could not install the fully generated sensitivity tree")
}
unlink(backup_root, recursive = TRUE, force = TRUE)

cat(sprintf("Generated %d sensitivity folders from the refreshed reference bundle.\n", nrow(models)))
cat(sprintf("Refreshed reference input-set SHA-256: %s\n", reference_sha256))
cat(sprintf("Job 5319 archived bet.frq SHA-256: %s\n", frq_sha256))
cat(sprintf("Stepwise tag-grouping source commit: %s\n", stepwise_refresh_commit))
cat(sprintf("Tag-prep main source commit: %s\n", tag_prep_commit))
cat("Regional scaling: active 20x5 plus retained full 292x5 source\n")
cat("Effort creep reapplied: no\n")
cat("Kflow submitted: no\n")
