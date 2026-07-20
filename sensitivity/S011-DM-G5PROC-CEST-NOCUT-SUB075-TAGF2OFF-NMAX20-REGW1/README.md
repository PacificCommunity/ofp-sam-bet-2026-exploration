# BET 2026 S011-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2OFF-NMAX20-REGW1

This model is the matched DM interaction in the focused SUB075 regional-scaling
design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| Selectivity | Exact matched SA28-N5 normal-model settings |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM grouping | G5PROC |
| DM relative sample-size exponent | CEST, activated in phase 2 |
| DM maximum LF sample-size control | 20 directly from phase 1 |
| DM tail compression | Retain at least five class intervals |
| Observed LF cutoff | None |
| Fixed DW10 divisor | Not applicable to DM weighting |
| Tag flag column 2 | TAGF2OFF; paired OFF control: S011-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2OFF-NMAX20-REGW1 |
| Regional-scaling weight | 1; standardized SD multiplier 1.0000 (empirical covariance Sigma) |

All non-doitall inputs come from **S017-TC1-NOCUT-SUB075-TAGF2OFF** at
**81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** and retain SUB075. The DM controls come from
**S035-DM-G5PROC-CEST-NOCUT-TAGF2ON** at **20c19b02498a6ee22cc39441a073159accca020b** (**experiment/cpue-hac4-single-area-tail-nmax10-20260719**). HAC4 sigma,
separate selectivity-tail changes, and extra stabilization phases are excluded.
The report is deferred from phase 2 to the final fit only for DM output safety.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.

Status: generated; Kflow has not been submitted.
