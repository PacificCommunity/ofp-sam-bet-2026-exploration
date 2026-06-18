#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT_DIR="${OUTPUT_DIR:-outputs}"
WORK_DIR="${ROOT}/work"
PROGRAM_PATH="${PROGRAM_PATH:-/home/mfcl/mfclo64}"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"
rm -rf "${WORK_DIR}/inputs"
mkdir -p "${WORK_DIR}/inputs"

echo "BET stepwise task"
echo "Bundled input: mfcl/inputs/2023_4region_1007"
echo "MFCL program: ${PROGRAM_PATH}"

if [[ ! -d "${ROOT}/mfcl/inputs/2023_4region_1007" ]]; then
  echo "Missing bundled MFCL input folder: mfcl/inputs/2023_4region_1007" >&2
  exit 2
fi

cp -a "${ROOT}/mfcl" "${WORK_DIR}/inputs/"
if [[ -d "${ROOT}/metadata" ]]; then
  cp -a "${ROOT}/metadata" "${WORK_DIR}/inputs/"
fi

Rscript R/run_stepwise.R
