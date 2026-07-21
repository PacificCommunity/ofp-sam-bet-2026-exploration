# BET 2026 mix-0.15 unconstrained regional-scaling sensitivities

This branch contains 32 NOCUT MFCL models based on
**PacificCommunity/ofp-sam-bet-2026-exploration@81a456fa5c36ef1be5bd9da38308ef07ebc55ff4** (**experiment/normal-francis-initial-20260719**). All models use the SUB075
age-length input, the upstream mix-period 0.15 INI, and corrected SA28-N5
selectivity baseline. The F9-only non-decreasing constraint is removed, so no
fishery uses fish flag 16=1. CUT90 is excluded.
The retained Job 5319 FRQ already contains the selected 2026 effort-creep
adjustment, and the build never reapplies effort creep.

## Model design

| IDs | LF likelihood and weighting | Tag flag column 2 | REGW sequence |
| --- | --- | ---: | --- |
| S001-S004 | Robust normal; F21/F22/F23 DW10 | 0 (OFF) | 50, 11, 1, 0 |
| S005-S008 | Robust normal; F21/F22/F23 DW10 | 1 (ON) | 50, 11, 1, 0 |
| S009-S012 | DM G7OSHL-CEST; Nmax20 | 0 (OFF) | 50, 11, 1, 0 |
| S013-S016 | DM G7OSHL-CEST; Nmax20 | 1 (ON) | 50, 11, 1, 0 |
| S017-S020 | Robust normal; F21/F22/F23 DW10; PTTP26 prior | 0 (OFF) | 50, 11, 1, 0 |
| S021-S024 | Robust normal; F21/F22/F23 DW10; PTTP26 prior | 1 (ON) | 50, 11, 1, 0 |
| S025-S028 | DM G7OSHL-CEST; Nmax20; PTTP26 prior | 0 (OFF) | 50, 11, 1, 0 |
| S029-S032 | DM G7OSHL-CEST; Nmax20; PTTP26 prior | 1 (ON) | 50, 11, 1, 0 |

The four REGW values occur in the displayed order within every ID range. This
gives matched comparisons for LF likelihood, tag flag column 2, and regional-
scaling weight. Within each OFF/ON pair, all 98 values in tag flag column 2
change from 0 to 1; the other INI fields and model data are unchanged.

## PTTP-derived RTTP/PTTP reporting-rate prior sensitivity

The original S001-S016 models retain the upstream manual reporting-rate
penalties. S017-S032 are exact matched copies that propagate the 2026
PTTP-derived regional purse-seine priors to corresponding active
program-specific RTTP and PTTP/pooled groups. JPTP retains its upstream prior.

| Region | Fisheries | Active groups receiving Tom prior | JPTP handling | Inactive groups retained at zero | S017-S032 mean / target | S017-S032 penalty |
| --- | --- | --- | --- | --- | --- | ---: |
| 2 | F19/F20 | RTTP 7; PTTP 14 | Group 26 inactive | JPTP 26 | 0.4962 / 49.62 | 354.5 |
| 3 | F25/F27 | RTTP 10; PTTP 17 | Group 29 retains 0.5 / 50 / 1 | None | 0.5121 / 51.21 | 739.2 |
| 4 | F26/F28 | PTTP 18 | Group 30 inactive | RTTP 11; JPTP 30 | 0.5282 / 52.82 | 231.2 |

The mix-0.15 INI already maps these strata to separate program-by-region
groups, so the sensitivity changes prior values without changing membership.
The generator assigns values by reporting-group ID across the complete tag
matrix, but only where the corresponding parameter is active. Active flags are
unchanged. Inactive groups must retain zero initial, target, and penalty values
for native MFCL compatibility and are not activated by this sensitivity.

The 2026 report directly estimates priors from 2007-2024 PTTP tag-seeding data;
it does not estimate separate RTTP or JPTP priors. Applying the PTTP-derived
values to corresponding RTTP groups is therefore an explicit modelling
sensitivity, not a recommendation attributed to the report. JPTP retains its
program-specific upstream prior. Domestic Indonesian and Philippines purse-
seine groups remain unchanged, consistent with the report's recommendation
that these priors are not representative of them.

The source report is WCPFC-SC22-2026-SA-IP05, which reports PTTP purse-seine
means and penalties by assessment region. Exact project input values were
cross-checked against BET/bet.2026.single.region.ini in the 2026 INI-build
repository. The model input itself remains bet.2026.mix-0.15.ini, including its
existing separate Region 3 and Region 4 reporting-group membership:

https://meetings.wcpfc.int/node/32332

For robust-normal models, DW10 means F21/F22/F23 flag-49 divisor 200 against
the global divisor 20. It is not applied to DM models because fixed flag-49
divisors are not the DM observation-weight parameter. For DM models, Nmax20 is
the phase-1 maximum LF sample-size control. It is not a statement that the
realized effective sample size is exactly 20; realized information also
depends on the estimated DM concentration and relative sample-size exponent.

## DM G7OSHL grouping

| Group | Fisheries |
| --- | --- |
| Remaining longline | F1-F4, F6-F8, F10-F11 |
| Offshore longline | F5, F9 |
| Large-scale purse seine | F12, F19-F20, F25-F28 |
| Domestic purse seine | F17-F18 |
| Handline | F14-F15 |
| Other extraction | F13, F16, F21-F24 |
| Index | F29-F33 |

This changes only DM fish flag 68. Tag-reporting groups (flag 32), selectivity
groups (flag 24), the FRQ, and other model data are unchanged.

## INI provenance

The model INI is derived from
**PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@86627214cbac6db5766841e404bb32ea4f6afe61/BET/ini.mix-period/bet.2026.mix-0.15.ini**. TAGF2ON retains the
upstream tag flags. TAGF2OFF changes only all 98 values in tag flag column 2
from 1 to 0.

## Regional-scaling weights

| REGW | Effective covariance | Standardized SD multiplier | Role in this design |
| ---: | ---: | ---: | --- |
| 50 | Sigma / 50 | 0.1414 | Inherited strong constraint |
| 11 | Sigma / 11 | 0.3015 | Intermediate constraint |
| 1 | Sigma | 1.0000 | Empirical covariance without an extra precision multiplier |
| 0 | Not applicable | Not applicable | Regional-scaling penalty disabled |

The active regional-scaling data are 20 quarterly regional CPUE values for
1965-1969. MFCL converts each row to regional proportions, calculates their
mean and covariance, removes Region 5 as the MVN reference dimension, and uses

    penalty = 0.5 * weight * d' * Sigma^-1 * d.

Thus weights 50, 11, and 1 give standardized SD multipliers of 0.1414,
0.3015, and 1.0000 relative to the empirical MVN covariance; weight 0 disables
the regional-scaling penalty. These are penalty-strength interpretations, not
literal CVs on regional biomass or on each regional target mean.

The derivation, source/manual references, and distinction from target-relative
marginal CV are documented in
**notes/regional-scaling-weight-interpretation.md**.

## Rebuild

    bash scripts/build_regional_scaling_weight_sensitivities.sh

Generated inputs and file-level provenance are under **sensitivity/**.
