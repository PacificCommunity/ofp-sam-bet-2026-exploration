# BET 2026 S043-OPR-Y72-E2-S01-R50-I50-TAGF2ON BASE075 corrected N5 normal TC1 NOCUT DW1 OPR Y72 E2 S01 R50 I50 TAGF2ON

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

The refreshed reference bundle has input-set SHA-256 `66532e40a12135811e23ef92434e7d011a3db3a8846e56928ec4080106b97fa3`.
The retained Job 5319 effort-crept `bet.frq` has SHA-256 `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`; effort creep is not reapplied.
`bet.ini` starts from `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@548de05aff9bdc96a9ee7a817bbfd8068020ba26` path `BET/ini.mix-period/bet.2026.mix-0.2.ini`. S043-OPR-Y72-E2-S01-R50-I50-TAGF2ON restores all 98 `tag_flags(:,2)` values to the upstream value 1; its exact flag-column-2=0 control is `S042-OPR-Y72-E2-S01-R50-I50`; column 1 and every other INI value remain unchanged.
`fishery_map.R` comes from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`; `tag_rep_map.R` is regenerated from that metadata and the derived `bet.ini`.
`bet.tag` is the latest tag-prep main file at commit `79733c429b320e84ed5047aa6c932c8f19dab187` and is byte-identical to PDH 13-DataWeighting.
`bet.reg_scaling` is the MFCL-ready 20x5 active matrix and `bet.reg_scaling.full` retains the complete 292x5 sensitivity source. The active matrix is exactly full-source rows 53:72.
Beyond the inherited CUT90 and flag-49 treatment, `doitall.sh` changes only the documented selectivity treatment; all other Job 5319 controls remain unchanged.
No MFCL source or executable is changed.

## Cutoff audit

No cutoff audit is required because bet.frq is byte-identical to the Job 5319 archive.

## Corrected selectivity baseline

Semantic treatment: `SA28-N5`.
The corrected N5 baseline assigns independent selectivity groups to F1-F28, applies the audited young-age, F9 monotonicity, and upper-age constraints, fixes the first two ages of F29-F33 to zero, uses five nodes, and splits regional-index groups F29-F33 in phase 5.
This is the promoted core baseline: independent extraction groups, audited support constraints, five nodes, and phase-5 regional-index splitting.
The LF likelihood, CUT90 transform, composition weighting, BASE075 age-length input, tag controls, phase sequence, and regional-scaling settings are inherited from the paired reference.
Corrected selectivity source: `PacificCommunity/ofp-sam-bet-yft-2026-single-area@5363029b509cacf902aef2866efdc04634c89045`.

## Recruitment OPR control

This model uses the reviewed BET `apply_opr()` switch semantics.

| MFCL control | Fixed value |
| --- | ---: |
| Annual OPR coefficients, parest 155 | 72 |
| Compatibility state, parest 221 | 72 |
| End window, parest 202 | 2 |
| Season coefficients, parest 217 | 1 |
| Region coefficients, parest 216 | 50 |
| Region-season coefficients, parest 218 | 50 |
| Terminal penalty, parest 397 | 0 (disabled) |

The OPR structure is fixed at Y72-E2-S01-R50-I50. Terminal penalty is disabled in both models and is not a sensitivity axis.
Reviewed BET OPR apply_opr() semantics from the existing local ofp-sam-bet-2026-opr-sensitivities worktree, maintained in R/prepare_doitall.R.

Status: generated and ready for validation; Kflow has not been submitted.
