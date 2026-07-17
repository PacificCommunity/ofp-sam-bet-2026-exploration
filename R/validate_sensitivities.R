## Fail-fast validation for the 36 BET 2026 MFCL LF sensitivity folders.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
root <- if (length(script_arg)) {
  script_path <- sub("^--file=", "", script_arg[[1L]])
  dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)))
} else {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

fail <- function(...) stop(paste0(...), call. = FALSE)
assert_true <- function(ok, ...) {
  if (length(ok) != 1L || is.na(ok) || !isTRUE(ok)) fail(...)
  invisible(TRUE)
}
pass <- function(message) cat("PASS: ", message, "\n", sep = "")

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
  assert_true(length(output) > 0L, "sha256sum returned no output for ", path)
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

read_raw <- function(path) {
  size <- file.info(path)$size
  assert_true(is.finite(size), "Cannot stat file: ", path)
  readBin(path, what = "raw", n = as.integer(size))
}
same_file <- function(left, right) {
  left_info <- file.info(left)
  right_info <- file.info(right)
  isTRUE(left_info$size == right_info$size) &&
    identical(read_raw(left), read_raw(right))
}

config_path <- file.path(root, "job-config.R")
assert_true(file.exists(config_path), "Missing job-config.R under ", root)
config_env <- new.env(parent = globalenv())
sys.source(config_path, envir = config_env)
models <- config_env$stepwise_models
assert_true(is.data.frame(models), "job-config.R must define stepwise_models")

expected_grid <- expand.grid(
  tail_compression_percent = c(0L, 1L, 3L, 5L),
  cutoff = c("NONE", "100", "70"),
  lf_downweight_factor = c(1L, 10L, 100L),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
cell_key <- function(tc, cutoff, dw) paste(tc, cutoff, dw, sep = "|")
actual_keys <- cell_key(
  models$tail_compression_percent,
  ifelse(is.na(models$cutoff_cm), "NONE", as.character(as.integer(models$cutoff_cm))),
  models$lf_downweight_factor
)
expected_keys <- cell_key(
  expected_grid$tail_compression_percent,
  expected_grid$cutoff,
  expected_grid$lf_downweight_factor
)
assert_true(nrow(models) == 36L, "Expected exactly 36 configured cells")
assert_true(!anyDuplicated(models$step_id), "Configured step IDs must be unique")
assert_true(!anyDuplicated(models$job_title), "Configured job titles must be unique")
assert_true(!anyDuplicated(actual_keys) && setequal(actual_keys, expected_keys),
            "Configured cells must be the exact 4 x 3 x 3 factorial")
assert_true(all(models$enabled), "All 36 sensitivity cells must be enabled")
assert_true(all(models$run_mode == "doitall"), "All cells must use doitall")
assert_true(all(models$regional_scaling_weight == 50L),
            "Regional-scaling weight must be 50 in all cells")
assert_true(all(models$lf_size_divisor == 20L * models$lf_downweight_factor),
            "Configured LF divisors must be exactly 20, 200, or 2000")
assert_true(setequal(unique(models$cutoff_code), c("NOCUT", "CUT100", "CUT70")),
            "Cutoff codes must be NOCUT, CUT100, and CUT70")
pass("exact 36-cell TC x cutoff x downweight design")

sensitivity_root <- file.path(root, "sensitivity")
assert_true(dir.exists(sensitivity_root), "Missing sensitivity directory")
top_entries <- list.files(sensitivity_root, full.names = TRUE, no.. = TRUE)
top_dirs <- basename(top_entries[file.info(top_entries)$isdir %in% TRUE])
assert_true(length(top_dirs) == 36L && setequal(top_dirs, models$step_id),
            "sensitivity must contain exactly the 36 configured folders")
forbidden_dirs <- c(
  file.path(root, "steps"),
  file.path(root, ".generation-staging"),
  file.path(sensitivity_root, "steps"),
  file.path(sensitivity_root, "staging"),
  file.path(sensitivity_root, ".generation-staging")
)
assert_true(!any(dir.exists(forbidden_dirs)), "No steps or staging directory may persist")
nested_dirs <- list.dirs(sensitivity_root, recursive = TRUE, full.names = TRUE)
assert_true(!any(basename(nested_dirs) %in% c("steps", "staging", ".generation-staging")),
            "No nested steps or staging directory may persist")
for (i in seq_len(nrow(models))) {
  readme_path <- file.path(sensitivity_root, models$step_id[[i]], "README.md")
  assert_true(file.exists(readme_path), "Missing titled README: ", readme_path)
  title <- readLines(readme_path, n = 1L, warn = FALSE)
  assert_true(identical(title, paste0("# ", models$job_title[[i]])),
              "Folder title does not match job-config.R: ", models$step_id[[i]])
}
pass("exactly 36 titled folders with no steps or staging")

reference_dir <- file.path(root, "reference-inputs", "job-5319", "mfcl-inputs")
reference_required <- c(
  "bet.age_length", "bet.frq", "bet.ini", "bet.reg_scaling",
  "bet.reg_scaling.full", "bet.tag", "doitall.sh", "fishery_map.R",
  "mfcl.cfg", "tag_rep_map.R"
)
expected_reference_sha256 <-
  "a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc"
expected_frq_sha256 <-
  "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"
expected_ini_sha256 <-
  "3c9503e0762547762bab20b26997c3a4e627b0965b1d88418d71a1a17f40bb11"
expected_tag_sha256 <-
  "3f1b836a844ec2ca8e70fc5814d94c5a1ebc37ff4a5571c1dc1f6b83e477dfe8"
stepwise_refresh_commit <- "26c74dc6f303faa951b1ab331d7de14ea20b7489"
tag_prep_commit <- "79733c429b320e84ed5047aa6c932c8f19dab187"
assert_true(dir.exists(reference_dir), "Missing refreshed reference input directory")
reference_files <- sort(list.files(reference_dir, all.files = FALSE, no.. = TRUE))
assert_true(identical(reference_files, sort(reference_required)),
            "Reference bundle must contain exactly the ten required inputs")
reference_sha256 <- reference_input_set_sha256(reference_dir)
frq_sha256 <- sha256_file(file.path(reference_dir, "bet.frq"))
ini_sha256 <- sha256_file(file.path(reference_dir, "bet.ini"))
tag_sha256 <- sha256_file(file.path(reference_dir, "bet.tag"))
assert_true(identical(reference_sha256, expected_reference_sha256),
            "Refreshed reference input-set SHA-256 mismatch: ", reference_sha256)
assert_true(identical(frq_sha256, expected_frq_sha256),
            "Job 5319 archived bet.frq SHA-256 mismatch: ", frq_sha256)
assert_true(identical(ini_sha256, expected_ini_sha256),
            "Refreshed bet.ini SHA-256 mismatch: ", ini_sha256)
assert_true(identical(tag_sha256, expected_tag_sha256),
            "Refreshed bet.tag SHA-256 mismatch: ", tag_sha256)
root_readme <- paste(readLines(file.path(root, "README.md"), warn = FALSE), collapse = "\n")
assert_true(grepl(expected_reference_sha256, root_readme, fixed = TRUE) &&
              grepl(expected_frq_sha256, root_readme, fixed = TRUE) &&
              grepl(expected_ini_sha256, root_readme, fixed = TRUE) &&
              grepl(expected_tag_sha256, root_readme, fixed = TRUE) &&
              grepl(stepwise_refresh_commit, root_readme, fixed = TRUE) &&
              grepl(tag_prep_commit, root_readme, fixed = TRUE),
            "README.md must record the refreshed reference provenance")
assert_true(!grepl("public repository", root_readme, fixed = TRUE),
            "README.md must not use the phrase public repository")
pass("refreshed reference provenance and SHA-256 hashes")

reference_ini <- readLines(file.path(reference_dir, "bet.ini"), warn = FALSE)
tag_header <- grep("^# tag flags[[:space:]]*$", reference_ini)
assert_true(length(tag_header) == 1L, "bet.ini must contain one tag flags block")
next_headers <- which(seq_along(reference_ini) > tag_header & grepl("^#", reference_ini))
assert_true(length(next_headers) > 0L, "Could not find the section after tag flags")
tag_rows <- reference_ini[seq.int(tag_header + 1L, min(next_headers) - 1L)]
tag_rows <- tag_rows[nzchar(trimws(tag_rows))]
tag_fields <- strsplit(trimws(tag_rows), "[[:space:]]+")
assert_true(length(tag_fields) == 98L && all(lengths(tag_fields) >= 2L),
            "bet.ini must contain 98 tag-flag rows")
tag_flag_column_2 <- suppressWarnings(as.numeric(vapply(tag_fields, `[[`, character(1), 2L)))
assert_true(!anyNA(tag_flag_column_2) && all(tag_flag_column_2 == 0),
            "Every tag_flags(:,2) value must remain 0")
pass("98 refreshed tag groups retain tag_flags(:,2)=0")

required_model_inputs <- c(
  "bet.frq", "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
  "bet.reg_scaling.full", "doitall.sh", "mfcl.cfg", "fishery_map.R",
  "tag_rep_map.R"
)
byte_identical_inputs <- c(
  "bet.ini", "bet.tag", "bet.age_length", "bet.reg_scaling",
  "bet.reg_scaling.full", "mfcl.cfg", "fishery_map.R", "tag_rep_map.R"
)
for (i in seq_len(nrow(models))) {
  step_id <- models$step_id[[i]]
  model_dir <- file.path(sensitivity_root, step_id, "model")
  paths <- file.path(model_dir, required_model_inputs)
  assert_true(all(file.exists(paths)),
              "Incomplete doitall input set for ", step_id, ": ",
              paste(required_model_inputs[!file.exists(paths)], collapse = ", "))
  assert_true(all(file.info(paths)$size > 0), "Empty required input in ", step_id)
  assert_true(file.access(file.path(model_dir, "doitall.sh"), mode = 1L) == 0L,
              "doitall.sh is not executable in ", step_id)
  for (file in byte_identical_inputs) {
    assert_true(
      same_file(file.path(model_dir, file), file.path(reference_dir, file)),
      step_id, "/model/", file, " is not byte-identical to the refreshed reference"
    )
  }
  if (is.na(models$cutoff_cm[[i]])) {
    assert_true(
      same_file(file.path(model_dir, "bet.frq"), file.path(reference_dir, "bet.frq")),
      "NOCUT FRQ is not byte-identical to the refreshed reference in ", step_id
    )
  }
}
pass("complete doitall inputs with refreshed tag controls, maps, and regional scaling")

cutoff_phrase <- function(cutoff_cm) {
  sprintf(
    "observed LF counts in bins with midpoint above the %.0f cm cutoff are set to zero",
    cutoff_cm
  )
}
for (i in seq_len(nrow(models))) {
  step_id <- models$step_id[[i]]
  step_dir <- file.path(sensitivity_root, step_id)
  manifest_path <- file.path(step_dir, "input_manifest.csv")
  assert_true(file.exists(manifest_path), "Missing input_manifest.csv in ", step_id)
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  assert_true(all(c("role", "file", "source", "source_commit", "note") %in% names(manifest)),
              "Malformed input_manifest.csv in ", step_id)
  assert_true(all(required_model_inputs %in% manifest$file),
              "Manifest does not enumerate every doitall input in ", step_id)
  manifest_text <- paste(manifest$note, collapse = " ")
  readme_text <- paste(readLines(file.path(step_dir, "README.md"), warn = FALSE), collapse = " ")
  public_fields <- paste(
    models$model_label[[i]],
    models$change_axis[[i]],
    models$job_title[[i]]
  )
  if (is.finite(models$cutoff_cm[[i]])) {
    phrase <- cutoff_phrase(models$cutoff_cm[[i]])
    assert_true(grepl(phrase, public_fields, fixed = TRUE),
                "Configured public description lacks exact cutoff semantics in ", step_id)
    assert_true(grepl(phrase, readme_text, fixed = TRUE),
                "Sensitivity README lacks exact cutoff semantics in ", step_id)
    assert_true(grepl(phrase, manifest_text, fixed = TRUE),
                "Manifest lacks exact cutoff semantics in ", step_id)
    assert_true("lf_cutoff_audit.csv" %in% manifest$file,
                "Cutoff manifest lacks lf_cutoff_audit.csv in ", step_id)
  } else {
    assert_true(grepl("observed LF counts are unchanged; no cutoff is applied", public_fields, fixed = TRUE),
                "NOCUT public description is unclear in ", step_id)
    assert_true(!("lf_cutoff_audit.csv" %in% manifest$file),
                "NOCUT manifest must not contain a cutoff audit in ", step_id)
  }
  assert_true(!grepl("public repository", readme_text, fixed = TRUE),
              "Generated README must not use the phrase public repository in ", step_id)
}
pass("public descriptions and manifests state exact observed-count semantics")

flag_value <- function(lines, actor, flag, context) {
  pattern <- sprintf("^[[:space:]]*%s[[:space:]]+%s[[:space:]]+", actor, flag)
  hit <- grep(pattern, lines)
  assert_true(length(hit) == 1L,
              context, " must contain exactly one ", actor, "/", flag, " flag")
  words <- strsplit(trimws(sub("#.*$", "", lines[[hit]])), "[[:space:]]+")[[1L]]
  value <- suppressWarnings(as.numeric(words[[3L]]))
  assert_true(is.finite(value), "Non-numeric ", actor, "/", flag, " flag in ", context)
  value
}

fish_49_50_records <- function(lines) {
  records <- list()
  for (line_no in seq_along(lines)) {
    clean <- trimws(sub("#.*$", "", lines[[line_no]]))
    if (!nzchar(clean)) next
    words <- strsplit(clean, "[[:space:]]+")[[1L]]
    if (length(words) < 3L) next
    starts <- seq.int(1L, length(words) - 2L, by = 3L)
    for (start in starts) {
      actor <- suppressWarnings(as.integer(words[[start]]))
      flag <- suppressWarnings(as.integer(words[[start + 1L]]))
      value <- suppressWarnings(as.numeric(words[[start + 2L]]))
      if (!is.na(actor) && !is.na(flag) && is.finite(value) && flag %in% 49:50) {
        records[[length(records) + 1L]] <- data.frame(
          actor = actor,
          flag = flag,
          value = value,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  if (!length(records)) {
    return(data.frame(actor = integer(), flag = integer(), value = numeric()))
  }
  do.call(rbind, records)
}

flag_record_keys <- function(records) {
  sort(sprintf("%d|%d|%.15g", records$actor, records$flag, records$value))
}

reference_doitall <- readLines(file.path(reference_dir, "doitall.sh"), warn = FALSE)
reference_fish_flags <- fish_49_50_records(reference_doitall)
assert_true(!any(reference_fish_flags$actor %in% -(21:23) & reference_fish_flags$flag == 49L),
            "Job 5319 archive unexpectedly has F21/F22/F23 flag-49 overrides")
expected_fixed_flags <- c(
  "141" = 3,
  "311" = 1,
  "77" = 50,
  "78" = 1,
  "79" = 240,
  "80" = 220,
  "81" = 1
)
for (i in seq_len(nrow(models))) {
  step_id <- models$step_id[[i]]
  doitall_path <- file.path(sensitivity_root, step_id, "model", "doitall.sh")
  lines <- readLines(doitall_path, warn = FALSE)
  for (flag in names(expected_fixed_flags)) {
    actual <- flag_value(lines, 1L, as.integer(flag), step_id)
    assert_true(actual == expected_fixed_flags[[flag]],
                "Flag ", flag, " does not match design in ", step_id)
  }
  tc <- flag_value(lines, 1L, 313L, step_id)
  assert_true(tc == models$tail_compression_percent[[i]],
              "Flag 313 does not match tail-compression design in ", step_id)

  generated_fish_flags <- fish_49_50_records(lines)
  target <- generated_fish_flags[
    generated_fish_flags$actor %in% -(21:23) & generated_fish_flags$flag == 49L,
    ,
    drop = FALSE
  ]
  assert_true(nrow(target) == 3L && setequal(target$actor, -(21:23)),
              "Expected exactly three F21/F22/F23 flag-49 overrides in ", step_id)
  for (fishery in 21:23) {
    value <- target$value[target$actor == -fishery]
    assert_true(length(value) == 1L && value == models$lf_size_divisor[[i]],
                "F", fishery, " flag-49 divisor is wrong in ", step_id)
  }
  inherited <- generated_fish_flags[
    !(generated_fish_flags$actor %in% -(21:23) & generated_fish_flags$flag == 49L),
    ,
    drop = FALSE
  ]
  assert_true(
    identical(flag_record_keys(inherited), flag_record_keys(reference_fish_flags)),
    "Inherited fishery flag-49/50 settings changed outside F21/F22/F23 in ", step_id
  )

  override_lines <- grep(
    "^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+",
    lines
  )
  assert_true(length(override_lines) == 3L,
              "doitall reconciliation found an unexpected override count in ", step_id)
  reconciled <- lines[-override_lines]
  reference_tc_line <- grep("^[[:space:]]*1[[:space:]]+313[[:space:]]+", reference_doitall)
  generated_tc_line <- grep("^[[:space:]]*1[[:space:]]+313[[:space:]]+", reconciled)
  assert_true(length(reference_tc_line) == 1L && length(generated_tc_line) == 1L,
              "Cannot reconcile flag 313 in ", step_id)
  reconciled[[generated_tc_line]] <- reference_doitall[[reference_tc_line]]
  assert_true(identical(reconciled, reference_doitall),
              "doitall differs from Job 5319 outside flag 313 and F21/F22/F23 flag 49 in ", step_id)
}
pass("flags 141/311/313/77-81 and isolated F21/F22/F23 divisors")

reference_regional_active <- readLines(
  file.path(reference_dir, "bet.reg_scaling"), warn = FALSE
)
reference_regional_full <- readLines(
  file.path(reference_dir, "bet.reg_scaling.full"), warn = FALSE
)
active_fields <- lengths(strsplit(trimws(reference_regional_active), "[[:space:]]+"))
full_fields <- lengths(strsplit(trimws(reference_regional_full), "[[:space:]]+"))
assert_true(length(reference_regional_active) == 20L && all(active_fields == 5L),
            "Reference bet.reg_scaling must be exactly 20x5")
assert_true(length(reference_regional_full) == 292L && all(full_fields == 5L),
            "Reference bet.reg_scaling.full must be exactly 292x5")
assert_true(identical(reference_regional_active, reference_regional_full[53:72]),
            "Active regional scaling must equal full-source rows 53:72")
for (step_id in models$step_id) {
  generated_active <- readLines(
    file.path(sensitivity_root, step_id, "model", "bet.reg_scaling"),
    warn = FALSE
  )
  generated_full <- readLines(
    file.path(sensitivity_root, step_id, "model", "bet.reg_scaling.full"),
    warn = FALSE
  )
  assert_true(identical(generated_active, reference_regional_active),
              "Active regional scaling differs from the reference in ", step_id)
  assert_true(identical(generated_full, reference_regional_full),
              "Full regional-scaling source differs from the reference in ", step_id)
}
pass("regional scaling retains exact active 20x5 and full 292x5 matrices")

frq_paths <- file.path(sensitivity_root, models$step_id, "model", "bet.frq")
frq_md5 <- unname(tools::md5sum(frq_paths))
assert_true(!anyNA(frq_md5), "Could not hash every generated FRQ")
variant_hashes <- vapply(c("NOCUT", "CUT100", "CUT70"), function(code) {
  hashes <- unique(frq_md5[models$cutoff_code == code])
  assert_true(length(hashes) == 1L, "FRQ bytes vary within ", code)
  hashes[[1L]]
}, character(1))
assert_true(length(unique(variant_hashes)) == 3L,
            "Generated folders must contain exactly three distinct FRQ variants")
for (code in names(variant_hashes)) {
  paths <- frq_paths[models$cutoff_code == code]
  reference <- paths[[1L]]
  for (path in paths[-1L]) {
    assert_true(same_file(reference, path), "FRQ byte mismatch within ", code)
  }
}
pass("exactly three byte-distinct FRQ variants: NOCUT, CUT100, CUT70")

read_words <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1L]]
}
frq_shape <- function(lines, path) {
  header <- grep("Datasets / LFIntervals", lines, fixed = TRUE)
  assert_true(length(header) == 1L, "Expected one FRQ shape header in ", path)
  words <- read_words(lines[[header + 1L]])
  assert_true(length(words) >= 6L, "Malformed FRQ shape row in ", path)
  shape <- list(
    n_records = as.integer(words[[1L]]),
    n_lf = as.integer(words[[2L]]),
    lf_first = as.numeric(words[[3L]]),
    lf_width = as.numeric(words[[4L]]),
    n_wf = as.integer(words[[6L]])
  )
  assert_true(all(is.finite(unlist(shape))), "Non-numeric FRQ shape in ", path)
  shape$record_start <- length(lines) - shape$n_records + 1L
  assert_true(shape$record_start > header + 1L,
              "FRQ record count is inconsistent in ", path)
  shape
}

split_record <- function(line, shape, context) {
  words <- read_words(line)
  assert_true(length(words) >= 9L, "Malformed FRQ record in ", context)
  metadata <- words[1:7]
  if (identical(words[[8L]], "-1")) {
    lf <- NULL
    suffix <- words[9:length(words)]
  } else {
    lf_end <- 7L + shape$n_lf
    assert_true(length(words) > lf_end, "Truncated LF record in ", context)
    lf <- suppressWarnings(as.numeric(words[8:lf_end]))
    assert_true(!anyNA(lf), "Non-numeric LF count in ", context)
    suffix <- words[(lf_end + 1L):length(words)]
  }
  valid_suffix <- (length(suffix) == 1L && identical(suffix, "-1")) ||
    length(suffix) == shape$n_wf
  assert_true(valid_suffix, "Malformed WF suffix in ", context)
  list(words = words, metadata = metadata, lf = lf, suffix = suffix)
}

numeric_equal <- function(left, right) {
  length(left) == length(right) &&
    isTRUE(all.equal(left, right, tolerance = 1e-12, check.attributes = FALSE))
}

validate_cutoff_variant <- function(source_path, variant_path, cutoff_cm) {
  source_lines <- readLines(source_path, warn = FALSE)
  variant_lines <- readLines(variant_path, warn = FALSE)
  assert_true(length(source_lines) == length(variant_lines),
              "Cutoff changed FRQ line count: ", variant_path)
  shape <- frq_shape(source_lines, source_path)
  variant_shape <- frq_shape(variant_lines, variant_path)
  assert_true(identical(shape[1:5], variant_shape[1:5]),
              "Cutoff changed FRQ shape metadata: ", variant_path)
  header_lines <- seq_len(shape$record_start - 1L)
  assert_true(identical(source_lines[header_lines], variant_lines[header_lines]),
              "Cutoff changed FRQ header metadata: ", variant_path)

  bins <- shape$lf_first + (seq_len(shape$n_lf) - 1L) * shape$lf_width
  upper <- bins > cutoff_cm
  stats <- data.frame(
    fishery = 21:23,
    cutoff_cm = rep(cutoff_cm, 3L),
    removed_count = numeric(3L),
    affected_records = integer(3L),
    emptied_records = integer(3L),
    newly_below_minimum = integer(3L),
    stringsAsFactors = FALSE
  )

  for (record_index in seq_len(shape$n_records)) {
    line_index <- shape$record_start + record_index - 1L
    context <- paste0(basename(variant_path), " record ", record_index)
    source <- split_record(source_lines[[line_index]], shape, context)
    variant <- split_record(variant_lines[[line_index]], shape, context)
    assert_true(identical(source$metadata, variant$metadata),
                "Cutoff changed record metadata in ", context)
    fishery <- suppressWarnings(as.integer(source$metadata[[4L]]))
    assert_true(!is.na(fishery), "Non-numeric fishery in ", context)

    if (!fishery %in% 21:23 || is.null(source$lf)) {
      assert_true(identical(source_lines[[line_index]], variant_lines[[line_index]]),
                  "Cutoff changed a non-target or absent-LF record in ", context)
      next
    }

    removed <- sum(source$lf[upper])
    if (removed <= 0) {
      assert_true(identical(source_lines[[line_index]], variant_lines[[line_index]]),
                  "Cutoff changed a target record with no upper-bin counts in ", context)
      next
    }

    expected_lf <- source$lf
    expected_lf[upper] <- 0
    before <- sum(source$lf)
    after <- sum(expected_lf)
    stat_index <- match(fishery, stats$fishery)
    stats$removed_count[[stat_index]] <- stats$removed_count[[stat_index]] + removed
    stats$affected_records[[stat_index]] <- stats$affected_records[[stat_index]] + 1L
    if (before >= 50 && after > 0 && after < 50) {
      stats$newly_below_minimum[[stat_index]] <-
        stats$newly_below_minimum[[stat_index]] + 1L
    }

    assert_true(identical(source$suffix, variant$suffix),
                "Cutoff changed WF data in ", context)
    if (after <= 0) {
      assert_true(is.null(variant$lf) && identical(variant$words[[8L]], "-1"),
                  "All-zero LF vector is not one -1 LF sentinel in ", context)
      stats$emptied_records[[stat_index]] <- stats$emptied_records[[stat_index]] + 1L
    } else {
      assert_true(!is.null(variant$lf),
                  "Retained LF categories were replaced by a sentinel in ", context)
      assert_true(numeric_equal(variant$lf, expected_lf),
                  "Cutoff changed counts outside the declared upper LF bins in ", context)
      assert_true(all(variant$lf[upper] == 0),
                  "An upper-bin observed LF count remains after cutoff in ", context)
    }
  }
  stats
}

compare_audit <- function(path, expected, step_id) {
  assert_true(file.exists(path), "Missing lf_cutoff_audit.csv in ", step_id)
  actual <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c(
    "fishery", "cutoff_cm", "removed_count", "affected_records",
    "emptied_records", "newly_below_minimum", "transform"
  )
  assert_true(identical(names(actual), required), "Malformed cutoff audit in ", step_id)
  actual <- actual[order(actual$fishery), , drop = FALSE]
  expected <- expected[order(expected$fishery), , drop = FALSE]
  assert_true(nrow(actual) == 3L && identical(as.integer(actual$fishery), expected$fishery),
              "Cutoff audit fisheries do not reconcile in ", step_id)
  for (column in c(
    "cutoff_cm", "removed_count", "affected_records",
    "emptied_records", "newly_below_minimum"
  )) {
    assert_true(numeric_equal(as.numeric(actual[[column]]), as.numeric(expected[[column]])),
                "Cutoff audit column ", column, " does not reconcile in ", step_id)
  }
  assert_true(all(actual$transform == "lf_upper_cutoff"),
              "Cutoff audit transform label is wrong in ", step_id)
}

source_frq <- file.path(reference_dir, "bet.frq")
expected_audits <- list()
for (code in c("CUT100", "CUT70")) {
  cutoff <- as.numeric(sub("^CUT", "", code))
  representative <- frq_paths[models$cutoff_code == code][[1L]]
  expected_audits[[code]] <- validate_cutoff_variant(source_frq, representative, cutoff)
}
for (i in seq_len(nrow(models))) {
  audit_path <- file.path(
    sensitivity_root,
    models$step_id[[i]],
    "model",
    "lf_cutoff_audit.csv"
  )
  if (models$cutoff_code[[i]] == "NOCUT") {
    assert_true(!file.exists(audit_path),
                "NOCUT cell must not contain a cutoff audit: ", models$step_id[[i]])
  } else {
    compare_audit(audit_path, expected_audits[[models$cutoff_code[[i]]]], models$step_id[[i]])
  }
}
pass("cutoffs change only F21/F22/F23 upper LF counts, preserve metadata/WF, and reconcile audits")

cat("VALIDATION PASSED: 36 titled sensitivity folders; all requested invariants hold.\n")
