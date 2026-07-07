# 10 TagMixingKS

KS coefficient 0.2 release-group-specific tag mixing periods.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/10-TagMixingKS/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses `bet.2026.mix-0.2.ini` from the ini-build repo. |
| 2 | Keeps the full 2024 regional CPUE `.frq`, 2026 tag file, and updated 2026 CAAL. |
| 3 | Applies FixM M row from the 01-Diag2023 mgc=-5 diagnostic final par to the mix-period ini. |
| 4 | Removes the inherited `-9999 1 2` line from `doitall.sh` so release-group-specific mixing-period values in the ini are not overwritten. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.mix-0.2.ini`, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; raised 2 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0; normalized MFCL 1007 tag-control rows for 98 release groups |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR groups and canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | Full `bet.2026.reg_scaling` global CPUE regional-scaling matrix; parest flags select active periods 53-72 (1965-1969) for the prior |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | No generated edit; full 2024 regional-CPUE source is used. | Catch, effort, CPUE, and composition records from the selected source. |
| `.ini` | Uses release-specific mixing and latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, raises source zero mixing periods to `1`, applies fixed M, and validates positive recapture cells. | Positive release-specific mixing values and RR matrix structure. |
| `.tag` | No generated edit. | 2026 low-recapture-removed source tag file. |
| `.age_length` | Changes effective sample size from `1` to `0.75`. | 2026 CAAL records themselves. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `386d169` | Correct RR init values |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` | Correct RR group init values |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The all-release-group mixing-period override is removed. |
| 2 | All other 08-RegionalCPUE fishery, tag recapture, selectivity, and regional-scaling controls are retained. |
| 3 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 4 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 5 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 6 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag-control dimensions, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, inspect tag residuals and release-group behavior before tuning tag-reporting assumptions further. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
