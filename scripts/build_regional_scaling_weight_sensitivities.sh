#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="81a456fa5c36ef1be5bd9da38308ef07ebc55ff4"
SOURCE_REF="experiment/normal-francis-initial-20260719"
SOURCE_REPO="PacificCommunity/ofp-sam-bet-2026-exploration"
DM_SOURCE_COMMIT="20c19b02498a6ee22cc39441a073159accca020b"
DM_SOURCE_REF="experiment/cpue-hac4-single-area-tail-nmax10-20260719"
AGE_SHA256="426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c"
INI_SOURCE_REPO="PacificCommunity/ofp-sam-2026-BET-YFT-build-ini"
INI_SOURCE_COMMIT="86627214cbac6db5766841e404bb32ea4f6afe61"
INI_SOURCE_PATH="BET/ini.mix-period/bet.2026.mix-0.15.ini"
INI_SOURCE_SHA256="b8a43730e7808c0f2d0f07924a2e175910294ce63a1359c2585b44f9e5e2dad6"
INI_SOURCE_FILE="$ROOT/reference-inputs/bet.2026.mix-0.15.ini"

normal_templates=(
  "S017-TC1-NOCUT-SUB075-TAGF2OFF"
  "S018-TC1-NOCUT-SUB075-TAGF2ON"
)
weights=(50 11 1 0)
dm_template="S035-DM-G5PROC-CEST-NOCUT-TAGF2ON"

if ! git -C "$ROOT" cat-file -e "${SOURCE_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$ROOT" fetch --depth=1 origin "$SOURCE_COMMIT"
fi
if ! git -C "$ROOT" cat-file -e "${DM_SOURCE_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$ROOT" fetch --depth=1 origin "$DM_SOURCE_COMMIT"
fi

tmp="$(mktemp -d)"
cleanup() {
  find "$tmp" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT

for template in "${normal_templates[@]}"; do
  git -C "$ROOT" archive "$SOURCE_COMMIT" "sensitivity/$template" | tar -x -C "$tmp"
done
git -C "$ROOT" archive "$DM_SOURCE_COMMIT" \
  "sensitivity/$dm_template/model/doitall.sh" | tar -x -C "$tmp"

mkdir -p "$ROOT/sensitivity"
find "$ROOT/sensitivity" -depth -mindepth 1 -delete
mapping="$tmp/model-map.csv"
printf '%s\n' 'model,source_model,dm_source_model,regional_scaling_weight,standardized_sd_interpretation,tag_flag2,tag_control,lf_likelihood,dm_grouping,dm_nmax,lf_downweight_factor,lf_size_divisor' > "$mapping"

regw_text() {
  case "$1" in
    50) printf '%s' 'standardized SD multiplier 0.1414 (effective covariance Sigma/50)' ;;
    11) printf '%s' 'standardized SD multiplier 0.3015 (effective covariance Sigma/11)' ;;
    1) printf '%s' 'standardized SD multiplier 1.0000 (empirical covariance Sigma)' ;;
    0) printf '%s' 'regional-scaling penalty disabled' ;;
    *) return 1 ;;
  esac
}

write_model_ini() {
  local output="$1"
  local tag_flag2="$2"
  Rscript - "$INI_SOURCE_FILE" "$output" "$tag_flag2" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
source_path <- args[[1L]]
output_path <- args[[2L]]
tag_flag2 <- as.integer(args[[3L]])
stopifnot(tag_flag2 %in% 0:1)

lines <- readLines(source_path, warn = FALSE)
tag_start <- grep("^# tag flags[[:space:]]*$", lines)
stopifnot(length(tag_start) == 1L, tag_start + 98L <= length(lines))
tag_rows <- tag_start + seq_len(98L)
fields <- strsplit(trimws(lines[tag_rows]), "[[:space:]]+")
stopifnot(
  all(lengths(fields) == 10L),
  all(vapply(fields, function(x) !is.na(suppressWarnings(as.integer(x[[1L]]))), logical(1))),
  all(vapply(fields, function(x) x[[2L]] == "1", logical(1)))
)
fields <- lapply(fields, function(x) {
  x[[2L]] <- as.character(tag_flag2)
  x
})
lines[tag_rows] <- vapply(fields, paste, collapse = " ", character(1))
writeLines(lines, output_path, useBytes = TRUE)
RS
}

remove_f9_monotonicity() {
  local path="$1"
  awk '
    /^# Single-area extraction monotonicity constraint[.]$/ {
      print "# Extraction selectivity is not constrained to be non-decreasing."
      next
    }
    $1 == -9 && $2 == 16 && $3 == 1 { next }
    { print }
  ' "$path" > "$path.new"
  mv "$path.new" "$path"
  chmod 0755 "$path"
}

number=0
for template_index in "${!normal_templates[@]}"; do
  template="${normal_templates[$template_index]}"
  tag_flag2="$template_index"
  tag_code="TAGF2OFF"
  [[ "$tag_flag2" -eq 1 ]] && tag_code="TAGF2ON"

  for weight in "${weights[@]}"; do
    number=$((number + 1))
    id="$(printf 'S%03d' "$number")"
    model="${id}-TC1-NOCUT-DW10-SUB075-MIX015-${tag_code}-REGW${weight}"
    destination="$ROOT/sensitivity/$model"
    cp -a "$tmp/sensitivity/$template" "$destination"
    write_model_ini "$destination/model/bet.ini" "$tag_flag2"
    remove_f9_monotonicity "$destination/model/doitall.sh"

    awk -v weight="$weight" '
      $1 ~ /^-2[123]$/ && $2 == 49 && $3 == 20 {
        fishery = substr($1, 2)
        print "  " $1 " 49 200  # DW10: F" fishery " LF divisor, 10 times the global divisor 20"
        next
      }
      $1 == 1 && $2 == 77 && $3 == 50 {
        if (weight == 0) {
          print "  1 77 0    # regional-scaling penalty disabled"
        } else {
          print "  1 77 " weight "    # MVN regional-scaling penalty weight"
        }
        next
      }
      { print }
    ' "$destination/model/doitall.sh" > "$destination/model/doitall.sh.new"
    mv "$destination/model/doitall.sh.new" "$destination/model/doitall.sh"
    chmod 0755 "$destination/model/doitall.sh"

    control="$model"
    if [[ "$tag_flag2" -eq 1 ]]; then
      control_id="$(printf 'S%03d' "$((number - 4))")"
      control="${control_id}-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2OFF-REGW${weight}"
    fi
    interpretation="$(regw_text "$weight")"

    cat > "$destination/README.md" <<MODEL_README
# BET 2026 $model

This model is part of the focused SUB075 regional-scaling sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| INI | bet.2026.mix-0.15.ini |
| Selectivity | Corrected SA28-N5 baseline; no fishery has flag 16=1 |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1 percent |
| Observed LF cutoff | None |
| F21/F22/F23 LF weighting | DW10, flag-49 divisor 200 versus global divisor 20 |
| Tag flag column 2 | $tag_code; paired OFF control: $control |
| Regional-scaling form | Multivariate normal when weight is positive |
| Regional-scaling weight | $weight; $interpretation |
| Regional-scaling target/window | Mean proportions and covariance from 20 quarters in 1965-1969 |

In the active MFCL MVN path, the penalty is w/2 times the squared
Mahalanobis distance from the regional-scaling target. A positive weight
therefore changes the effective covariance to Sigma/w and the standardized
SD multiplier to 1/sqrt(w). Weights 50, 11, and 1 give multipliers 0.1414,
0.3015, and 1.0000, respectively; weight 0 disables the penalty.
Region 5 is the MVN reference category, as in MFCL, while its proportion is
implicitly determined because all five proportions sum to one.

The model is copied from **$template** at
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). Apart from the documented
F21/F22/F23 divisor, parest flag 77, F9 monotonicity removal, identifiers, and
metadata, all CPUE sigma, regional-scaling data, flags 78-81, phase timing,
FRQ, tag, age-length, and remaining selectivity settings are unchanged. The INI
is replaced by **$INI_SOURCE_REPO@$INI_SOURCE_COMMIT/$INI_SOURCE_PATH**;
TAGF2OFF changes only tag_flags(:,2) from 1 to 0.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.

Status: generated; Kflow has not been submitted.
MODEL_README

    printf '"%s","%s","",%s,"%s",%s,"%s","normal","",,10,200\n' \
      "$model" "$template" "$weight" "$interpretation" "$tag_flag2" "$control" >> "$mapping"
  done
done

# Add matched TAGF2OFF/ON DM G7OSHL-CEST models. Fixed flag-49 divisors are
# intentionally not labelled DW10 because they are not the DM observation-
# weight control.
for template_index in "${!normal_templates[@]}"; do
  dm_normal_template="${normal_templates[$template_index]}"
  tag_flag2="$template_index"
  tag_code="TAGF2OFF"
  [[ "$tag_flag2" -eq 1 ]] && tag_code="TAGF2ON"

  for weight in "${weights[@]}"; do
    number=$((number + 1))
    id="$(printf 'S%03d' "$number")"
    model="${id}-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-${tag_code}-NMAX20-REGW${weight}"
    destination="$ROOT/sensitivity/$model"
    cp -a "$tmp/sensitivity/$dm_normal_template" "$destination"
    write_model_ini "$destination/model/bet.ini" "$tag_flag2"
    remove_f9_monotonicity "$destination/model/doitall.sh"

  Rscript - \
    "$destination/model/doitall.sh" \
    "$tmp/sensitivity/$dm_template/model/doitall.sh" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
target_path <- args[[1L]]
dm_source_path <- args[[2L]]
target <- readLines(target_path, warn = FALSE)
dm_source <- readLines(dm_source_path, warn = FALSE)

replace_block <- function(target, source, start_marker, end_marker) {
  target_start <- which(target == start_marker)
  target_end <- which(target == end_marker)
  source_start <- which(source == start_marker)
  source_end <- which(source == end_marker)
  stopifnot(
    length(target_start) == 1L, length(target_end) == 1L,
    length(source_start) == 1L, length(source_end) == 1L,
    target_start < target_end, source_start < source_end
  )
  c(
    target[seq_len(target_start - 1L)],
    source[seq.int(source_start, source_end - 1L)],
    target[seq.int(target_end, length(target))]
  )
}

target <- replace_block(
  target, dm_source,
  "# Likelihood component settings",
  "# Additional LF/WF sample-size reductions retained from the inherited setup."
)

for (flag in c(311L, 313L)) {
  pattern <- paste0("^[[:space:]]*1[[:space:]]+", flag, "[[:space:]]+")
  target_row <- grep(pattern, target)
  source_row <- grep(pattern, dm_source)
  stopifnot(length(target_row) == 1L, length(source_row) == 1L)
  target[target_row] <- dm_source[source_row]
}

phase2_command <- grep("<<PHASE2[[:space:]]*$", target)
phase2_cest <- grep("^[[:space:]]*-999[[:space:]]+89[[:space:]]+1", dm_source, value = TRUE)
stopifnot(length(phase2_command) == 1L, length(phase2_cest) == 1L)
target <- append(target, phase2_cest, after = phase2_command)

early_report <- grep("^[[:space:]]*1[[:space:]]+190[[:space:]]+1", target)
source_early_report <- grep("^[[:space:]]*1[[:space:]]+190[[:space:]]+0", dm_source, value = TRUE)
stopifnot(length(early_report) == 1L, length(source_early_report) == 1L)
target[early_report] <- source_early_report
final_report <- grep("^[[:space:]]*1[[:space:]]+190[[:space:]]+1", dm_source, value = TRUE)
phase11_end <- which(target == "PHASE11")
stopifnot(length(final_report) == 1L, length(phase11_end) == 1L)
target <- append(target, final_report, after = phase11_end - 1L)

# G7OSHL preserves the process grouping while separating offshore longline
# and handline observations into their own DM estimation groups.
dm_groups <- list(
  "Remaining longline" = c(1:4, 6:8, 10:11),
  "Offshore longline" = c(5, 9),
  "Large-scale purse seine" = c(12, 19:20, 25:28),
  "Domestic purse seine" = 17:18,
  "Handline" = 14:15,
  "Other extraction" = c(13, 16, 21:24),
  "Index" = 29:33
)
group_id <- integer(33L)
group_name <- character(33L)
for (group in seq_along(dm_groups)) {
  fisheries <- dm_groups[[group]]
  group_id[fisheries] <- group
  group_name[fisheries] <- names(dm_groups)[[group]]
}
all_fisheries <- as.integer(unlist(dm_groups, use.names = FALSE))
stopifnot(
  all(group_id > 0L),
  length(all_fisheries) == 33L,
  !anyDuplicated(all_fisheries),
  identical(sort(all_fisheries), 1:33)
)
for (fishery in 1:33) {
  pattern <- paste0("^[[:space:]]*-", fishery, "[[:space:]]+68[[:space:]]+")
  row <- grep(pattern, target)
  stopifnot(length(row) == 1L)
  target[row] <- sprintf(
    "  -%d 68 %d  # DM LF group: %s",
    fishery, group_id[[fishery]], group_name[[fishery]]
  )
}

stopifnot(!any(grepl("PHASE7A|PHASE9A|06a[.]par|08a[.]par", target)))
writeLines(target, target_path, useBytes = TRUE)
RS

    awk -v weight="$weight" '
      $1 == 1 && $2 == 77 && $3 == 50 {
        if (weight == 0) {
          print "  1 77 0    # regional-scaling penalty disabled"
        } else {
          print "  1 77 " weight "    # MVN regional-scaling penalty weight"
        }
        next
      }
      $1 == 1 && $2 == 342 && $3 == 10 {
        print "  1 342 20    # DM maximum LF sample-size control (Nmax20)"
        next
      }
      { print }
    ' "$destination/model/doitall.sh" > "$destination/model/doitall.sh.new"
    mv "$destination/model/doitall.sh.new" "$destination/model/doitall.sh"
    chmod 0755 "$destination/model/doitall.sh"
    interpretation="$(regw_text "$weight")"

    control="$model"
    if [[ "$tag_flag2" -eq 1 ]]; then
      control_id="$(printf 'S%03d' "$((number - 4))")"
      control="${control_id}-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2OFF-NMAX20-REGW${weight}"
    fi

    cat > "$destination/README.md" <<MODEL_README
# BET 2026 $model

This model is the matched DM interaction in the focused SUB075 regional-scaling
design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| INI | bet.2026.mix-0.15.ini |
| Selectivity | Exact matched SA28-N5 normal-model settings; no fishery has flag 16=1 |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM grouping | G7OSHL: remaining LL; OS F5/F9; large-scale PS; domestic PS; HL F14/F15; other extraction; index |
| DM relative sample-size exponent | CEST, activated in phase 2 |
| DM maximum LF sample-size control | 20 directly from phase 1 |
| DM tail compression | Retain at least five class intervals |
| Observed LF cutoff | None |
| Fixed DW10 divisor | Not applicable to DM weighting |
| Tag flag column 2 | $tag_code; paired OFF control: $control |
| Regional-scaling weight | $weight; $interpretation |

All non-doitall inputs except the INI come from **$dm_normal_template** at
**$SOURCE_COMMIT** and retain SUB075. The INI comes from
**$INI_SOURCE_REPO@$INI_SOURCE_COMMIT/$INI_SOURCE_PATH**. The DM controls come from
**$dm_template** at **$DM_SOURCE_COMMIT** (**$DM_SOURCE_REF**). HAC4 sigma,
additional selectivity-tail constraints, and extra stabilization phases are excluded.
The report is deferred from phase 2 to the final fit only for DM output safety.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.

Status: generated; Kflow has not been submitted.
MODEL_README

    printf '"%s","%s","%s",%s,"%s",%s,"%s","dm_no_re","G7OSHL_CEST",20,,\n' \
      "$model" "$dm_normal_template" "$dm_template" "$weight" "$interpretation" \
      "$tag_flag2" "$control" >> "$mapping"
  done
done

Rscript - "$ROOT" "$mapping" "$SOURCE_COMMIT" "$DM_SOURCE_COMMIT" "$AGE_SHA256" \
  "$INI_SOURCE_REPO" "$INI_SOURCE_COMMIT" "$INI_SOURCE_PATH" "$INI_SOURCE_SHA256" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
root <- args[[1L]]
mapping <- read.csv(args[[2L]], stringsAsFactors = FALSE, check.names = FALSE)
source_commit <- args[[3L]]
dm_source_commit <- args[[4L]]
age_sha256 <- args[[5L]]
ini_source_repo <- args[[6L]]
ini_source_commit <- args[[7L]]
ini_source_path <- args[[8L]]
ini_source_sha256 <- args[[9L]]
mapping$regional_scaling_weight <- as.integer(mapping$regional_scaling_weight)

for (i in seq_len(nrow(mapping))) {
  model <- mapping$model[[i]]
  source_model <- mapping$source_model[[i]]
  manifest_path <- file.path(root, "sensitivity", model, "input_manifest.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  manifest$note <- gsub(source_model, model, manifest$note, fixed = TRUE)

  reg_row <- manifest$role == "reg_scaling"
  manifest$note[reg_row] <- paste0(
    "Active 20x5 regional-scaling matrix retained unchanged. Parest flag 77 is ",
    mapping$regional_scaling_weight[[i]], ": ",
    mapping$standardized_sd_interpretation[[i]],
    "; flags 78-81 and the 1965-1969 window are unchanged."
  )

  is_dm <- mapping$lf_likelihood[[i]] == "dm_no_re"
  doitall_row <- manifest$role == "doitall"
  if (is_dm) {
    manifest$source[doitall_row] <- paste0(
      "sensitivity/", mapping$dm_source_model[[i]], "/model/doitall.sh"
    )
    manifest$source_commit[doitall_row] <- dm_source_commit
    manifest$note[doitall_row] <- paste0(
      "Matched DM-noRE G7OSHL-CEST doitall with Nmax20 directly from phase 1; ",
      "fixed DW10 is not used by the DM likelihood. Parest flag 77 is ",
      mapping$regional_scaling_weight[[i]], "."
    )
  } else {
    manifest$note[doitall_row] <- paste0(
      "SUB075 NOCUT robust-normal doitall; F21/F22/F23 flag-49 divisors are ",
      "200 (DW10 relative to global divisor 20). Parest flag 77 is ",
      mapping$regional_scaling_weight[[i]], "."
    )
  }

  ini_row <- manifest$role == "ini"
  manifest$source[ini_row] <- paste0(
    "https://github.com/", ini_source_repo, "/blob/", ini_source_commit, "/",
    ini_source_path
  )
  manifest$source_commit[ini_row] <- ini_source_commit
  manifest$note[ini_row] <- paste0(
    "Upstream mix-period 0.15 INI (SHA-256 ", ini_source_sha256,
    "). The model retains every upstream field; TAGF2OFF changes only all 98 ",
    "tag_flags(:,2) values from 1 to 0. Matched OFF control: ",
    mapping$tag_control[[i]], "."
  )

  context_row <- manifest$role == "design_context"
  manifest$note[context_row] <- paste0(
    "Public sixteen-model SUB075 NOCUT regional-scaling design: eight robust-normal ",
    "DW10 and eight DM G7OSHL-CEST Nmax20 models, each crossing TAGF2OFF/ON ",
    "with weights 50/11/1/0."
  )
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
}

is_dm <- mapping$lf_likelihood == "dm_no_re"
selection <- data.frame(
  model = mapping$model,
  base_sensitivity = mapping$source_model,
  age_length_variant = "SUB075",
  age_length_source_file = "bet.2026.sub.basin.0.75.age_length",
  age_length_sha256 = age_sha256,
  lf_likelihood = mapping$lf_likelihood,
  tail_compression_percent = ifelse(is_dm, NA_integer_, 1L),
  lf_downweight_factor = ifelse(is_dm, NA_integer_, 10L),
  lf_size_divisor = ifelse(is_dm, NA_integer_, 200L),
  dm_tail_min_classes = ifelse(is_dm, 5L, NA_integer_),
  dm_grouping = ifelse(is_dm, "G7OSHL", NA_character_),
  dm_concentration = ifelse(is_dm, "estimated_phase2", NA_character_),
  dm_nmax = ifelse(is_dm, 20L, NA_integer_),
  cutoff_cm = NA_real_,
  tag_flag2 = mapping$tag_flag2,
  regional_scaling_weight = mapping$regional_scaling_weight,
  regional_scaling_interpretation = mapping$standardized_sd_interpretation,
  selectivity_treatment = "sa28_n5",
  status = "prepared",
  stringsAsFactors = FALSE
)
write.csv(selection, file.path(root, "SENSITIVITY_SELECTION.csv"), row.names = FALSE, na = "")

labels <- ifelse(
  is_dm,
  paste0(
    "SUB075 NOCUT ",
    ifelse(mapping$tag_flag2 == 1L, "TAGF2ON", "TAGF2OFF"),
    " DM G7OSHL-CEST Nmax20 REGW",
    mapping$regional_scaling_weight
  ),
  paste0(
    "SUB075 NOCUT DW10 ",
    ifelse(mapping$tag_flag2 == 1L, "TAGF2ON", "TAGF2OFF"),
    " REGW", mapping$regional_scaling_weight
  )
)
stepwise_run <- list(
  default_step_select = mapping$model[[1L]],
  flow_group = "bet-2026-sub075-mix015-unconstrained-g7oshl-dm20-20260721",
  trigger_next = FALSE
)
stepwise_models <- data.frame(
  step_id = mapping$model,
  enabled = TRUE,
  model_label = labels,
  run_mode = "doitall",
  frq = "bet.frq",
  region_count = 5L,
  age_length_variant = "SUB075",
  cutoff_code = "NOCUT",
  tag_flag2 = mapping$tag_flag2,
  lf_likelihood = mapping$lf_likelihood,
  lf_downweight_factor = ifelse(is_dm, NA_integer_, 10L),
  lf_size_divisor = ifelse(is_dm, NA_integer_, 200L),
  dm_grouping = ifelse(is_dm, "G7OSHL", NA_character_),
  dm_concentration = ifelse(is_dm, "estimated_phase2", NA_character_),
  dm_nmax = ifelse(is_dm, 20L, NA_integer_),
  regional_scaling_weight = mapping$regional_scaling_weight,
  major_step = "Regional scaling",
  substep = paste0(
    ifelse(is_dm, "DM Nmax20 ", "DW10 "),
    "REGW", mapping$regional_scaling_weight
  ),
  change_axis = ifelse(
    is_dm,
    "lf_likelihood+regional_scaling_weight",
    "regional_scaling_weight"
  ),
  stringsAsFactors = FALSE
)
config_lines <- c(
  "# Generated SUB075 NOCUT DW10 regional-scaling sensitivity configuration.",
  "stepwise_run <-", capture.output(dput(stepwise_run)), "",
  "stepwise_models <-", capture.output(dput(stepwise_models)), "",
  "stepwise_models_all <- stepwise_models"
)
config_lines <- sub("[[:space:]]+$", "", config_lines)
writeLines(config_lines, file.path(root, "job-config.R"), useBytes = TRUE)
RS

first_model="S001-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2OFF-REGW50"
perl -0pi -e 's/STEP_SELECT: "[^"]+"/STEP_SELECT: "'"$first_model"'"/; s/JOB_TITLE: "[^"]+"/JOB_TITLE: "BET 2026 mix-0.15 unconstrained regional-scaling fit"/; s/JOB_DESCRIPTION: "[^"]+"/JOB_DESCRIPTION: "Run one SUB075 mix-0.15 unconstrained regional-scaling sensitivity model."/; s/MODEL_LABEL: "[^"]+"/MODEL_LABEL: "SUB075 MIX015 NOCUT DW10 TAGF2OFF REGW50"/; s/JOB_KEY: [^\n]+/JOB_KEY: s001-sub075-mix015-nocut-dw10-tagf2off-regw50/; s/FLOW_GROUP: [^\n]+/FLOW_GROUP: bet-2026-sub075-mix015-unconstrained-g7oshl-dm20-20260721/' "$ROOT/kflow.yaml"

cat > "$ROOT/README.md" <<ROOT_README
# BET 2026 mix-0.15 unconstrained regional-scaling sensitivities

This branch contains sixteen NOCUT MFCL models based on
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). All models use the SUB075
age-length input, the upstream mix-period 0.15 INI, and corrected SA28-N5
selectivity baseline. The F9-only non-decreasing constraint is removed, so no
fishery uses fish flag 16=1. CUT90 is excluded.
The retained Job 5319 FRQ already contains the selected 2026 effort-creep
adjustment, and the build never reapplies effort creep.

## Model design

| IDs | LF likelihood and weighting | Tag flag column 2 | REGW sequence |
| --- | --- | ---: | --- |
| S001-S004 | Robust normal; F21/F22/F23 DW10 | 0 (OFF) | 50, 11, 1, 0 |
| S005-S008 | Robust normal; F21/F22/F23 DW10 | 1 (ON) | 50, 11, 1, 0 |
| S009-S012 | DM G7OSHL-CEST; Nmax20 | 0 (OFF) | 50, 11, 1, 0 |
| S013-S016 | DM G7OSHL-CEST; Nmax20 | 1 (ON) | 50, 11, 1, 0 |

The four REGW values occur in the displayed order within every ID range. This
gives matched comparisons for LF likelihood, tag flag column 2, and regional-
scaling weight. Within each OFF/ON pair, all 98 values in tag flag column 2
change from 0 to 1; the other INI fields and model data are unchanged.

For robust-normal models, DW10 means F21/F22/F23 flag-49 divisor 200 against
the global divisor 20. It is not applied to DM models because fixed flag-49
divisors are not the DM observation-weight parameter. For DM models, Nmax20 is
the phase-1 maximum LF sample-size control. It is not a statement that the
realized effective sample size is exactly 20; realized information also
depends on the estimated DM concentration and relative sample-size exponent.

## DM G7OSHL grouping

| Group | Fisheries |
| --- | --- |
| Remaining longline | F1-F4, F6-F8, F10-F11 |
| Offshore longline | F5, F9 |
| Large-scale purse seine | F12, F19-F20, F25-F28 |
| Domestic purse seine | F17-F18 |
| Handline | F14-F15 |
| Other extraction | F13, F16, F21-F24 |
| Index | F29-F33 |

This changes only DM fish flag 68. Tag-reporting groups (flag 32), selectivity
groups (flag 24), the FRQ, and other model data are unchanged.

## INI provenance

The model INI is derived from
**$INI_SOURCE_REPO@$INI_SOURCE_COMMIT/$INI_SOURCE_PATH**. TAGF2ON retains the
upstream tag flags. TAGF2OFF changes only all 98 values in tag flag column 2
from 1 to 0.

## Regional-scaling weights

| REGW | Effective covariance | Standardized SD multiplier | Role in this design |
| ---: | ---: | ---: | --- |
| 50 | Sigma / 50 | 0.1414 | Inherited strong constraint |
| 11 | Sigma / 11 | 0.3015 | Intermediate constraint |
| 1 | Sigma | 1.0000 | Empirical covariance without an extra precision multiplier |
| 0 | Not applicable | Not applicable | Regional-scaling penalty disabled |

The active regional-scaling data are 20 quarterly regional CPUE values for
1965-1969. MFCL converts each row to regional proportions, calculates their
mean and covariance, removes Region 5 as the MVN reference dimension, and uses

    penalty = 0.5 * weight * d' * Sigma^-1 * d.

Thus weights 50, 11, and 1 give standardized SD multipliers of 0.1414,
0.3015, and 1.0000 relative to the empirical MVN covariance; weight 0 disables
the regional-scaling penalty. These are penalty-strength interpretations, not
literal CVs on regional biomass or on each regional target mean.

The derivation, source/manual references, and distinction from target-relative
marginal CV are documented in
**notes/regional-scaling-weight-interpretation.md**.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated inputs and file-level provenance are under **sensitivity/**.
ROOT_README

printf 'Generated %s SUB075 NOCUT regional-scaling sensitivity models.\n' "$number"
