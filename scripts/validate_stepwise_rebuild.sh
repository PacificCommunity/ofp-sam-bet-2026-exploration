#!/usr/bin/env bash

# Validate the intended BET 2026 stepwise rebuild boundaries.
#
# Usage:
#   scripts/validate_stepwise_rebuild.sh [repository-root]
#
# The optional repository root makes it possible to run this validator against
# a staged rebuild or a fixture. By default it validates the checkout that
# contains this script.

set -uo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=${1:-"$(CDPATH= cd -- "$script_dir/.." && pwd)"}
steps_root="$repo_root/steps"
failures=0
checks=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

pass() {
  checks=$((checks + 1))
}

require_doitall() {
  local step=$1
  doitall_path="$steps_root/$step/model/doitall.sh"

  if [[ ! -f "$doitall_path" ]]; then
    fail "$step: missing model/doitall.sh"
    return 1
  fi
}

# Print the values from matching MFCL control triplets. Comments are removed
# first, and lines containing multiple triplets are handled three fields at a
# time (for example: -20 16 0  -20 3 37).
setting_values() {
  local path=$1
  local owner=$2
  local flag=$3

  awk -v owner="$owner" -v flag="$flag" '
    {
      sub(/#.*/, "")
      for (i = 1; i + 2 <= NF; i += 3) {
        if ($i == owner && $(i + 1) == flag) {
          print $(i + 2)
        }
      }
    }
  ' "$path"
}

has_setting_value() {
  local path=$1
  local owner=$2
  local flag=$3
  local expected=$4
  local value

  while IFS= read -r value; do
    if [[ "$value" == "$expected" ]]; then
      return 0
    fi
  done < <(setting_values "$path" "$owner" "$flag")

  return 1
}

assert_exact_setting() {
  local step=$1
  local path=$2
  local owner=$3
  local flag=$4
  local expected=$5
  local label=$6
  local -a values=()

  mapfile -t values < <(setting_values "$path" "$owner" "$flag")
  if (( ${#values[@]} != 1 )); then
    fail "$step: expected exactly one $label=$expected; found ${#values[@]} (${values[*]:-none})"
  elif [[ "${values[0]}" != "$expected" ]]; then
    fail "$step: expected $label=$expected; found ${values[0]}"
  else
    pass
  fi
}

assert_target_pair_absent() {
  local step=$1
  local path=$2
  local fishery=$3
  local flag_a=$4
  local value_a=$5
  local flag_b=$6
  local value_b=$7
  local label=$8

  if has_setting_value "$path" "-$fishery" "$flag_a" "$value_a" &&
     has_setting_value "$path" "-$fishery" "$flag_b" "$value_b"; then
    fail "$step: reviewed $label change is present before its intended boundary"
  else
    pass
  fi
}

assert_target_setting_absent() {
  local step=$1
  local path=$2
  local fishery=$3
  local flag=$4
  local value=$5
  local label=$6

  if has_setting_value "$path" "-$fishery" "$flag" "$value"; then
    fail "$step: reviewed $label change is present before its intended boundary"
  else
    pass
  fi
}

validate_reviewed_selectivity() {
  local step=$1
  local path=$2

  assert_exact_setting "$step" "$path" -20 16 0 'F20 flag 16'
  assert_exact_setting "$step" "$path" -20 3 37 'F20 flag 3'
  assert_exact_setting "$step" "$path" -28 16 0 'F28 flag 16'
  assert_exact_setting "$step" "$path" -28 3 37 'F28 flag 3'
  assert_exact_setting "$step" "$path" -26 75 1 'F26 flag 75'
  assert_exact_setting "$step" "$path" -12 75 2 'F12 flag 75'
  assert_exact_setting "$step" "$path" -17 16 2 'F17 flag 16'
  assert_exact_setting "$step" "$path" -17 3 6 'F17 flag 3'
}

validate_no_review_leakage() {
  local step=$1
  local path=$2

  assert_target_pair_absent "$step" "$path" 20 16 0 3 37 F20
  assert_target_pair_absent "$step" "$path" 28 16 0 3 37 F28
  assert_target_setting_absent "$step" "$path" 26 75 1 F26
  assert_target_pair_absent "$step" "$path" 12 75 2 24 12 F12
  assert_target_pair_absent "$step" "$path" 17 16 2 3 6 F17

  # F12 flag 75=2 already occurs in the legacy 01-03 fishery mapping, so it is
  # not a standalone leakage signal there. Pairing it with selectivity group 12
  # distinguishes reviewed new-structure F12 from legacy F12 (group 6).
}

validate_step04_baseline() {
  local step=$1
  local path=$2

  validate_no_review_leakage "$step" "$path"
  assert_target_setting_absent "$step" "$path" 12 75 2 F12
}

validate_opr_exact() {
  local step=$1
  local path=$2

  # Owner 1 denotes an active parest flag. Owner 2 entries with the same flag
  # number belong to other MFCL flag families and are intentionally ignored.
  # Repeated values across phases are allowed. A zero may stage a control in an
  # earlier phase, but every non-zero value and the final effective value must
  # equal the reviewed target.
  assert_effective_active_setting "$step" "$path" 155 72 'OPR pf155'
  assert_effective_active_setting "$step" "$path" 221 72 'reference-par pf221'
  assert_effective_active_setting "$step" "$path" 202 2 'OPR pf202'
  assert_effective_active_setting "$step" "$path" 216 50 'OPR pf216'
  assert_effective_active_setting "$step" "$path" 217 1 'OPR pf217'
  assert_effective_active_setting "$step" "$path" 218 50 'OPR pf218'
  assert_effective_active_setting "$step" "$path" 397 100 'OPR pf397'
}

assert_effective_active_setting() {
  local step=$1
  local path=$2
  local flag=$3
  local expected=$4
  local label=$5
  local -a values=()
  local -a unexpected=()
  local value
  local final

  mapfile -t values < <(setting_values "$path" 1 "$flag")
  if (( ${#values[@]} == 0 )); then
    fail "$step: expected $label=$expected; found no parest flag $flag entries"
    return
  fi

  for value in "${values[@]}"; do
    if [[ "$value" != 0 && "$value" != "$expected" ]]; then
      unexpected+=("$value")
    fi
  done

  final=${values[$(( ${#values[@]} - 1 ))]}
  if (( ${#unexpected[@]} > 0 )); then
    fail "$step: expected all active $label values to equal $expected; found ${unexpected[*]} (sequence: ${values[*]})"
  elif [[ "$final" != "$expected" ]]; then
    fail "$step: expected final effective $label=$expected; found $final (sequence: ${values[*]})"
  else
    pass
  fi
}

assert_not_active() {
  local step=$1
  local path=$2
  local flag=$3
  local -a values=()
  local -a active=()
  local value

  mapfile -t values < <(setting_values "$path" 1 "$flag")
  for value in "${values[@]}"; do
    if [[ "$value" != 0 ]]; then
      active+=("$value")
    fi
  done

  if (( ${#active[@]} > 0 )); then
    fail "$step: active OPR pf$flag must not appear before Step 12; found ${active[*]}"
  else
    pass
  fi
}

validate_no_opr() {
  local step=$1
  local path=$2
  local flag

  for flag in 155 202 216 217 218 221 397; do
    assert_not_active "$step" "$path" "$flag"
  done
}

legacy_steps=(
  01-Diag2023
  02a-NewExe
  02b-Ini1007
  02c-LengthWeight
  03-FixM
)

reviewed_steps=(
  04a-SelectivityReview
  05-ConvertToLength
  06-LengthPlusLength
  07-DataTo2024
  08-RegionalCPUE
  09-NewOtoliths
  10-TagMixingKS
  11-TimeVaryingCV
  12-OrthogonalPoly
  13-LengthBasedSel
  14-EffortCreep
  15-DataWeighting
)

pre_opr_steps=(
  01-Diag2023
  02a-NewExe
  02b-Ini1007
  02c-LengthWeight
  03-FixM
  04-NewStructure
  04a-SelectivityReview
  05-ConvertToLength
  06-LengthPlusLength
  07-DataTo2024
  08-RegionalCPUE
  09-NewOtoliths
  10-TagMixingKS
  11-TimeVaryingCV
)

opr_steps=(
  12-OrthogonalPoly
  13-LengthBasedSel
  14-EffortCreep
  15-DataWeighting
)

for step in "${legacy_steps[@]}"; do
  if require_doitall "$step"; then
    validate_no_review_leakage "$step" "$doitall_path"
  fi
done

if require_doitall 04-NewStructure; then
  validate_step04_baseline 04-NewStructure "$doitall_path"
fi

for step in "${reviewed_steps[@]}"; do
  if require_doitall "$step"; then
    validate_reviewed_selectivity "$step" "$doitall_path"
  fi
done

for step in "${pre_opr_steps[@]}"; do
  if require_doitall "$step"; then
    validate_no_opr "$step" "$doitall_path"
  fi
done

for step in "${opr_steps[@]}"; do
  if require_doitall "$step"; then
    validate_opr_exact "$step" "$doitall_path"
    if ! bash -n "$doitall_path"; then
      fail "$step: doitall.sh does not pass bash syntax validation"
    elif ! grep -Fq '$program_path bet.frq 11.par 12.par -file - <<PHASE12' "$doitall_path"; then
      fail "$step: missing independent 11.par -> 12.par terminal-penalty refinement"
    else
      pass
    fi
  fi
done

for file in bet.frq bet.ini bet.tag bet.age_length; do
  if cmp -s \
    "$steps_root/04-NewStructure/model/$file" \
    "$steps_root/04a-SelectivityReview/model/$file"; then
    pass
  else
    fail "04a-SelectivityReview: $file differs from the 04-NewStructure input"
  fi
done

if (( failures > 0 )); then
  printf '\nValidation failed: %d issue(s), %d passing assertion(s).\n' "$failures" "$checks" >&2
  exit 1
fi

printf 'Validation passed: %d assertions across the rebuilt step boundaries.\n' "$checks"
