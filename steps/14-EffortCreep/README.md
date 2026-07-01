# 14 EffortCreep

Apply the lower effort-creep level in the diagnostic model path.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/14-EffortCreep/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses 13-LengthBasedSel controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`. |
| 2 | Retains the `69-01-50-50` OPR setting and time-varying CPUE CV controls. |
| 3 | The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024. |
| 4 | Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE, with index effort creep applied |
| `.ini` | `bet.2026.mix-0.2.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0 |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build, including canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions |
| `input_manifest.csv` | machine-readable source/input notes |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `d884ce5` | remove len comps from LL from 2023.new.structure |
| `ofp-sam-2026-BET-YFT-build-ini` | `b39cbfd` | updated ini files to reflect updated tag files |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | assign unassigned gear to PS from canneries |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |

## Controls

| # | Control |
| --- | --- |
| 1 | 13-LengthBasedSel controls are retained. |
| 2 | No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`. |
| 3 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 4 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 5 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 6 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag flags, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | The effort-creep `.frq` is generated from the full 2024 regional CPUE source by changing only positive effort values for index fisheries 29-33. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, review index residuals and implied CPUE scaling against 13-LengthBasedSel. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
