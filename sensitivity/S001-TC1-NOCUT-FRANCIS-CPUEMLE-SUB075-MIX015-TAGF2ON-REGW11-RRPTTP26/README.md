# BET 2026 S001: Francis TA1.8 and CPUE MLE

## Model

- Model: S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26
- Source fitted model: S022-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26
- Source fitted result: Kflow Job 12306
- Source repository commit: 8df6a0e4b9856c5cd1e06ab7010c6e71c773f428
- Source payload SHA-256: 58e60d5185a8633cafd8997c8d92b76cd38305c54b70a92ef098429f18a58c98

This model applies full fishery-specific Francis TA1.8 length-composition divisors and CPUE likelihood MLE sigma values in one refit.

The inherited configuration is robust-normal length likelihood, 1% MFCL tail compression, no LF cutoff, SUB075 age-length data, MIX015 tag mixing, tag flag 2 on, regional-scaling weight 11, and reporting-rate prior 26. All other inputs and controls are unchanged. Effort creep was already applied once in the inherited source input and is not reapplied here.

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

Job 12306 stores centered log observed and predicted CPUE in MFCLRep. For residual r_t and normalized variance multiplier lambda_t, the MFCL survey-index likelihood gives:

sigma_MLE squared = mean(r_t squared / lambda_t)

fishery flag 92 = round(100 * sigma_MLE)

| Index | n | Existing sigma | MLE sigma | Existing flag 92 | MLE flag 92 |
|---|---:|---:|---:|---:|---:|
| R1 | 292 | 0.35 | 0.3708 | 35 | 37 |
| R2 | 292 | 0.24 | 0.2521 | 24 | 25 |
| R3 | 292 | 0.21 | 0.1981 | 21 | 20 |
| R4 | 290 | 0.24 | 0.2269 | 24 | 23 |
| R5 | 292 | 0.23 | 0.2140 | 23 | 21 |

The closed-form estimates match direct numerical minimization of the MFCL likelihood to within 3.4e-09 in sigma. The complete audit is in model/cpue_mle.csv.

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
