## Rebuild the 36 BET 2026 MFCL LF sensitivity folders.
##
## Every cell starts from the exact raw inputs archived by Kflow Job 5319.
## The archived FRQ already contains effort creep, so this script never applies
## an effort-creep transform. It changes only observed LF bins for cutoff cells,
## parest flag 313, and new fishery-49 overrides for F21/F22/F23.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
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

job_5319_input_dir <- file.path(root, "reference-inputs", "job-5319", "mfcl-inputs")
job_5319_required <- c(
  "bet.age_length",
  "bet.frq",
  "bet.ini",
  "bet.reg_scaling",
  "bet.tag",
  "doitall.sh",
  "fishery_map.R",
  "mfcl.cfg",
  "tag_rep_map.R"
)
expected_archive_sha256 <-
  "993aa5e2d32f308ec8468765ddde35a08563c6ab4884c18f6f10660a5f1f37c4"
expected_frq_sha256 <-
  "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"

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

archive_input_set_sha256 <- function(input_dir) {
  files <- sort(list.files(input_dir, all.files = FALSE, no.. = TRUE))
  hashes <- vapply(file.path(input_dir, files), sha256_file, character(1))
  manifest <- tempfile("job-5319-sha256-")
  on.exit(unlink(manifest), add = TRUE)
  writeLines(sprintf("%s  %s", hashes, files), manifest, useBytes = TRUE)
  sha256_file(manifest)
}

if (!dir.exists(job_5319_input_dir)) {
  fail("Missing Job 5319 archive directory: ", job_5319_input_dir)
}
archive_files <- sort(list.files(job_5319_input_dir, all.files = FALSE, no.. = TRUE))
if (!identical(archive_files, sort(job_5319_required))) {
  fail(
    "Job 5319 archive must contain exactly: ",
    paste(sort(job_5319_required), collapse = ", ")
  )
}
archive_sha256 <- archive_input_set_sha256(job_5319_input_dir)
frq_sha256 <- sha256_file(file.path(job_5319_input_dir, "bet.frq"))
if (!identical(archive_sha256, expected_archive_sha256)) {
  fail("Job 5319 archived input-set SHA-256 mismatch: ", archive_sha256)
}
if (!identical(frq_sha256, expected_frq_sha256)) {
  fail("Job 5319 archived bet.frq SHA-256 mismatch: ", frq_sha256)
}

if (!is.data.frame(models) || nrow(models) != 36L ||
    anyDuplicated(models$step_id) || any(!models$enabled)) {
  fail("job-config.R must define exactly 36 unique enabled sensitivity cells")
}
if (!all(models$run_mode == "doitall") ||
    !all(models$regional_scaling_weight == 50L)) {
  fail("Every sensitivity must use doitall and regional-scaling weight 50")
}
if (!all(models$lf_size_divisor == 20L * models$lf_downweight_factor)) {
  fail("F21/F22/F23 LF divisors must be 20, 200, or 2000 by design")
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
  source_path <- file.path(job_5319_input_dir, "doitall.sh")
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
  archive_source <- file.path("reference-inputs", "job-5319", "mfcl-inputs")
  unchanged_note <- paste0(
    "Byte-identical Job 5319 archived input; archived input-set SHA-256 ",
    expected_archive_sha256, "."
  )
  frq_note <- paste(
    paste0(
      "Exact Job 5319 archived effort-crept bet.frq; SHA-256 ",
      expected_frq_sha256, "."
    ),
    treatment,
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
      "Exact Job 5319 archived doitall control sequence except parest flag ",
      "313=%d and three new flag-49 overrides for F21/F22/F23, each with ",
      "divisor %d; inherited settings for every other fishery are unchanged."
    ),
    as.integer(row$tail_compression_percent),
    as.integer(row$lf_size_divisor)
  )

  manifest <- data.frame(
    role = c(
      "frq", "ini", "tag", "age_length", "reg_scaling", "doitall",
      "mfcl_config", "fishery_map", "tag_reporting_map"
    ),
    file = c(
      "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
      "doitall.sh", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
    ),
    source = file.path(
      archive_source,
      c(
        "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
        "doitall.sh", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
      )
    ),
    source_commit = NA_character_,
    note = c(
      frq_note,
      unchanged_note,
      unchanged_note,
      unchanged_note,
      paste(
        "Rows 53:72 copied verbatim from the Job 5319 archived 292x5",
        "bet.reg_scaling source, yielding exactly 20x5; fixed weight 50."
      ),
      doitall_note,
      unchanged_note,
      unchanged_note,
      unchanged_note
    ),
    stringsAsFactors = FALSE
  )
  if (has_cutoff) {
    manifest <- rbind(
      manifest,
      data.frame(
        role = "frq_transform_audit",
        file = "lf_cutoff_audit.csv",
        source = file.path(archive_source, "bet.frq"),
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
    "This is one cell of the 36-model BET 2026 MFCL LF sensitivity factorial.",
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
      "All inputs derive from the exact raw MFCL bundle archived by Kflow Job 5319 ",
      "(input-set SHA-256 `", expected_archive_sha256, "`)."
    ),
    paste0(
      "The archived effort-crept `bet.frq` has SHA-256 `", expected_frq_sha256,
      "`; effort creep is not reapplied."
    ),
    paste(
      "Archived regional-scaling rows 53:72 are copied verbatim as a 20x5",
      "matrix. The `doitall.sh` changes are limited to flag 313 and three new",
      "F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls remain unchanged."
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

regional_source <- file.path(job_5319_input_dir, "bet.reg_scaling")
regional_lines <- readLines(regional_source, warn = FALSE)
regional_fields <- lengths(strsplit(trimws(regional_lines), "[[:space:]]+"))
if (length(regional_lines) != 292L || any(regional_fields != 5L)) {
  fail("Job 5319 bet.reg_scaling must be exactly 292x5")
}

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  step_id <- as.character(row$step_id)
  step_dir <- file.path(sensitivity_root, step_id)
  model_dir <- file.path(step_dir, "model")
  unlink(step_dir, recursive = TRUE, force = TRUE)
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  for (file in c(
    "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "mfcl.cfg",
    "fishery_map.R", "tag_rep_map.R"
  )) {
    copy_exact(
      file.path(job_5319_input_dir, file),
      file.path(model_dir, file)
    )
  }
  writeLines(
    regional_lines[53:72],
    file.path(model_dir, "bet.reg_scaling"),
    useBytes = TRUE
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

cat(sprintf("Generated %d sensitivity folders from Kflow Job 5319.\n", nrow(models)))
cat(sprintf("Job 5319 archived input-set SHA-256: %s\n", archive_sha256))
cat(sprintf("Job 5319 archived bet.frq SHA-256: %s\n", frq_sha256))
cat("Effort creep reapplied: no\n")
cat("Kflow submitted: no\n")
