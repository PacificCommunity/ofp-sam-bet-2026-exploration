#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT_DIR="${OUTPUT_DIR:-outputs}"
WORK_DIR="${ROOT}/work"
PROGRAM_PATH="${PROGRAM_PATH:-/home/mfcl/mfclo64}"

runtime_packages_enabled() {
  case "${KFLOW_RUNTIME_PACKAGES:-}" in
    ""|0|false|FALSE|no|NO|off|OFF|none|NONE|skip|SKIP) return 1 ;;
    *) return 0 ;;
  esac
}

prepare_runtime_packages() {
  runtime_packages_enabled || return 0
  export R_LIBS_USER="${R_LIBS_USER:-${ROOT}/.R-library}"
  export KFLOW_RUNTIME_LIBRARY="${KFLOW_RUNTIME_LIBRARY:-${R_LIBS_USER}}"
  export KFLOW_RUNTIME_STATE_DIR="${KFLOW_RUNTIME_STATE_DIR:-${ROOT}/.kflow-runtime-cache}"
  mkdir -p "${R_LIBS_USER}" "${KFLOW_RUNTIME_STATE_DIR}"
  if [[ -x /usr/local/bin/30-update-kflow-runtime-packages ]]; then
    bash /usr/local/bin/30-update-kflow-runtime-packages
  else
    echo "[kflow-runtime-update] Runtime updater not found; using bundled packages." >&2
  fi
}

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

prepare_runtime_packages
Rscript R/run_stepwise.R
