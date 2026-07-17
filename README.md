# BET 2026 LF sensitivity grid

This branch contains a focused `3 x 3` TC1 design: `NOCUT`, `CUT70`, and `CUT90`, each combined with target-fishery LF downweight factors 1, 5, and 10. It also contains one LF Dirichlet-multinomial-noRE pilot using uncut data and baseline weighting. Three previously fitted combinations had a positive-definite Hessian (PDH), one had a non-PDH Hessian, and six models are newly prepared. The full 36-model factorial design remains on `main`.

## Selected models

| Model | LF likelihood | LF cutoff | LF downweight | Hessian PDH | Non-positive eigenvalues | Smallest eigenvalue |
|---|---|---:|---:|:---:|---:|---:|
| `S001-TC1-NOCUT-DW1` | Normal, TC1 | None | 1 | No | 1 | -19.2 |
| `S002-TC1-NOCUT-DW5` | Normal, TC1 | None | 5 | Not run | - | - |
| `S003-TC1-NOCUT-DW10` | Normal, TC1 | None | 10 | Yes | 0 | 6.438e-8 |
| `S004-TC1-CUT70-DW1` | Normal, TC1 | 70 cm | 1 | Yes | 0 | 1.719e-7 |
| `S005-TC1-CUT70-DW5` | Normal, TC1 | 70 cm | 5 | Not run | - | - |
| `S006-TC1-CUT70-DW10` | Normal, TC1 | 70 cm | 10 | Yes | 0 | 1.328e-7 |
| `S007-TC1-CUT90-DW1` | Normal, TC1 | 90 cm | 1 | Not run | - | - |
| `S008-TC1-CUT90-DW5` | Normal, TC1 | 90 cm | 5 | Not run | - | - |
| `S009-TC1-CUT90-DW10` | Normal, TC1 | 90 cm | 10 | Not run | - | - |
| `S010-DM-G4-CEST-NOCUT` | DM-noRE | None | n/a | Not run | - | - |

## Dirichlet-multinomial pilot

`S010` uses MFCL LF likelihood option 11 with four fishery groups: longline, purse seine, other extraction, and index. The group scalar is estimated from the first fit, and the relative sample-size exponent is activated in the second fit. The inherited minimum sample-size filter remains active, percentage and DM-specific tail compression are disabled, the DM effective-sample-size upper bound is 1000, and no weight-frequency DM controls are activated.

This pilot intentionally uses `NOCUT` and retains all extraction and index LF observations. The normal-likelihood models use flag 49 to apply an extra `/2` to LF streams used as both extraction and index data, but MFCL option 11 ignores flag 49 and has no fixed `0.5` LF-contribution control. S010 therefore cannot reproduce that correction. Instead, it estimates the index fisheries as a separate fourth DM group alongside longline, purse-seine, and other extraction fisheries.

S010 is a deliberate DM self-weighting and overdispersion sensitivity, not an exact duplicate-use correction. The two retained LF representations can differ through aggregation, and the separate group does not model their correlation. Its `dmsizemult`, convergence, Hessian, LF residuals, index fits, and key quantities should be reviewed together; raw objective values are not directly ranked against the normal-likelihood models.

The complete machine-readable selection is in [`SENSITIVITY_SELECTION.csv`](SENSITIVITY_SELECTION.csv); the three retained fitted PDH results remain in [`PDH_SELECTION.csv`](PDH_SELECTION.csv). Historical IDs are replaced by branch-local sequential IDs. The former `S034-TC1-CUT70-DW100` result is preserved in Git history and is not attributed to `DW5` because its weighting changed.

## Historical 90 cm treatment

The 2023 assessment excluded reported lengths above 90 cm from the corresponding Indonesia, Philippines, and Vietnam domestic small-fish compositions because the large fish were suspected to reflect gear misreporting. The current mapping is F21 `DOM.ID.2`, F22 `DOM.PH.2`, and F23 `DOM.VN.2`.

For each `CUT90` model, the 90 cm bin is retained and only observed LF bins with midpoint greater than 90 cm are set to zero. Counts are not transferred, all WF observations and record metadata are preserved, and the treatment is not applied to any other fishery. See [WCPFC-SC19-2023/SA-WP-05](https://meetings.wcpfc.int/node/19353).

The corresponding flag-49 divisors are 20, 100, and 200 for F21/F22/F23 only. Every other fishery retains the archived Job 5319 weighting. Divisor 20 is the historical baseline; divisors 100 and 200 are target-only sensitivity levels, not settings claimed to have been used in the 2023 assessment.

## Input provenance

- Model snapshots are inherited from exploration `main` commit `ef267dc`.
- Refreshed reference input-set SHA-256: `a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc`.
- Archived Job 5319 `bet.frq` SHA-256: `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`.
- The tag-group `.ini` is from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`.
- Refreshed `bet.ini` SHA-256: `3c9503e0762547762bab20b26997c3a4e627b0965b1d88418d71a1a17f40bb11`.
- The tag observations are from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
- Authoritative `bet.tag` SHA-256: `3f1b836a844ec2ca8e70fc5814d94c5a1ebc37ff4a5571c1dc1f6b83e477dfe8`.
- The archived Job 5319 FRQ and `doitall.sh` are retained; effort creep is not reapplied.
- Active regional scaling is `20 x 5`; the complete `292 x 5` source matrix is retained for alternative period sensitivities.

Only the ten directories listed above are run candidates on this branch. The six newly prepared models have not been submitted to Kflow. Use `main` to inspect the complete 36-model design.
