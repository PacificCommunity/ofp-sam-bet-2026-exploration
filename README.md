# BET 2026 LF, age-length, and selectivity sensitivity set

This branch retains the explicit `17 x 5 = 85` LF-age-length factorial, adds six focused BASE075 DM grouping models, and adds six paired BASE075 selectivity models, for 97 models in total. S001:S017 retain the existing BASE075 names and files. S018:S085 pair each base configuration with REG075, REG100, SUB075, or SUB100 while changing only `model/bet.age_length`. S086:S091 change only the sharing of DM dispersion parameters and the established cutoff treatment. S092:S097 isolate three selectivity treatments under matched CUT90 normal and G5PROC-CEST DM configurations.

## Age-length factorial

| Level | Definition | Model IDs |
| --- | --- | --- |
| `BASE075` | Current 2026 base body with the 181 effective-sample-size values changed from 1 to 0.75 | S001:S017 |
| `REG075` | Exact `BET/bet.2026.regional.0.75.age_length` | S018:S034 |
| `REG100` | Exact `BET/bet.2026.regional.1.age_length` | S035:S051 |
| `SUB075` | Exact `BET/bet.2026.sub.basin.0.75.age_length` | S052:S068 |
| `SUB100` | Exact `BET/bet.2026.sub.basin.1.age_length` | S069:S085 |

The four alternatives are vendored under `reference-inputs/age-length-variants` from `PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build` commit `96a06d21ef3c666f39ce456d3a6818b6c17324c4`. The plain source `BET/bet.2026.age_length` is used only to document the BASE075 derivation and is not included as a sixth BASE100 factorial level.

The 17 factorial LF configurations comprise the focused `3 x 3` TC1 cutoff/downweight design and eight LF Dirichlet-multinomial-noRE sensitivities: the balanced NOCUT factorial `G1/G2/G4 x C0/CEST`, plus focused G4-CEST CUT70 and CUT90 variants. Six additional models evaluate the primary `G5PROC` and secondary `G7QUAL` groupings at NOCUT, CUT70, and CUT90 without multiplying them across age-length inputs. The full 36-model LF design remains on `main`.

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
| `S011-DM-G1-C0-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S012-DM-G1-CEST-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S013-DM-G2-C0-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S014-DM-G2-CEST-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S015-DM-G4-C0-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S016-DM-G4-CEST-CUT70` | DM-noRE | 70 cm | n/a | Not run | - | - |
| `S017-DM-G4-CEST-CUT90` | DM-noRE | 90 cm | n/a | Not run | - | - |
| `S086-DM-G5PROC-CEST-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S087-DM-G5PROC-CEST-CUT70` | DM-noRE | 70 cm | n/a | Not run | - | - |
| `S088-DM-G5PROC-CEST-CUT90` | DM-noRE | 90 cm | n/a | Not run | - | - |
| `S089-DM-G7QUAL-CEST-NOCUT` | DM-noRE | None | n/a | Not run | - | - |
| `S090-DM-G7QUAL-CEST-CUT70` | DM-noRE | 70 cm | n/a | Not run | - | - |
| `S091-DM-G7QUAL-CEST-CUT90` | DM-noRE | 90 cm | n/a | Not run | - | - |
| `S092-TC1-CUT90-DW5-SA28-N5` | Normal, TC1 | 90 cm | 5 | Not run | - | - |
| `S093-TC1-CUT90-DW5-SA28-N8` | Normal, TC1 | 90 cm | 5 | Not run | - | - |
| `S094-TC1-CUT90-DW5-IDX-Z2` | Normal, TC1 | 90 cm | 5 | Not run | - | - |
| `S095-DM-G5PROC-CEST-CUT90-SA28-N5` | DM-noRE | 90 cm | n/a | Not run | - | - |
| `S096-DM-G5PROC-CEST-CUT90-SA28-N8` | DM-noRE | 90 cm | n/a | Not run | - | - |
| `S097-DM-G5PROC-CEST-CUT90-IDX-Z2` | DM-noRE | 90 cm | n/a | Not run | - | - |

## Paired selectivity design

The six new models form three isolated selectivity contrasts under two likelihood configurations. The normal reference is `S008-TC1-CUT90-DW5`; the DM reference is `S088-DM-G5PROC-CEST-CUT90`, which retains G5PROC and estimates the relative sample-size exponent from PHASE2. Every cell uses BASE075 age-length inputs and the established F21/F22/F23 CUT90 transform.

| Selectivity state | Normal TC1-CUT90-DW5 | DM G5PROC-CEST-CUT90 |
|---|---|---|
| Current five-region reference | `S008` | `S088` |
| `SA28-N5` | `S092` | `S095` |
| `SA28-N8` | `S093` | `S096` |
| `IDX-Z2` | `S094` | `S097` |

`SA28-N5` and `SA28-N8` give F1:F28 independent selectivity groups and adopt the pinned single-area extraction young-age, monotonic, and upper-age constraints. `SA28-N5` retains five spline nodes for F12/F13; `SA28-N8` uses eight. Both preserve the current F29:F33 regional-index configuration. `IDX-Z2` retains current extraction settings and adds first-two-age-zero constraints only to F29:F33. No model combines the extraction and index treatments, and no CUT70 selectivity variant is generated.

## Dirichlet-multinomial pilot

All eight DM models use MFCL LF likelihood option 11. The group scalar `d` is estimated from PHASE1. In C0 models, the relative sample-size exponent `c` stays fixed at the MFCL default zero in every phase; in CEST models it is fixed at zero in PHASE1 and estimated from PHASE2. The inherited minimum sample-size filter remains active, percentage tail compression is disabled, DM-specific tail compression retains at least five class intervals (`parest flag 320 = 5`), the DM effective-sample-size upper bound is 1000, and no weight-frequency DM controls are activated.

The NOCUT factorial uses three groupings. G1 pools F1:F33. G2 separates extraction F1:F28 from index F29:F33. G4 separates longline F1:F11; purse seine F12, F17:F20, and F25:F28; other extraction F13:F16 and F21:F24; and index F29:F33. S016 and S017 retain G4-CEST and reuse exactly the established F21/F22/F23 CUT70 and CUT90 transformations from the corresponding normal-likelihood models. No G1, G2, or C0 cutoff variants are included.

### Evidence-based grouping additions

`G5PROC` is the recommended primary grouping. It shares DM dispersion within five observation processes: longline extraction F1:F11; large-scale purse seine F12/F19:F20/F25:F28; domestic purse seine F17:F18; other extraction F13:F16/F21:F24; and abundance-reweighted index F29:F33. This reflects the distinct sampling, filtering, and reweighting procedures used to construct the 2026 LF inputs while retaining enough observations per group for stable estimation.

`G7QUAL` is a secondary challenge model. It separates associated purse seine F19/F25:F26 from unassociated purse seine F20/F27:F28, retains domestic purse seine F17:F18, pools the low-catch and multimodal Japanese PS/PL F12:F13, pools the remaining other extraction F14:F16/F21:F24, and keeps longline extraction and index fisheries separate. It is deliberately not the default because grouping on observed fit quality can absorb structural selectivity mismatch as apparent overdispersion.

The design follows the 2023 assessment distinction between extraction and index compositions, including the duplicated-source concern and the documented poorer aggregate fits for Japanese PS/PL and index LF. It also uses the 2026 input-preparation evidence that longline, large-scale purse seine, domestic purse seine, other small-scale fisheries, and index fisheries have materially different sampling and reweighting processes. See [WCPFC-SC19-2023/SA-WP-05](https://meetings.wcpfc.int/node/19353) and [WCPFC-SC22-2026/SA-IP06](https://meetings.wcpfc.int/node/32346).

The 2023 DM pilot increased the effective weight of composition data and degraded CPUE fits, so improved LF fit alone is not an acceptance criterion. Compare fitted `dmsizemult`, quarterly LF residuals, CPUE fits, convergence, Hessian PDH, and key management quantities. Sparse series such as region-2 purse seine and index region 5 are pooled rather than assigned singleton DM parameters.

All index LF observations are retained. The normal-likelihood models use flag 49 to apply an extra `/2` to LF streams used as both extraction and index data, but MFCL option 11 ignores flag 49 and has no fixed `0.5` LF-contribution control. These are therefore deliberate grouping, self-weighting, and overdispersion sensitivities, not exact duplicate-use corrections. The retained LF representations can differ through aggregation, and the groups do not model their correlation. Their `dmsizemult`, convergence, Hessian, LF residuals, index fits, and key quantities should be reviewed together; raw objective values are not directly ranked against the normal-likelihood models.

The authoritative 97-cell generation and discovery table is `job-config.R`. The original machine-readable 17 x 5 factorial selection remains in [`SENSITIVITY_SELECTION.csv`](SENSITIVITY_SELECTION.csv); the three retained fitted PDH results remain in [`PDH_SELECTION.csv`](PDH_SELECTION.csv). Historical IDs are replaced by branch-local sequential IDs. The former `S034-TC1-CUT70-DW100` result is preserved in Git history and is not attributed to `DW5` because its weighting changed.

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

All 91 directories are explicit run candidates on this branch. The 68 alternative age-length models and six focused grouping models have not been submitted to Kflow. Use `main` to inspect the complete 36-model LF design.
