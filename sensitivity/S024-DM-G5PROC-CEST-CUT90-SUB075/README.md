# BET 2026 S024-DM-G5PROC-CEST-CUT90-SUB075 SUB075 DM G5PROC CEST CUT90

This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.

## Design

| Control | Setting |
| --- | --- |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| LF grouping | G5PROC: longline F1:F11; large-scale purse seine F12/F19:F20/F25:F28; domestic purse seine F17:F18; other extraction F13:F16/F21:F24; index F29:F33 |
| Group scalar exponent d | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |
| Relative sample-size exponent c | CEST: c is fixed at zero in PHASE1 and estimated from PHASE2 |
| DM maximum effective sample size | 1000 |
| LF preprocessing | Enabled; inherited N < 50 filter retained |
| LF tail compression | Percentage compression disabled; DM compression retains at least five class intervals (`parest flag 320 = 5`) |
| LF cutoff | Established F21/F22/F23 upper-bin cutoff above 90 cm |
| Index LF | F29:F33 retained unchanged |
| Regional-scaling penalty weight | 50 |

## Grouping rationale

This primary grouping follows observation and reweighting processes: catch-reweighted longline, large-scale purse seine, domestic purse seine, unreweighted or small-scale extraction, and abundance-reweighted index LF.
The grouping is informed by WCPFC-SC19-2023/SA-WP-05 and WCPFC-SC22-2026/SA-IP06; it changes DM dispersion sharing only, not fishery definitions, selectivity sharing, or LF observations.

## Interpretation

The normal-likelihood models use flag 49 to apply an extra /2 to LF streams used as both extraction and index data. MFCL option 11 ignores flag 49 and has no fixed 0.5 LF-contribution control, so that correction cannot be reproduced in these models.
Both extraction and index LF representations are retained. Grouping and DM overdispersion are the sensitivity axes; they are not exact duplicate-use corrections and do not model correlation introduced by aggregation differences between representations.
For F21/F22/F23, observed LF counts in bins with midpoint above the 90 cm cutoff are set to zero. This is exactly the established transform used by the corresponding normal-likelihood cutoff model; no index or other fishery LF is changed.

## Provenance and audit

The reference input-set SHA-256 is `a864b81f4d07321e977454a0d4c8389c8008b00159f374601f40ad6a6f7379d7`.
The retained Job 5319 effort-crept `bet.frq` SHA-256 is `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
F21 removed 56 counts from 3 records (1 all-zero LF sentinels); F22 removed 5760 counts from 122 records (0 all-zero LF sentinels); F23 removed 1375 counts from 16 records (0 all-zero LF sentinels)
The tag-control `.ini` comes from `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@548de05aff9bdc96a9ee7a817bbfd8068020ba26` path `BET/ini.mix-period/bet.2026.mix-0.2.ini`, with only `tag_flags(:,2)` changed from 1 to 0.
The tag data come from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
No MFCL source or executable is changed.

## Corrected selectivity baseline

Semantic treatment: `SA28-N5`.
The corrected N5 baseline assigns independent selectivity groups to F1-F28, applies the audited young-age, F9 monotonicity, and upper-age constraints, fixes the first two ages of F29-F33 to zero, uses five nodes, and splits regional-index groups F29-F33 in phase 5. Fish flag 26=2 evaluates the flag-57 cubic spline on scaled mean length-at-age to produce final selectivity-at-age; flag 61 supplies nodes on that coordinate.
This is the promoted core baseline: independent extraction groups, audited support constraints, five nodes, and phase-5 regional-index splitting.
The LF likelihood, CUT90 transform, composition weighting, BASE075 age-length input, tag controls, phase sequence, and regional-scaling settings are inherited from the paired reference.
Corrected selectivity source: `PacificCommunity/ofp-sam-bet-yft-2026-single-area@5363029b509cacf902aef2866efdc04634c89045`.

## Age-length variant

Semantic level: `SUB075`.
Paired base sensitivity: `S006-DM-G5PROC-CEST-CUT90`.
Model input: `reference-inputs/age-length-variants/bet.2026.sub.basin.0.75.age_length`.
Source repository: https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build.
Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`.
Source file: `bet.2026.sub.basin.0.75.age_length`.
SHA-256: `426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c`.
Every other model input and all inherited normal/DM/cutoff controls are identical to the paired BASE075 sensitivity.

## 41-model design context

This model belongs to the public 41-model design: 30 core age-length/LF combinations, two targeted N8 controls, five core TAGF2ON controls, and normal plus DM OPR tag-control pairs. Every model uses the complete single-area-derived selectivity baseline, including F29-F33 first-two-age zeros; N8 changes only F12 PS.JP.1 and F13 PL.JP.1. Age-length levels are BASE075, REG075, REG100, SUB075, and SUB100. DM models use DM-noRE, G5PROC, estimated relative sample-size exponent C, and Nmax 1000. TAGF2ON changes only all 98 tag_flags(:,2) values. OPR is activated in phase 3, movement in phase 4, and regional scaling in phase 5; terminal penalty is disabled. Fish flag 26=2 evaluates the flag-57 cubic spline on scaled mean length-at-age to produce final selectivity-at-age; flag-61 nodes use that coordinate, while flags 75/3/16 remain age constraints. This setting is separate from the LF likelihood. This model uses age-length level SUB075.

Status: generated and ready for validation; Kflow has not been submitted.
