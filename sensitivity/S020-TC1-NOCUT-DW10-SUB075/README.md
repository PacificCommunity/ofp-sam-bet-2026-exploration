# BET 2026 S020-TC1-NOCUT-DW10-SUB075 SUB075 normal TC1 NOCUT DW10

This is one model in the curated BET 2026 TC1 LF sensitivity set.

## Design

| Control | Setting |
| --- | --- |
| Global MFCL LF tail compression | 1% |
| F21/F22/F23 observed LF upper-bin zeroing | none |
| F21/F22/F23 LF likelihood downweight | 10x; flag-49 divisor 200 |
| Regional-scaling penalty weight | 50 |

## Observed LF semantics

For F21/F22/F23, observed LF counts are unchanged; no cutoff is applied.
This model retains its previously selected cutoff treatment.
The bins remain as categories in the MFCL option-3 LF likelihood, and MFCL internally renormalizes retained counts. Counts are not transferred. An all-zero LF vector is represented by one `-1` whole-sample sentinel; record metadata and weight-frequency data remain unchanged.

## Provenance and controls

The refreshed reference bundle has input-set SHA-256 `66532e40a12135811e23ef92434e7d011a3db3a8846e56928ec4080106b97fa3`.
The retained Job 5319 effort-crept `bet.frq` has SHA-256 `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
`bet.ini` comes wholesale from `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@548de05aff9bdc96a9ee7a817bbfd8068020ba26` path `BET/ini.mix-period/bet.2026.mix-0.2.ini`; the only intentional deviation is changing all 98 `tag_flags(:,2)` values from 1 to 0.
`fishery_map.R` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`; `tag_rep_map.R` is regenerated from that metadata and the derived `bet.ini`.
`bet.tag` is the latest tag-prep main file at commit `79733c429b320e84ed5047aa6c932c8f19dab187` and is byte-identical to PDH 13-DataWeighting.
`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and `bet.reg_scaling.full` retains the complete 292x5 sensitivity source. The active matrix is exactly full-source rows 53:72.
The `doitall.sh` changes are limited to flag 313 and three new F21/F22/F23 flag-49 overrides; all other inherited Job 5319 controls remain unchanged.
No MFCL source or executable is changed.

## Cutoff audit

No cutoff audit is required because bet.frq is byte-identical to the Job 5319 archive.

## Age-length variant

Semantic level: `SUB075`.
Paired base sensitivity: `S002-TC1-NOCUT-DW10`.
Model input: `reference-inputs/age-length-variants/bet.2026.sub.basin.0.75.age_length`.
Source repository: https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build.
Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`.
Source file: `bet.2026.sub.basin.0.75.age_length`.
SHA-256: `426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c`.
Every other model input and all inherited normal/DM/cutoff controls are identical to the paired BASE075 sensitivity.

Status: generated and ready for validation; Kflow has not been submitted.
