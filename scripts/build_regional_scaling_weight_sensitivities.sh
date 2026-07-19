#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="81a456fa5c36ef1be5bd9da38308ef07ebc55ff4"
SOURCE_REF="experiment/normal-francis-initial-20260719"
SOURCE_REPO="PacificCommunity/ofp-sam-bet-2026-exploration"

templates=(
  "S001-TC1-NOCUT-BASE075-TAGF2OFF"
  "S002-TC1-NOCUT-BASE075-TAGF2ON"
  "S003-TC1-CUT90-BASE075-TAGF2OFF"
  "S004-TC1-CUT90-BASE075-TAGF2ON"
)
weights=(25 10 5)

if ! git -C "$ROOT" cat-file -e "${SOURCE_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$ROOT" fetch --depth=1 origin "$SOURCE_COMMIT"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for template in "${templates[@]}"; do
  git -C "$ROOT" archive "$SOURCE_COMMIT" "sensitivity/$template" | tar -x -C "$tmp"
done

rm -rf "$ROOT/sensitivity"
mkdir -p "$ROOT/sensitivity"
mapping="$tmp/model-map.csv"
printf '%s\n' 'model,source_model,regional_scaling_weight,cutoff_code,tag_flag2,tag_control' > "$mapping"

number=0
for template_index in "${!templates[@]}"; do
  template="${templates[$template_index]}"
  slug="${template#S???-}"
  cutoff_code="NOCUT"
  tag_flag2=0
  [[ "$slug" == *CUT90* ]] && cutoff_code="CUT90"
  [[ "$slug" == *TAGF2ON* ]] && tag_flag2=1

  for weight in "${weights[@]}"; do
    number=$((number + 1))
    id="$(printf 'S%03d' "$number")"
    model="${id}-${slug}-REGW${weight}"
    destination="$ROOT/sensitivity/$model"
    cp -a "$tmp/sensitivity/$template" "$destination"

    awk -v weight="$weight" '
      $1 == 1 && $2 == 77 && $3 == 50 {
        print "  1 77 " weight "   # MVN regional-scaling penalty weight; sensitivity value"
        next
      }
      { print }
    ' "$destination/model/doitall.sh" > "$destination/model/doitall.sh.new"
    mv "$destination/model/doitall.sh.new" "$destination/model/doitall.sh"
    chmod 0755 "$destination/model/doitall.sh"

    control="$model"
    if [[ "$tag_flag2" -eq 1 ]]; then
      control_id="$(printf 'S%03d' "$((number - 3))")"
      control_slug="${slug/TAGF2ON/TAGF2OFF}"
      control="${control_id}-${control_slug}-REGW${weight}"
    fi

    cutoff_text="No observed LF cutoff"
    if [[ "$cutoff_code" == "CUT90" ]]; then
      cutoff_text="F21/F22/F23 observed LF bins above 90 cm set to zero"
    fi
    tag_text="all tag_flags(:,2) values set to 0"
    if [[ "$tag_flag2" -eq 1 ]]; then
      tag_text="all tag_flags(:,2) values set to 1; paired control: $control"
    fi

    cat > "$destination/README.md" <<EOF
# BET 2026 $model

This model is part of the BASE075 regional-scaling-weight sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | BASE075 |
| Selectivity | Corrected SA28-N5 baseline |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1% |
| Observed LF treatment | $cutoff_text |
| Tag flag column 2 | $tag_text |
| Regional-scaling penalty | MVN, parest flag 81 = 1 |
| Regional-scaling penalty weight | $weight |
| Regional-scaling target/window | Unchanged from the source model |

Only parest flag 77 differs from the corresponding source model at weight 50.
CPUE observations and sigma, the active regional-scaling matrix, flags 78-81,
phase timing, LF divisors, selectivity, age-length data, and all other MFCL
settings are unchanged. The N8 selectivity variant is excluded.

Source model: **$template** from
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**).
See **input_manifest.csv** for file-level provenance.

Status: generated; Kflow has not been submitted.
EOF

    printf '"%s","%s",%s,"%s",%s,"%s"\n' \
      "$model" "$template" "$weight" "$cutoff_code" "$tag_flag2" "$control" >> "$mapping"
  done
done

Rscript - "$ROOT" "$mapping" "$SOURCE_COMMIT" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
root <- args[[1L]]
mapping <- read.csv(args[[2L]], stringsAsFactors = FALSE)
source_commit <- args[[3L]]

for (i in seq_len(nrow(mapping))) {
  model <- mapping$model[[i]]
  source_model <- mapping$source_model[[i]]
  weight <- mapping$regional_scaling_weight[[i]]
  manifest_path <- file.path(root, "sensitivity", model, "input_manifest.csv")
  manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  manifest$note <- gsub(source_model, model, manifest$note, fixed = TRUE)

  reg_row <- manifest$role == "reg_scaling"
  manifest$note[reg_row] <- paste0(
    "MFCL-ready active 20x5 regional-scaling matrix inherited unchanged from ",
    "the source model. Parest flag 77 is set to the sensitivity weight ", weight,
    "; flags 78-81 and the 1965-1969 target/covariance window are unchanged."
  )

  doitall_row <- manifest$role == "doitall"
  manifest$note[doitall_row] <- paste0(
    manifest$note[doitall_row],
    " This sensitivity changes only the MVN regional-scaling penalty weight ",
    "from 50 to ", weight, "."
  )

  ini_row <- manifest$role == "ini"
  if (mapping$tag_flag2[[i]] == 1L) {
    manifest$note[ini_row] <- sub(
      "its exact flag-column-2=0 control is [^;]+;",
      paste0("its exact flag-column-2=0 control is ", mapping$tag_control[[i]], ";"),
      manifest$note[ini_row],
      perl = TRUE
    )
  }

  context_row <- manifest$role == "design_context"
  manifest$note[context_row] <- paste0(
    "Public 12-model BASE075 regional-scaling-weight design: NOCUT/CUT90 x ",
    "TAGF2OFF/TAGF2ON x weights 25/10/5. Corrected SA28-N5 selectivity is ",
    "common to every model; N8 is excluded. Source commit ", source_commit, "."
  )
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
}

selection <- data.frame(
  model = mapping$model,
  base_sensitivity = mapping$source_model,
  age_length_variant = "BASE075",
  age_length_source_file = "bet.age_length",
  age_length_sha256 = "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
  lf_likelihood = "normal",
  tail_compression_percent = 1L,
  cutoff_cm = ifelse(mapping$cutoff_code == "CUT90", 90, NA_real_),
  tag_flag2 = mapping$tag_flag2,
  regional_scaling_weight = mapping$regional_scaling_weight,
  selectivity_treatment = "sa28_n5",
  status = "prepared",
  basis = "Only parest flag 77 differs from the weight-50 source model",
  stringsAsFactors = FALSE
)
write.csv(selection, file.path(root, "SENSITIVITY_SELECTION.csv"), row.names = FALSE, na = "")

labels <- paste0(
  "BASE075 ", mapping$cutoff_code, " ",
  ifelse(mapping$tag_flag2 == 1L, "TAGF2ON", "TAGF2OFF"),
  " regional-scaling weight ", mapping$regional_scaling_weight
)
stepwise_run <- list(
  default_step_select = mapping$model[[1L]],
  flow_group = "bet-2026-base075-regional-scaling-weights-20260720",
  trigger_next = FALSE
)
stepwise_models <- data.frame(
  step_id = mapping$model,
  enabled = TRUE,
  model_label = labels,
  run_mode = "doitall",
  frq = "bet.frq",
  region_count = 5L,
  age_length_variant = "BASE075",
  cutoff_code = mapping$cutoff_code,
  tag_flag2 = mapping$tag_flag2,
  regional_scaling_weight = mapping$regional_scaling_weight,
  major_step = "Regional scaling",
  substep = paste0("Weight ", mapping$regional_scaling_weight),
  change_axis = "regional_scaling_weight",
  stringsAsFactors = FALSE
)
config_lines <- c(
  "# Generated BASE075 regional-scaling-weight sensitivity configuration.",
  "stepwise_run <-",
  capture.output(dput(stepwise_run)),
  "",
  "stepwise_models <-",
  capture.output(dput(stepwise_models)),
  "",
  "stepwise_models_all <- stepwise_models"
)
writeLines(config_lines, file.path(root, "job-config.R"), useBytes = TRUE)
RS

first_model="S001-TC1-NOCUT-BASE075-TAGF2OFF-REGW25"
perl -0pi -e 's/STEP_SELECT: "[^"]+"/STEP_SELECT: "'"$first_model"'"/; s/JOB_TITLE: "[^"]+"/JOB_TITLE: "BET 2026 regional-scaling sensitivity fit"/; s/JOB_DESCRIPTION: "[^"]+"/JOB_DESCRIPTION: "Run one BASE075 regional-scaling-weight sensitivity model."/; s/MODEL_LABEL: "[^"]+"/MODEL_LABEL: "BASE075 NOCUT TAGF2OFF regional-scaling weight 25"/; s/JOB_KEY: [^\n]+/JOB_KEY: s001-base075-nocut-tagf2off-regw25/; s/FLOW_GROUP: [^\n]+/FLOW_GROUP: bet-2026-base075-regional-scaling-weights-20260720/' "$ROOT/kflow.yaml"

cat > "$ROOT/README.md" <<EOF
# BET 2026 BASE075 regional-scaling-weight sensitivities

This branch contains 12 MFCL models derived from
**$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). It retains only the corrected
SA28-N5 BASE075 models and excludes the N8 selectivity variant.

## Purpose

The source models use MVN regional-scaling penalty weight 50. This design
changes only parest flag 77 to 25, 10, or 5, allowing progressively more
freedom in relative biomass allocation among regions. Regional-scaling inputs,
flags 78-81, the 1965-1969 target/covariance window, CPUE observations and
sigma, phase timing, LF settings, tag inputs, age-length data, and selectivity
are held fixed.

MFCL normalizes regional mean biomass to proportions before evaluating this
penalty. These sensitivities therefore relax relative regional allocation
directly; effects on total biomass are indirect through the coupled population
dynamics.

## Design

| IDs | Cutoff | Tag flag column 2 | Regional-scaling weights |
| --- | --- | --- | --- |
| S001-S003 | NOCUT | 0 | 25, 10, 5 |
| S004-S006 | NOCUT | 1 | 25, 10, 5 |
| S007-S009 | CUT90 | 0 | 25, 10, 5 |
| S010-S012 | CUT90 | 1 | 25, 10, 5 |

Relative to weight 50, weights 25, 10, and 5 increase the prior standard
deviation by approximately sqrt(2), sqrt(5), and sqrt(10), respectively. The
weight-50 controls remain on the source branch and are not duplicated here.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated models are under **sensitivity/**; exact input provenance is recorded
in each model's **input_manifest.csv**.
EOF

printf 'Generated %s regional-scaling sensitivity models.\n' "$number"
