# BET 2026 BASE075 regional-scaling-weight sensitivities

This branch contains 12 MFCL models derived from
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). It retains only the corrected
SA28-N5 BASE075 models and excludes the N8 selectivity variant.

## Purpose

The source models use MVN regional-scaling penalty weight 50. This design
changes only parest flag 77 to 25, 10, or 5, allowing progressively more
freedom in relative biomass allocation among regions. Regional-scaling inputs,
flags 78-81, the 1965-1969 target/covariance window, CPUE observations and
sigma, phase timing, LF settings, tag inputs, age-length data, and selectivity
are held fixed.

MFCL normalizes regional mean biomass to proportions before evaluating this
penalty. These sensitivities therefore relax relative regional allocation
directly; effects on total biomass are indirect through the coupled population
dynamics.

## Design

| IDs | Cutoff | Tag flag column 2 | Regional-scaling weights |
| --- | --- | --- | --- |
| S001-S003 | NOCUT | 0 | 25, 10, 5 |
| S004-S006 | NOCUT | 1 | 25, 10, 5 |
| S007-S009 | CUT90 | 0 | 25, 10, 5 |
| S010-S012 | CUT90 | 1 | 25, 10, 5 |

Relative to weight 50, weights 25, 10, and 5 increase the prior standard
deviation by approximately sqrt(2), sqrt(5), and sqrt(10), respectively. The
weight-50 controls remain on the source branch and are not duplicated here.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated models are under **sensitivity/**; exact input provenance is recorded
in each model's **input_manifest.csv**.
