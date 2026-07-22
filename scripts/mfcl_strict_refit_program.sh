#!/usr/bin/env bash
set -euo pipefail

real_program="${MFCL_REAL_PROGRAM_PATH:-/home/mfcl/mfclo64}"
neval="${MFCL_STRICT_NEVAL:-20000}"
convergence="${MFCL_STRICT_CONVERGENCE:--5}"

if [[ ! -x "$real_program" ]]; then
  echo "MFCL executable is not available: $real_program" >&2
  exit 1
fi
if [[ ! "$neval" =~ ^[1-9][0-9]*$ ]]; then
  echo "MFCL_STRICT_NEVAL must be a positive integer." >&2
  exit 1
fi
if [[ ! "$convergence" =~ ^-[0-9]+$ ]]; then
  echo "MFCL_STRICT_CONVERGENCE must be a negative integer exponent." >&2
  exit 1
fi
if (( $# < 3 )); then
  echo "Expected MFCL arguments: frequency file, input PAR, output PAR." >&2
  exit 1
fi

"$real_program" "$@" -file - <<EOF
  1 1 $neval
  1 50 $convergence
  1 246 1
EOF
