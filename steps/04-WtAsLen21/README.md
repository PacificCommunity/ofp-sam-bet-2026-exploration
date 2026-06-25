# 04 WtAsLen21

Transition step using 2026 weights-as-lengths size/catch data chopped to 2021, while retaining the 2023 new-structure CPUE/index records.

## What Changed

- Builds a hybrid `bet.frq`: non-index records come from `bet.2026.wt.as.len.frq` chopped to year <= 2021, while index fisheries 29-33 are replaced with CPUE records from `bet.2023.new.structure.frq`.
- This isolates the weights-to-lengths transition without also switching the CPUE/index data to the 2026 regional index series.
- Keeps the 03-RegFish 96-release tag/ini structure because this step remains a 2021-terminal comparison.
- Resets the chopped `.frq` tag-group header from the 2026 source count to 96 to match the selected tag file.
- Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.
- Applies the FixM M row to the 03-RegFish-compatible ini.

## Inputs

- `.frq`: hybrid of `bet.2026.wt.as.len.frq` chopped to 2021 for non-index size/catch records, plus index fisheries 29-33 copied from `bet.2023.new.structure.frq`; tag-group header reset to 96
- `.ini`: `steps/03-RegFish/model/bet.ini`, FixM M row applied
- `.tag`: `steps/03-RegFish/model/bet.tag`
- `.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `7d636e8` - update frq files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 96-release tag set.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- The first implementation chopped the 2026 `.frq` directly, which also carried the 2026 CPUE/index records. The corrected transition keeps the 2023 new-structure CPUE/index records for fisheries 29-33.
- Kflow failed when this 2021-chopped `.frq` was paired with the full 2026 tag/ini family; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.
- To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's 96-release setup, and the chopped `.frq` tag-group header is reset to 96.
- No tag release or recapture rows were deleted to silence warnings; this step only changes which already-prepared input family is paired with the chopped 2026 size/catch records.
- Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03.

## Outstanding Checks

- After fitting, compare directly with 03-RegFish to isolate the effect of converting weights to lengths while CPUE/index data are held constant.
- Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
