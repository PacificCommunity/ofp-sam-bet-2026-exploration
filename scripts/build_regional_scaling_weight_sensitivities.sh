#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMIT="81a456fa5c36ef1be5bd9da38308ef07ebc55ff4"
SOURCE_REF="experiment/normal-francis-initial-20260719"
SOURCE_REPO="PacificCommunity/ofp-sam-bet-2026-exploration"
DM_SOURCE_COMMIT="20c19b02498a6ee22cc39441a073159accca020b"
DM_SOURCE_REF="experiment/cpue-hac4-single-area-tail-nmax10-20260719"

templates=(
  "S001-TC1-NOCUT-BASE075-TAGF2OFF"
  "S002-TC1-NOCUT-BASE075-TAGF2ON"
  "S003-TC1-CUT90-BASE075-TAGF2OFF"
  "S004-TC1-CUT90-BASE075-TAGF2ON"
)
weights=(25 10 5)
dm_templates=(
  "S035-DM-G5PROC-CEST-NOCUT-TAGF2ON"
  "S036-DM-G5PROC-CEST-CUT90-TAGF2ON"
)
dm_normal_templates=(
  "S002-TC1-NOCUT-BASE075-TAGF2ON"
  "S004-TC1-CUT90-BASE075-TAGF2ON"
)

if ! git -C "$ROOT" cat-file -e "${SOURCE_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$ROOT" fetch --depth=1 origin "$SOURCE_COMMIT"
fi
if ! git -C "$ROOT" cat-file -e "${DM_SOURCE_COMMIT}^{commit}" 2>/dev/null; then
  git -C "$ROOT" fetch --depth=1 origin "$DM_SOURCE_COMMIT"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for template in "${templates[@]}"; do
  git -C "$ROOT" archive "$SOURCE_COMMIT" "sensitivity/$template" | tar -x -C "$tmp"
done
for template in "${dm_templates[@]}"; do
  git -C "$ROOT" archive "$DM_SOURCE_COMMIT" \
    "sensitivity/$template/model/doitall.sh" | tar -x -C "$tmp"
done

rm -rf "$ROOT/sensitivity"
mkdir -p "$ROOT/sensitivity"
mapping="$tmp/model-map.csv"
printf '%s\n' 'model,source_model,dm_source_model,regional_scaling_weight,cutoff_code,tag_flag2,tag_control,lf_likelihood,dm_grouping,dm_nmax' > "$mapping"

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

This model is part of the 18-model BASE075 regional-scaling-weight sensitivity design.

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

    printf '"%s","%s","",%s,"%s",%s,"%s","normal","",\n' \
      "$model" "$template" "$weight" "$cutoff_code" "$tag_flag2" "$control" >> "$mapping"
  done
done

# Add the focused DM interaction subset without the DM source branch's HAC4,
# selectivity-tail experiment, or extra numerical-stabilization phases. Each
# model starts directly at Nmax 10 and retains the normal phase sequence.
for dm_index in "${!dm_templates[@]}"; do
  dm_template="${dm_templates[$dm_index]}"
  normal_template="${dm_normal_templates[$dm_index]}"
  cutoff_code="NOCUT"
  [[ "$dm_template" == *CUT90* ]] && cutoff_code="CUT90"

  for weight in "${weights[@]}"; do
    number=$((number + 1))
    id="$(printf 'S%03d' "$number")"
    model="${id}-DM-G5PROC-CEST-${cutoff_code}-BASE075-TAGF2ON-NMAX10-REGW${weight}"
    destination="$ROOT/sensitivity/$model"
    cp -a "$tmp/sensitivity/$normal_template" "$destination"

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

# Import only the DM likelihood, G5PROC groups, CEST staging, and direct Nmax10.
target <- replace_block(
  target, dm_source,
  "# Likelihood component settings",
  "# Additional LF/WF sample-size reductions retained from the inherited setup."
)

# Match the tested DM preprocessing semantics while preserving flag 312 = 50.
for (flag in c(311L, 313L)) {
  pattern <- paste0("^[[:space:]]*1[[:space:]]+", flag, "[[:space:]]+")
  target_row <- grep(pattern, target)
  source_row <- grep(pattern, dm_source)
  stopifnot(length(target_row) == 1L, length(source_row) == 1L)
  target[target_row] <- dm_source[source_row]
}

# Estimate the group-specific relative-sample-size exponent from phase 2.
phase2_command <- grep("<<PHASE2[[:space:]]*$", target)
phase2_cest <- grep("^[[:space:]]*-999[[:space:]]+89[[:space:]]+1", dm_source, value = TRUE)
stopifnot(length(phase2_command) == 1L, length(phase2_cest) == 1L)
target <- append(target, phase2_cest, after = phase2_command)

# DM report timing is an output-safety fix, not an optimization phase: suppress
# the early phase-2 report and write it once from the final fitted parameter set.
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
        print "  1 77 " weight "   # MVN regional-scaling penalty weight; sensitivity value"
        next
      }
      { print }
    ' "$destination/model/doitall.sh" > "$destination/model/doitall.sh.new"
    mv "$destination/model/doitall.sh.new" "$destination/model/doitall.sh"
    chmod 0755 "$destination/model/doitall.sh"

    cutoff_text="No observed LF cutoff"
    if [[ "$cutoff_code" == "CUT90" ]]; then
      cutoff_text="F21/F22/F23 observed LF bins above 90 cm set to zero"
    fi

    cat > "$destination/README.md" <<EOF
# BET 2026 $model

This model is part of the focused DM interaction subset in the 18-model
BASE075 regional-scaling-weight sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | BASE075 |
| Selectivity | Exact matched SA28-N5 normal-model settings |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM observation grouping | G5PROC: longline, large-scale PS, domestic PS, other extraction, index |
| DM relative sample-size exponent | CEST: group-specific exponent activated in phase 2 |
| DM maximum LF effective sample size | 10 from phase 1 onward |
| DM tail compression | Retain at least five class intervals |
| Observed LF treatment | $cutoff_text |
| Tag flag column 2 | all tag_flags(:,2) values set to 1 |
| Regional-scaling penalty | MVN, parest flag 81 = 1 |
| Regional-scaling penalty weight | $weight |

All files other than **doitall.sh** are byte-identical to the corresponding
TAGF2ON normal source model at **$SOURCE_COMMIT**. CPUE sigma, selectivity,
regional-scaling inputs, tag and age-length data, and FRQ are unchanged. The DM
likelihood/grouping controls come from **$dm_template** at
**$DM_SOURCE_COMMIT** (**$DM_SOURCE_REF**), but its HAC4 sigma, separate
selectivity-tail changes, and extra stabilization phases are excluded. The
phase-2/final report switch only prevents an early DM report crash; it does not
add an optimization phase. Parest flag 77 is set to $weight.

Status: generated; Kflow has not been submitted.
EOF

    printf '"%s","%s","%s",%s,"%s",1,"","dm_no_re","G5PROC_CEST",10\n' \
      "$model" "$normal_template" "$dm_template" "$weight" "$cutoff_code" >> "$mapping"
  done
done

Rscript - "$ROOT" "$mapping" "$SOURCE_COMMIT" "$DM_SOURCE_COMMIT" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
root <- args[[1L]]
mapping <- read.csv(args[[2L]], stringsAsFactors = FALSE)
source_commit <- args[[3L]]
dm_source_commit <- args[[4L]]

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
  is_dm <- mapping$lf_likelihood[[i]] == "dm_no_re"
  if (is_dm) {
    manifest$source[doitall_row] <- paste0(
      "sensitivity/", mapping$dm_source_model[[i]], "/model/doitall.sh"
    )
    manifest$source_commit[doitall_row] <- dm_source_commit
    manifest$note[doitall_row] <- paste0(
      "Matched DM-noRE doitall using option 11, G5PROC groups, group-specific ",
      "relative sample-size exponent estimated from phase 2, five-class ",
      "minimum tail compression, and Nmax 10 directly from phase 1. The normal ",
      "phase sequence, CPUE sigma, and SA28-N5 selectivity controls are retained; ",
      "HAC4, the separate selectivity-tail experiment, and extra stabilization ",
      "phases are excluded. The report is deferred from phase 2 to the final ",
      "fit for DM output safety. Parest flag 77 is set to ", weight, "."
    )
  } else {
    manifest$note[doitall_row] <- paste0(
      manifest$note[doitall_row],
      " This sensitivity changes only the MVN regional-scaling penalty weight ",
      "from 50 to ", weight, "."
    )
  }

  ini_row <- manifest$role == "ini"
  if (mapping$tag_flag2[[i]] == 1L && !is_dm) {
    manifest$note[ini_row] <- sub(
      "its exact flag-column-2=0 control is [^;]+;",
      paste0("its exact flag-column-2=0 control is ", mapping$tag_control[[i]], ";"),
      manifest$note[ini_row],
      perl = TRUE
    )
  } else if (is_dm) {
    manifest$note[ini_row] <- sub(
      "its exact flag-column-2=0 control is [^;]+;",
      "no DM TAGF2OFF counterpart is included in this focused interaction subset;",
      manifest$note[ini_row],
      perl = TRUE
    )
  }

  context_row <- manifest$role == "design_context"
  manifest$note[context_row] <- paste0(
    "Public 18-model BASE075 regional-scaling-weight design: 12 robust-normal ",
    "models plus six matched TAGF2ON DM G5PROC-CEST Nmax10 models crossing ",
    "NOCUT/CUT90 and weights 25/10/5. SA28-N5 is common and N8 is excluded. ",
    "Normal source commit ", source_commit, "; DM source commit ",
    dm_source_commit, "."
  )
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
}

selection <- data.frame(
  model = mapping$model,
  base_sensitivity = mapping$source_model,
  age_length_variant = "BASE075",
  age_length_source_file = "bet.age_length",
  age_length_sha256 = "e7f591cb39b08a7b381b5e322331d5a4ca17e30008e8b976ae1b73e9111f655d",
  lf_likelihood = mapping$lf_likelihood,
  tail_compression_percent = ifelse(mapping$lf_likelihood == "normal", 1L, NA_integer_),
  dm_tail_min_classes = ifelse(mapping$lf_likelihood == "dm_no_re", 5L, NA_integer_),
  dm_grouping = ifelse(mapping$lf_likelihood == "dm_no_re", "G5PROC", NA_character_),
  dm_concentration = ifelse(mapping$lf_likelihood == "dm_no_re", "estimated_phase2", NA_character_),
  dm_nmax = ifelse(mapping$lf_likelihood == "dm_no_re", mapping$dm_nmax, NA_integer_),
  cutoff_cm = ifelse(mapping$cutoff_code == "CUT90", 90, NA_real_),
  tag_flag2 = mapping$tag_flag2,
  regional_scaling_weight = mapping$regional_scaling_weight,
  selectivity_treatment = "sa28_n5",
  status = "prepared",
  basis = ifelse(
    mapping$lf_likelihood == "normal",
    "Only parest flag 77 differs from the weight-50 source model",
    "Matched normal inputs with direct DM G5PROC-CEST Nmax10 and selected parest flag 77 weight"
  ),
  stringsAsFactors = FALSE
)
write.csv(selection, file.path(root, "SENSITIVITY_SELECTION.csv"), row.names = FALSE, na = "")

labels <- ifelse(
  mapping$lf_likelihood == "dm_no_re",
  paste0(
    "BASE075 ", mapping$cutoff_code,
    " TAGF2ON DM G5PROC-CEST Nmax10 regional-scaling weight ",
    mapping$regional_scaling_weight
  ),
  paste0(
    "BASE075 ", mapping$cutoff_code, " ",
    ifelse(mapping$tag_flag2 == 1L, "TAGF2ON", "TAGF2OFF"),
    " regional-scaling weight ", mapping$regional_scaling_weight
  )
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
  lf_likelihood = mapping$lf_likelihood,
  dm_grouping = ifelse(mapping$lf_likelihood == "dm_no_re", "G5PROC", NA_character_),
  dm_concentration = ifelse(mapping$lf_likelihood == "dm_no_re", "estimated_phase2", NA_character_),
  dm_nmax = ifelse(mapping$lf_likelihood == "dm_no_re", mapping$dm_nmax, NA_integer_),
  regional_scaling_weight = mapping$regional_scaling_weight,
  major_step = "Regional scaling",
  substep = ifelse(
    mapping$lf_likelihood == "dm_no_re",
    paste0("DM Nmax10 weight ", mapping$regional_scaling_weight),
    paste0("Weight ", mapping$regional_scaling_weight)
  ),
  change_axis = ifelse(
    mapping$lf_likelihood == "dm_no_re",
    "lf_likelihood+regional_scaling_weight",
    "regional_scaling_weight"
  ),
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
config_lines <- sub("[[:space:]]+$", "", config_lines)
writeLines(config_lines, file.path(root, "job-config.R"), useBytes = TRUE)
RS

first_model="S001-TC1-NOCUT-BASE075-TAGF2OFF-REGW25"
perl -0pi -e 's/STEP_SELECT: "[^"]+"/STEP_SELECT: "'"$first_model"'"/; s/JOB_TITLE: "[^"]+"/JOB_TITLE: "BET 2026 regional-scaling sensitivity fit"/; s/JOB_DESCRIPTION: "[^"]+"/JOB_DESCRIPTION: "Run one BASE075 regional-scaling-weight sensitivity model."/; s/MODEL_LABEL: "[^"]+"/MODEL_LABEL: "BASE075 NOCUT TAGF2OFF regional-scaling weight 25"/; s/JOB_KEY: [^\n]+/JOB_KEY: s001-base075-nocut-tagf2off-regw25/; s/FLOW_GROUP: [^\n]+/FLOW_GROUP: bet-2026-base075-regional-scaling-weights-20260720/' "$ROOT/kflow.yaml"

cat > "$ROOT/README.md" <<EOF
# BET 2026 BASE075 regional-scaling-weight sensitivities

This branch contains 18 MFCL models. The 12 robust-normal models are derived
from **$SOURCE_REPO@$SOURCE_COMMIT** (**$SOURCE_REF**). Six focused DM models
also use the tested G5PROC-CEST Nmax10 implementation from
**$SOURCE_REPO@$DM_SOURCE_COMMIT** (**$DM_SOURCE_REF**). Every model retains
the corrected SA28-N5 BASE075 structure; N8 is excluded.

## Purpose

The source models use MVN regional-scaling penalty weight 50. This design
changes only parest flag 77 to 25, 10, or 5, allowing progressively more
freedom in relative biomass allocation among regions. Regional-scaling inputs,
flags 78-81, the 1965-1969 target/covariance window, CPUE observations and
sigma, phase timing, LF settings, tag inputs, age-length data, and selectivity
are held fixed.

The six DM models provide a focused interaction check at TAGF2ON across
NOCUT/CUT90 and the same three regional-scaling weights. They start directly at
Nmax 10 and retain the normal-model phase sequence, CPUE sigma, selectivity,
and all non-doitall inputs. HAC4 sigma, the separate selectivity-tail
experiment, and extra DM stabilization phases from the implementation source
are excluded. The phase-2/final report switch is retained only to avoid the
known early DM report failure. DM Nmax10 reduces composition influence and may
therefore increase the relative influence of CPUE indices; this subset is a
diagnostic interaction rather than an assumed remedy for index conflict.

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
| S013-S015 | NOCUT, DM G5PROC-CEST Nmax10 | 1 | 25, 10, 5 |
| S016-S018 | CUT90, DM G5PROC-CEST Nmax10 | 1 | 25, 10, 5 |

Relative to weight 50, weights 25, 10, and 5 increase the prior standard
deviation by approximately sqrt(2), sqrt(5), and sqrt(10), respectively. The
weight-50 controls remain on the source branch and are not duplicated here.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated models are under **sensitivity/**; exact input provenance is recorded
in each model's **input_manifest.csv**.
EOF

printf 'Generated %s regional-scaling sensitivity models.\n' "$number"
