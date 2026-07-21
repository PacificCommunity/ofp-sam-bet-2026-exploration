# BET 2026 S030-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX20-REGW11-RRPTTP26

This model is the matched DM interaction in the focused SUB075 regional-scaling
design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| INI | bet.2026.mix-0.15.ini |
| Selectivity | Exact matched SA28-N5 normal-model settings; no fishery has flag 16=1 |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM grouping | G7OSHL: remaining LL; OS F5/F9; large-scale PS; domestic PS; HL F14/F15; other extraction; index |
| DM relative sample-size exponent | CEST, activated in phase 2 |
| DM maximum LF sample-size control | 20 directly from phase 1 |
| DM tail compression | Retain at least five class intervals |
| Observed LF cutoff | None |
| Fixed DW10 divisor | Not applicable to DM weighting |
| Tag flag column 2 | TAGF2ON; paired OFF control: S010-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2OFF-NMAX20-REGW11 |
| Regional-scaling weight | 11; standardized SD multiplier 0.3015 (effective covariance Sigma/11) |

All non-doitall inputs except the INI come from **S018-TC1-NOCUT-SUB075-TAGF2ON** at
**81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** and retain SUB075. The INI comes from
**PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@86627214cbac6db5766841e404bb32ea4f6afe61/BET/ini.mix-period/bet.2026.mix-0.15.ini**. The DM controls come from
**S035-DM-G5PROC-CEST-NOCUT-TAGF2ON** at **20c19b02498a6ee22cc39441a073159accca020b** (**experiment/cpue-hac4-single-area-tail-nmax10-20260719**). HAC4 sigma,
additional selectivity-tail constraints, and extra stabilization phases are excluded.
The report is deferred from phase 2 to the final fit only for DM output safety.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.


## PTTP reporting-rate prior sensitivity

Only PTTP purse-seine prior cells are restored to the 2026 assessment
values: F19/F20 (Region 2) use mean 0.4962, target 49.62, and penalty 354.5;
F25/F27 (Region 3) use 0.5121, 51.21, and 739.2; F26/F28 (Region 4)
use 0.5282, 52.82, and 231.2.
The corresponding PTTP rows are release rows 16-61 plus pooled row 99.
RTTP, JPTP, reporting groups, active flags, and all other settings are
identical to the matched manual-8/10 model.

Status: generated; Kflow has not been submitted.
