# BET 2026 S019-TC1-NOCUT-DW1-SUB075 SUB075 normal TC1 NOCUT DW1

This is one model in the curated BET 2026 TC1 LF sensitivity set.

## Design

| Control | Setting |
| --- | --- |
| Global MFCL LF tail compression | 1% |
| F21/F22/F23 observed LF upper-bin zeroing | none |
| F21/F22/F23 LF likelihood downweight | 1x; flag-49 divisor 20 |
| Regional-scaling penalty weight | 50 |

## Observed LF semantics

For F21/F22/F23, observed LF counts are unchanged; no cutoff is applied.
This model retains its previously selected cutoff treatment.
The bins remain as categories in the MFCL option-3 LF likelihood, and MFCL internally renormalizes retained counts. Counts are not transferred. An all-zero LF vector is represented by one `-1` whole-sample sentinel; record metadata and weight-frequency data remain unchanged.

## Provenance and controls

The refreshed reference bundle has input-set SHA-256 `a864b81f4d07321e977454a0d4c8389c8008b00159f374601f40ad6a6f7379d7`.
The retained Job 5319 effort-crept `bet.frq` has SHA-256 `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
`bet.ini` comes wholesale from `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@548de05aff9bdc96a9ee7a817bbfd8068020ba26` path `BET/ini.mix-period/bet.2026.mix-0.2.ini`; the only intentional deviation is changing all 98 `tag_flags(:,2)` values from 1 to 0.
`fishery_map.R` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`; `tag_rep_map.R` is regenerated from that metadata and the derived `bet.ini`.
`bet.tag` is the latest tag-prep main file at commit `79733c429b320e84ed5047aa6c932c8f19dab187` and is byte-identical to PDH 13-DataWeighting.
`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and `bet.reg_scaling.full` retains the complete 292x5 sensitivity source. The active matrix is exactly full-source rows 53:72.
Beyond the inherited CUT90 and flag-49 treatment, `doitall.sh` changes only the documented selectivity treatment; all other Job 5319 controls remain unchanged.
No MFCL source or executable is changed.

## Cutoff audit

No cutoff audit is required because bet.frq is byte-identical to the Job 5319 archive.

## Corrected selectivity baseline

Selectivity nodes: `N5`. The single-area-derived F1-F28 structure is common to all 41 models.
The corrected N5 baseline assigns independent selectivity groups to F1-F28, applies the audited young-age, F9 monotonicity, and upper-age constraints, fixes the first two ages of F29-F33 to zero, uses five nodes, and splits regional-index groups F29-F33 in phase 5. Fish flag 24 group labels are contiguous in every phase without changing group membership. Fish flag 26=2 evaluates the flag-57 cubic spline on scaled mean length-at-age to produce final selectivity-at-age; flag 61 supplies nodes on that coordinate.
This is the promoted core baseline: independent extraction groups, audited support constraints, five nodes, and phase-5 regional-index splitting.
The LF likelihood, CUT90 transform, composition weighting, BASE075 age-length input, tag controls, phase sequence, and regional-scaling settings are inherited from the paired reference.
Corrected selectivity source: `PacificCommunity/ofp-sam-bet-yft-2026-single-area@5363029b509cacf902aef2866efdc04634c89045`.

## Age-length variant

Semantic level: `SUB075`.
Paired base sensitivity: `S001-TC1-NOCUT-DW1`.
Model input: `reference-inputs/age-length-variants/bet.2026.sub.basin.0.75.age_length`.
Source repository: https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build.
Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`.
Source file: `bet.2026.sub.basin.0.75.age_length`.
SHA-256: `426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c`.
Every other model input and all inherited normal/DM/cutoff controls are identical to the paired BASE075 sensitivity.

## 41-model design context

This model belongs to the public 41-model design: 30 core age-length/LF combinations, two targeted N8 controls, five core TAGF2ON controls, and normal plus DM OPR tag-control pairs. Every model uses the complete single-area-derived selectivity baseline, including F29-F33 first-two-age zeros; N8 changes only F12 PS.JP.1 and F13 PL.JP.1. Age-length levels are BASE075, REG075, REG100, SUB075, and SUB100. DM models use DM-noRE, G5PROC, estimated relative sample-size exponent C, and Nmax 25. TAGF2ON changes only all 98 tag_flags(:,2) values. OPR is activated in phase 3, movement in phase 4, and regional scaling in phase 5; terminal penalty is disabled. Fish flag 26=2 evaluates the flag-57 cubic spline on scaled mean length-at-age to produce final selectivity-at-age; flag-61 nodes use that coordinate, while flags 75/3/16 remain age constraints. This setting is separate from the LF likelihood. This model uses age-length level SUB075.

Status: generated and ready for validation; Kflow has not been submitted.
