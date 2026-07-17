# BET 2026 S007-TC3-CUT100-DW1 global MFCL LF tail compression 3%; F21/F22/F23 observed LF counts in bins with midpoint above the 100 cm cutoff are set to zero; F21/F22/F23 LF likelihood downweight 1x with flag-49 divisor 20

This is one cell of the 36-model BET 2026 MFCL LF sensitivity factorial.

## Design

| Control | Setting |
| --- | --- |
| Global MFCL LF tail compression | 3% |
| F21/F22/F23 observed LF upper-bin zeroing | above 100 cm |
| F21/F22/F23 LF likelihood downweight | 1x; flag-49 divisor 20 |
| Regional-scaling penalty weight | 50 |

## Observed LF semantics

For F21/F22/F23, observed LF counts in bins with midpoint above the 100 cm cutoff are set to zero.
The bins remain as categories in the MFCL option-3 LF likelihood, and MFCL internally renormalizes retained counts. Counts are not transferred. An all-zero LF vector is represented by one `-1` whole-sample sentinel; record metadata and weight-frequency data remain unchanged.

## Provenance and controls

The refreshed reference bundle has input-set SHA-256 `a8e0598d06a1f795bf5cd0ced5c19e4462fa16921fde7412b295e460cacc8dbc`.
The retained Job 5319 effort-crept `bet.frq` has SHA-256 `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
`bet.ini`, `fishery_map.R`, and `tag_rep_map.R` are refreshed from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`; the 98 `tag_flags(:,2)` values remain 0.
`bet.tag` is the latest tag-prep main file at commit `79733c429b320e84ed5047aa6c932c8f19dab187` and is byte-identical to PDH 13-DataWeighting.
`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and `bet.reg_scaling.full` retains the complete 292x5 sensitivity source. The active matrix is exactly full-source rows 53:72.
The `doitall.sh` changes are limited to flag 313 and three new F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls remain unchanged.
No MFCL source or executable is changed.

## Cutoff audit

F21 removed 55 counts from 3 records (0 all-zero LF sentinels); F22 removed 4451 counts from 120 records (0 all-zero LF sentinels); F23 removed 529 counts from 14 records (0 all-zero LF sentinels)

Status: generated and ready for validation; Kflow has not been submitted.
