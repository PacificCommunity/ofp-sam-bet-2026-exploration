# 09 NewOtoliths

New Japanese otoliths and 2026 CAAL input on the regional CPUE model.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/09-NewOtoliths/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same regional CPUE `.frq`, latest 2026 tag-reporting matrices, and 2026 `.tag` as 08-RegionalCPUE. |
| 2 | Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`. |
| 3 | The 2026 age_length file includes the new otolith data used for this step. |
| 4 | Applies FixM M row from the 01-Diag2023 mgc=-5 diagnostic final par to the 2026 ini. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.ini` with RR/active/target/penalty matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; harmonized initial RR values only in 1 tag reporting-rate group(s) so grouped starts are native-MFCL compatible; group flags, targets, and penalties unchanged; normalized MFCL 1007 tag-control rows for 98 release groups |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR groups and canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL/new otoliths); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | Full `bet.2026.reg_scaling` global CPUE regional-scaling matrix; parest flags select active periods 53-72 (1965-1969) for the prior |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | No generated edit; full 2024 regional-CPUE source is used. | Catch, effort, CPUE, and composition records from the selected source. |
| `.ini` | Copies latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, applies fixed M, and validates positive recapture cells. | Two-quarter tag mixing for all release groups. |
| `.tag` | No generated edit. | 2026 low-recapture-removed source tag file. |
| `.age_length` | Switches to the 2026 CAAL source and changes effective sample size from `1` to `0.75`. | 2026 CAAL records themselves. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `f8faf7c` | updated RR groupings |
| `ofp-sam-2026-BET-YFT-tag-prep` | `e0b427d` | updated RR groups |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | 08-RegionalCPUE controls retained. |
| 2 | The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period. |
| 3 | The latest 2026 RR, active, target, and penalty matrices are copied from `bet.2026.mix-0.2.ini` before final alignment checks. |
| 4 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 5 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 6 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 7 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Generated inputs only repair `.ini` alignment: reporting-rate matrices, tag flags, and shed rates are matched to the selected release-group count. |
| 2 | The latest `bet.2026.low.recaps.removed.tag` is kept; the tag build assigns missing-gear canneries recaptures to purse-seine before low-recap filtering. |
| 3 | The latest 2026 reporting-rate, active, target, and penalty matrices are copied from the mix-period ini source before Kflow runs. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, compare CAAL likelihood and age residuals against 08-RegionalCPUE. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
