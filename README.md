# BET 2026 SUB075 DW10 regional-scaling sensitivities

This branch contains nine NOCUT MFCL models based on
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). All models use the SUB075
age-length input and corrected SA28-N5 selectivity baseline. CUT90 is excluded.

## Design

| IDs | LF treatment | Tag flag column 2 | Regional-scaling weights |
| --- | --- | --- | --- |
| S001-S003 | Robust normal, F21/F22/F23 DW10 | 0 | 3, 1, 0 |
| S004-S006 | Robust normal, F21/F22/F23 DW10 | 1 | 3, 1, 0 |
| S007-S009 | DM G5PROC-CEST Nmax10 | 1 | 3, 1, 0 |

For robust-normal models, DW10 means F21/F22/F23 flag-49 divisor 200 against
the global divisor 20. It is not applied to DM models because fixed flag-49
divisors are not the DM observation-weight parameter.

The active regional-scaling data are 20 quarterly regional CPUE values for
1965-1969. MFCL converts each row to regional proportions, calculates their
mean and covariance, removes Region 5 as the MVN reference dimension, and uses

    penalty = 0.5 * weight * d' * Sigma^-1 * d.

Thus weight 3 gives approximately 9.4-11.5 percent marginal CV, weight 1 uses
the raw CPUE covariance (16.3-19.8 percent marginal CV), and weight 0 disables
the regional-scaling penalty. These are data-specific marginal CVs, not the
generic penalty-only approximation.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated inputs and file-level provenance are under **sensitivity/**.
