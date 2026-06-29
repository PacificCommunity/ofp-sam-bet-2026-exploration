# 03 FixM

NewExe baseline with the FixM M-scale row applied at the 2023 MLE value.

## What Changed

- Uses the 2023 diagnostic 9-region, 41-fishery inputs ending in 2021.
- `bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader while retaining the diagnostic values.
- The current-executable `doitall.sh` controls match the existing stepwise diagnostic baseline: initial Z uses `2 94 1 2 128 100`, and survey CPUE CV settings are the current BET 2023 values.
- Applies the FixM M-scale row at the 2023 MLE value.

## Inputs

- `.frq`: 2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021
- `.ini`: 2023 diagnostic ini promoted for the current reader FixM M row applied; set ini version to 1007; inserted MFCL 1007 tag flags for 118 release groups with 2 mixing periods and reporting rates excluded during mixing; inserted zero tag shed-rate vector for 118 release groups; inserted MFCL 1007 total-population scalar default 25; inserted MFCL 1007 Richards growth parameter default 0
- `.tag`: 2023 diagnostic tag input
- `.age_length`: 2023 diagnostic CAAL input
- `input_manifest.csv`: machine-readable source/input notes with source commits

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `db75a05` - updated frq files based on updated stepwise
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- The current MFCL executable `/home/mfcl/mfclo64` is used.
- The step output includes the 2023 nine-region GeoJSON asset as a display-only map asset; it does not change MFCL inputs.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- This step should continue to match the previously generated 2026 stepwise diagnostic baseline.
- No fishery, tag, CAAL, or CPUE update is intended in this step.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
