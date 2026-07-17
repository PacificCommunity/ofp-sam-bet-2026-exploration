# BET 2026 S064-DM-G2-C0-NOCUT-ALSUB075 MFCL LF Dirichlet-multinomial noRE; all index LF retained; two LF groups separating extraction and index fisheries; relative sample-size exponent fixed at MFCL default zero; no DM tail compression; uncut LF data; DM self-weighting/overdispersion sensitivity, not fixed duplicate-use correction; age-length variant SUB075 from bet.2026.sub.basin.0.75.age_length

This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.

## Design

| Control | Setting |
| --- | --- |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| LF grouping | G2: extraction F1:F28 in group 1; index F29:F33 in group 2 |
| Group scalar exponent d | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |
| Relative sample-size exponent c | C0: c remains fixed at MFCL default zero in every phase |
| DM maximum effective sample size | 1000 |
| LF preprocessing | Enabled; inherited N < 50 filter retained |
| LF tail compression | Percentage and DM-specific compression disabled |
| LF cutoff | None |
| Index LF | F29:F33 retained unchanged |
| Regional-scaling penalty weight | 50 |

## Interpretation

The normal-likelihood models use flag 49 to apply an extra /2 to LF streams used as both extraction and index data. MFCL option 11 ignores flag 49 and has no fixed 0.5 LF-contribution control, so that correction cannot be reproduced in these models.
Both extraction and index LF representations are retained. Grouping and DM overdispersion are the sensitivity axes; they are not exact duplicate-use corrections and do not model correlation introduced by aggregation differences between representations.
No LF cutoff transform is applied.

## Provenance and audit

The reference input-set SHA-256 is `a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc`.
The retained Job 5319 effort-crept `bet.frq` SHA-256 is `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
No LF transform is applied; bet.frq is byte-identical to the Job 5319 archive.
The refreshed tag-control `.ini` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`.
The tag data come from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
No MFCL source or executable is changed.

## Age-length variant

Semantic level: `SUB075`.
Paired base sensitivity: `S013-DM-G2-C0-NOCUT`.
Model input: `reference-inputs/age-length-variants/bet.2026.sub.basin.0.75.age_length`.
Source repository: https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build.
Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`.
Source file: `bet.2026.sub.basin.0.75.age_length`.
SHA-256: `426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c`.
Every other model input and all inherited normal/DM/cutoff controls are identical to the paired BASE075 sensitivity.

Status: generated and ready for validation; Kflow has not been submitted.
