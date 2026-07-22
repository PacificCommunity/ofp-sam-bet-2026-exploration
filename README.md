# BET 2026 composition-weighting and associated-purse-seine selectivity sensitivities

This public branch contains eight matched BET 2026 MFCL fits comparing Francis
TA1.8 reweighting with a Dirichlet-multinomial observation model. All retain
SUB075, NOCUT, mix-period 0.15, TAGF2ON, the selected 2026 effort-creep FRQ,
the low-recapture-filtered tag file, and the SA28 selectivity baseline with a matched F25/F26 shared seven-node sensitivity.

## Models

| IDs | LF observation model | REGW | Reporting-rate prior | Source jobs |
| --- | --- | --- | --- | --- |
| S001-S002 | Francis TA1.8 plus CPUE MLE sigma | 11, 1 | PTTP26 | 12306, 12307 |
| S003-S004 | Francis TA1.8 plus CPUE MLE sigma | 11, 1 | Manual 8/10 | 12292, 12291 |
| S005-S006 | DM G8PSSET, Nmax25 | 11, 1 | PTTP26 | 12314, 12313 |
| S007-S008 | DM G8PSSET, Nmax25 | 11, 1 | Manual 8/10 | 12751, 12299 |

S005-S008 preserve their source controls except DM fish flag 68 and parest flag
342. Job 12751 completed its MFCL fit but failed while building
`model_payload.rds`; S007 therefore uses its public source definition at commit
`8df6a0e4b9856c5cd1e06ab7010c6e71c773f428`, not an incomplete output archive.

## Common CPUE sigma

All eight models use the same survey-index likelihood sigma controls:\nR1-R5 fish flag 92 = 36, 25, 21, 24, 22. The continuous reference values\nare the arithmetic means of the four independently fitted S001-S004\nMFCL-equivalent MLE sigma estimates. This removes CPUE weighting differences\nfrom the matched Francis/DM and selectivity comparisons. The calculation is\nrecorded in [notes/common-cpue-sigma.md](notes/common-cpue-sigma.md).\n\n## F25-F26 associated-purse-seine selectivity

All eight models apply the same targeted selectivity sensitivity. Fisheries 25
and 26 share one cubic-spline selectivity group with seven nodes. Both retain
the inherited dome-tail penalty (fish flag 16 = 2), upper-age boundary (flag 3
= 25), age-based length-overlap option (flag 26 = 2), and no forced zero at the
youngest age (flag 75 = 0). Other fisheries retain five nodes and their existing
shape controls. Group labels are renumbered contiguously through both the shared
index initialization and final index ungrouping phases.

This changes the two associated-purse-seine fisheries from ten independently
estimated spline coefficients to seven shared coefficients. It therefore adds
local shape resolution while reducing the combined parameter dimension by
three. The full rationale and selectivity audit are in
[notes/f25-f26-selectivity.md](notes/f25-f26-selectivity.md).

## DM G8PSSET grouping

Groups were defined before fitting from gear, purse-seine set type, fishery
definition, and composition sampling process. Poor aggregate fit alone was not
used to create a single-fishery group.

| Group | Fisheries | Rationale |
| ---: | --- | --- |
| 1 | F1-F4, F6-F8, F10-F11 | Main longline composition process |
| 2 | F5, F9 | Offshore longline; its earlier separation improved fit and it has a distinct sampling history |
| 3 | F12, F17, F18 | Purse-seine fisheries without set-type separation |
| 4 | F19, F25, F26 | Associated purse-seine fisheries |
| 5 | F20, F27, F28 | Unassociated purse-seine fisheries |
| 6 | F14, F15 | Handline fisheries |
| 7 | F13, F16, F21-F24 | Other extraction fisheries, pooled for stable estimation |
| 8 | F29-F33 | Regional indices sharing the relative-abundance reweighting procedure |

```text
1 1 1 1 2 1 1 1 2 1 1 3 7 6 6 7 3 3 4 5 7 7 7 7 4 4 5 5 8 8 8 8 8
```

Only flag 68 is regrouped. Selectivity groups (flag 24), tag-reporting groups
(flag 32), FRQ, INI, tag, age-length, and regional-scaling inputs are unchanged.

## Why Nmax is 25

Nmax is an upper bound on DM effective sample size, not its mean. It was
calibrated against 2,399 positive LF compositions in S001-S004 using the MFCL
sample-size cap of 1,000 and committed fishery-specific Francis divisors.

| Francis ESS statistic | S001-S004 range |
| --- | ---: |
| Mean | 9.94-10.39 |
| Median | 8.62-10.53 |
| 75th percentile | 12.99-13.33 |
| 90th percentile | 20.41-20.83 |
| 95th percentile | 22.22-23.81 |
| Maximum | 52.63-62.50 |

A cap of 25 lies just above the 95th percentile. Averaging each composition's
ESS across S001-S004, only 2.96% exceed 25. It preserves nearly all
Francis-supported information while preventing the small upper tail from
letting LF data dominate conflicting CPUE information. Nmax10 would bind many
supported compositions; Nmax40-60 would mainly accommodate the unstable tail.

MFCL uses `Neff = Nmax * (1 + lambda) / (Nmax + lambda)`, so realized
information is estimated below the cap. The implementation is public in
[`src/len_dm_nore.cpp`](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/ongoing-dev/src/len_dm_nore.cpp).

## Public provenance

The DM sources are in `PacificCommunity/ofp-sam-bet-2026-exploration`, branch
`experiment/mix015-unconstrained-g7oshl-dm20-20260721`. Each model README and
`input_manifest.csv` records source jobs, commits, and retained inputs.
