# BET 2026 S004: Francis TA1.8 and CPUE MLE

## Model

- Model: S004-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RR8-10
- Source fitted model: S007-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW1
- Source fitted result: Kflow Job 12291
- Source repository commit: 84afb5a52536b1043c47a66dc65c0c4f054ee44e
- Source payload SHA-256: d9880c240702c3ff97846ae477e5a2a645f6076be67717e39acfb87ead78dc79
- Source archive SHA-256: 3d963ae69c97aad11934bb65a6b8b395ae7af986e6d9dbcd491c64bfde705afe
- Source fit objective: -192819.890726332
- Source fit maximum gradient: 9.92683937919524e-05
- Regional-scaling flag 77: 1 (standardized SD multiplier 1.0000; empirical covariance Sigma)
- Reporting-rate prior: manual 8/10

This refit applies full fishery-specific Francis TA1.8 length-composition divisors and MFCL-equivalent CPUE likelihood MLE sigma values. It retains robust-normal length likelihood, 1% MFCL tail compression, no LF cutoff, SUB075 age-length data, MIX015 tag mixing, TAGF2ON, and all parent controls other than fishery flags 49 and 92 and the F25/F26 selectivity changes documented below. Effort creep is not reapplied.

## Francis TA1.8

For each fitted composition y:

N_eff,y = min(N_y, 1000) / d_old

z_y = (mean_observed,y - mean_expected,y) / sqrt(V_expected,y / N_eff,y)

w = 1 / Var(z_y)

d_new = d_old / w

The original unbounded Francis multiplier is applied to all 33 fisheries, including F20 with two fitted compositions. Continuous divisors are rounded to the nearest positive integer for flag 49.

| Fishery | n | Old divisor | Continuous divisor | New flag 49 |
|---:|---:|---:|---:|---:|
| 1 | 179 | 40 | 94.947691 | 95 |
| 2 | 124 | 40 | 174.542535 | 175 |
| 3 | 80 | 20 | 43.041493 | 43 |
| 4 | 142 | 40 | 112.554217 | 113 |
| 5 | 28 | 20 | 64.729263 | 65 |
| 6 | 50 | 40 | 23.735112 | 24 |
| 7 | 202 | 40 | 74.620496 | 75 |
| 8 | 70 | 40 | 39.470987 | 39 |
| 9 | 128 | 20 | 90.277612 | 90 |
| 10 | 26 | 40 | 119.144755 | 119 |
| 11 | 106 | 20 | 48.862819 | 49 |
| 12 | 10 | 20 | 188.026766 | 188 |
| 13 | 45 | 20 | 376.118617 | 376 |
| 14 | 26 | 20 | 14.792568 | 15 |
| 15 | 108 | 20 | 139.489421 | 139 |
| 16 | 17 | 20 | 267.788562 | 268 |
| 17 | 13 | 20 | 87.083641 | 87 |
| 18 | 31 | 20 | 144.256840 | 144 |
| 19 | 18 | 20 | 138.812881 | 139 |
| 20 | 2 | 20 | 248.079474 | 248 |
| 21 | 15 | 200 | 100.392521 | 100 |
| 22 | 125 | 200 | 403.094672 | 403 |
| 23 | 21 | 200 | 733.298637 | 733 |
| 24 | 17 | 20 | 38.755080 | 39 |
| 25 | 48 | 20 | 24.636257 | 25 |
| 26 | 27 | 20 | 38.363467 | 38 |
| 27 | 21 | 20 | 16.200541 | 16 |
| 28 | 23 | 20 | 48.841930 | 49 |
| 29 | 218 | 40 | 87.822796 | 88 |
| 30 | 126 | 40 | 58.236911 | 58 |
| 31 | 243 | 40 | 49.058007 | 49 |
| 32 | 89 | 40 | 58.311481 | 58 |
| 33 | 21 | 40 | 36.315531 | 36 |

## CPUE likelihood MLE

MFCL reads FRQ field 7 as the CPUE precision multiplier and normalizes it within each fishery:

lambda_MFCL,t = lambda_raw,t / mean(lambda_raw).

For centered log-residual r_t:

sigma_MLE squared = mean(r_t squared / lambda_MFCL,t)

fishery flag 92 = round(100 * sigma_MLE)

| Index | n | Mean raw lambda | Source sigma | MFCL-equivalent sigma | New flag 92 |
|---|---:|---:|---:|---:|---:|
| R1 | 292 | 1.060731334858 | 0.35 | 0.376786183915 | 38 |
| R2 | 292 | 1.022662732125 | 0.24 | 0.255231476956 | 26 |
| R3 | 292 | 0.996426248464 | 0.21 | 0.199048451326 | 20 |
| R4 | 290 | 1.047514623061 | 0.24 | 0.234439881267 | 23 |
| R5 | 292 | 0.990231135408 | 0.23 | 0.212942049415 | 21 |

The complete machine-readable audits are in model/francis_weights.csv and model/cpue_mle.csv.

## Preserved controls

- Regional scaling flags 77-81: 1, 1, 240, 220, 1
- Reporting-rate prior: manual 8/10, retained byte-for-byte in bet.ini
- Maximum reporting rate: flag 1 33 99
- Release-group reporting rates active: flag 2 198 1
- Tag likelihood: negative binomial, flag 1 111 4
- Tag mixing treatment: tag flag 2 on
- Source fitted MFCL implementation audited at ongoing-dev commit de4abeca920063bf234ce66ec3a0f043c56e885f

## Implementation provenance

- Model source repository: PacificCommunity/ofp-sam-bet-2026-exploration
- Model source branch: experiment/mix015-unconstrained-g7oshl-dm20-20260721
- MFCL likelihood implementation audited on ongoing-dev commit de4abeca920063bf234ce66ec3a0f043c56e885f
- mfclkit Francis implementation commit: 0272c9dabf7810326f650b1377d5e8a747e1ed26
- Raw model-input and integrated-file hashes: input_manifest.csv

MFCL source references:

- [Survey-index lambda normalization and likelihood](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/newl2.cpp#L903-L956)
- [FRQ effort-weight reading](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/newmaux4.cpp#L87-L104)

## References

- Francis, R. I. C. C. (2011). Data weighting in statistical fisheries stock assessment models. Canadian Journal of Fisheries and Aquatic Sciences 68: 1124-1138.
- MULTIFAN-CL User Guide, robust-normal length likelihood and survey-index likelihood controls.
- r4ss SSMethod.TA1.8, independent implementation of the Francis TA1.8 point estimator.

## F25-F26 selectivity sensitivity

This branch pairs this model with parent Kflow Job ${parent_jobs[S004]} from
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
