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

input_repo_roots <- c(
  "ofp-sam-2026-BET-YFT-frq-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build"),
  "ofp-sam-2026-BET-YFT-build-ini" = file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini"),
  "ofp-sam-2026-BET-YFT-tag-prep" = file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep"),
  "ofp-sam-2026-BET-YFT-age-length-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build")
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

for (base_step in c("01-Diag23", "02-FixM", "03-RegFish")) {
  base_doitall <- file.path(root, "steps", base_step, "model", "doitall.sh")
  remove_model_par_files(file.path(root, "steps", base_step, "model"))
  write_doitall(base_doitall, base_doitall)
}

base_ini_1007_notes <- lapply(c("01-Diag23", "02-FixM"), function(base_step) {
  ensure_ini_1007_compatibility(
    file.path(root, "steps", base_step, "model", "bet.ini"),
    file.path(root, "steps", base_step, "model", "bet.tag")
  )
})
names(base_ini_1007_notes) <- c("01-Diag23", "02-FixM")

write_readme(
  file.path(root, "steps", "01-Diag23"),
  "01 Diag23",
  "2023 diagnostic BET model structure, retained as the starting point for the 2026 stepwise transition.",
  c(
    "Uses the inherited 9-region, 41-fishery inputs ending in 2021.",
    "Natural mortality setup is the pre-FixM diagnostic baseline.",
    "`bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the diagnostic values.",
    "Run mode is `doitall` so the model can be built from `bet.ini` with the bundled control script."
  ),
  c(
    "bet.frq" = "2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021",
    "bet.ini" = "2023 diagnostic ini before the FixM M-scale row change; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0",
    "bet.tag" = "2023 diagnostic tag input",
    "bet.age_length" = "2023 diagnostic CAAL input"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "The step output includes `bet-2023-nine-region.geojson` as a display-only MFCL Shiny map asset; it does not change MFCL inputs.",
    "`bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.",
    "Survey index fishery sigma settings are the BET 2023 region-specific values.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "This is a baseline reference step; no 2026 input updates are intended here.",
    "Run diagnostics should confirm the archived 2023 behavior before interpreting later deltas."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

write_readme(
  file.path(root, "steps", "02-FixM"),
  "02 FixM",
  "2023 diagnostic structure with the FixM M-scale row applied.",
  c(
    "Same 9-region, 41-fishery input structure as 01-Diag23.",
    "The M-related age parameter row is set to `-2.54917483258212e+00 -1 ...`.",
    "`bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the FixM diagnostic values.",
    "This is the M source used when preparing later 5-region inputs."
  ),
  c(
    "bet.frq" = "same structural input as 01-Diag23, terminal year 2021",
    "bet.ini" = "FixM version of the diagnostic ini; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0",
    "bet.tag" = "same tag structure as 01-Diag23",
    "bet.age_length" = "same CAAL structure as 01-Diag23"
  ),
  c(
    "Inherited 9-region `doitall.sh` retained.",
    "This step is used as the reference for the M row copied into 03+.",
    "The step output includes `bet-2023-nine-region.geojson` as a display-only MFCL Shiny map asset; it does not change MFCL inputs.",
    "`bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "Confirm the FixM M row reproduces the intended fixed-M diagnostic before comparing against 03+.",
    "No fishery, tag, CAAL, or CPUE update is intended in this step."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here."
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
regfish_frq_source <- file.path(frq_root, "bet.2023.new.structure.frq")
regfish_ini_source <- file.path(ini_root, "bet.2023.new.structure.ini")
regfish_tag_source <- file.path(tag_root, "bet.2023.new.structure-low.recaps.removed.tag")
regfish_dir <- file.path(root, "steps", "03-RegFish")
regfish_model_dir <- file.path(regfish_dir, "model")
remove_model_par_files(regfish_model_dir)
copy_one(regfish_frq_source, file.path(regfish_model_dir, "bet.frq"))
copy_one(regfish_ini_source, file.path(regfish_model_dir, "bet.ini"))
copy_one(regfish_tag_source, file.path(regfish_model_dir, "bet.tag"))
copy_one(old_age, file.path(regfish_model_dir, "bet.age_length"))
n_normalized_03 <- normalize_frq_absent_lf_records(file.path(regfish_model_dir, "bet.frq"))
ensure_frq_fishery_region_locations(file.path(regfish_model_dir, "bet.frq"))
apply_fixm_m(file.path(regfish_model_dir, "bet.ini"))
frq_counts_03 <- frq_header_counts(
  readLines(file.path(regfish_model_dir, "bet.frq"), warn = FALSE),
  file.path(regfish_model_dir, "bet.frq")
)
ini_tag_note_03 <- ensure_ini_tag_flags(
  file.path(regfish_model_dir, "bet.ini"),
  frq_counts_03$n_tag_groups
)
write_generated_tag_rep_map(regfish_model_dir)
write_manifest(regfish_dir, list(
  list(
    role = "frq",
    file = "bet.frq",
    source = regfish_frq_source,
    note = paste0(
      "5-region 2021-terminal new-structure frq; old CPUE/global index approach retained",
      if (n_normalized_03) paste0("; normalized ", n_normalized_03, " records with stray absent-LF bins") else ""
    )
  ),
  list(
    role = "ini",
    file = "bet.ini",
    source = regfish_ini_source,
    note = paste(c("FixM M row applied", ini_tag_note_03)[nzchar(c("FixM M row applied", ini_tag_note_03))], collapse = "; ")
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
  )
))

write_readme(
  file.path(root, "steps", "03-RegFish"),
  "03 RegFish",
  "First 5-region / 33-fishery BET input step, ending in 2021.",
  c(
    "Uses the latest `bet.2023.new.structure.*` source inputs from the 2026 input build repos.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Uses `bet.2023.new.structure.frq` exactly as the 2021-terminal new-region/new-fishery frequency source, including the old CPUE/global index approach.",
    "Uses the old CAAL data re-assigned to the new fisheries.",
    paste0(
      "Uses the old/restructured tag setup with ", frq_counts_03$n_tag_groups,
      " release groups and ", frq_counts_03$n_tag_groups + 1L,
      " tag-event rows including pooled tags."
    ),
    "Regenerates `tag_rep_map.R` from the five MFCL reporting-rate matrices in `bet.ini` plus release metadata in `bet.tag`.",
    paste0("Normalizes ", n_normalized_03, " old records that had an absent-LF sentinel followed by stray LF bins."),
    "Applies the 2026 CPUE index sigma settings for index fisheries 29-33.",
    "Applies FixM M row while retaining the 5-region `.ini` structure.",
    "Inserts default MFCL 1007 tag flags for the pre-mix step: 2 mixing periods and reporting rates excluded during mixing."
  ),
  c(
    "bet.frq" = "`bet.2023.new.structure.frq`; 5-region, 33-fishery structure, terminal year 2021, old CPUE/global index approach retained",
    "bet.ini" = "`bet.2023.new.structure.ini`; FixM M row applied and explicit default tag flags inserted if needed",
    "bet.tag" = paste0(
      "`bet.2023.new.structure-low.recaps.removed.tag`; ",
      frq_counts_03$n_tag_groups,
      " release-group tag input with low recap groups removed"
    ),
    "bet.age_length" = "`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries",
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "5-region fishery/tag/selectivity controls are remapped in `doitall.sh`.",
    "Index fisheries 29-33 use sigmas 0.28, 0.20, 0.22, 0.21, and 0.24.",
    "The `-9999 1 2` all-release mixing-period setting is retained for this pre-mix step.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.",
    paste0("The ", n_normalized_03, " normalized absent-LF records should be reviewed against the upstream frq-build script so the source generator can eventually emit MFCL-ready records."),
    "The upstream non-mix `.ini` files are labelled 1007 but can have non-standard or short tag-flag blocks; generated inputs now normalize and pad explicit tag flags for MFCL >=2.2.7.5.",
    "Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here.",
  source_revisions = input_repo_revision_table()
)

regfish_ini <- file.path(root, "steps", "03-RegFish", "model", "bet.ini")
regfish_tag <- file.path(root, "steps", "03-RegFish", "model", "bet.tag")
full_plus_frq <- file.path(frq_root, "bet.2026.wt.as.len.plus.len.frq")
wt_as_len_frq <- file.path(frq_root, "bet.2026.wt.as.len.frq")
full_2024_alignment_run_notes <- c(
  "The first full-2024 Kflow attempt failed during MFCL `-makepar`, before any fit output was available. The logged fatal sequence was `initial_tag_year(2) 157`, `Error reading region_flags`, and `Bounds error reading pmature(34) in par file value is 0`; downstream payload creation then failed because no MFCL output folder existed.",
  "The failure was traced to using the 2026 `.frq/.tag` release-group count with a source `bet.2026.ini` whose tag controls were shorter: the selected `.frq` and `.tag` had 98 release groups, while the ini tag flags and tag shed-rate vector only covered 91 groups and the tag reporting-rate matrices were missing the 7 new release rows.",
  "Generated inputs now repair only the `.ini` alignment: missing tag reporting-rate rows 92-98 are filled by matching tag program, region, year, and month from `bet.2023.new.structure.ini`; explicit MFCL 1007 tag flags are padded to 98 rows; and `# tag shed rate` is padded from 91 to 98 zero shed rates.",
  "The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows were deleted to suppress warnings.",
  "After the alignment repair, `mfclo64 bet.frq bet.ini 00.par -makepar` exits 0 and creates `00.par` for 06-Full2024 and 07-CAAL2026 in the `tuna-flow:v1.10` image."
)
mix_period_alignment_run_notes <- c(
  "These steps were audited after the 06/07 full-2024 failure because they use the same 98-release 2026 `.frq` and `.tag` family.",
  "The mix-period ini family already carries release-group-specific tag controls, so the generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive the mixing-period settings.",
  "Generation still validates the same release-group alignment checks as 06/07: tag flags, tag shed rate, and the five tag reporting-rate matrices must match the 98 selected release groups plus the pooled reporting row where appropriate.",
  "Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0; this is an ini-control normalization, not a deletion of tag data.",
  "Local `mfclo64 bet.frq bet.ini 00.par -makepar` smoke tests now exit 0 and create `00.par` for 08-MixPeriod02 through 12-DataWeight40 in the `tuna-flow:v1.10` image."
)

make_step(
  step_id = "04-WtAsLen21",
  frq_source = wt_as_len_frq,
  ini_source = regfish_ini,
  tag_source = regfish_tag,
  age_source = old_age,
  frq_chop_year = 2021L,
  frq_tag_groups = frq_counts_03$n_tag_groups,
  index_cpue_source = regfish_frq_source,
  title = "04 WtAsLen21",
  summary = "Transition step using 2026 weights-as-lengths size/catch data chopped to 2021, while retaining the 2023 new-structure CPUE/index records.",
  bullets = c(
    "Builds a hybrid `bet.frq`: non-index records come from `bet.2026.wt.as.len.frq` chopped to year <= 2021, while index fisheries 29-33 are replaced with CPUE records from `bet.2023.new.structure.frq`.",
    "This isolates the weights-to-lengths transition without also switching the CPUE/index data to the 2026 regional index series.",
    paste0("Keeps the 03-RegFish ", frq_counts_03$n_tag_groups, "-release tag/ini structure because this step remains a 2021-terminal comparison."),
    paste0("Resets the chopped `.frq` tag-group header from the 2026 source count to ", frq_counts_03$n_tag_groups, " to match the selected tag file."),
    "Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.",
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = paste0(
      "hybrid of `bet.2026.wt.as.len.frq` chopped to 2021 for non-index size/catch records, plus index fisheries 29-33 copied from `bet.2023.new.structure.frq`; tag-group header reset to ",
      frq_counts_03$n_tag_groups
    ),
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    paste0(
      "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish ",
      frq_counts_03$n_tag_groups,
      "-release tag set."
    )
  ),
  run_notes = c(
    "The first implementation chopped the 2026 `.frq` directly, which also carried the 2026 CPUE/index records. The corrected transition keeps the 2023 new-structure CPUE/index records for fisheries 29-33.",
    "Kflow failed when this 2021-chopped `.frq` was paired with the full 2026 tag/ini family; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    paste0(
      "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's ",
      frq_counts_03$n_tag_groups,
      "-release setup, and the chopped `.frq` tag-group header is reset to ",
      frq_counts_03$n_tag_groups,
      "."
    ),
    "No tag release or recapture rows were deleted to silence warnings; this step only changes which already-prepared input family is paired with the chopped 2026 size/catch records.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "After fitting, compare directly with 03-RegFish to isolate the effect of converting weights to lengths while CPUE/index data are held constant.",
    "Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage."
  )
)

make_step(
  step_id = "05-WtAsLenPlusLen21",
  frq_source = full_plus_frq,
  ini_source = regfish_ini,
  tag_source = regfish_tag,
  age_source = old_age,
  frq_chop_year = 2021L,
  frq_tag_groups = frq_counts_03$n_tag_groups,
  index_cpue_source = regfish_frq_source,
  title = "05 WtAsLenPlusLen21",
  summary = "Transition step using 2026 weights-as-lengths plus observed lengths chopped to 2021, while retaining the 2023 new-structure CPUE/index records.",
  bullets = c(
    "Builds a hybrid `bet.frq`: non-index records come from `bet.2026.wt.as.len.plus.len.frq` chopped to year <= 2021, while index fisheries 29-33 are replaced with CPUE records from `bet.2023.new.structure.frq`.",
    "This isolates the plus-length size-composition transition without also switching the CPUE/index data to the 2026 regional index series.",
    "Maintains the old CAAL input while moving the size-composition frequency file to the plus-length variant.",
    paste0("Keeps the 03-RegFish ", frq_counts_03$n_tag_groups, "-release tag/ini structure because this step remains a 2021-terminal comparison."),
    paste0("Resets the chopped `.frq` tag-group header from the 2026 source count to ", frq_counts_03$n_tag_groups, " to match the selected tag file."),
    "Applies the FixM M row to the 03-RegFish-compatible ini."
  ),
  input_notes = c(
    "bet.frq" = paste0(
      "hybrid of `bet.2026.wt.as.len.plus.len.frq` chopped to 2021 for non-index size/catch records, plus index fisheries 29-33 copied from `bet.2023.new.structure.frq`; tag-group header reset to ",
      frq_counts_03$n_tag_groups
    ),
    "bet.ini" = "`steps/03-RegFish/model/bet.ini`, FixM M row applied",
    "bet.tag" = "`steps/03-RegFish/model/bet.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    paste0(
      "The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish ",
      frq_counts_03$n_tag_groups,
      "-release tag set."
    )
  ),
  run_notes = c(
    "The first implementation chopped the 2026 `.frq` directly, which also carried the 2026 CPUE/index records. The corrected transition keeps the 2023 new-structure CPUE/index records for fisheries 29-33.",
    "Kflow failed when this 2021-chopped `.frq` was paired with the full 2026 tag/ini family; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.",
    paste0(
      "To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's ",
      frq_counts_03$n_tag_groups,
      "-release setup, and the chopped `.frq` tag-group header is reset to ",
      frq_counts_03$n_tag_groups,
      "."
    ),
    "No tag release or recapture rows were deleted to silence warnings; this step only changes which already-prepared input family is paired with the chopped 2026 size/catch records.",
    "Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03."
  ),
  outstanding = c(
    "After fitting, compare directly with 04-WtAsLen21 to isolate the effect of adding observed lengths while CPUE/index data are held constant."
  )
)

make_step(
  step_id = "06-Full2024",
  frq_source = full_plus_frq,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = old_age,
  reg_scaling_source = reg_scaling_source,
  title = "06 Full2024",
  summary = "Full 2024 data step with weights-as-lengths plus lengths, new regional CPUE/index inputs, and 2026 tag reporting priors.",
  bullets = c(
    "Uses `bet.2026.wt.as.len.plus.len.frq` without year chopping.",
    "Moves from the 2021-chopped transition steps to the full 2024 frequency/catch/size series.",
    "Keeps old CAAL for this step, matching the plan's 'no change to CAAL file' instruction.",
    "Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2023.new-structure.age_length` (old CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group mixing period remains fixed at 2 for this pre-mix step."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c(
    "Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.",
    "This step intentionally keeps old CAAL so the CAAL update is isolated in 07-CAAL2026."
  )
)

make_step(
  step_id = "07-CAAL2026",
  frq_source = full_plus_frq,
  ini_source = new_ini,
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  title = "07 CAAL2026",
  summary = "Full 2024 data step with the updated 2026 CAAL / age_length input.",
  bullets = c(
    "Uses the same full 2024 `.frq`, 2026 `.ini`, and 2026 `.tag` as 06-Full2024.",
    "Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.",
    "The 2026 age_length file has 181 records through 2024 and includes Japan/SPC new age data.",
    "Applies the FixM M row to the 2026 ini."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "03-RegFish 5-region `doitall.sh` controls retained.",
    "The all-release-group mixing period remains fixed at 2 for this pre-mix step."
  ),
  run_notes = full_2024_alignment_run_notes,
  outstanding = c(
    "After fitting, compare CAAL likelihood and age residuals against 06-Full2024.",
    "Confirm the 2026 CAAL source remains the chosen final CAAL file before later sensitivity runs."
  )
)

make_step(
  step_id = "08-MixPeriod02",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  title = "08 MixPeriod02",
  summary = "Release-group-specific tag mixing periods using the 0.2 KS diagnostic cutoff.",
  bullets = c(
    "Uses `bet.2026.mix-0.2.ini` from the ini-build repo.",
    "Keeps the full 2024 `.frq`, 2026 tag file, and updated 2026 CAAL.",
    "Applies the FixM M row to the mix-period ini.",
    "Removes the inherited `-9999 1 2` line from `doitall.sh` so the release-group-specific tag flags in the ini are not overwritten."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override is removed.",
    "All other 03-RegFish 5-region fishery, tag recapture, selectivity, and CPUE sigma controls are retained."
  ),
  run_notes = mix_period_alignment_run_notes,
  outstanding = c(
    "Confirm that the 0.2 KS mix-period ini is the main 12-step path; the 0.15 version remains a sensitivity candidate.",
    "After fitting, inspect tag residuals and release-group behavior before tuning tag-reporting assumptions further."
  )
)

make_step(
  step_id = "09-SizeBasedSel",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE),
  title = "09 SizeBasedSel",
  summary = "Size-based selectivity step after the main 0.2 KS tag mixing-period setup.",
  bullets = c(
    "Uses the same full 2024 `.frq`, `bet.2026.mix-0.2.ini`, 2026 tag file, and updated 2026 CAAL as 08-MixPeriod02.",
    "Sets fish flag 26 from 2 to 3 in `doitall.sh`, following the YFT 2026 length-based selectivity note.",
    "Keeps the extraction-fishery selectivity mapping and fishery-specific constraints from 03-RegFish, while index fisheries unshare from PHASE 5 under regional scaling."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "The all-release-group mixing-period override remains removed.",
    "`-999 26 3` is applied for size-based selectivity."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The extra step-specific change after the mix-period audit is limited to fish flag 26: `doitall.sh` sets `-999 26 3` for the size-based selectivity experiment."
  ),
  outstanding = c(
    "Confirm with the modelling group that BET should use the same flag-26 setting as the YFT 2026 size-based selectivity experiment.",
    "Not yet reviewed after fitting: upper-age selectivity constraints inherited from 03-RegFish, especially `24.PL.ALL.WEST.3`."
  )
)

make_step(
  step_id = "10-OPR",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE),
  title = "10 OPR",
  summary = "Orthogonal polynomial recruitment step using the best-ranked BET OPR screening setting.",
  bullets = c(
    "Uses the same input files as 09-SizeBasedSel.",
    "Applies the BIGEYE AIC rank-1 OPR screening model: `69-01-50-50`.",
    "The OPR comparison was run on the BET 4R model, but this step carries the best-ranked setting into the current 5-region stepwise path.",
    "OPR controls are applied in PHASE 3 of `doitall.sh`, so early phases still use the pre-OPR recruitment setup before the transfer."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "`-999 26 3` is retained from 09-SizeBasedSel.",
    "PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.",
    "`1 149 0`, `1 398 0`, `1 400 0`, `2 177 0`, `2 32 0`, and `2 113 0` are applied at PHASE 3 for the OPR transfer, matching the OPR screening `doitall` example except for obsolete `parest_flag(221)`.",
    "`1 155 69` sets the OPR year effect from the `69-01-50-50` setting. `parest_flag(221)` is not set because current MFCL treats it as an obsolete/commented-out legacy year-effect override; the active source reads the year degree from `parest_flag(155)`.",
    "`1 217 1`, `1 216 50`, and `1 218 50` set season, region, and region-season interaction effects.",
    "`1 202 2` sets the OPR end window to the last 2 real years, where the orthogonal-polynomial basis is held at the lower-degree/constant-end form. `1 210 0`, `1 212 0`, and `1 214 0` do not turn that off; in current MFCL, zero means the region, season, and region-season effects inherit `parest_flag(202)`. Use `-1` to turn an end window off.",
    "`2 30 1` is deliberately retained at the OPR phase because current MFCL requires `age_flag(30)=1` to activate the OPR polynomial coefficients.",
    "`2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.",
    "PHASE 3 uses 500 function evaluations, matching the OPR screening `doitall` example."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The step-specific OPR change follows the BET OPR screening: the BET 4R rank-1 AIC setting `69-01-50-50` is carried into this 5-region path. The README records that this is an applied transfer from the 4R screening, not a separate 5-region OPR search.",
    "The OPR transfer keeps `2 30 1` because current MFCL does not activate the OPR recruitment-polynomial coefficients without it; the step turns off `2 70`, `2 71`, `2 178`, and the `-100000 1:5` regional recruitment-distribution flags."
  ),
  outstanding = c(
    "After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result.",
    "If diagnostics disagree with the 4R screening, revisit the other BET-ranked OPR options."
  )
)

make_step(
  step_id = "11-EffortCreep",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE),
  title = "11 EffortCreep",
  summary = "Minimum effort-creep scenario applied to the regional index fisheries.",
  bullets = c(
    "Uses 10-OPR controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.",
    "Retains the `69-01-50-50` OPR setting selected from the BET 4R OPR screening.",
    "The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.",
    "Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "10-OPR `doitall.sh` controls are retained, including the explicit `2 30 1` OPR activation safeguard.",
    "No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The effort-creep `.frq` is generated from the full 2024 plus-length source by changing only positive effort values for index fisheries 29-33; extraction fisheries and size-composition records are left as in the source file.",
    "The implemented multiplier is 1.00 in 1952, 1.24 in 1976, and 1.48 in 2024; this applies the agreed piecewise effort-creep scenario rather than extending the 1%/yr rate through the full time series."
  ),
  outstanding = c(
    "After fitting, review the index residuals and implied CPUE scaling against 10-OPR to confirm this agreed effort-creep scenario behaves as expected."
  )
)

make_step(
  step_id = "12-DataWeight40",
  frq_source = full_plus_frq,
  ini_source = file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"),
  tag_source = new_tag,
  age_source = new_age,
  reg_scaling_source = reg_scaling_source,
  frq_transform = "effort_creep",
  mix_from_ini = TRUE,
  doitall_edits = list(size_based_selectivity = TRUE, opr = TRUE, data_weighting = TRUE),
  title = "12 DataWeight40",
  summary = "Initial manual strategic data-weighting step with stronger global size-composition downweighting.",
  bullets = c(
    "Uses the same effort-creep `.frq`, mix-period `.ini`, tag, and CAAL as 11-EffortCreep.",
    "Keeps size-based selectivity and the `69-01-50-50` OPR controls from 10-OPR.",
    "Changes global LF and WF sample-size divisors from 20 to 40 in `doitall.sh`."
  ),
  input_notes = c(
    "bet.frq" = "`bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied",
    "bet.ini" = "`bet.2026.mix-0.2.ini`, FixM M row applied",
    "bet.tag" = "`bet.2026.low.recaps.removed.tag`",
    "bet.age_length" = "`bet.2026.age_length` (updated CAAL)"
  ),
  control_notes = c(
    "10-OPR `doitall.sh` controls are retained, including the explicit `2 30 1` OPR activation safeguard.",
    "`-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.",
    "Fishery-specific divisor-40 settings inherited from 03-RegFish are retained."
  ),
  run_notes = c(
    mix_period_alignment_run_notes,
    "The step-specific data-weighting change is limited to the global LF/WF sample-size divisors: `-999 49 40` and `-999 50 40` replace the divisor-20 settings. This was documented as an initial runnable weighting scenario, not a final tuned weighting scheme."
  ),
  outstanding = c(
    "This is a first runnable manual weighting scenario, not a final tuned weighting scheme.",
    "Not yet implemented: alternative divisor scenarios or targeted CAAL/size weighting after diagnostics."
  )
)
