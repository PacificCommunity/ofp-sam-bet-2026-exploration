# BET 2026 S013-DM-G5PROC-CEST-NOCUT-BASE075-TAGF2ON-NMAX10-REGW25

This model is part of the focused DM interaction subset in the 18-model
BASE075 regional-scaling-weight sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | BASE075 |
| Selectivity | Exact matched SA28-N5 normal-model settings |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| DM observation grouping | G5PROC: longline, large-scale PS, domestic PS, other extraction, index |
| DM relative sample-size exponent | CEST: group-specific exponent activated in phase 2 |
| DM maximum LF effective sample size | 10 from phase 1 onward |
| DM tail compression | Retain at least five class intervals |
| Observed LF treatment | No observed LF cutoff |
| Tag flag column 2 | all tag_flags(:,2) values set to 1 |
| Regional-scaling penalty | MVN, parest flag 81 = 1 |
| Regional-scaling penalty weight | 25 |

All files other than **doitall.sh** are byte-identical to the corresponding
TAGF2ON normal source model at **81a456fa5c36ef1be5bd9da38308ef07ebc55ff4**. CPUE sigma, selectivity,
regional-scaling inputs, tag and age-length data, and FRQ are unchanged. The DM
likelihood/grouping controls come from **S035-DM-G5PROC-CEST-NOCUT-TAGF2ON** at
**20c19b02498a6ee22cc39441a073159accca020b** (**experiment/cpue-hac4-single-area-tail-nmax10-20260719**), but its HAC4 sigma, separate
selectivity-tail changes, and extra stabilization phases are excluded. The
phase-2/final report switch only prevents an early DM report crash; it does not
add an optimization phase. Parest flag 77 is set to 25.

Status: generated; Kflow has not been submitted.
