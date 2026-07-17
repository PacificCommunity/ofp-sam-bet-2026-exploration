# BET 2026 S032-DM-G4-C0-NOCUT-ALREG075 MFCL LF Dirichlet-multinomial noRE; all index LF retained; four gear/data-source groups separating longline, purse seine, other extraction, and index fisheries; relative sample-size exponent fixed at MFCL default zero; no DM tail compression; uncut LF data; DM self-weighting/overdispersion sensitivity, not fixed duplicate-use correction; age-length variant REG075 from bet.2026.regional.0.75.age_length

This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.

## Design

| Control | Setting |
| --- | --- |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| LF grouping | G4: longline F1:F11; purse seine F12/F17:F20/F25:F28; other extraction F13:F16/F21:F24; index F29:F33 |
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

Semantic level: `REG075`.
Paired base sensitivity: `S015-DM-G4-C0-NOCUT`.
Model input: `reference-inputs/age-length-variants/bet.2026.regional.0.75.age_length`.
Source repository: https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build.
Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`.
Source file: `bet.2026.regional.0.75.age_length`.
SHA-256: `83e66c115df9ec2adabea262c650716dc711ad7ca9e1fdb98a5675778ee0ad74`.
Every other model input and all inherited normal/DM/cutoff controls are identical to the paired BASE075 sensitivity.

Status: generated and ready for validation; Kflow has not been submitted.
