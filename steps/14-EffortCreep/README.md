# 14 EffortCreep

Apply the lower effort-creep level in the diagnostic model path.

## What Changed

- Uses 13-LengthBasedSel controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.
- Retains the `69-01-50-50` OPR setting and time-varying CPUE CV controls.
- The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.
- Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched.

## Inputs

- `.frq`: `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE, with index effort creep applied
- `.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0; set tag_flags(it,2)=0 for 98 release groups so reporting rates are retained in predicted tag catches during mixing
- `.tag`: `bet.2026.low.recaps.removed.tag`
- `.age_length`: `bet.2026.age_length` (updated CAAL); set age_length effective sample size to 0.75 for 181 records
- `.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `d884ce5` - remove len comps from LL from 2023.new.structure
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 13-LengthBasedSel controls are retained.
- No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`.
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

- The mix-period ini family carries release-group-specific tag controls, so generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive mixing periods while retaining reporting rates in predicted tag catches.
- Generation validates that tag flags, tag shed rate, and the five tag reporting-rate matrices match the selected release-group count.
- Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0.
- The effort-creep `.frq` is generated from the full 2024 regional CPUE source by changing only positive effort values for index fisheries 29-33.

## Outstanding Checks

- After fitting, review index residuals and implied CPUE scaling against 13-LengthBasedSel.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
