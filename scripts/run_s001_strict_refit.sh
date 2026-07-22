#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

export STEP_SELECT="${STEP_SELECT:-S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26}"
export MODEL_ROOT="${MODEL_ROOT:-sensitivity}"
export RUN_MODE="job_par"
export PAR_SOURCE_JOB="${PAR_SOURCE_JOB:-12774}"
export STEPWISE_PAR_SOURCE_JOB="$PAR_SOURCE_JOB"
export OUTPUT_PAR="${OUTPUT_PAR:-final.par}"
export PROGRAM_PATH="$repo_root/scripts/mfcl_strict_refit_program.sh"
export MFCL_REAL_PROGRAM_PATH="${MFCL_REAL_PROGRAM_PATH:-/home/mfcl/mfclo64}"
export MFCL_STRICT_NEVAL="${MFCL_STRICT_NEVAL:-20000}"
export MFCL_STRICT_CONVERGENCE="${MFCL_STRICT_CONVERGENCE:--5}"
export STEPWISE_BUILD_PAYLOAD="true"
export STEPWISE_SAVE_RAW_MFCL_INPUTS="true"
export STEPWISE_SAVE_FINAL_PAR="false"
export STEPWISE_SINGLE_PAR_REPORT="true"
export MFCL_LIVE_LOG="${MFCL_LIVE_LOG:-true}"

exec bash run.sh
