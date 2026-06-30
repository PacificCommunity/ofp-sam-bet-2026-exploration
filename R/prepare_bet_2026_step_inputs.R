## Rebuild BET 2026 stepwise input folders.
##
## This script copies source `.frq`, `.ini`, `.tag`, and age-length files from
## `input-repos/`, applies the documented stepwise changes, writes manifests
## and READMEs, and removes generated `.par` run products from model folders.
## Helper functions live in `R/prepare_*.R`; this file keeps setup and step
## definitions together.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
input_repo_names <- c(
  "ofp-sam-2026-BET-YFT-frq-build",
  "ofp-sam-2026-BET-YFT-build-ini",
  "ofp-sam-2026-BET-YFT-tag-prep",
  "ofp-sam-2026-BET-YFT-age-length-build"
)
input_root_env <- Sys.getenv("BET_2026_INPUT_ROOT", "")
input_root_candidates <- if (nzchar(input_root_env)) {
  input_root_env
} else {
  c(
    file.path(dirname(root), "input-repos"),
    dirname(root),
    file.path(dirname(root), "bet_2026_input_repos")
  )
}
has_input_repos <- function(path) {
  all(dir.exists(file.path(path, input_repo_names)))
}
input_root_hit <- input_root_candidates[vapply(input_root_candidates, has_input_repos, logical(1))]
if (!length(input_root_hit)) {
  stop(
    "Could not find BET 2026 input repos. Set BET_2026_INPUT_ROOT to a folder containing: ",
    paste(input_repo_names, collapse = ", "),
    call. = FALSE
  )
}
input_root <- normalizePath(input_root_hit[[1L]], winslash = "/", mustWork = TRUE)

frq_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build", "BET")
ini_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini", "BET")
tag_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep", "BET")
age_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build", "BET")
reg_scaling_source <- file.path(frq_root, "bet.2026.reg_scaling")
reg_scaling_active_start_period <- 53L
reg_scaling_active_end_period <- 72L
reg_scaling_active_years <- "1965-1969"

fixm_age_par_value <- "-2.54917483258212e+00"

diagnostic_root_env <- Sys.getenv("BET_2023_DIAGNOSTIC_ROOT", "")
diagnostic_root_candidates <- if (nzchar(diagnostic_root_env)) {
  diagnostic_root_env
} else {
  c(
    file.path(dirname(root), "ofp-sam-bet-2023-diagnostic"),
    file.path(dirname(root), "input-repos", "ofp-sam-bet-2023-diagnostic")
  )
}
diagnostic_mfcl_candidate <- function(path) {
  if (file.exists(file.path(path, "MFCL", "bet.frq"))) {
    return(file.path(path, "MFCL"))
  }
  if (file.exists(file.path(path, "bet.frq"))) {
    return(path)
  }
  ""
}
diagnostic_mfcl_hits <- vapply(diagnostic_root_candidates, diagnostic_mfcl_candidate, character(1))
diagnostic_mfcl_hits <- diagnostic_mfcl_hits[nzchar(diagnostic_mfcl_hits)]
if (!length(diagnostic_mfcl_hits)) {
  stop(
    "Could not find the BET 2023 diagnostic MFCL folder. Set BET_2023_DIAGNOSTIC_ROOT to the repo root or MFCL folder.",
    call. = FALSE
  )
}
diagnostic_mfcl_root <- normalizePath(diagnostic_mfcl_hits[[1L]], winslash = "/", mustWork = TRUE)
diagnostic_repo_root <- if (basename(diagnostic_mfcl_root) == "MFCL") {
  dirname(diagnostic_mfcl_root)
} else {
  diagnostic_mfcl_root
}

input_repo_roots <- c(
  "ofp-sam-2026-BET-YFT-frq-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build"),
  "ofp-sam-2026-BET-YFT-build-ini" = file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini"),
  "ofp-sam-2026-BET-YFT-tag-prep" = file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep"),
  "ofp-sam-2026-BET-YFT-age-length-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build"),
  "ofp-sam-bet-2023-diagnostic" = diagnostic_repo_root
)

git_value <- function(repo, args) {
  if (!dir.exists(file.path(repo, ".git"))) return("")
  value <- tryCatch(
    system2("git", c("-C", repo, args), stdout = TRUE, stderr = NULL),
    error = function(e) character()
  )
  if (!length(value)) "" else value[[1L]]
}

git_commit <- function(repo) {
  git_value(repo, c("rev-parse", "--short", "HEAD"))
}

git_subject <- function(repo) {
  git_value(repo, c("log", "-1", "--pretty=%s"))
}

source_commit_for_path <- function(path) {
  if (!nzchar(path)) return("")
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  for (repo in input_repo_roots) {
    repo_prefix <- paste0(normalizePath(repo, winslash = "/", mustWork = FALSE), "/")
    if (startsWith(norm, repo_prefix)) {
      return(git_commit(repo))
    }
  }
  input_prefix <- paste0(normalizePath(input_root, winslash = "/", mustWork = TRUE), "/")
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  if (startsWith(norm, input_prefix)) {
    parts <- strsplit(substring(norm, nchar(input_prefix) + 1L), "/", fixed = TRUE)[[1L]]
    repo <- file.path(input_root, parts[[1L]])
    return(git_commit(repo))
  }
  if (startsWith(norm, root_prefix) || grepl("^steps/", path)) {
    return(git_commit(root))
  }
  ""
}

input_repo_revision_table <- function() {
  data.frame(
    repo = names(input_repo_roots),
    commit = vapply(input_repo_roots, git_commit, character(1)),
    subject = vapply(input_repo_roots, git_subject, character(1)),
    stringsAsFactors = FALSE
  )
}

region_map_helper <- file.path(root, "R", "write_bet_region_map_assets.R")
if (file.exists(region_map_helper)) {
  source(region_map_helper, local = TRUE)
}

source_prepare_module <- function(file) {
  sys.source(file.path(root, "R", file), envir = parent.frame())
}

for (module in c(
  "prepare_common.R",
  "prepare_mfcl_inputs.R",
  "prepare_readme_manifest.R",
  "prepare_doitall.R",
  "prepare_step_builder.R"
)) {
  source_prepare_module(module)
}

write_shared_region_map_assets()

## Step definitions ----------------------------------------------------------

first_existing <- function(paths, label) {
  hit <- paths[file.exists(paths)]
  if (!length(hit)) {
    stop(
      "Could not find ", label, ". Tried: ",
      paste(paths, collapse = ", "),
      call. = FALSE
    )
  }
  hit[[1L]]
}

diagnostic_file <- function(file) {
  file.path(diagnostic_mfcl_root, file)
}

diagnostic_model_files <- c(
  "bet.frq",
  "bet.ini",
  "bet.tag",
  "bet.age_length",
  "mfcl.cfg",
  "labels.tmp"
)

prepare_step_model_dir <- function(step_id) {
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  remove_model_par_files(model_dir)
  list(step_dir = step_dir, model_dir = model_dir)
}

copy_diagnostic_model_files <- function(model_dir) {
  for (file in diagnostic_model_files) {
    copy_if_exists(diagnostic_file(file), file.path(model_dir, file))
  }
  unlink(file.path(model_dir, "fdesc.txt"), force = TRUE)
}

copy_aux_if_exists <- function(from_dir, to_dir, file) {
  from <- file.path(from_dir, file)
  to <- file.path(to_dir, file)
  if (!file.exists(from)) return(invisible(FALSE))
  if (normalizePath(from, winslash = "/", mustWork = FALSE) ==
      normalizePath(to, winslash = "/", mustWork = FALSE)) {
    return(invisible(FALSE))
  }
  copy_one(from, to)
  invisible(TRUE)
}

write_original_diagnostic_step <- function() {
  paths <- prepare_step_model_dir("01-Diag2023")
  copy_diagnostic_model_files(paths$model_dir)
  write_2023_historical_doitall(
    diagnostic_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh")
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "original 2023 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = "original 2023 diagnostic ini, intentionally not promoted or edited"),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "original 2023 diagnostic tag input"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "original 2023 diagnostic CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = diagnostic_file("doitall.sh"), note = "historical 2023 diagnostic control script with PHASE 10/11 convergence switch; run_stepwise resolves bare mfclo64 to the historical 2.2.2.0 executable for this step")
  ))
  write_readme(
    paths$step_dir,
    "01 Diag2023",
    "Original BET 2023 diagnostic model rerun with the historical MFCL executable.",
    c(
      "Copies the 2023 diagnostic `MFCL` model files without changing the model inputs.",
      "`bet.ini` remains in its original 2023 diagnostic format for the historical `mfclo64` reader.",
      "`doitall.sh` keeps the historical diagnostic control sequence while allowing `BET_PHASE10_11_CONVERGENCE` to set PHASE 10/11 convergence from Kflow.",
      "The runner supplies a temporary `mfclo64` PATH shim pointing to `/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0`.",
      "This step is the direct reproducibility anchor before moving to the current executable."
    ),
    c(
      "bet.frq" = "original 2023 diagnostic frequency/catch/size input",
      "bet.ini" = "original 2023 diagnostic ini, not promoted to MFCL 1007",
      "bet.tag" = "original 2023 diagnostic tag input",
      "bet.age_length" = "original 2023 diagnostic CAAL input",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The model files come from `ofp-sam-bet-2023-diagnostic/MFCL`.",
      "The step-specific executable path is set in `job-config.R`; only this step uses the historical MFCL binary.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict archival comparisons can set `-5` without editing model folders.",
      "No FixM, new-executable compatibility edits, new fishery structure, or 2026 input files are applied here."
    ),
    c(
      "Compare this rerun against the archived 2023 diagnostic output before interpreting later deltas.",
      "Apart from the PHASE 10/11 convergence switch, failures will reflect the original diagnostic control sequence."
    ),
    "Ready for Kflow with the tuna-flow image that includes the historical 2023 diagnostic MFCL executable.",
    source_revisions = input_repo_revision_table()
  )
}

write_current_diagnostic_step <- function(step_id, title, summary, fixm = FALSE,
                                          legacy_aux_step = "02-NewExe") {
  paths <- prepare_step_model_dir(step_id)
  copy_diagnostic_model_files(paths$model_dir)
  ini_note <- ensure_ini_1007_compatibility(
    file.path(paths$model_dir, "bet.ini"),
    file.path(paths$model_dir, "bet.tag")
  )
  if (isTRUE(fixm)) {
    apply_fixm_m(file.path(paths$model_dir, "bet.ini"))
  }
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    diagnostic_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = fixm
  )
  legacy_aux_dir <- file.path(root, "steps", legacy_aux_step, "model")
  current_aux_dir <- file.path(root, "steps", step_id, "model")
  copied <- copy_aux_if_exists(current_aux_dir, paths$model_dir, "fishery_map.R")
  if (!isTRUE(copied)) copy_aux_if_exists(legacy_aux_dir, paths$model_dir, "fishery_map.R")
  ini_notes <- c(
    if (isTRUE(fixm)) "FixM M row applied",
    ini_note
  )
  ini_note_text <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "2023 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = ini_note_text),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "2023 diagnostic tag input; tag reporting map regenerated from ini/tag"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "2023 diagnostic CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = diagnostic_file("doitall.sh"), note = "current-executable compatibility controls: updated initial Z and CPUE CV settings, PROGRAM_PATH wrapper, and PHASE 10/11 convergence switch")
  ))
  write_readme(
    paths$step_dir,
    title,
    summary,
    c(
      "Uses the 2023 diagnostic 9-region, 41-fishery inputs ending in 2021.",
      "`bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader while retaining the diagnostic values.",
      "The current-executable `doitall.sh` controls match the existing stepwise diagnostic baseline: initial Z uses `2 94 1 2 128 100`, and survey CPUE CV settings are the current BET 2023 values.",
      if (isTRUE(fixm)) "Applies the FixM M-scale row at the 2023 MLE value." else "Natural mortality setup remains the pre-FixM diagnostic baseline."
    ),
    c(
      "bet.frq" = "2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021",
      "bet.ini" = paste("2023 diagnostic ini promoted for the current reader", ini_note_text),
      "bet.tag" = "2023 diagnostic tag input",
      "bet.age_length" = "2023 diagnostic CAAL input",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable `/home/mfcl/mfclo64` is used.",
      "The step output includes the 2023 nine-region GeoJSON asset as a display-only map asset; it does not change MFCL inputs.",
      "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
    ),
    c(
      "This step should continue to match the previously generated 2026 stepwise diagnostic baseline.",
      if (isTRUE(fixm)) "No fishery, tag, CAAL, or CPUE update is intended in this step." else "FixM is intentionally isolated in the next step."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    source_revisions = input_repo_revision_table()
  )
}

write_original_diagnostic_step()
write_current_diagnostic_step(
  "02-NewExe",
  "02 NewExe",
  "2023 diagnostic inputs run with the current MFCL executable and the existing current-executable compatibility controls.",
  fixm = FALSE,
  legacy_aux_step = "02-NewExe"
)
write_current_diagnostic_step(
  "03-FixM",
  "03 FixM",
  "NewExe baseline with the FixM M-scale row applied at the 2023 MLE value.",
  fixm = TRUE,
  legacy_aux_step = "03-FixM"
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
mix_ini <- file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini")
regfish_ini_source <- file.path(ini_root, "bet.2023.new.structure.ini")
regfish_tag_source <- file.path(tag_root, "bet.2023.new.structure-low.recaps.removed.tag")

frq_new_structure_global_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.frq")
frq_convert_length_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.wt-as-len.frq")
frq_length_plus_length_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq")
frq_global_2024 <- file.path(frq_root, "bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq")
frq_regional_2024 <- first_existing(
  c(
    file.path(frq_root, "bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq"),
    file.path(frq_root, "bet.2026.new-structure.regional-cpue.wt-as-len-plus-len.frq")
  ),
  "2026 regional CPUE frq"
)

## 04-NewStructure is the first 5-region template. Cache the inherited template
## before overwriting the folder so the script is rerunnable after old folders
## have been removed.
newstructure_dir <- file.path(root, "steps", "04-NewStructure")
newstructure_model_dir <- file.path(newstructure_dir, "model")
template_candidates <- c(
  newstructure_model_dir
)
template_model_dir <- first_existing(
  file.path(template_candidates, "doitall.sh"),
  "5-region doitall template"
)
template_model_dir <- dirname(template_model_dir)
template_cache <- tempfile("newstructure-template-")
dir.create(template_cache, recursive = TRUE, showWarnings = FALSE)
for (file in c("mfcl.cfg", "fishery_map.R", "doitall.sh")) {
  copy_one(file.path(template_model_dir, file), file.path(template_cache, file))
}

dir.create(newstructure_model_dir, recursive = TRUE, showWarnings = FALSE)
remove_model_par_files(newstructure_model_dir)
copy_one(frq_new_structure_global_2021, file.path(newstructure_model_dir, "bet.frq"))
copy_one(regfish_ini_source, file.path(newstructure_model_dir, "bet.ini"))
copy_one(regfish_tag_source, file.path(newstructure_model_dir, "bet.tag"))
copy_one(old_age, file.path(newstructure_model_dir, "bet.age_length"))
copy_one(file.path(template_cache, "mfcl.cfg"), file.path(newstructure_model_dir, "mfcl.cfg"))
copy_one(file.path(template_cache, "fishery_map.R"), file.path(newstructure_model_dir, "fishery_map.R"))
n_normalized_04 <- normalize_frq_absent_lf_records(file.path(newstructure_model_dir, "bet.frq"))
ensure_frq_fishery_region_locations(file.path(newstructure_model_dir, "bet.frq"))
apply_fixm_m(file.path(newstructure_model_dir, "bet.ini"))
frq_counts_04 <- frq_header_counts(
  readLines(file.path(newstructure_model_dir, "bet.frq"), warn = FALSE),
  file.path(newstructure_model_dir, "bet.frq")
)
ini_tag_note_04 <- ensure_ini_tag_flags(
  file.path(newstructure_model_dir, "bet.ini"),
  frq_counts_04$n_tag_groups
)
write_generated_tag_rep_map(newstructure_model_dir)
write_doitall(
  file.path(template_cache, "doitall.sh"),
  file.path(newstructure_model_dir, "doitall.sh")
)
write_manifest(newstructure_dir, list(
  list(
    role = "frq",
    file = "bet.frq",
    source = frq_new_structure_global_2021,
    note = paste0(
      "5-region 2021-terminal new-structure frq with global CPUE",
      if (n_normalized_04) paste0("; normalized ", n_normalized_04, " records with stray absent-LF bins") else ""
    )
  ),
  list(
    role = "ini",
    file = "bet.ini",
    source = regfish_ini_source,
    note = paste(c("FixM M row applied", ini_tag_note_04)[nzchar(c("FixM M row applied", ini_tag_note_04))], collapse = "; ")
  ),
  list(
    role = "tag",
    file = "bet.tag",
    source = regfish_tag_source,
    note = "low-recapture-removed 2023 new-structure tag input; tag reporting map regenerated from ini/tag"
  ),
  list(
    role = "age_length",
    file = "bet.age_length",
    source = old_age,
    note = "old CAAL / age_length reassigned to the new fisheries"
  ),
  list(
    role = "doitall",
    file = "doitall.sh",
    source = file.path("steps", basename(dirname(template_model_dir)), "model", "doitall.sh"),
    note = "5-region controls retained and made fail-fast for Kflow"
  )
))
write_readme(
  newstructure_dir,
  "04 NewStructure",
  "First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE.",
  c(
    "Uses the new 5-region and new-fishery frequency source from the frq-build repo.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Keeps data through 2021 and uses the global CPUE setup for this structural transition.",
    "Uses old CAAL re-assigned to the new fisheries.",
    paste0("Uses the restructured tag setup with ", frq_counts_04$n_tag_groups, " release groups."),
    "Applies FixM M row while retaining the 5-region `.ini` structure."
  ),
  c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.frq`; 5-region, 33-fishery structure, terminal year 2021, global CPUE",
    "bet.ini" = "`bet.2023.new.structure.ini`; FixM M row applied and explicit default tag flags inserted if needed",
    "bet.tag" = "`bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input",
    "bet.age_length" = "`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries",
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "This step becomes the 5-region control template for steps 05-15.",
    "Generated `.frq` files include region locations for every fishery, including index fisheries.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here.",
  source_revisions = input_repo_revision_table()
)

stepwise_5_region_template_step_id <- "04-NewStructure"
newstructure_ini <- file.path(newstructure_model_dir, "bet.ini")
newstructure_tag <- file.path(newstructure_model_dir, "bet.tag")

full_2024_alignment_run_notes <- c(
  "Generated inputs repair only the `.ini` alignment where needed: tag reporting-rate matrices, explicit tag flags, and tag shed rates are matched to the selected release-group count.",
  "The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows are deleted to suppress warnings.",
  "These steps use the current tuna-flow MFCL executable and the 04-NewStructure 5-region controls unless a later step explicitly changes controls."
)
mix_period_alignment_run_notes <- c(
  "The mix-period ini family carries release-group-specific tag controls, so generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive mixing periods.",
  "Generation validates that tag flags, tag shed rate, and the five tag reporting-rate matrices match the selected release-group count.",
  "Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0."
)

make_step(
  step_id = "05-ConvertToLength",
  frq_source = frq_convert_length_2021,
  ini_source = newstructure_ini,
  tag_source = newstructure_tag,
  age_source = old_age,
  frq_tag_groups = frq_counts_04$n_tag_groups,
  title = "05 ConvertToLength",
  summary = "Data to 2021, global CPUE, converting existing weight compositions to length.",
  bullets = c(
    "Uses `bet.2023.new-structure.global-cpue.wt-as-len.frq` from the frq-build repo.",
    "Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the weight-to-length conversion.",
    "Applies the FixM M row through the inherited 04-NewStructure ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.wt-as-len.frq`; terminal year 2021, global CPUE",
    "bet.ini" = "`steps/04-NewStructure/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/04-NewStructure/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c("04-NewStructure 5-region `doitall.sh` controls retained."),
  run_notes = c("Compare directly with 04-NewStructure to isolate the effect of converting existing weight compositions to length."),
  outstanding = c("Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage.")
)

make_step(
  step_id = "06-LengthPlusLength",
  frq_source = frq_length_plus_length_2021,
  ini_source = newstructure_ini,
  tag_source = newstructure_tag,
  age_source = old_age,
  frq_tag_groups = frq_counts_04$n_tag_groups,
  title = "06 LengthPlusLength",
  summary = "Data to 2021, global CPUE, adding length compositions that were not used in the past.",
  bullets = c(
    "Uses `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq` from the frq-build repo.",
    "Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the additional length-composition data.",
    "Applies the FixM M row through the inherited 04-NewStructure ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq`; terminal year 2021, global CPUE",
    "bet.ini" = "`steps/04-NewStructure/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/04-NewStructure/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c("04-NewStructure 5-region `doitall.sh` controls retained."),
  run_notes = c("Compare directly with 05-ConvertToLength to isolate the extra length-composition records."),
  outstanding = c("Review fit impacts before deciding whether length-composition weighting needs adjustment.")
)

make_step(
  step_id = "07-DataTo2024",
  frq_source = frq_global_2024,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = old_age,
  title = "07 DataTo2024",
  summary = "Data to 2024, global CPUE, isolating the effect of adding three years of data.",
  bullets = c(
    "Uses `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq` without year chopping.",
    "Moves from the 2021 transition steps to the full 2024 frequency/catch/size series.",
    "Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths.",
    "Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq`, full 2024 with global CPUE",
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained.",
    "The all-release-group mixing period remains fixed at 2 for this pre-mix step."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c("Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.")
)

make_step(
  step_id = "08-RegionalCPUE",
  frq_source = frq_regional_2024,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = old_age,
  reg_scaling_source = reg_scaling_source,
  title = "08 RegionalCPUE",
  summary = "Regional CPUE step using the 2024 regional CPUE frequency file and regional-scaling prior.",
  bullets = c(
    "Uses the full 2024 regional CPUE `.frq` from the frq-build repo.",
    "Adds `bet.reg_scaling` and switches to the regional-scaling prior in PHASE 5.",
    "Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths.",
    "Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained until PHASE 5.",
    "PHASE 5 switches index CPUE/selectivity grouping for the regional-scaling prior."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c("Evaluate and test different regional CPUE prior values after this runnable baseline fit.")
)

make_step(
  step_id = "09-NewOtoliths",
  frq_source = frq_regional_2024,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  title = "09 NewOtoliths",
  summary = "New Japanese otoliths and 2026 CAAL input on the regional CPUE model.",
  bullets = c(
    "Uses the same regional CPUE `.frq`, 2026 `.ini`, and 2026 `.tag` as 08-RegionalCPUE.",
    "Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.",
    "The 2026 age_length file includes the new otolith data used for this step.",
    "Applies the FixM M row to the 2026 ini."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL/new otoliths)"
  ),
  control_notes = c("08-RegionalCPUE controls retained."),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c("After fitting, compare CAAL likelihood and age residuals against 08-RegionalCPUE.")
)

make_step(
  step_id = "10-TagMixingKS",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  title = "10 TagMixingKS",
  summary = "KS coefficient 0.2 release-group-specific tag mixing periods.",
  bullets = c(
    "Uses `bet.2026.mix-0.2.ini` from the ini-build repo.",
    "Keeps the full 2024 regional CPUE `.frq`, 2026 tag file, and updated 2026 CAAL.",
    "Applies the FixM M row to the mix-period ini.",
    "Removes the inherited `-9999 1 2` line from `doitall.sh` so release-group-specific tag flags in the ini are not overwritten."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override is removed.",
    "All other 08-RegionalCPUE fishery, tag recapture, selectivity, and regional-scaling controls are retained."
  ),
  run_notes = mix_period_alignment_run_notes,
  outstanding = c("After fitting, inspect tag residuals and release-group behavior before tuning tag-reporting assumptions further.")
)

make_step(
  step_id = "11-TimeVaryingCV",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(time_varying_cv = TRUE),
  title = "11 TimeVaryingCV",
  summary = "Enable time-varying CPUE CV for the regional index fisheries.",
  bullets = c(
    "Uses the same inputs as 10-TagMixingKS.",
    "Sets the index-fishery time-varying CPUE CV flag from 0 to 1 in `doitall.sh`.",
    "No fishery, tag, CAAL, or `.frq` source changes are made in this step."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override remains removed.",
    "Index fisheries 29-33 have fish flag 66 set to 1 for time-varying CPUE CV."
  ),
  run_notes = mix_period_alignment_run_notes,
  outstanding = c("After fitting, compare CPUE residuals and estimated CV behavior against 10-TagMixingKS.")
)

make_step(
  step_id = "12-OrthogonalPoly",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(time_varying_cv = TRUE, opr = TRUE),
  title = "12 OrthogonalPoly",
  summary = "Orthogonal polynomial recruitment step, ensuring `2 177 0` is used.",
  bullets = c(
    "Uses the same inputs as 11-TimeVaryingCV.",
    "Applies the BET OPR screening rank-1 model: `69-01-50-50`.",
    "Keeps time-varying CPUE CV enabled for index fisheries 29-33.",
    "OPR controls are applied in PHASE 3 of `doitall.sh`, including `2 177 0`."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "Time-varying CPUE CV flags are retained.",
    "`1 149 0`, `1 398 0`, `1 400 0`, `2 177 0`, `2 32 0`, and `2 113 0` are applied at PHASE 3 for the OPR transfer.",
    "`1 155 69`, `1 217 1`, `1 216 50`, and `1 218 50` set the OPR year, season, region, and region-season effects.",
    "`2 30 1` is deliberately retained at the OPR phase because current MFCL requires `age_flag(30)=1` to activate the OPR polynomial coefficients."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The OPR transfer follows the BET 4R screening rank-1 AIC setting `69-01-50-50`."
  ),
  outstanding = c("After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result.")
)

make_step(
  step_id = "13-LengthBasedSel",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(time_varying_cv = TRUE, opr = TRUE, size_based_selectivity = TRUE),
  title = "13 LengthBasedSel",
  summary = "Length-based selectivity test after the OPR step.",
  bullets = c(
    "Uses the same inputs as 12-OrthogonalPoly.",
    "Retains time-varying CPUE CV and OPR controls.",
    "Sets fish flag 26 from 2 to 3 in `doitall.sh` for the length-based selectivity test."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "12-OrthogonalPoly controls are retained.",
    "`-999 26 3` is applied for length-based selectivity."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The step-specific change after OPR is limited to fish flag 26: `doitall.sh` sets `-999 26 3`."
  ),
  outstanding = c("Confirm with the modelling group whether BET should keep the same flag-26 setting after the test fit.")
)

make_step(
  step_id = "14-EffortCreep",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(time_varying_cv = TRUE, opr = TRUE, size_based_selectivity = TRUE),
  title = "14 EffortCreep",
  summary = "Apply the lower effort-creep level in the diagnostic model path.",
  bullets = c(
    "Uses 13-LengthBasedSel controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.",
    "Retains the `69-01-50-50` OPR setting and time-varying CPUE CV controls.",
    "The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.",
    "Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE, with index effort creep applied"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "13-LengthBasedSel controls are retained.",
    "No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The effort-creep `.frq` is generated from the full 2024 regional CPUE source by changing only positive effort values for index fisheries 29-33."
  ),
  outstanding = c("After fitting, review index residuals and implied CPUE scaling against 13-LengthBasedSel.")
)

make_step(
  step_id = "15-DataWeighting",
  frq_source = frq_regional_2024,
  ini_source = mix_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(
    time_varying_cv = TRUE,
    opr = TRUE,
    size_based_selectivity = TRUE,
    data_weighting = TRUE
  ),
  title = "15 DataWeighting",
  summary = "Initial selective data-weighting step after the effort-creep model.",
  bullets = c(
    "Uses the same effort-creep `.frq`, mix-period `.ini`, tag, and CAAL as 14-EffortCreep.",
    "Keeps time-varying CPUE CV, OPR, and length-based selectivity controls.",
    "Applies the currently implemented size-composition data-weighting control change."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE, with index effort creep applied"),
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "14-EffortCreep controls are retained.",
    "`-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.",
    "Fishery-specific divisor-40 settings inherited from the 5-region controls are retained."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The implemented data-weighting change is the existing runnable control path: global LF/WF sample-size divisors are changed from 20 to 40."
  ),
  outstanding = c(
    "This is a first runnable weighting scenario; targeted weighting by small-catch strata can be refined after diagnostics.",
    "Review likelihood and composition residuals before treating this as the final tuned weighting scheme."
  )
)
