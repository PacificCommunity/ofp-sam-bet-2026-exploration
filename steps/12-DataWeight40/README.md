# 12 DataWeight40

Initial manual strategic data-weighting step with stronger global size-composition downweighting.

## What Changed

- Uses the same effort-creep `.frq`, mix-period `.ini`, tag, and CAAL as 11-EffortCreep.
- Keeps size-based selectivity and OPR controls from 10-OPR.
- Changes global LF and WF sample-size divisors from 20 to 40 in `doitall.sh`.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- `-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.
- Fishery-specific divisor-40 settings inherited from 03-RegFish are retained.

## Outstanding Checks

- This is a first runnable manual weighting scenario, not a final tuned weighting scheme.
- Not yet implemented: alternative divisor scenarios or targeted CAAL/size weighting after diagnostics.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

