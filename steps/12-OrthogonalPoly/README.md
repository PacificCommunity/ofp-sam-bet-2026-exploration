# 12 OrthogonalPoly

Orthogonal polynomial recruitment step, ensuring `2 177 0` is used.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/12-OrthogonalPoly/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same inputs as 11-TimeVaryingCV. |
| 2 | Applies the BET OPR screening rank-1 model: `69-01-50-50`. |
| 3 | Keeps time-varying CPUE CV enabled for index fisheries 29-33. |
| 4 | OPR controls are applied in PHASE 3 of `doitall.sh`, including `2 177 0`. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
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
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | Time-varying CPUE CV flags are retained. |
| 2 | `1 149 0`, `1 398 0`, `1 400 0`, `2 177 0`, `2 32 0`, and `2 113 0` are applied at PHASE 3 for the OPR transfer. |
| 3 | `1 155 69`, `1 217 1`, `1 216 50`, and `1 218 50` set the OPR year, season, region, and region-season effects. |
| 4 | `2 30 1` is deliberately retained at the OPR phase because current MFCL requires `age_flag(30)=1` to activate the OPR polynomial coefficients. |
| 5 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 6 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 7 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 8 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag flags, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | The OPR transfer follows the BET 4R screening rank-1 AIC setting `69-01-50-50`. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
