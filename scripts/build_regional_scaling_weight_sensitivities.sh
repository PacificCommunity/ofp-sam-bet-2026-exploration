#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="81a456fa5c36ef1be5bd9da38308ef07ebc55ff4"
SOURCE_REF="experiment/normal-francis-initial-20260719"
SOURCE_REPO="PacificCommunity/ofp-sam-bet-2026-exploration"
DM_SOURCE_COMMIT="20c19b02498a6ee22cc39441a073159accca020b"
DM_SOURCE_REF="experiment/cpue-hac4-single-area-tail-nmax10-20260719"
AGE_SHA256="426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c"

normal_templates=(
  "S017-TC1-NOCUT-SUB075-TAGF2OFF"
  "S018-TC1-NOCUT-SUB075-TAGF2ON"
)
weights=(3 1 0)
dm_template="S035-DM-G5PROC-CEST-NOCUT-TAGF2ON"
dm_normal_template="S018-TC1-NOCUT-SUB075-TAGF2ON"

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
printf '%s\n' 'model,source_model,dm_source_model,regional_scaling_weight,actual_cv,tag_flag2,tag_control,lf_likelihood,dm_grouping,dm_nmax,lf_downweight_factor,lf_size_divisor' > "$mapping"

cv_text() {
  case "$1" in
    3) printf '%s' 'about 9.4-11.5 percent marginal CV' ;;
    1) printf '%s' 'about 16.3-19.8 percent marginal CV (raw CPUE covariance)' ;;
    0) printf '%s' 'regional-scaling penalty disabled' ;;
    *) return 1 ;;
  esac
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
    model="${id}-TC1-NOCUT-DW10-SUB075-${tag_code}-REGW${weight}"
    destination="$ROOT/sensitivity/$model"
    cp -a "$tmp/sensitivity/$template" "$destination"

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
      control_id="$(printf 'S%03d' "$((number - 3))")"
      control="${control_id}-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW${weight}"
    fi
    interpretation="$(cv_text "$weight")"

    cat > "$destination/README.md" <<MODEL_README
# BET 2026 $model

This model is part of the focused SUB075 regional-scaling sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| Selectivity | Corrected SA28-N5 baseline |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1 percent |
| Observed LF cutoff | None |
| F21/F22/F23 LF weighting | DW10, flag-49 divisor 200 versus global divisor 20 |
| Tag flag column 2 | $tag_code; paired OFF control: $control |
| Regional-scaling form | Multivariate normal when weight is positive |
| Regional-scaling weight | $weight; $interpretation |
| Regional-scaling target/window | Mean proportions and covariance from 20 quarters in 1965-1969 |

The 1965-1969 CPUE-derived marginal CVs are 16.3-19.8 percent before
weighting. A positive weight divides that covariance by the weight. Weight 3
therefore gives approximately 9.4-11.5 percent marginal CV; weight 1 retains
the empirical covariance; weight 0 disables the regional-scaling penalty.
Region 5 is the MVN reference category, as in MFCL, while its proportion is
implicitly determined because all five proportions sum to one.

The model is copied from **$template** at
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). Apart from the documented
F21/F22/F23 divisor, parest flag 77, identifiers, and metadata, all CPUE sigma,
regional-scaling data, flags 78-81, phase timing, FRQ, INI, tag, age-length,
and selectivity settings are unchanged.

Status: generated; Kflow has not been submitted.
MODEL_README

    printf '"%s","%s","",%s,"%s",%s,"%s","normal","",,10,200\n' \
      "$model" "$template" "$weight" "$interpretation" "$tag_flag2" "$control" >> "$mapping"
  done
done

# Add matched DM G5PROC-CEST models. Fixed flag-49 divisors are intentionally
# not labelled DW10 because they are not the DM observation-weight control.
for weight in "${weights[@]}"; do
  number=$((number + 1))
  id="$(printf 'S%03d' "$number")"
  model="${id}-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2ON-NMAX10-REGW${weight}"
  destination="$ROOT/sensitivity/$model"
  cp -a "$tmp/sensitivity/$dm_normal_template" "$destination"

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
    { print }
  ' "$destination/model/doitall.sh" > "$destination/model/doitall.sh.new"
  mv "$destination/model/doitall.sh.new" "$destination/model/doitall.sh"
  chmod 0755 "$destination/model/doitall.sh"
  interpretation="$(cv_text "$weight")"

  cat > "$destination/README.md" <<MODEL_README
# BET 2026 $model

This model is the matched DM interaction in the focused SUB075 regional-scaling
design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| Selectivity | Exact matched SA28-N5 normal-model settings |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM grouping | G5PROC |
| DM relative sample-size exponent | CEST, activated in phase 2 |
| DM maximum LF effective sample size | 10 directly from phase 1 |
| DM tail compression | Retain at least five class intervals |
| Observed LF cutoff | None |
| Fixed DW10 divisor | Not applicable to DM weighting |
| Tag flag column 2 | TAGF2ON |
| Regional-scaling weight | $weight; $interpretation |

All non-doitall inputs come from **$dm_normal_template** at
**$SOURCE_COMMIT** and retain SUB075. The DM controls come from
**$dm_template** at **$DM_SOURCE_COMMIT** (**$DM_SOURCE_REF**). HAC4 sigma,
separate selectivity-tail changes, and extra stabilization phases are excluded.
The report is deferred from phase 2 to the final fit only for DM output safety.

Status: generated; Kflow has not been submitted.
MODEL_README

  printf '"%s","%s","%s",%s,"%s",1,"","dm_no_re","G5PROC_CEST",10,,\n' \
    "$model" "$dm_normal_template" "$dm_template" "$weight" "$interpretation" >> "$mapping"
done

Rscript - "$ROOT" "$mapping" "$SOURCE_COMMIT" "$DM_SOURCE_COMMIT" "$AGE_SHA256" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
root <- args[[1L]]
mapping <- read.csv(args[[2L]], stringsAsFactors = FALSE, check.names = FALSE)
source_commit <- args[[3L]]
dm_source_commit <- args[[4L]]
age_sha256 <- args[[5L]]
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
    mapping$regional_scaling_weight[[i]], ": ", mapping$actual_cv[[i]],
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
      "Matched DM-noRE G5PROC-CEST doitall with Nmax10 directly from phase 1; ",
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
  if (!is_dm && mapping$tag_flag2[[i]] == 1L) {
    manifest$note[ini_row] <- sub(
      "its exact flag-column-2=0 control is [^;]+;",
      paste0("its exact flag-column-2=0 control is ", mapping$tag_control[[i]], ";"),
      manifest$note[ini_row], perl = TRUE
    )
  } else if (is_dm) {
    manifest$note[ini_row] <- sub(
      "its exact flag-column-2=0 control is [^;]+;",
      "no DM TAGF2OFF counterpart is included in this focused subset;",
      manifest$note[ini_row], perl = TRUE
    )
  }

  context_row <- manifest$role == "design_context"
  manifest$note[context_row] <- paste0(
    "Public nine-model SUB075 NOCUT regional-scaling design: six robust-normal ",
    "DW10 models crossing TAGF2OFF/ON with weights 3/1/0, plus three matched ",
    "TAGF2ON DM G5PROC-CEST Nmax10 models."
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
  dm_grouping = ifelse(is_dm, "G5PROC", NA_character_),
  dm_concentration = ifelse(is_dm, "estimated_phase2", NA_character_),
  dm_nmax = ifelse(is_dm, 10L, NA_integer_),
  cutoff_cm = NA_real_,
  tag_flag2 = mapping$tag_flag2,
  regional_scaling_weight = mapping$regional_scaling_weight,
  regional_scaling_interpretation = mapping$actual_cv,
  selectivity_treatment = "sa28_n5",
  status = "prepared",
  stringsAsFactors = FALSE
)
write.csv(selection, file.path(root, "SENSITIVITY_SELECTION.csv"), row.names = FALSE, na = "")

labels <- ifelse(
  is_dm,
  paste0(
    "SUB075 NOCUT TAGF2ON DM G5PROC-CEST Nmax10 REGW",
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
  flow_group = "bet-2026-sub075-dw10-regw310-20260721",
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
  dm_grouping = ifelse(is_dm, "G5PROC", NA_character_),
  dm_concentration = ifelse(is_dm, "estimated_phase2", NA_character_),
  dm_nmax = ifelse(is_dm, 10L, NA_integer_),
  regional_scaling_weight = mapping$regional_scaling_weight,
  major_step = "Regional scaling",
  substep = paste0(
    ifelse(is_dm, "DM Nmax10 ", "DW10 "),
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

first_model="S001-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW3"
perl -0pi -e 's/STEP_SELECT: "[^"]+"/STEP_SELECT: "'"$first_model"'"/; s/JOB_TITLE: "[^"]+"/JOB_TITLE: "BET 2026 SUB075 regional-scaling sensitivity fit"/; s/JOB_DESCRIPTION: "[^"]+"/JOB_DESCRIPTION: "Run one SUB075 NOCUT DW10 regional-scaling sensitivity model."/; s/MODEL_LABEL: "[^"]+"/MODEL_LABEL: "SUB075 NOCUT DW10 TAGF2OFF REGW3"/; s/JOB_KEY: [^\n]+/JOB_KEY: s001-sub075-nocut-dw10-tagf2off-regw3/; s/FLOW_GROUP: [^\n]+/FLOW_GROUP: bet-2026-sub075-dw10-regw310-20260721/' "$ROOT/kflow.yaml"

cat > "$ROOT/README.md" <<ROOT_README
# BET 2026 SUB075 DW10 regional-scaling sensitivities

This branch contains nine NOCUT MFCL models based on
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). All models use the SUB075
age-length input and corrected SA28-N5 selectivity baseline. CUT90 is excluded.

## Design

| IDs | LF treatment | Tag flag column 2 | Regional-scaling weights |
| --- | --- | --- | --- |
| S001-S003 | Robust normal, F21/F22/F23 DW10 | 0 | 3, 1, 0 |
| S004-S006 | Robust normal, F21/F22/F23 DW10 | 1 | 3, 1, 0 |
| S007-S009 | DM G5PROC-CEST Nmax10 | 1 | 3, 1, 0 |

For robust-normal models, DW10 means F21/F22/F23 flag-49 divisor 200 against
the global divisor 20. It is not applied to DM models because fixed flag-49
divisors are not the DM observation-weight parameter.

The active regional-scaling data are 20 quarterly regional CPUE values for
1965-1969. MFCL converts each row to regional proportions, calculates their
mean and covariance, removes Region 5 as the MVN reference dimension, and uses

    penalty = 0.5 * weight * d' * Sigma^-1 * d.

Thus weight 3 gives approximately 9.4-11.5 percent marginal CV, weight 1 uses
the raw CPUE covariance (16.3-19.8 percent marginal CV), and weight 0 disables
the regional-scaling penalty. These are data-specific marginal CVs, not the
generic penalty-only approximation.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated inputs and file-level provenance are under **sensitivity/**.
ROOT_README

printf 'Generated %s SUB075 NOCUT regional-scaling sensitivity models.\n' "$number"
