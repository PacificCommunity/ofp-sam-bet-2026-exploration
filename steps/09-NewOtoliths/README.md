# 09 NewOtoliths

New Japanese otoliths and 2026 CAAL input on the regional CPUE model.

## What Changed

- Uses the same regional CPUE `.frq`, 2026 `.ini`, and 2026 `.tag` as 08-RegionalCPUE.
- Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.
- The 2026 age_length file includes the new otolith data used for this step.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `.frq`: `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE
- `.ini`: `bet.2026.ini`, FixM M row applied; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; normalized tag flags marker; padded existing MFCL 1007 tag flags from 91 to 98 release groups with 2 mixing periods and reporting rates excluded during mixing; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates
- `.tag`: `bet.2026.low.recaps.removed.tag`
- `.age_length`: `bet.2026.age_length` (updated CAAL/new otoliths)
- `.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `db75a05` - updated frq files based on updated stepwise
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 08-RegionalCPUE controls retained.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; flags 77-81 configure the regional-scaling MVN prior.
- The regional-scaling penalty weight is 50 (`parest_flags(77)=50`); the inline control comment records this as approximately CV 0.1.
- The active `bet.reg_scaling` window is periods 53-72 (1965-1969) because the global CPUE covariance matrices were estimated from data fitted over 1965 through the end of 1969, the period with the highest spatial-temporal coverage.
- For the 292-period full-2024 models, `parest_flags(79)=240` means `292 - 240 + 1 = 53` and `parest_flags(80)=220` means `292 - 220 = 72`, so the regional-scaling prior is limited to that covariance-estimation window.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep the 2026 index-fishery sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.

## Run Note

- Generated inputs repair only the `.ini` alignment where needed: tag reporting-rate matrices, explicit tag flags, and tag shed rates are matched to the selected release-group count.
- The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows are deleted to suppress warnings.
- These steps use the current tuna-flow MFCL executable and the 04-NewStructure 5-region controls unless a later step explicitly changes controls.

## Outstanding Checks

- After fitting, compare CAAL likelihood and age residuals against 08-RegionalCPUE.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
