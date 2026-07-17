# BET 2026 MFCL Length-Frequency Sensitivities

This analysis isolates three length-frequency (LF) choices around the reviewed
BET 2026 effort-creep model. It uses the existing MFCL executable and changes
neither MFCL source code nor executable files.

## Reference baseline

Every cell retains the exact effort-crept `bet.frq` archived by Kflow Job 5319.
The tag-group controls and tag data are refreshed from
`PacificCommunity/ofp-sam-bet-2026-stepwise` branch
`experiment/tag-grouping-reg-scaling-2026`, commit
`26c74dc6f303faa951b1ab331d7de14ea20b7489`. Step 11 through Step 14 use the
same refreshed `bet.ini` and `bet.tag`, so the update does not change the
LF-sensitivity baseline or reapply effort creep.

The reference bundle is stored in `reference-inputs/job-5319/mfcl-inputs`.

| Provenance item | SHA-256 |
| --- | --- |
| Refreshed 10-file reference bundle | `806f1e81e0bbbc74c9925646d04947d8cb2abeea1e707140e8cf32a89f244a03` |
| Retained Job 5319 `bet.frq` | `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c` |
| Refreshed `bet.ini` | `3c9503e0762547762bab20b26997c3a4e627b0965b1d88418d71a1a17f40bb11` |
| Refreshed `bet.tag` | `a0365342054ae96ba9e48292b7bf46f469f0cf8b577985587b0e29fd49c23269` |

The refreshed ini contains 98 tag-release rows and retains
`tag_flags(:,2)=0` for every row. `tag_rep_map.R` matches the updated reporting
rate groups, initial values, targets, penalties, and fishery names used by
`bet.ini` and `bet.tag`. The existing Job 5319 `doitall.sh` is retained so this
refresh does not introduce later OPR controls.

## 36-cell design

The full factorial is defined in `job-config.R`.

| Axis | Levels | Scope |
| --- | --- | --- |
| MFCL LF tail compression | 0%, 1%, 3%, 5% | All observed LF samples |
| Observed upper-bin zeroing | None, above 100 cm, above 70 cm | F21, F22, F23 only |
| LF likelihood downweight | 1x, 10x, 100x | F21, F22, F23 only |
| Regional-scaling weight | 50 | Fixed in all cells |

For a cutoff cell, observed LF counts in bins with midpoint above the stated
cutoff are set to zero. The bins remain as categories in the MFCL option-3 LF
likelihood, and MFCL internally renormalizes the retained counts. Counts are not
moved to another bin. If no LF count remains, the LF vector is replaced by one
`-1` whole-sample sentinel. Record metadata and weight-frequency data are
unchanged.

Tail compression is the existing MFCL behavior controlled by flags 311 and 313;
it pools tail mass rather than discarding it. Downweighting adds only flag-49
overrides for F21/F22/F23, using divisors 20, 200, or 2000. All inherited Job
5319 fishery settings outside those three overrides remain unchanged.

Each model stores the MFCL-ready 20x5 active matrix as `bet.reg_scaling` and the
complete 292x5 sensitivity source as `bet.reg_scaling.full`. The active matrix
is exactly full-source rows 53:72; MFCL reads only `bet.reg_scaling`.

## Rebuild and validate

```bash
Rscript R/prepare_bet_2026_step_inputs.R
Rscript R/validate_sensitivities.R
```

Each of the 36 titled folders contains a complete `doitall` input set, a concise
README, and `input_manifest.csv`. Cutoff cells also contain
`model/lf_cutoff_audit.csv`. Neither script submits Kflow jobs.
