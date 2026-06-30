# 01 Diag2023

Original BET 2023 diagnostic model rerun with the historical MFCL executable.

## What Changed

- Copies the 2023 diagnostic `MFCL` model files without changing the model inputs.
- `bet.ini` remains in its original 2023 diagnostic format for the historical `mfclo64` reader.
- `doitall.sh` keeps the historical diagnostic control sequence while allowing `BET_PHASE10_11_CONVERGENCE` to set PHASE 10/11 convergence from Kflow.
- The runner supplies a temporary `mfclo64` PATH shim pointing to `/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0`.
- This step is the direct reproducibility anchor before moving to the current executable.

## Inputs

- `.frq`: original 2023 diagnostic frequency/catch/size input
- `.ini`: original 2023 diagnostic ini, not promoted to MFCL 1007
- `.tag`: original 2023 diagnostic tag input
- `.age_length`: original 2023 diagnostic CAAL input
- `input_manifest.csv`: machine-readable source/input notes with source commits

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `db75a05` - updated frq files based on updated stepwise
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- The model files come from `ofp-sam-bet-2023-diagnostic/MFCL`.
- The step-specific executable path is set in `job-config.R`; only this step uses the historical MFCL binary.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict archival comparisons can set `-5` without editing model folders.
- No FixM, new-executable compatibility edits, new fishery structure, or 2026 input files are applied here.

## Outstanding Checks

- Compare this rerun against the archived 2023 diagnostic output before interpreting later deltas.
- Apart from the PHASE 10/11 convergence switch, failures will reflect the original diagnostic control sequence.

## Status

Ready for Kflow with the tuna-flow image that includes the historical 2023 diagnostic MFCL executable.
