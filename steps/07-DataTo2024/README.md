# 07 DataTo2024

Data to 2024, global CPUE, isolating the effect of adding three years of data.

## What Changed

- Uses `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq` without year chopping.
- Moves from the 2021 transition steps to the full 2024 frequency/catch/size series.
- Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths.
- Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604.

## Inputs

- `.frq`: `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq`, full 2024 with global CPUE
- `.ini`: `bet.2026.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; set total population scaling factor LN(R0) from 17 to 21; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; normalized tag flags marker; padded existing MFCL 1007 tag flags from 91 to 98 release groups with 2 mixing periods and reporting rates retained during mixing; set tag_flags(it,2)=0 for 91 release groups so reporting rates are retained in predicted tag catches during mixing; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates
- `.tag`: `bet.2026.low.recaps.removed.tag`
- `.age_length`: `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `d884ce5` - remove len comps from LL from 2023.new.structure
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 04-NewStructure 5-region `doitall.sh` controls retained.
- The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period.
- `tag_flags(it,2)` is set to 0 for the 2026 tag setup so reporting rates are retained in predicted tag catches during mixing.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- Generated inputs repair only the `.ini` alignment where needed: tag reporting-rate matrices, explicit tag flags, and tag shed rates are matched to the selected release-group count.
- The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows are deleted to suppress warnings.
- These 2026 data steps keep `tag_flags(it,1)=2` in the ini for the two-quarter mixing period and set `tag_flags(it,2)=0` so reporting rates remain in predicted tag catches during mixing.
- These steps use the current tuna-flow MFCL executable and the 04-NewStructure 5-region controls unless a later step explicitly changes controls.

## Outstanding Checks

- Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
