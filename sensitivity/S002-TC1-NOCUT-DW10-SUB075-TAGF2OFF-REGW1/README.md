# BET 2026 S002-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW1

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
| Tag flag column 2 | TAGF2OFF; paired OFF control: S002-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW1 |
| Regional-scaling form | Multivariate normal when weight is positive |
| Regional-scaling weight | 1; about 16.3-19.8 percent marginal CV (raw CPUE covariance) |
| Regional-scaling target/window | Mean proportions and covariance from 20 quarters in 1965-1969 |

The 1965-1969 CPUE-derived marginal CVs are 16.3-19.8 percent before
weighting. A positive weight divides that covariance by the weight. Weight 3
therefore gives approximately 9.4-11.5 percent marginal CV; weight 1 retains
the empirical covariance; weight 0 disables the regional-scaling penalty.
Region 5 is the MVN reference category, as in MFCL, while its proportion is
implicitly determined because all five proportions sum to one.

The model is copied from **S017-TC1-NOCUT-SUB075-TAGF2OFF** at
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). Apart from the documented
F21/F22/F23 divisor, parest flag 77, identifiers, and metadata, all CPUE sigma,
regional-scaling data, flags 78-81, phase timing, FRQ, INI, tag, age-length,
and selectivity settings are unchanged.

Status: generated; Kflow has not been submitted.
