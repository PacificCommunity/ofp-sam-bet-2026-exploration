#!/usr/bin/env bash
set -euo pipefail

real_program="${MFCL_REAL_PROGRAM_PATH:-/home/mfcl/mfclo64}"
neval="${MFCL_STRICT_NEVAL:-20000}"
convergence="${MFCL_STRICT_CONVERGENCE:--5}"
minimizer="${MFCL_STRICT_MINIMIZER:-1}"
memory_steps="${MFCL_STRICT_MEMORY_STEPS:-400}"
angle_bound="${MFCL_STRICT_ANGLE_BOUND:-0}"

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
if [[ ! "$minimizer" =~ ^[012]$ ]]; then
  echo "MFCL_STRICT_MINIMIZER must be 0, 1, or 2." >&2
  exit 1
fi
if [[ ! "$memory_steps" =~ ^[1-9][0-9]*$ ]]; then
  echo "MFCL_STRICT_MEMORY_STEPS must be a positive integer." >&2
  exit 1
fi
if [[ ! "$angle_bound" =~ ^[0-9]+$ ]] || (( angle_bound > 90 )); then
  echo "MFCL_STRICT_ANGLE_BOUND must be an integer from 0 to 90." >&2
  exit 1
fi
if (( $# < 3 )); then
  echo "Expected MFCL arguments: frequency file, input PAR, output PAR." >&2
  exit 1
fi

"$real_program" "$@" -file - <<EOF
  1 1 $neval
  1 50 $convergence
  1 351 $minimizer
  1 192 $memory_steps
  1 352 $angle_bound
  1 246 1
EOF
