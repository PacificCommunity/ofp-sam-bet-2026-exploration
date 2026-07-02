# 11 TimeVaryingCV

Enable time-varying CPUE CV for the regional index fisheries.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/11-TimeVaryingCV/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same inputs as 10-TagMixingKS. |
| 2 | Sets the index-fishery time-varying CPUE CV flag from 0 to 1 in `doitall.sh`. |
| 3 | No fishery, tag, CAAL, or `.frq` source changes are made in this step. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.mix-0.2.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; filled fishery 19 reporting-rate cells for positive tag recaptures from fishery 21 settings in release groups 19-21,31,35,40; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0; normalized MFCL 1007 tag-control rows for 98 release groups |
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
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The all-release-group mixing-period override remains removed. |
| 2 | Index fisheries 29-33 have fish flag 66 set to 1 for time-varying CPUE CV. |
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
| 4 | Positive fishery 19 tag recaptures with inactive zero reporting-rate cells are assigned the matching fishery 21 reporting-rate settings. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, compare CPUE residuals and estimated CV behavior against 10-TagMixingKS. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
