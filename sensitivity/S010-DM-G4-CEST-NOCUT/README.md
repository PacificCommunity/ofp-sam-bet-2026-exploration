# BET 2026 S010-DM-G4-CEST-NOCUT MFCL LF Dirichlet-multinomial noRE; all extraction and index LF retained in four gear/data-source groups; separate index group; estimated relative sample-size covariate; no DM tail compression; uncut LF data with DM self-scaling, not fixed duplicate-use correction

This model is the LF Dirichlet-multinomial-noRE pilot in the BET 2026 sensitivity set.

## Design

| Control | Setting |
| --- | --- |
| LF likelihood | MFCL option 11, Dirichlet-multinomial without random effects |
| LF groups | Longline; purse seine; other extraction; index |
| Group scalar exponent | Starts at MFCL default zero; estimated from PHASE1 with fish flag 69 |
| Relative sample-size exponent | Starts at MFCL default zero; estimated from PHASE2 with fish flag 89 |
| DM maximum effective sample size | 1000 |
| LF tail compression | Disabled |
| LF cutoff | None |
| LF weighting | All extraction and index LF retained; separate index DM group; self-scaling |
| Regional-scaling penalty weight | 50 |

The four DM groups are generated from `fishery_map.R`, not from display order alone.
All extraction and index LF observations and the retained Job 5319 effort-creep treatment are unchanged.
The existing minimum input sample-size filter of 50 remains active through the LF preprocessing gate.
There are no WF observations; no DM weight-frequency parameter is activated.

## Interpretation

The normal-likelihood models use flag 49 to apply an extra /2 to LF streams used as both extraction and index data. MFCL option 11 ignores flag 49 and has no fixed 0.5 LF-contribution control, so that correction cannot be reproduced here.
S010 deliberately retains both LF representations and estimates the index fisheries as a separate DM group. It is a self-weighting and overdispersion sensitivity, not an exact duplicate-use correction; aggregation differences between the two representations may remain.
MFCL estimates one scalar exponent and one relative sample-size exponent per group.
The `dmsizemult` output must be used to inspect fitted effective sample sizes; raw objective values are not directly ranked against the normal-likelihood models.
Convergence, Hessian PDH, LF residuals, index fits, and key quantities must be considered together.

## Provenance

The reference input-set SHA-256 is `a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc`.
The retained Job 5319 effort-crept `bet.frq` SHA-256 is `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
The refreshed tag-control `.ini` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`.
The tag data come from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
No MFCL source or executable is changed.

Status: generated and ready for validation; Kflow has not been submitted.
