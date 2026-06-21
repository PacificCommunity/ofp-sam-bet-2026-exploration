# 02 FixM

2023 diagnostic structure with the FixM M-scale row applied.

## What Changed

- Same 9-region, 41-fishery input structure as 01-Diag23.
- The M-related age parameter row is set to `-2.54917483258212e+00 -1 ...`.
- This is the M source used when preparing later 5-region inputs.

## Inputs

- `bet.frq`: same structural input as 01-Diag23, terminal year 2021
- `bet.ini`: FixM version of the diagnostic ini
- `bet.tag`: same tag structure as 01-Diag23
- `bet.age_length`: same CAAL structure as 01-Diag23

## Control Notes

- Inherited 9-region `doitall.sh` retained.
- This step is used as the reference for the M row copied into 03+.

## Outstanding Checks

- Confirm the FixM M row reproduces the intended fixed-M diagnostic before comparing against 03+.
- No fishery, tag, CAAL, or CPUE update is intended in this step.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

