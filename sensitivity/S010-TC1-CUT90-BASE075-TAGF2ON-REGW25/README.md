# BET 2026 S010-TC1-CUT90-BASE075-TAGF2ON-REGW25

This model is part of the 18-model BASE075 regional-scaling-weight sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | BASE075 |
| Selectivity | Corrected SA28-N5 baseline |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1% |
| Observed LF treatment | F21/F22/F23 observed LF bins above 90 cm set to zero |
| Tag flag column 2 | all tag_flags(:,2) values set to 1; paired control: S007-TC1-CUT90-BASE075-TAGF2OFF-REGW25 |
| Regional-scaling penalty | MVN, parest flag 81 = 1 |
| Regional-scaling penalty weight | 25 |
| Regional-scaling target/window | Unchanged from the source model |

Only parest flag 77 differs from the corresponding source model at weight 50.
CPUE observations and sigma, the active regional-scaling matrix, flags 78-81,
phase timing, LF divisors, selectivity, age-length data, and all other MFCL
settings are unchanged. The N8 selectivity variant is excluded.

Source model: **S004-TC1-CUT90-BASE075-TAGF2ON** from
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**).
See **input_manifest.csv** for file-level provenance.

Status: generated; Kflow has not been submitted.
