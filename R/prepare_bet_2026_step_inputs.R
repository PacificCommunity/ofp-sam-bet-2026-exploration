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
five_region_total_population_scalar <- 17L
bias_corrected_length_weight_parameters <- c("3.073533e-05", "2.932410")
bias_corrected_length_weight_note <- paste(
  "bias-corrected BET 2026 L-W parameters",
  paste0("a=", bias_corrected_length_weight_parameters[[1L]], ","),
  paste0("b=", bias_corrected_length_weight_parameters[[2L]])
)

fixm_age_par_value <- "-2.54930339768360e+00"
fixm_age_par_source <- "the 01-Diag2023 mgc=-5 diagnostic final par"
fixm_age_par_note <- paste("FixM M row applied from", fixm_age_par_source)
fixm_age_par_display <- paste("FixM M row from", fixm_age_par_source)

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

bet_2026_root_env <- Sys.getenv("BET_2026_REPO_ROOT", "")
bet_2026_root_candidates <- if (nzchar(bet_2026_root_env)) {
  bet_2026_root_env
} else {
  c(
    file.path(dirname(root), "ofp-sam-2026-BET"),
    file.path(dirname(root), "input-repos", "ofp-sam-2026-BET")
  )
}
bet_2026_root_candidate <- function(path) {
  input_dir <- file.path(path, "mfcl", "inputs", "2023_rep")
  if (file.exists(file.path(input_dir, "bet.ini"))) return(input_dir)
  ""
}
bet_2026_rep_hits <- vapply(bet_2026_root_candidates, bet_2026_root_candidate, character(1))
bet_2026_rep_hits <- bet_2026_rep_hits[nzchar(bet_2026_rep_hits)]
if (!length(bet_2026_rep_hits)) {
  stop(
    "Could not find ofp-sam-2026-BET/mfcl/inputs/2023_rep. Set BET_2026_REPO_ROOT to the repo root.",
    call. = FALSE
  )
}
rep2023_root <- normalizePath(bet_2026_rep_hits[[1L]], winslash = "/", mustWork = TRUE)
bet_2026_repo_root <- normalizePath(file.path(rep2023_root, "..", "..", ".."), winslash = "/", mustWork = TRUE)

input_repo_roots <- c(
  "ofp-sam-2026-BET-YFT-frq-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build"),
  "ofp-sam-2026-BET-YFT-build-ini" = file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini"),
  "ofp-sam-2026-BET-YFT-tag-prep" = file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep"),
  "ofp-sam-2026-BET-YFT-age-length-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build"),
  "ofp-sam-bet-2023-diagnostic" = diagnostic_repo_root,
  "ofp-sam-2026-BET" = bet_2026_repo_root
)

git_value <- function(repo, args) {
  if (!file.exists(file.path(repo, ".git"))) return("")
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
  copy_one(rep2023_file("fishery_map.R"), file.path(paths$model_dir, "fishery_map.R"))
  write_2023_historical_doitall(
    diagnostic_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh")
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "original 2023 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = "original 2023 diagnostic ini, intentionally not promoted or edited"),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "original 2023 diagnostic tag input"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "original 2023 diagnostic CAAL input"),
    list(role = "fishery_map", file = "fishery_map.R", source = rep2023_file("fishery_map.R"), note = "display metadata copied from the 2023 assessment replication inputs; fishery definitions match the diagnostic model"),
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
      "The runner resolves `mfclo64` to the historical 2023 diagnostic MFCL executable for this step.",
      "This step is the direct reproducibility anchor before moving to the current executable."
    ),
    c(
      "bet.frq" = "original 2023 diagnostic frequency/catch/size input",
      "bet.ini" = "original 2023 diagnostic ini, not promoted to MFCL 1007",
      "bet.tag" = "original 2023 diagnostic tag input",
      "bet.age_length" = "original 2023 diagnostic CAAL input",
      "fishery_map.R" = "2023 fishery names copied from the assessment replication input set for viewer labels",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The model files come from `ofp-sam-bet-2023-diagnostic/MFCL`.",
      "`fishery_map.R` is copied from the 2023 assessment replication input set because the diagnostic and replication fisheries match; this only supplies viewer/display labels.",
      "The step-specific executable path is set in `job-config.R`; only this step uses the historical MFCL binary.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict archival comparisons can set `-5` without editing model folders.",
      "No FixM, new-executable compatibility edits, new fishery structure, or 2026 input files are applied here."
    ),
    c(
      "Compare this rerun against the archived 2023 diagnostic output before interpreting later deltas.",
      "Apart from the PHASE 10/11 convergence switch, failures will reflect the original diagnostic control sequence."
    ),
    "Ready for Kflow with the tuna-flow image that includes the historical 2023 diagnostic MFCL executable.",
    input_changes = input_change_table(
      c(".frq", ".ini", ".tag", ".age_length", "fishery_map.R"),
      c("No generated edit.", "No generated edit.", "No generated edit.", "No generated edit.", "Copied from the 2023 assessment replication inputs for display labels."),
      c("Original 2023 diagnostic source file.", "Original 2023 diagnostic format.", "Original 2023 diagnostic source file.", "Original 2023 diagnostic source file.", "Fishery names and grouping only; not an MFCL input.")
    ),
    source_revisions = input_repo_revision_table()
  )
}

rep2023_file <- function(file) {
  file.path(rep2023_root, file)
}

copy_model_core_files <- function(from_dir, to_dir) {
  for (file in c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "mfcl.cfg", "fishery_map.R")) {
    copy_if_exists(file.path(from_dir, file), file.path(to_dir, file))
  }
}

write_02a_newexe_step <- function() {
  paths <- prepare_step_model_dir("02a-NewExe")
  copy_model_core_files(rep2023_root, paths$model_dir)
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    rep2023_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = FALSE,
    mix_from_ini = FALSE
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = rep2023_file("bet.frq"), note = "2023 assessment replication frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = rep2023_file("bet.ini"), note = "MFCL 1003 ini from the 2023 assessment replication input set; not promoted in this substep"),
    list(role = "tag", file = "bet.tag", source = rep2023_file("bet.tag"), note = "2023 replication tag input; tag reporting map regenerated from ini/tag"),
    list(role = "age_length", file = "bet.age_length", source = rep2023_file("bet.age_length"), note = "2023 replication CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = rep2023_file("doitall.sh"), note = "2023 assessment replication controls adapted for the current executable with PROGRAM_PATH wrapper, PHASE 10/11 convergence switch, and 1003 ini tag mixing override retained")
  ))
  write_readme(
    paths$step_dir,
    "02a NewExe",
    "2023 assessment replication inputs run with the current MFCL executable while keeping the MFCL 1003 ini.",
    c(
      "Uses the archived 2023 assessment replication input set as the source model (`ofp-sam-2026-BET/mfcl/inputs/2023_rep`).",
      "Keeps `bet.ini` as version 1003 so this substep isolates the current executable and the original 2023 control script.",
      "Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block.",
      "Adds the usual Kflow safety wrapper: `set -eu`, PROGRAM_PATH guard, and `BET_PHASE10_11_CONVERGENCE` for PHASE 10/11."
    ),
    c(
      "bet.frq" = "2023 assessment replication `.frq`; 9 regions, 41 fisheries, terminal year 2021",
      "bet.ini" = "2023 assessment replication `.ini`; MFCL 1003, no explicit tag flags",
      "bet.tag" = "2023 assessment replication `.tag`",
      "bet.age_length" = "2023 assessment replication `.age_length`",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "This substep is the executable/control-script bridge before changing the ini layout.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      "Compare directly with 01-Diag2023 to isolate historical-executable versus current-executable/control effects.",
      "Do not interpret this as a 1007 ini test; that is isolated in 02b-Ini1007."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = input_change_table(
      c(".ini", ".frq", ".tag", ".age_length"),
      c("No generated input edit; MFCL 1003 layout is retained.", "No generated edit.", "No generated edit.", "No generated edit."),
      c("2023 replication ini values.", "2023 replication source file.", "2023 replication source file.", "2023 replication source file.")
    ),
    source_revisions = input_repo_revision_table()
  )
}

write_diagnostic_substep <- function(step_id, title, summary, source_step,
                                     promote_1007 = FALSE,
                                     total_population_scalar = NA_integer_,
                                     length_weight_parameters = character(),
                                     fixm = FALSE) {
  paths <- prepare_step_model_dir(step_id)
  source_model_dir <- file.path(root, "steps", source_step, "model")
  copy_model_core_files(source_model_dir, paths$model_dir)
  ini_notes <- character()
  if (isTRUE(promote_1007)) {
    ini_notes <- c(ini_notes, ensure_ini_1007_compatibility(
      file.path(paths$model_dir, "bet.ini"),
      file.path(paths$model_dir, "bet.tag"),
      total_population_scalar = 25L,
      retain_reporting_rates_during_mixing = TRUE
    ))
  }
  if (!is.na(total_population_scalar)) {
    ini_notes <- c(ini_notes, set_total_population_scalar(
      file.path(paths$model_dir, "bet.ini"),
      total_population_scalar
    ))
  }
  if (length(length_weight_parameters)) {
    ini_notes <- c(ini_notes, set_length_weight_parameters(
      file.path(paths$model_dir, "bet.ini"),
      length_weight_parameters
    ))
  }
  if (isTRUE(fixm)) {
    apply_fixm_m(file.path(paths$model_dir, "bet.ini"))
    ini_notes <- c(ini_notes, paste("FixM M row applied from", fixm_age_par_source))
  }
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    file.path(source_model_dir, "doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = fixm,
    mix_from_ini = TRUE
  )
  ini_note_text <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  if (!nzchar(ini_note_text)) ini_note_text <- paste0("inherits `", source_step, "` ini unchanged")
  diagnostic_input_changes <- if (isTRUE(promote_1007)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("Promotes MFCL 1003 to 1007 by adding tag flags, tag shed rates, `LN(R0)=25`, and Richards growth default `0`.", "No generated edit."),
      c("Diagnostic data values and tag grouping.", paste0("Inherited from `", source_step, "`."))
    )
  } else if (!is.na(total_population_scalar)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c(paste0("Changes only `LN(R0)` to `", as.integer(total_population_scalar), "`."), "No generated edit."),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else if (length(length_weight_parameters)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c(
        paste0(
          "Changes only `# Length-weight parameters` to `",
          paste(length_weight_parameters, collapse = " "),
          "`."
        ),
        "No generated edit."
      ),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else if (isTRUE(fixm)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("Applies the fixed-M row from the 01 diagnostic `mgc=-5` final par.", "No generated edit."),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("No generated edit.", "No generated edit."),
      c(paste0("Inherited from `", source_step, "`."), paste0("Inherited from `", source_step, "`."))
    )
  }
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = file.path("steps", source_step, "model", "bet.frq"), note = paste0("inherited from ", source_step)),
    list(role = "ini", file = "bet.ini", source = file.path("steps", source_step, "model", "bet.ini"), note = ini_note_text),
    list(role = "tag", file = "bet.tag", source = file.path("steps", source_step, "model", "bet.tag"), note = paste0("inherited from ", source_step, "; tag reporting map regenerated from ini/tag")),
    list(role = "age_length", file = "bet.age_length", source = file.path("steps", source_step, "model", "bet.age_length"), note = paste0("inherited from ", source_step)),
    list(role = "doitall", file = "doitall.sh", source = file.path("steps", source_step, "model", "doitall.sh"), note = "current-executable controls regenerated; 1007 tag flags drive mixing periods; PHASE 10/11 convergence switch retained")
  ))
  change_lines <- c(
    paste0("Inherits the diagnostic-side 2023 assessment replication model from `", source_step, "`."),
    if (isTRUE(promote_1007)) "`bet.ini` is promoted from MFCL 1003 to 1007 while retaining the diagnostic values.",
    if (!is.na(total_population_scalar)) paste0("Sets the total population scaling factor LN(R0) to ", as.integer(total_population_scalar), "."),
    if (length(length_weight_parameters)) paste0("Sets the BET bias-corrected 2026 length-weight parameters to `", paste(length_weight_parameters, collapse = " "), "`."),
    if (isTRUE(fixm)) paste("Applies the FixM M-scale row from", fixm_age_par_source, "with value", fixm_age_par_value),
    if (!isTRUE(promote_1007) && is.na(total_population_scalar) && !length(length_weight_parameters) && !isTRUE(fixm)) "No additional input change is applied."
  )
  write_readme(
    paths$step_dir,
    title,
    summary,
    change_lines[nzchar(change_lines)],
    c(
      "bet.frq" = paste0("`steps/", source_step, "/model/bet.frq`"),
      "bet.ini" = paste0("`steps/", source_step, "/model/bet.ini`; ", ini_note_text),
      "bet.tag" = paste0("`steps/", source_step, "/model/bet.tag`"),
      "bet.age_length" = paste0("`steps/", source_step, "/model/bet.age_length`"),
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed.",
      "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      paste0("Compare directly with ", source_step, " to isolate this substep's change."),
      if (isTRUE(fixm)) "No fishery, tag, CAAL, or CPUE update is intended in this step." else "Later steps inherit this substep unless explicitly documented otherwise."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = diagnostic_input_changes,
    source_revisions = input_repo_revision_table()
  )
}

write_original_diagnostic_step()
write_02a_newexe_step()
write_diagnostic_substep(
  "02b-Ini1007",
  "02b Ini1007",
  "02a current-executable baseline promoted from MFCL 1003 to MFCL 1007 ini layout.",
  source_step = "02a-NewExe",
  promote_1007 = TRUE
)
write_diagnostic_substep(
  "02c-LengthWeight",
  "02c LengthWeight",
  "02b 1007 ini baseline with BET bias-corrected 2026 length-weight parameters.",
  source_step = "02b-Ini1007",
  length_weight_parameters = bias_corrected_length_weight_parameters
)
write_diagnostic_substep(
  "03-FixM",
  "03 FixM",
  "02c length-weight baseline with the FixM M-scale row applied from the 01-Diag2023 mgc=-5 final run.",
  source_step = "02c-LengthWeight",
  fixm = TRUE
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
age_note_04 <- set_age_length_effective_sample_size(file.path(newstructure_model_dir, "bet.age_length"))
copy_one(file.path(template_cache, "mfcl.cfg"), file.path(newstructure_model_dir, "mfcl.cfg"))
copy_one(file.path(template_cache, "fishery_map.R"), file.path(newstructure_model_dir, "fishery_map.R"))
n_normalized_04 <- normalize_frq_absent_lf_records(file.path(newstructure_model_dir, "bet.frq"))
ensure_frq_fishery_region_locations(file.path(newstructure_model_dir, "bet.frq"))
apply_fixm_m(file.path(newstructure_model_dir, "bet.ini"))
total_population_note_04 <- set_total_population_scalar(
  file.path(newstructure_model_dir, "bet.ini"),
  five_region_total_population_scalar
)
length_weight_note_04 <- set_length_weight_parameters(
  file.path(newstructure_model_dir, "bet.ini"),
  bias_corrected_length_weight_parameters
)
frq_counts_04 <- frq_header_counts(
  readLines(file.path(newstructure_model_dir, "bet.frq"), warn = FALSE),
  file.path(newstructure_model_dir, "bet.frq")
)
ini_tag_note_04 <- ensure_ini_tag_flags(
  file.path(newstructure_model_dir, "bet.ini"),
  frq_counts_04$n_tag_groups
)
tag_reporting_group_note_04 <- repair_tag_reporting_grouped_initial_values(
  file.path(newstructure_model_dir, "bet.ini")
)
validate_tag_reporting_grouped_initial_values(file.path(newstructure_model_dir, "bet.ini"))
write_generated_tag_rep_map(newstructure_model_dir)
write_doitall(
  file.path(template_cache, "doitall.sh"),
  file.path(newstructure_model_dir, "doitall.sh"),
  mix_from_ini = TRUE
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
    note = paste(
      c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_group_note_04)[
        nzchar(c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_group_note_04))
      ],
      collapse = "; "
    )
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
    note = paste("old CAAL / age_length reassigned to the new fisheries", age_note_04, sep = "; ")
  ),
  list(
    role = "doitall",
    file = "doitall.sh",
    source = file.path("steps", basename(dirname(template_model_dir)), "model", "doitall.sh"),
    note = "5-region controls retained; tag mixing periods read from MFCL 1007 ini tag flags; made fail-fast for Kflow"
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
    paste("Applies", fixm_age_par_display, "while retaining the 5-region `.ini` structure."),
    paste0("Sets total population scaling factor LN(R0) to ", five_region_total_population_scalar, "."),
    paste0("Uses ", bias_corrected_length_weight_note, ".")
  ),
  c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.frq`; 5-region, 33-fishery structure, terminal year 2021, global CPUE",
    "bet.ini" = paste(
      c(
        "`bet.2023.new.structure.ini`",
        fixm_age_par_note,
        total_population_note_04,
        length_weight_note_04,
        ini_tag_note_04,
        tag_reporting_group_note_04
      )[nzchar(c(
        "`bet.2023.new.structure.ini`",
        fixm_age_par_note,
        total_population_note_04,
        length_weight_note_04,
        ini_tag_note_04,
        tag_reporting_group_note_04
      ))],
      collapse = "; "
    ),
    "bet.tag" = "`bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input",
    "bet.age_length" = paste("`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries", age_note_04, sep = "; "),
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "This step is the 5-region control template for steps 05-15.",
    "Generated `.frq` files include region locations for every fishery, including index fisheries.",
    "MFCL 1007 `# tag flags` supply tag mixing periods directly; the inherited `-9999 1 2` doitall override is removed.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here.",
  input_changes = input_change_table(
    c(".frq", ".ini", ".tag", ".age_length"),
    c(
      "No generated edit beyond source validation.",
      paste(
        "Applies the fixed-M row, normalizes the tag-flags marker, and uses",
        paste0(bias_corrected_length_weight_note, "."),
        "Grouped tag reporting-rate initial values are harmonized for native MFCL without changing group flags, targets, or penalties."
      ),
      "No generated edit.",
      "Changes effective sample size from `1` to `0.75`."
    ),
    c(
      "2023 new-structure global-CPUE source records.",
      "`LN(R0)=17`, bias-corrected L-W, tag grouping, and `tag_flags(it,2)=0`.",
      "2023 new-structure low-recapture-removed source file.",
      "CAAL records themselves."
    )
  ),
  source_revisions = input_repo_revision_table()
)

stepwise_5_region_template_step_id <- "04-NewStructure"
newstructure_ini <- file.path(newstructure_model_dir, "bet.ini")
newstructure_tag <- file.path(newstructure_model_dir, "bet.tag")

latest_2026_tag_note <- paste(
  "`bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR",
  "groups and canneries-based reassignment of recaptures with missing gear to",
  "purse-seine fisheries before low-recap filtering"
)

fishery19_reporting_rate_repair <- list(list(
  target_fishery = 19L,
  source_fishery = 21L
))
fishery19_reporting_rate_note <- paste(
  "Positive tag recapture RR, active, target, and penalty cells are validated",
  "after copying the latest RR groupings; the fishery 19 repair only remains",
  "as a fallback for older sources that still need it."
)

full_2024_alignment_run_notes <- c(
  "Generated inputs only repair `.ini` alignment: reporting-rate matrices, tag flags, and shed rates are matched to the selected release-group count.",
  "The latest `bet.2026.low.recaps.removed.tag` is kept; the tag build assigns missing-gear canneries recaptures to purse-seine before low-recap filtering.",
  "The latest 2026 reporting-rate, active, target, and penalty matrices are copied from the mix-period ini source before Kflow runs.",
  fishery19_reporting_rate_note
)
mix_period_alignment_run_notes <- c(
  "The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment.",
  "Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override.",
  "Generation validates tag-control dimensions, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader.",
  fishery19_reporting_rate_note
)

input_changes_05_06 <- input_change_table(
  c(".frq", ".ini", ".tag", ".age_length"),
  c(
    "Uses the selected length-composition source file; no extra generated edit.",
    "Inherits the generated 04 `.ini` with fixed M and 5-region tag controls.",
    "No generated edit.",
    "Changes effective sample size from `1` to `0.75`."
  ),
  c(
    "Catch, effort, and composition records from the selected source.",
    "All other 04-NewStructure ini controls.",
    "04-NewStructure source tag file.",
    "CAAL records themselves."
  )
)

input_changes_07_08 <- input_change_table(
  c(".frq", ".ini", ".tag", ".age_length"),
  c(
    "No generated edit; full 2024 source is used.",
    "Copies latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, applies fixed M, and validates positive recapture cells.",
    "No generated edit.",
    "Changes effective sample size from `1` to `0.75`."
  ),
  c(
    "Catch, effort, CPUE, and composition records from the selected source.",
    "Two-quarter tag mixing for all release groups.",
    "2026 low-recapture-removed source tag file.",
    "Old CAAL records themselves."
  )
)

input_changes_09 <- input_change_table(
  c(".frq", ".ini", ".tag", ".age_length"),
  c(
    "No generated edit; full 2024 regional-CPUE source is used.",
    "Copies latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, applies fixed M, and validates positive recapture cells.",
    "No generated edit.",
    "Switches to the 2026 CAAL source and changes effective sample size from `1` to `0.75`."
  ),
  c(
    "Catch, effort, CPUE, and composition records from the selected source.",
    "Two-quarter tag mixing for all release groups.",
    "2026 low-recapture-removed source tag file.",
    "2026 CAAL records themselves."
  )
)

input_changes_mix_period <- input_change_table(
  c(".frq", ".ini", ".tag", ".age_length"),
  c(
    "No generated edit; full 2024 regional-CPUE source is used.",
    "Uses release-specific mixing and latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, raises source zero mixing periods to `1`, applies fixed M, and validates positive recapture cells.",
    "No generated edit.",
    "Changes effective sample size from `1` to `0.75`."
  ),
  c(
    "Catch, effort, CPUE, and composition records from the selected source.",
    "Positive release-specific mixing values and RR matrix structure.",
    "2026 low-recapture-removed source tag file.",
    "2026 CAAL records themselves."
  )
)

input_changes_effort_creep <- input_change_table(
  c(".frq", ".ini", ".tag", ".age_length"),
  c(
    "Applies effort creep to positive effort values for index fisheries 29-33.",
    "Uses release-specific mixing and latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, raises source zero mixing periods to `1`, applies fixed M, and validates positive recapture cells.",
    "No generated edit.",
    "Changes effective sample size from `1` to `0.75`."
  ),
  c(
    "Catch and size-composition records.",
    "Positive release-specific mixing values and RR matrix structure.",
    "2026 low-recapture-removed source tag file.",
    "2026 CAAL records themselves."
  )
)

make_step(
  step_id = "05-ConvertToLength",
  frq_source = frq_convert_length_2021,
  ini_source = newstructure_ini,
  tag_source = newstructure_tag,
  age_source = old_age,
  frq_tag_groups = frq_counts_04$n_tag_groups,
  retain_reporting_rates_during_mixing = TRUE,
  title = "05 ConvertToLength",
  summary = "Data to 2021, global CPUE, converting existing weight compositions to length.",
  bullets = c(
    "Uses `bet.2023.new-structure.global-cpue.wt-as-len.frq` from the frq-build repo.",
    "Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the weight-to-length conversion.",
    paste("Applies", fixm_age_par_display, "through the inherited 04-NewStructure ini.")
  ),
  input_notes = c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.wt-as-len.frq`; terminal year 2021, global CPUE",
    "bet.ini" = paste("`steps/04-NewStructure/model/bet.ini`,", fixm_age_par_note),
    "bet.tag" = "`steps/04-NewStructure/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained."
  ),
  input_changes = input_changes_05_06,
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
  retain_reporting_rates_during_mixing = TRUE,
  title = "06 LengthPlusLength",
  summary = "Data to 2021, global CPUE, adding length compositions that were not used in the past.",
  bullets = c(
    "Uses `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq` from the frq-build repo.",
    "Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the additional length-composition data.",
    paste("Applies", fixm_age_par_display, "through the inherited 04-NewStructure ini.")
  ),
  input_notes = c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq`; terminal year 2021, global CPUE",
    "bet.ini" = paste("`steps/04-NewStructure/model/bet.ini`,", fixm_age_par_note),
    "bet.tag" = "`steps/04-NewStructure/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained."
  ),
  input_changes = input_changes_05_06,
  run_notes = c("Compare directly with 05-ConvertToLength to isolate the extra length-composition records."),
  outstanding = c("Review fit impacts before deciding whether length-composition weighting needs adjustment.")
)

make_step(
  step_id = "07-DataTo2024",
  frq_source = frq_global_2024,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = old_age,
  mix_from_ini = TRUE,
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_source = mix_ini,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
  title = "07 DataTo2024",
  summary = "Data to 2024, global CPUE, isolating the effect of adding three years of data.",
  bullets = c(
    "Uses `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq` without year chopping.",
    "Moves from the 2021 transition steps to the full 2024 frequency/catch/size series.",
    "Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths.",
    paste0("Uses the 2026 low-recapture-removed tag file and latest 2026 tag-reporting matrices, with ", fixm_age_par_display, ".")
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq`, full 2024 with global CPUE",
    "bet.ini" = paste("`bet.2026.ini` with RR/active/target/penalty matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained.",
    "The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period.",
    "The latest 2026 RR, active, target, and penalty matrices are copied from `bet.2026.mix-0.2.ini` before final alignment checks."
  ),
  input_changes = input_changes_07_08,
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
  mix_from_ini = TRUE,
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_source = mix_ini,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
  title = "08 RegionalCPUE",
  summary = "Regional CPUE step using the 2024 regional CPUE frequency file and regional-scaling prior.",
  bullets = c(
    "Uses the full 2024 regional CPUE `.frq` from the frq-build repo.",
    "Adds `bet.reg_scaling` and switches to the regional-scaling prior in PHASE 5.",
    "Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths.",
    paste0("Uses the 2026 low-recapture-removed tag file and latest 2026 tag-reporting matrices, with ", fixm_age_par_display, ".")
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = paste("`bet.2026.ini` with RR/active/target/penalty matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "04-NewStructure 5-region `doitall.sh` controls retained until PHASE 5.",
    "PHASE 5 switches index CPUE/selectivity grouping for the regional-scaling prior.",
    "The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period.",
    "The latest 2026 RR, active, target, and penalty matrices are copied from `bet.2026.mix-0.2.ini` before final alignment checks."
  ),
  input_changes = input_changes_07_08,
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
  mix_from_ini = TRUE,
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_source = mix_ini,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
  title = "09 NewOtoliths",
  summary = "New Japanese otoliths and 2026 CAAL input on the regional CPUE model.",
  bullets = c(
    "Uses the same regional CPUE `.frq`, latest 2026 tag-reporting matrices, and 2026 `.tag` as 08-RegionalCPUE.",
    "Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.",
    "The 2026 age_length file includes the new otolith data used for this step.",
    paste("Applies", fixm_age_par_display, "to the 2026 ini.")
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = paste("`bet.2026.ini` with RR/active/target/penalty matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL/new otoliths)"
  ),
  control_notes = c(
    "08-RegionalCPUE controls retained.",
    "The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period.",
    "The latest 2026 RR, active, target, and penalty matrices are copied from `bet.2026.mix-0.2.ini` before final alignment checks."
  ),
  input_changes = input_changes_09,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
  title = "10 TagMixingKS",
  summary = "KS coefficient 0.2 release-group-specific tag mixing periods.",
  bullets = c(
    "Uses `bet.2026.mix-0.2.ini` from the ini-build repo.",
    "Keeps the full 2024 regional CPUE `.frq`, 2026 tag file, and updated 2026 CAAL.",
    paste("Applies", fixm_age_par_display, "to the mix-period ini."),
    "Removes the inherited `-9999 1 2` line from `doitall.sh` so release-group-specific mixing-period values in the ini are not overwritten."
  ),
  input_notes = c(
    "bet.frq" = paste0("`", basename(frq_regional_2024), "`, full 2024 with regional CPUE"),
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override is removed.",
    "All other 08-RegionalCPUE fishery, tag recapture, selectivity, and regional-scaling controls are retained."
  ),
  input_changes = input_changes_mix_period,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
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
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override remains removed.",
    "Index fisheries 29-33 have fish flag 66 set to 1 for time-varying CPUE CV."
  ),
  input_changes = input_changes_mix_period,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
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
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
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
  input_changes = input_changes_mix_period,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
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
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
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
  input_changes = input_changes_mix_period,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
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
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
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
  input_changes = input_changes_effort_creep,
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
  retain_reporting_rates_during_mixing = TRUE,
  tag_reporting_cell_repairs = fishery19_reporting_rate_repair,
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
    "bet.ini" = paste("`bet.2026.mix-0.2.ini`,", fixm_age_par_note),
    "bet.tag" = latest_2026_tag_note,
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
  input_changes = input_changes_effort_creep,
  outstanding = c(
    "This is a first runnable weighting scenario; targeted weighting by small-catch strata can be refined after diagnostics.",
    "Review likelihood and composition residuals before treating this as the final tuned weighting scheme."
  )
)
