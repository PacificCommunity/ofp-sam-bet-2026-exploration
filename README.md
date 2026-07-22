# BET 2026 DM Nmax and F25/F26 selectivity sensitivities

This public branch contains twelve matched BET 2026 MFCL Dirichlet-multinomial
fits. The design compares Nmax 15 and 25 across REGW 11, 25, and 100 and two
tag-reporting-rate prior settings. All models use G8PSSET grouping, common
R1-R5 CPUE sigma controls, SUB075, NOCUT, mix-period 0.15, TAGF2ON, and
independent seven-node F25/F26 selectivities.

## Models

| IDs | DM Nmax | REGW | Reporting-rate prior | Source jobs |
| --- | ---: | ---: | --- | --- |
| S001-S002 | 15 | 11, 25 | PTTP26 | 12314, 12313 |
| S003-S004 | 15 | 11, 25 | Manual 8/10 | 12751, 12299 |
| S005-S006 | 25 | 11, 25 | PTTP26 | 12314, 12313 |
| S007-S008 | 25 | 11, 25 | Manual 8/10 | 12751, 12299 |
| S009 | 15 | 100 | PTTP26 | 12314 |
| S010 | 15 | 100 | Manual 8/10 | 12751 |
| S011 | 25 | 100 | PTTP26 | 12314 |
| S012 | 25 | 100 | Manual 8/10 | 12751 |

Job 12751 completed its MFCL fit but failed while building model_payload.rds.
Models sourced from it therefore use its public model definition at commit
8df6a0e4b9856c5cd1e06ab7010c6e71c773f428.

## Nmax calibration

Nmax is an upper bound on DM effective sample size. It is not the mean ESS.
The comparison uses the empirical Francis ESS distribution from 2,399 positive
LF compositions in the matched initial robust-normal fits.

| Francis ESS statistic | Range |
| --- | ---: |
| Mean | 9.94-10.39 |
| Median | 8.62-10.53 |
| 75th percentile | 12.99-13.33 |
| 90th percentile | 20.41-20.83 |
| 95th percentile | 22.22-23.81 |

Nmax 15 is a conservative intermediate cap just above the Francis upper
quartile. Nmax 25 is an upper-tail cap just above the Francis 95th percentile.
The paired design tests whether reducing the active LF information cap improves
the balance between composition and CPUE fit without changing other controls.

Completed Nmax25 parent fits assigned a median realized ESS of 24.57 and placed
88.1% of compositions at ESS 24 or higher. This confirms that Nmax25 acts as an
active regularisation cap rather than a rarely reached upper bound.

MFCL uses:

    Neff = Nmax * (1 + lambda) / (Nmax + lambda)

The implementation is public in the ongoing-dev src/len_dm_nore.cpp source.

## G8PSSET grouping

| Group | Fisheries | Rationale |
| ---: | --- | --- |
| 1 | F1-F4, F6-F8, F10-F11 | Main longline composition process |
| 2 | F5, F9 | Offshore longline with a distinct sampling history |
| 3 | F12, F17, F18 | Purse-seine fisheries without set-type separation |
| 4 | F19, F25, F26 | Associated purse-seine fisheries |
| 5 | F20, F27, F28 | Unassociated purse-seine fisheries |
| 6 | F14, F15 | Handline fisheries |
| 7 | F13, F16, F21-F24 | Other extraction fisheries pooled for stable estimation |
| 8 | F29-F33 | Regional indices sharing the relative-abundance reweighting procedure |

    1 1 1 1 2 1 1 1 2 1 1 3 7 6 6 7 3 3 4 5 7 7 7 7 4 4 5 5 8 8 8 8 8

## F25/F26 selectivity

Fisheries 25 and 26 use independent cubic-spline selectivity groups 25 and 26
with seven nodes each. Both retain fish flag 16 = 2, flag 3 = 25, flag 26 = 2,
and flag 75 = 0. Other fisheries retain their existing selectivity controls.
See notes/f25-f26-selectivity.md.

## Common CPUE sigma

All models use common survey-index likelihood sigma controls:
R1-R5 fish flag 92 = 36, 25, 21, 24, 22. See notes/common-cpue-sigma.md.

## Public provenance

The DM source definitions are in PacificCommunity/ofp-sam-bet-2026-exploration,
branch experiment/mix015-unconstrained-g7oshl-dm20-20260721. Each model README
and input_manifest.csv records its source job and retained inputs.
