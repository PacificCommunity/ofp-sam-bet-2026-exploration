# BET 2026 S017-DM-G4-CEST-CUT90 MFCL LF Dirichlet-multinomial noRE; all index LF retained; four gear/data-source groups separating longline, purse seine, other extraction, and index fisheries; relative sample-size exponent estimated from PHASE2; no DM tail compression; established F21/F22/F23 upper-bin cutoff above 90 cm; DM self-weighting/overdispersion sensitivity, not fixed duplicate-use correction

This model is one LF Dirichlet-multinomial-noRE sensitivity in the BET 2026 set.

## Design

| Control | Setting |
| --- | --- |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| LF grouping | G4: longline F1:F11; purse seine F12/F17:F20/F25:F28; other extraction F13:F16/F21:F24; index F29:F33 |
| Group scalar exponent d | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |
| Relative sample-size exponent c | CEST: c is fixed at zero in PHASE1 and estimated from PHASE2 |
| DM maximum effective sample size | 1000 |
| LF preprocessing | Enabled; inherited N < 50 filter retained |
| LF tail compression | Percentage and DM-specific compression disabled |
| LF cutoff | Established F21/F22/F23 upper-bin cutoff above 90 cm |
| Index LF | F29:F33 retained unchanged |
| Regional-scaling penalty weight | 50 |

## Interpretation

The normal-likelihood models use flag 49 to apply an extra /2 to LF streams used as both extraction and index data. MFCL option 11 ignores flag 49 and has no fixed 0.5 LF-contribution control, so that correction cannot be reproduced in these models.
Both extraction and index LF representations are retained. Grouping and DM overdispersion are the sensitivity axes; they are not exact duplicate-use corrections and do not model correlation introduced by aggregation differences between representations.
For F21/F22/F23, observed LF counts in bins with midpoint above the 90 cm cutoff are set to zero. This is exactly the established transform used by the corresponding normal-likelihood cutoff model; no index or other fishery LF is changed.

## Provenance and audit

The reference input-set SHA-256 is `a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc`.
The retained Job 5319 effort-crept `bet.frq` SHA-256 is `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
F21 removed 56 counts from 3 records (1 all-zero LF sentinels); F22 removed 5760 counts from 122 records (0 all-zero LF sentinels); F23 removed 1375 counts from 16 records (0 all-zero LF sentinels)
The refreshed tag-control `.ini` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`.
The tag data come from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
No MFCL source or executable is changed.

Status: generated and ready for validation; Kflow has not been submitted.
