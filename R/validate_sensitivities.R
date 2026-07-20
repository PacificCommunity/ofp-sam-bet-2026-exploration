## Validate the focused sixteen-model SUB075 regional-scaling design.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)
config <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config)
models <- config$stepwise_models

expected_ids <- sprintf("S%03d", 1:16)
actual_ids <- sub("-.*$", "", models$step_id)
if (!is.data.frame(models) || nrow(models) != 16L ||
    !identical(actual_ids, expected_ids) || anyDuplicated(models$step_id)) {
  fail("Expected contiguous model IDs S001:S016")
}
normal_rows <- models$lf_likelihood == "normal"
dm_rows <- models$lf_likelihood == "dm_no_re"
if (sum(normal_rows) != 8L || sum(dm_rows) != 8L ||
    any(models$age_length_variant != "SUB075") ||
    any(models$cutoff_code != "NOCUT") ||
    any(grepl("CUT[0-9]+", models$step_id))) {
  fail("Expected eight normal and eight DM SUB075 NOCUT models")
}
if (!identical(models$regional_scaling_weight, rep(c(50L, 11L, 1L, 0L), 4L))) {
  fail("Each model family must use REGW50, REGW11, REGW1, and REGW0")
}
if (!identical(models$tag_flag2, rep(c(0L, 1L, 0L, 1L), each = 4L))) {
  fail("TAGF2 settings do not match the focused design")
}
if (any(models$lf_downweight_factor[normal_rows] != 10L) ||
    any(models$lf_size_divisor[normal_rows] != 200L) ||
    any(!is.na(models$lf_downweight_factor[dm_rows])) ||
    any(!is.na(models$lf_size_divisor[dm_rows])) ||
    any(models$dm_grouping[dm_rows] != "G5PROC") ||
    any(models$dm_nmax[dm_rows] != 20L)) {
  fail("Normal DW10 or DM G5PROC Nmax20 metadata are incorrect")
}

sensitivity_root <- file.path(root, "sensitivity")
model_dirs <- list.files(sensitivity_root, pattern = "^S[0-9]{3}-", full.names = FALSE)
if (!setequal(model_dirs, models$step_id) || length(model_dirs) != 16L) {
  fail("Generated sensitivity folders do not match job-config.R")
}

sha256_file <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  if (!length(output)) fail("Could not calculate SHA-256 for ", path)
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
expected_age_sha <- "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c"
duplicate_fisheries <- c(1L, 2L, 4L, 6L, 7L, 8L, 10L, 29L:33L)

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

  lines <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
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
        sum(grepl("^[[:space:]]*1[[:space:]]+342[[:space:]]+20([[:space:]]|$)", lines)) != 1L ||
        sum(grepl("^[[:space:]]*-[0-9]+[[:space:]]+68[[:space:]]+", lines)) != 33L ||
        sum(grepl("^[[:space:]]*-999[[:space:]]+89[[:space:]]+1([[:space:]]|$)", lines)) != 1L ||
        any(grepl("^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+200([[:space:]]|$)", lines))) {
      fail(row$step_id, ": DM G5PROC-CEST Nmax20 controls are incorrect")
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
family_key <- paste(models$lf_likelihood, models$tag_flag2, sep = ":")
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
for (likelihood in c("normal", "dm_no_re")) {
  for (weight in c(50L, 11L, 1L, 0L)) {
    off <- models$step_id[
      models$lf_likelihood == likelihood & models$tag_flag2 == 0L &
        models$regional_scaling_weight == weight
    ]
    on <- models$step_id[
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

# Normal and DM counterparts retain exactly the same non-doitall model inputs.
matched_likelihood_files <- c("bet.ini", common_pair_files)
for (tag_value in 0:1) {
  for (weight in c(50L, 11L, 1L, 0L)) {
    normal <- models$step_id[
      models$lf_likelihood == "normal" & models$tag_flag2 == tag_value &
        models$regional_scaling_weight == weight
    ]
    dm <- models$step_id[
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

cat(paste0(
  "Validated sixteen SUB075 NOCUT REGW50/11/1/0 models, including exact ",
  "TAGF2 OFF/ON and normal/DM input pairing.\n"
))
