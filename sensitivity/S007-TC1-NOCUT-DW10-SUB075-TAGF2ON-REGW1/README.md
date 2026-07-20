# BET 2026 S007-TC1-NOCUT-DW10-SUB075-TAGF2ON-REGW1

This model is part of the focused SUB075 regional-scaling sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| Selectivity | Corrected SA28-N5 baseline |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1 percent |
| Observed LF cutoff | None |
| F21/F22/F23 LF weighting | DW10, flag-49 divisor 200 versus global divisor 20 |
| Tag flag column 2 | TAGF2ON; paired OFF control: S003-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW1 |
| Regional-scaling form | Multivariate normal when weight is positive |
| Regional-scaling weight | 1; standardized SD multiplier 1.0000 (empirical covariance Sigma) |
| Regional-scaling target/window | Mean proportions and covariance from 20 quarters in 1965-1969 |

In the active MFCL MVN path, the penalty is w/2 times the squared
Mahalanobis distance from the regional-scaling target. A positive weight
therefore changes the effective covariance to Sigma/w and the standardized
SD multiplier to 1/sqrt(w). Weights 50, 11, and 1 give multipliers 0.1414,
0.3015, and 1.0000, respectively; weight 0 disables the penalty.
Region 5 is the MVN reference category, as in MFCL, while its proportion is
implicitly determined because all five proportions sum to one.

The model is copied from **S018-TC1-NOCUT-SUB075-TAGF2ON** at
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). Apart from the documented
F21/F22/F23 divisor, parest flag 77, identifiers, and metadata, all CPUE sigma,
regional-scaling data, flags 78-81, phase timing, FRQ, INI, tag, age-length,
and selectivity settings are unchanged.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.

Status: generated; Kflow has not been submitted.
