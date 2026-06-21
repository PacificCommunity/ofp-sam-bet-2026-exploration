# 11 EffortCreep

Minimum effort-creep scenario applied to the regional index fisheries.

## What Changed

- Uses 10-OPR controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.
- The transform follows the available single-region eff-creep file pattern: effort is multiplied by `1 + 0.01 * (year - 1952)`.
- Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 10-OPR `doitall.sh` controls are retained.
- No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`.

## Outstanding Checks

- Confirm that this 1 percent per year linear creep is the intended BET spatial minimum-effort-creep scenario.
- Not yet checked against a separately generated 5-region effort-creep `.frq` because the input repo currently exposes only the single-region eff-creep output.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

