## Rebuild the seven curated BET 2026 MFCL LF sensitivity folders.
##
## Every cell retains the exact effort-crept FRQ archived by Kflow Job 5319.
## Tag-group controls, display metadata, and regional-scaling inputs are
## refreshed from the reviewed stepwise branch; tag data come from the latest
## tag-prep main branch. The script
## never reapplies effort creep. It changes only observed LF bins for cutoff
## cells, parest flag 313, and new fishery-49 overrides for F21/F22/F23.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stepwise_refresh_ref <- "experiment/tag-grouping-reg-scaling-2026"
stepwise_refresh_commit <- "26c74dc6f303faa951b1ab331d7de14ea20b7489"
tag_prep_commit <- "79733c429b320e84ed5047aa6c932c8f19dab187"
tag_prep_source <- "PacificCommunity/ofp-sam-2026-BET-YFT-tag-prep"
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

if (!is.data.frame(models) || nrow(models) != 7L ||
    anyDuplicated(models$step_id) || any(!models$enabled)) {
  fail("job-config.R must define exactly seven unique enabled sensitivity cells")
}
if (!all(models$run_mode == "doitall") ||
    !all(models$regional_scaling_weight == 50L)) {
  fail("Every sensitivity must use doitall and regional-scaling weight 50")
}
if (!all(models$lf_size_divisor == 20L * models$lf_downweight_factor)) {
  fail("Every F21/F22/F23 LF divisor must equal 20 times its targeted downweight factor")
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

write_sensitivity_doitall <- function(to, tail_percent, divisor) {
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
  override_lines <- sprintf(
    "  -%d 49 %d  # sensitivity-only F%d LF effective-sample-size divisor",
    21:23,
    as.integer(divisor),
    21:23
  )
  lines <- append(lines, override_lines, after = global_49)
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
  frq_note <- paste(
    paste0(
      "Exact retained Job 5319 effort-crept bet.frq; SHA-256 ",
      expected_frq_sha256, "."
    ),
    treatment,
    cutoff_provenance(as.numeric(row$cutoff_cm)),
    if (has_cutoff) {
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
  doitall_note <- sprintf(
    paste0(
      "Retained Job 5319 doitall control sequence except parest flag ",
      "313=%d and three new flag-49 overrides for F21/F22/F23, each with ",
      "divisor %d; inherited settings for every other fishery are unchanged."
    ),
    as.integer(row$tail_compression_percent),
    as.integer(row$lf_size_divisor)
  )

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
    source = file.path(
      reference_source,
      c(
        "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
        "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
        "tag_rep_map.R"
      )
    ),
    source_commit = c(
      "", stepwise_refresh_commit, tag_prep_commit, "",
      stepwise_refresh_commit, stepwise_refresh_commit, "", "",
      stepwise_refresh_commit, stepwise_refresh_commit
    ),
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
      anchor_note,
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

write_model_readme <- function(step_dir, row, treatment, audit = NULL) {
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

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  step_id <- as.character(row$step_id)
  step_dir <- file.path(sensitivity_root, step_id)
  model_dir <- file.path(step_dir, "model")
  unlink(step_dir, recursive = TRUE, force = TRUE)
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  for (file in c(
    "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
    "bet.reg_scaling.full", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
  )) {
    copy_exact(
      file.path(reference_input_dir, file),
      file.path(model_dir, file)
    )
  }

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
    divisor = as.integer(row$lf_size_divisor)
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

cat(sprintf("Generated %d sensitivity folders from the refreshed reference bundle.\n", nrow(models)))
cat(sprintf("Refreshed reference input-set SHA-256: %s\n", reference_sha256))
cat(sprintf("Job 5319 archived bet.frq SHA-256: %s\n", frq_sha256))
cat(sprintf("Stepwise tag-grouping source commit: %s\n", stepwise_refresh_commit))
cat(sprintf("Tag-prep main source commit: %s\n", tag_prep_commit))
cat("Regional scaling: active 20x5 plus retained full 292x5 source\n")
cat("Effort creep reapplied: no\n")
cat("Kflow submitted: no\n")
