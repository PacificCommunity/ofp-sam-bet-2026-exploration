# BET 2026 S024-TC5-CUT70-DW10 global MFCL LF tail compression 5%; F21/F22/F23 observed LF counts in bins with midpoint above the 70 cm cutoff are set to zero; F21/F22/F23 LF likelihood downweight 10x with flag-49 divisor 200

This is one cell of the 36-model BET 2026 MFCL LF sensitivity factorial.

## Design

| Control | Setting |
| --- | --- |
| Global MFCL LF tail compression | 5% |
| F21/F22/F23 observed LF upper-bin zeroing | above 70 cm |
| F21/F22/F23 LF likelihood downweight | 10x; flag-49 divisor 200 |
| Regional-scaling penalty weight | 50 |

## Observed LF semantics

For F21/F22/F23, observed LF counts in bins with midpoint above the 70 cm cutoff are set to zero.
The bins remain as categories in the MFCL option-3 LF likelihood, and MFCL internally renormalizes retained counts. Counts are not transferred. An all-zero LF vector is represented by one `-1` whole-sample sentinel; record metadata and weight-frequency data remain unchanged.

## Provenance and controls

All inputs derive from the exact raw MFCL bundle archived by Kflow Job 5319 (input-set SHA-256 `993aa5e2d32f308ec8468765ddde35a08563c6ab4884c18f6f10660a5f1f37c4`).
The archived effort-crept `bet.frq` has SHA-256 `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
Archived regional-scaling rows 53:72 are copied verbatim as a 20x5 matrix. The `doitall.sh` changes are limited to flag 313 and three new F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls remain unchanged.
No MFCL source or executable is changed.

## Cutoff audit

F21 removed 61 counts from 3 records (1 all-zero LF sentinels); F22 removed 10125 counts from 128 records (1 all-zero LF sentinels); F23 removed 4264 counts from 19 records (0 all-zero LF sentinels)

Status: generated and ready for validation; Kflow has not been submitted.
