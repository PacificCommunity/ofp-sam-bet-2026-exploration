# BET 2026 S018-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2OFF-REGW11-RRPTTP26

This model is part of the focused SUB075 regional-scaling sensitivity design.

## Design

| Control | Setting |
| --- | --- |
| Age-length input | SUB075, bet.2026.sub.basin.0.75.age_length |
| INI | bet.2026.mix-0.15.ini |
| Selectivity | Corrected SA28-N5 baseline; no fishery has flag 16=1 |
| LF likelihood | MFCL option-3 robust normal |
| LF tail compression | 1 percent |
| Observed LF cutoff | None |
| F21/F22/F23 LF weighting | DW10, flag-49 divisor 200 versus global divisor 20 |
| Tag flag column 2 | TAGF2OFF; paired OFF control: S018-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2OFF-REGW11-RRPTTP26 |
| Regional-scaling form | Multivariate normal when weight is positive |
| Regional-scaling weight | 11; standardized SD multiplier 0.3015 (effective covariance Sigma/11) |
| Regional-scaling target/window | Mean proportions and covariance from 20 quarters in 1965-1969 |

In the active MFCL MVN path, the penalty is w/2 times the squared
Mahalanobis distance from the regional-scaling target. A positive weight
therefore changes the effective covariance to Sigma/w and the standardized
SD multiplier to 1/sqrt(w). Weights 50, 11, and 1 give multipliers 0.1414,
0.3015, and 1.0000, respectively; weight 0 disables the penalty.
Region 5 is the MVN reference category, as in MFCL, while its proportion is
implicitly determined because all five proportions sum to one.

The model is copied from **S017-TC1-NOCUT-SUB075-TAGF2OFF** at
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). Apart from the documented
F21/F22/F23 divisor, parest flag 77, F9 monotonicity removal, identifiers, and
metadata, all CPUE sigma, regional-scaling data, flags 78-81, phase timing,
FRQ, tag, age-length, and remaining selectivity settings are unchanged. The INI
is replaced by **PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@86627214cbac6db5766841e404bb32ea4f6afe61/BET/ini.mix-period/bet.2026.mix-0.15.ini**;
TAGF2OFF changes only tag_flags(:,2) from 1 to 0.

The retained FRQ already contains the selected 2026 effort-creep adjustment;
this build never reapplies effort creep.


## PTTP-derived RTTP/PTTP reporting-rate prior sensitivity

The 2026 PTTP purse-seine priors are propagated to corresponding active
RTTP and PTTP/pooled groups: F19/F20 (Region 2) use mean 0.4962,
target 49.62, and penalty 354.5;
F25/F27 (Region 3) use 0.5121, 51.21, and 739.2; F26/F28 (Region 4)
use 0.5282, 52.82, and 231.2.
The active group IDs receiving these values are 7/14 (Region 2),
10/17 (Region 3), and 18 (Region 4). JPTP group 29 retains its upstream
mean 0.5, target 50, and penalty 1; inactive groups 26, 11, and 30 retain
zero values. Reporting groups, active flags,
and all other settings are
identical to the matched manual-8/10 model.

Status: generated; Kflow has not been submitted.
