# BET 2026 S001: Francis TA1.8 and CPUE MLE

## Model

- Model: S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26
- Source fitted model: S022-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26
- Source fitted result: Kflow Job 12306
- Source repository commit: 8df6a0e4b9856c5cd1e06ab7010c6e71c773f428
- Source payload SHA-256: 58e60d5185a8633cafd8997c8d92b76cd38305c54b70a92ef098429f18a58c98

This model applies full fishery-specific Francis TA1.8 length-composition divisors and CPUE likelihood MLE sigma values in one refit.

The inherited configuration is robust-normal length likelihood, 1% MFCL tail compression, no LF cutoff, SUB075 age-length data, MIX015 tag mixing, tag flag 2 on, regional-scaling weight 11, and reporting-rate prior 26. Other than the F25/F26 selectivity sensitivity documented below, all remaining inputs and controls are unchanged. Effort creep was already applied once in the inherited source input and is not reapplied here.

## Francis TA1.8

The source fit has MFCL flag 141 = 3, flag 311 = 1, flag 312 = 50, and flag 313 = 1. Observed and predicted probabilities are pooled into the same observed 1% tail boundary bins used by MFCL square_fita.

For each composition y:

N_eff,y = min(N_y, 1000) / d_old

z_y = (mean_observed_y - mean_expected_y) / sqrt(V_expected,y / N_eff,y)

w = 1 / Var(z_y)

d_new = d_old / w

The original unbounded Francis multiplier is used for all 33 fisheries, including fishery 20 with two fitted compositions. Continuous divisors are rounded to the nearest positive integer for fishery flag 49. The complete audit is in model/francis_weights.csv.

An independent base-R implementation reproduced the mfclkit raw multipliers to within 1.4e-15 and continuous divisors to within 2.9e-13.

## CPUE likelihood MLE

MFCL reads FRQ field 7 as the CPUE precision multiplier and normalizes it within each fishery:

lambda_MFCL,t = lambda_raw,t / mean(lambda_raw).

For centered log-residual r_t, the relevant likelihood gives:

sigma_MLE squared = mean(r_t squared / lambda_MFCL,t)

fishery flag 92 = round(100 * sigma_MLE)

| Index | n | Source sigma | MFCL-equivalent sigma | Source flag 92 | New flag 92 |
|---|---:|---:|---:|---:|---:|
| R1 | 292 | 0.35 | 0.3818726195 | 35 | 38 |
| R2 | 292 | 0.24 | 0.2549668574 | 24 | 25 |
| R3 | 292 | 0.21 | 0.1977756009 | 21 | 20 |
| R4 | 290 | 0.24 | 0.2322172383 | 24 | 23 |
| R5 | 292 | 0.23 | 0.2129074544 | 23 | 21 |

These corrected estimates use the fishery-mean-normalized lambda convention implemented by MFCL ongoing-dev. The complete machine-readable audit is in model/cpue_mle.csv.

## Implementation provenance

- MFCL source branch: ongoing-dev (origin/ongoing-dev)
- MFCL source commit: de4abeca920063bf234ce66ec3a0f043c56e885f
- MFCL src/newl2.cpp SHA-256: d181892412dd398cbcf5728cc39f196084d2bc7a26e83d33b8d722d7c9960b46
- mfclkit source commit: 0272c9dabf7810326f650b1377d5e8a747e1ed26
- mfclkit R/francis.R SHA-256: b0075c2cb1721aa6d39d0fa54f4292bac956ea031c258240bab8fabd6559fafe
- CPUE lambda input SHA-256: 32bcc40cac731c3883bb9ad701dcc8a536b9945154f2ef29d7a8fd6b9bc5d9fb

## References

- Francis, R. I. C. C. (2011). Data weighting in statistical fisheries stock assessment models. Canadian Journal of Fisheries and Aquatic Sciences 68: 1124-1138.
- MULTIFAN-CL User Guide, robust-normal length likelihood and survey-index likelihood controls.
- r4ss SSMethod.TA1.8, an independent implementation of the Francis TA1.8 point estimator.

## F25-F26 selectivity sensitivity

This branch pairs this model with parent Kflow Job ${parent_jobs[S001]} from
BET 2026 Francis + CPUE MLE. F25 (PS.ASSOC.WEST.3) and F26
(PS.ASSOC.EAST.4) now share selectivity group 25 and use seven cubic-spline
nodes. Both retain fish flags 16 = 2, 3 = 25, 26 = 2, 57 = 3, and 75 = 0.
Subsequent selectivity groups are renumbered contiguously; other fishery
selectivity controls are unchanged. See
[notes/f25-f26-selectivity.md](../../notes/f25-f26-selectivity.md).

## Common CPUE sigma

For the matched eight-model comparison, R1-R5 use common fish flag 92 values
36, 25, 21, 24, and 22. These are the rounded index-wise medians across the
eight parent settings. S001-S004 provide MFCL-equivalent MLE estimates and
S005-S008 provide inherited fixed sigma inputs. Any earlier model-specific
sigma table above documents the parent calculation; this median vector is the
final setting applied by this branch. The shared calculation is in
[notes/common-cpue-sigma.md](../../notes/common-cpue-sigma.md).
