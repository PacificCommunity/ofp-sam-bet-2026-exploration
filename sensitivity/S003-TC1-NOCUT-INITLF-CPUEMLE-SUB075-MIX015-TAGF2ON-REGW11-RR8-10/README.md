# BET 2026 S003: Initial LF divisors and common CPUE sigma

## Model

- Model: S003-TC1-NOCUT-INITLF-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RR8-10
- Source fitted model: S006-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW11
- Source fitted result: Kflow Job 12292
- Source repository commit: 84afb5a52536b1043c47a66dc65c0c4f054ee44e
- Source payload SHA-256: 9fe718ec7cd280e4a5b12f7717e76461cf31c1a0d8a1845a65997de1a1b7ee9d
- Source archive SHA-256: eba1ccb4b7955d2afeee0ea9bd4d01c610944ab5a35438e8a83aa850d394aff2
- Source fit objective: -192694.065589759
- Source fit maximum gradient: 9.11968249580936e-05
- Regional-scaling flag 77: 11 (standardized SD multiplier 0.3015; effective covariance Sigma/11)
- Reporting-rate prior: manual 8/10

This branch restores the source robust-normal LF divisors and applies the common CPUE sigma and F25/F26 selectivity sensitivity. It retains robust-normal length likelihood, 1% MFCL tail compression, no LF cutoff, SUB075 age-length data, MIX015 tag mixing, TAGF2ON, and all parent controls other than the common CPUE sigma and the F25/F26 selectivity changes documented below. Effort creep is not reapplied.

## Final LF divisor setting\n\nFrancis overrides are not applied in this branch. The final divisor pattern is\n40/20 for the principal fisheries, 200 for F21-F23, and 40 for F29-F33. See\n[notes/initial-lf-divisors.md](../../notes/initial-lf-divisors.md).\n\n## Parent Francis TA1.8 audit (not applied)

For each fitted composition y:

N_eff,y = min(N_y, 1000) / d_old

z_y = (mean_observed,y - mean_expected,y) / sqrt(V_expected,y / N_eff,y)

w = 1 / Var(z_y)

d_new = d_old / w

The original unbounded Francis multiplier is applied to all 33 fisheries, including F20 with two fitted compositions. Continuous divisors are rounded to the nearest positive integer for flag 49.

| Fishery | n | Old divisor | Continuous divisor | New flag 49 |
|---:|---:|---:|---:|---:|
| 1 | 179 | 40 | 115.867488 | 116 |
| 2 | 124 | 40 | 147.404661 | 147 |
| 3 | 80 | 20 | 41.964901 | 42 |
| 4 | 142 | 40 | 110.357336 | 110 |
| 5 | 28 | 20 | 61.606430 | 62 |
| 6 | 50 | 40 | 23.410083 | 23 |
| 7 | 202 | 40 | 75.777477 | 76 |
| 8 | 70 | 40 | 41.204370 | 41 |
| 9 | 128 | 20 | 86.596554 | 87 |
| 10 | 26 | 40 | 119.960279 | 120 |
| 11 | 106 | 20 | 47.915335 | 48 |
| 12 | 10 | 20 | 207.201598 | 207 |
| 13 | 45 | 20 | 377.457380 | 377 |
| 14 | 26 | 20 | 15.901603 | 16 |
| 15 | 108 | 20 | 142.428831 | 142 |
| 16 | 17 | 20 | 286.057402 | 286 |
| 17 | 13 | 20 | 88.334898 | 88 |
| 18 | 31 | 20 | 146.761309 | 147 |
| 19 | 18 | 20 | 148.091178 | 148 |
| 20 | 2 | 20 | 254.090595 | 254 |
| 21 | 15 | 200 | 119.807990 | 120 |
| 22 | 125 | 200 | 405.063919 | 405 |
| 23 | 21 | 200 | 730.431002 | 730 |
| 24 | 17 | 20 | 35.065596 | 35 |
| 25 | 48 | 20 | 27.310585 | 27 |
| 26 | 27 | 20 | 39.344749 | 39 |
| 27 | 21 | 20 | 18.669337 | 19 |
| 28 | 23 | 20 | 49.448748 | 49 |
| 29 | 218 | 40 | 115.749746 | 116 |
| 30 | 126 | 40 | 56.837354 | 57 |
| 31 | 243 | 40 | 50.716138 | 51 |
| 32 | 89 | 40 | 56.303628 | 56 |
| 33 | 21 | 40 | 38.469070 | 38 |

## CPUE likelihood MLE

MFCL reads FRQ field 7 as the CPUE precision multiplier and normalizes it within each fishery:

lambda_MFCL,t = lambda_raw,t / mean(lambda_raw).

For centered log-residual r_t:

sigma_MLE squared = mean(r_t squared / lambda_MFCL,t)

fishery flag 92 = round(100 * sigma_MLE)

| Index | n | Mean raw lambda | Source sigma | MFCL-equivalent sigma | New flag 92 |
|---|---:|---:|---:|---:|---:|
| R1 | 292 | 1.060731334858 | 0.35 | 0.381164500819 | 38 |
| R2 | 292 | 1.022662732125 | 0.24 | 0.253889662560 | 25 |
| R3 | 292 | 0.996426248464 | 0.21 | 0.196216683761 | 20 |
| R4 | 290 | 1.047514623061 | 0.24 | 0.229608279909 | 23 |
| R5 | 292 | 0.990231135408 | 0.23 | 0.212053422081 | 21 |

The complete machine-readable audits are in model/francis_weights.csv and model/cpue_mle.csv.

## Preserved controls

- Regional scaling flags 77-81: 11, 1, 240, 220, 1
- Reporting-rate prior: manual 8/10, retained byte-for-byte in bet.ini
- Maximum reporting rate: flag 1 33 99
- Release-group reporting rates active: flag 2 198 1
- Tag likelihood: negative binomial, flag 1 111 4
- Tag mixing treatment: tag flag 2 on
- Source Job 12292 phase 10/11 convergence setting: -4; source fitted MFCL executable commit: 1321ccd196ba55d60b12ddf4baf2bf4599ad3723

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

This branch pairs this model with parent Kflow Job ${parent_jobs[S003]} from
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
