# BET 2026 S002: Francis TA1.8 and CPUE MLE

## Model

- Model: S002-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26
- Source fitted model: S023-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26
- Source fitted result: Kflow Job 12307
- Source repository commit: 8df6a0e4b9856c5cd1e06ab7010c6e71c773f428
- Source payload SHA-256: 8bdc65f02cce1871641e07e7c952b01588dad4ea3c1956a4289e71c1bbbd4196
- Source fit: objective -192574.7988; maximum gradient 8.966e-05

This model applies full fishery-specific Francis TA1.8 length-composition divisors and CPUE likelihood MLE sigma values in one refit. It retains the source model's robust-normal likelihood, 1% MFCL tail compression, no LF cutoff, SUB075 age-length data, MIX015 tag mixing, TAGF2ON, REGW1, and PTTP26 reporting-rate controls. All other inputs and controls are unchanged.

## Francis TA1.8

The calculation uses the authoritative Job 12307 fitted PAR, MFCL flags 141 = 3, 311 = 1, 312 = 50, and 313 = 1, and the native full-support `length.fit`. Observed and predicted probabilities are pooled into the same observed 1% tail boundary bins used by MFCL `square_fita`. The unbounded Francis multiplier is applied to all 33 fisheries, including F20 with two fitted compositions, and continuous divisors are rounded to the nearest positive integer for flag 49.

28 of 33 applied divisors differ from S1. The complete machine-readable table is [model/francis_weights.csv](model/francis_weights.csv).

| F | Fishery | n | Source | S1 | S2 continuous | S2 applied | S2 - S1 |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | LL.WEST.ALL.1 | 179 | 40 | 115 | 98.34 | 98 | -17 |
| 2 | LL.EAST.ALL.1 | 124 | 40 | 147 | 179.08 | 179 | +32 |
| 3 | LL.US.1 | 80 | 20 | 42 | 44.54 | 45 | +3 |
| 4 | LL.ALL.2 | 142 | 40 | 110 | 112.28 | 112 | +2 |
| 5 | LL.OS.2 | 28 | 20 | 63 | 64.57 | 65 | +2 |
| 6 | LL.ARCH.3 | 50 | 40 | 23 | 23.95 | 24 | +1 |
| 7 | LL.WEST.3 | 202 | 40 | 77 | 75.80 | 76 | -1 |
| 8 | LL.EAST.4 | 70 | 40 | 43 | 43.31 | 43 | +0 |
| 9 | LL.OS.3 | 128 | 20 | 85 | 87.69 | 88 | +3 |
| 10 | LL.ALL.5 | 26 | 40 | 117 | 119.78 | 120 | +3 |
| 11 | LL.AU.5 | 106 | 20 | 48 | 51.02 | 51 | +3 |
| 12 | PS.JP.1 | 10 | 20 | 209 | 203.58 | 204 | -5 |
| 13 | PL.JP.1 | 45 | 20 | 357 | 408.19 | 408 | +51 |
| 14 | HL.ID.2 | 26 | 20 | 16 | 15.64 | 16 | +0 |
| 15 | HL.PH.2 | 108 | 20 | 142 | 143.72 | 144 | +2 |
| 16 | PL.ALL.2 | 17 | 20 | 296 | 269.21 | 269 | -27 |
| 17 | PS.ID.2 | 13 | 20 | 88 | 88.32 | 88 | +0 |
| 18 | PS.PH.2 | 31 | 20 | 151 | 147.98 | 148 | -3 |
| 19 | PS.ASS.2 | 18 | 20 | 141 | 142.26 | 142 | +1 |
| 20 | PS.UNA.2 | 2 | 20 | 258 | 252.39 | 252 | -6 |
| 21 | MISC.ID.2 | 15 | 200 | 114 | 103.18 | 103 | -11 |
| 22 | MISC.PH.2 | 125 | 200 | 398 | 418.89 | 419 | +21 |
| 23 | MISC.VN.2 | 21 | 200 | 705 | 726.03 | 726 | +21 |
| 24 | PL.ALL.WEST.3 | 17 | 20 | 39 | 43.15 | 43 | +4 |
| 25 | PS.ASSOC.WEST.3 | 48 | 20 | 27 | 23.53 | 24 | -3 |
| 26 | PS.ASSOC.EAST.4 | 27 | 20 | 37 | 19.37 | 19 | -18 |
| 27 | PS.UNASSOC.WEST.3 | 21 | 20 | 18 | 19.03 | 19 | +1 |
| 28 | PS.UNASSOC.EAST.4 | 23 | 20 | 50 | 51.63 | 52 | +2 |
| 29 | Index R1 | 218 | 40 | 115 | 91.16 | 91 | -24 |
| 30 | Index R2 | 126 | 40 | 57 | 58.60 | 59 | +2 |
| 31 | Index R3 | 243 | 40 | 51 | 48.77 | 49 | -2 |
| 32 | Index R4 | 89 | 40 | 56 | 56.09 | 56 | +0 |
| 33 | Index R5 | 21 | 40 | 38 | 38.39 | 38 | +0 |

## CPUE likelihood MLE

MFCL reads FRQ field 7 as the CPUE precision multiplier and normalizes it within each fishery:

lambda_MFCL,t = lambda_raw,t / mean(lambda_raw).

For centered log-residual r_t, the relevant likelihood gives:

sigma_MLE squared = mean(r_t squared / lambda_MFCL,t)

fishery flag 92 = round(100 * sigma_MLE)

| Index | n | Source sigma | S1 sigma | S1 flag 92 | S2 sigma | S2 flag 92 |
|---|---:|---:|---:|---:|---:|---:|
| R1 | 292 | 0.35 | 0.3818726195 | 38 | 0.3786514370 | 38 |
| R2 | 292 | 0.24 | 0.2549668574 | 25 | 0.2550496561 | 26 |
| R3 | 292 | 0.21 | 0.1977756009 | 20 | 0.2040090921 | 20 |
| R4 | 290 | 0.24 | 0.2322172383 | 23 | 0.2320954604 | 23 |
| R5 | 292 | 0.23 | 0.2129074544 | 21 | 0.2167115803 | 22 |

The corrected estimates use the fishery-mean-normalized lambda convention implemented by MFCL ongoing-dev. Relative to S1, S2 changes flag 92 for R2 and R5. The complete machine-readable audit is in model/cpue_mle.csv.

## S1 comparison

S1 uses Job 12306 model S022 with REGW11; S2 uses Job 12307 model S023 with REGW1. Static observation inputs are identical. Differences in the reweighting estimates therefore arise from independently fitted predictions under the two regional-scaling weights. S2 changes 28 Francis flag-49 values relative to S1 and changes CPUE flag 92 for R2 and R5.

## Implementation provenance

- MFCL source branch: ongoing-dev (`origin/ongoing-dev`)
- MFCL source commit: `de4abeca920063bf234ce66ec3a0f043c56e885f`
- mfclkit calculation commit: `0272c9dabf7810326f650b1377d5e8a747e1ed26`
- CPUE lambda input SHA-256: `32bcc40cac731c3883bb9ad701dcc8a536b9945154f2ef29d7a8fd6b9bc5d9fb`

## References

- Francis, R. I. C. C. (2011). Data weighting in statistical fisheries stock assessment models. Canadian Journal of Fisheries and Aquatic Sciences 68: 1124-1138.
- MULTIFAN-CL User Guide, robust-normal length likelihood and survey-index likelihood controls.
