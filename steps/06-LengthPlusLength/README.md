# 06 LengthPlusLength

Data to 2021, global CPUE, adding length compositions that were not used in the past.

## What Changed

- Uses `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq` from the frq-build repo.
- Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the additional length-composition data.
- Applies the FixM M row through the inherited 04-NewStructure ini.

## Inputs

- `.frq`: `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq`; terminal year 2021, global CPUE
- `.ini`: `steps/04-NewStructure/model/bet.ini`, FixM M row applied
- `.tag`: `steps/04-NewStructure/model/bet.tag`
- `.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `db75a05` - updated frq files based on updated stepwise
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 04-NewStructure 5-region `doitall.sh` controls retained.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- Compare directly with 05-ConvertToLength to isolate the extra length-composition records.

## Outstanding Checks

- Review fit impacts before deciding whether length-composition weighting needs adjustment.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
