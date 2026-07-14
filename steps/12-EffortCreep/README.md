# 12 EffortCreep

Apply effort creep directly after the time-varying-CV model.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/12-EffortCreep/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Continues directly from 11-TimeVaryingCV and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`. |
| 2 | Does not apply the omitted OPR or length-based-selectivity changes; fish flag 26 remains 2 and OPR flags remain inactive. |
| 3 | The effort-creep transform multiplies index-fishery effort by a piecewise linear multiplier: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024. |
| 4 | Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE, with index effort creep applied |
| `.ini` | `bet.2026.mix-0.2.ini`, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; raised 2 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0; normalized MFCL 1007 tag-control rows for 98 release groups |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR groups and canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | Full `bet.2026.reg_scaling` global CPUE regional-scaling matrix; parest flags select active periods 53-72 (1965-1969) for the prior |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | Applies effort creep to positive effort values for index fisheries 29-33. | Catch and size-composition records. |
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
| 1 | 11-TimeVaryingCV controls are retained. |
| 2 | No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`. |
| 3 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 4 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 5 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 6 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |
| 7 | Index-fishery CPUE sigma is re-estimated from the fitted Step 12 residuals and applied through fish flag 92. |

## CPUE Sigma Sensitivity

The index-fishery sigma values are recalibrated from the fitted Step 12 CPUE
residuals on the same scale used by the MFCL catch-conditioned CPUE likelihood.
MFCL stores the reported CPUE observations and predictions for this likelihood as
normalised log-scale values, so the residual is calculated as `pred - obs`, not as
`log(pred) - log(obs)`.

This sensitivity follows a fitted-residual calibration approach: the assessment
model is first fitted with the prior regional CPUE sigma settings, then the
log-scale residual variance implied by that fitted model is used to update the
region-specific sigma values. This keeps the `.frq` time-varying precision
pattern intact while allowing the regional average sigma to reflect the
empirical residual scale of the current model fit. It is intended as a model
weighting sensitivity, not as a change to the CPUE index values themselves.

For index fishery `k`, the fitted residual sigma is:

```text
sigma_k = sqrt(mean((P_ki - O_ki)^2 / lambda_ki))
```

where `P_ki` and `O_ki` are the MFCL reported normalised log prediction and
observation, and `lambda_ki` is the time-varying precision pattern from the
`.frq` fishery-data column used when fish flag 66 is active. The pattern is
normalised within each index fishery before the calculation, matching the MFCL
likelihood implementation.

The resulting values from the fitted Step 12 reference model are:

| Region | Fishery | Fitted sigma | `fish_flags(92)` |
| --- | ---: | ---: | ---: |
| R1 | 29 | 0.354 | 35 |
| R2 | 30 | 0.237 | 24 |
| R3 | 31 | 0.212 | 21 |
| R4 | 32 | 0.239 | 24 |
| R5 | 33 | 0.225 | 23 |

The doitall entries therefore use `fish_flags(92)=35,24,21,24,23` for
fisheries 29-33, with fish flag 66 retained so the `.frq` time pattern still
controls relative annual precision.

Report wording:

> Regional CPUE index sigmas were recalibrated from the fitted model residuals
> on the MFCL catch-conditioned CPUE likelihood scale. The time-varying
> precision pattern supplied in the `.frq` file was retained, and only the
> regional average sigma values applied through `fish_flags(92)` were updated.

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag-control dimensions, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |
| 5 | The effort-creep `.frq` is generated from the full 2024 regional CPUE source by changing only positive effort values for index fisheries 29-33. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, review index residuals and implied CPUE scaling against 11-TimeVaryingCV. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
