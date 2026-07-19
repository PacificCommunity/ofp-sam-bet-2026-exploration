# BET 2026 BASE075 regional-scaling-weight sensitivities

This branch contains 18 MFCL models. The 12 robust-normal models are derived
from **PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). Six focused DM models
also use the tested G5PROC-CEST Nmax10 implementation from
**PacificCommunity/ofp-sam-bet-2026-exploration@20c19b02498a6ee22cc39441a073159accca020b** (**experiment/cpue-hac4-single-area-tail-nmax10-20260719**). Every model retains
the corrected SA28-N5 BASE075 structure; N8 is excluded.

## Purpose

The source models use MVN regional-scaling penalty weight 50. This design
changes only parest flag 77 to 25, 10, or 5, allowing progressively more
freedom in relative biomass allocation among regions. Regional-scaling inputs,
flags 78-81, the 1965-1969 target/covariance window, CPUE observations and
sigma, phase timing, LF settings, tag inputs, age-length data, and selectivity
are held fixed.

The six DM models provide a focused interaction check at TAGF2ON across
NOCUT/CUT90 and the same three regional-scaling weights. They start directly at
Nmax 10 and retain the normal-model phase sequence, CPUE sigma, selectivity,
and all non-doitall inputs. HAC4 sigma, the separate selectivity-tail
experiment, and extra DM stabilization phases from the implementation source
are excluded. The phase-2/final report switch is retained only to avoid the
known early DM report failure. DM Nmax10 reduces composition influence and may
therefore increase the relative influence of CPUE indices; this subset is a
diagnostic interaction rather than an assumed remedy for index conflict.

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
| S013-S015 | NOCUT, DM G5PROC-CEST Nmax10 | 1 | 25, 10, 5 |
| S016-S018 | CUT90, DM G5PROC-CEST Nmax10 | 1 | 25, 10, 5 |

Relative to weight 50, weights 25, 10, and 5 increase the prior standard
deviation by approximately sqrt(2), sqrt(5), and sqrt(10), respectively. The
weight-50 controls remain on the source branch and are not duplicated here.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated models are under **sensitivity/**; exact input provenance is recorded
in each model's **input_manifest.csv**.
