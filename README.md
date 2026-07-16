# BET 2026 MFCL Length-Frequency Sensitivities

This analysis isolates three length-frequency (LF) choices around the reviewed
BET 2026 Step 12 effort-creep model. It uses the existing MFCL executable and
changes neither MFCL source code nor executable files.

## Job 5319 provenance

Every cell starts from the raw MFCL input set archived by Kflow Job 5319 in
`reference-inputs/job-5319/mfcl-inputs`. The archived `bet.frq` is the exact
Step 12 frequency file and already contains the agreed effort-creep adjustment
for index fisheries 29-33. Generation copies that file directly and never
reapplies effort creep.

| Provenance item | SHA-256 |
| --- | --- |
| Job 5319 archived input set | `993aa5e2d32f308ec8468765ddde35a08563c6ab4884c18f6f10660a5f1f37c4` |
| Job 5319 archived `bet.frq` | `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c` |

The input-set hash is the SHA-256 of the sorted `sha256sum *` manifest for the
nine files in the archived `mfcl-inputs` directory. The generator and validator
both check these hashes before proceeding.

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

The archived regional-scaling matrix has 292 rows and five columns. Each cell
writes source rows 53:72 verbatim to `bet.reg_scaling`, producing exactly a
20x5 matrix, and retains regional-scaling weight 50.

## Rebuild and validate

```bash
Rscript R/prepare_bet_2026_step_inputs.R
Rscript R/validate_sensitivities.R
```

Each of the 36 titled folders contains a complete `doitall` input set, a concise
README, and `input_manifest.csv`. Cutoff cells also contain
`model/lf_cutoff_audit.csv`.

## Kflow plan

Validation is required before Kflow staging. The high-level sequence is to
review the 36-cell manifest, stage or dry-run the complete matrix, inspect the
planned jobs, and then submit the approved cells as a separate action. Neither
the generator nor the validator submits Kflow jobs.
