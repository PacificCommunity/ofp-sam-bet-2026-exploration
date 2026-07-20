## Validate the focused nine-model SUB075 regional-scaling design.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
fail <- function(...) stop(paste0(...), call. = FALSE)
config <- new.env(parent = globalenv())
sys.source(file.path(root, "job-config.R"), envir = config)
models <- config$stepwise_models

expected_ids <- sprintf("S%03d", 1:9)
actual_ids <- sub("-.*$", "", models$step_id)
if (!is.data.frame(models) || nrow(models) != 9L ||
    !identical(actual_ids, expected_ids) || anyDuplicated(models$step_id)) {
  fail("Expected contiguous model IDs S001:S009")
}
normal_rows <- models$lf_likelihood == "normal"
dm_rows <- models$lf_likelihood == "dm_no_re"
if (sum(normal_rows) != 6L || sum(dm_rows) != 3L ||
    any(models$age_length_variant != "SUB075") ||
    any(models$cutoff_code != "NOCUT") ||
    any(grepl("CUT[0-9]+", models$step_id))) {
  fail("Expected six normal and three DM SUB075 NOCUT models")
}
if (!identical(models$regional_scaling_weight, rep(c(3L, 1L, 0L), 3L))) {
  fail("Each model family must use REGW3, REGW1, and REGW0")
}
if (!identical(models$tag_flag2, c(rep(0L, 3L), rep(1L, 6L)))) {
  fail("TAGF2 settings do not match the focused design")
}
if (any(models$lf_downweight_factor[normal_rows] != 10L) ||
    any(models$lf_size_divisor[normal_rows] != 200L) ||
    any(!is.na(models$lf_downweight_factor[dm_rows])) ||
    any(!is.na(models$lf_size_divisor[dm_rows])) ||
    any(models$dm_grouping[dm_rows] != "G5PROC") ||
    any(models$dm_nmax[dm_rows] != 10L)) {
  fail("Normal DW10 or DM G5PROC Nmax10 metadata are incorrect")
}

sensitivity_root <- file.path(root, "sensitivity")
model_dirs <- list.files(sensitivity_root, pattern = "^S[0-9]{3}-", full.names = FALSE)
if (!setequal(model_dirs, models$step_id) || length(model_dirs) != 9L) {
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
        sum(grepl("^[[:space:]]*1[[:space:]]+342[[:space:]]+10([[:space:]]|$)", lines)) != 1L ||
        sum(grepl("^[[:space:]]*-[0-9]+[[:space:]]+68[[:space:]]+", lines)) != 33L ||
        sum(grepl("^[[:space:]]*-999[[:space:]]+89[[:space:]]+1([[:space:]]|$)", lines)) != 1L ||
        any(grepl("^[[:space:]]*-2[123][[:space:]]+49[[:space:]]+200([[:space:]]|$)", lines))) {
      fail(row$step_id, ": DM G5PROC-CEST Nmax10 controls are incorrect")
    }
  }
}

cat("Validated nine SUB075 NOCUT REGW3/1/0 models.\n")
