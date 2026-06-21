# 06 Full2024

Full 2024 data step with weights-as-lengths plus lengths, new regional CPUE/index inputs, and 2026 tag reporting priors.

## What Changed

- Uses `bet.2026.wt.as.len.plus.len.frq` without year chopping.
- Moves from the 2021-chopped transition steps to the full 2024 frequency/catch/size series.
- Keeps old CAAL for this step, matching the plan's 'no change to CAAL file' instruction.
- Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.ini`, FixM M row applied
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.

## Outstanding Checks

- Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.
- This step intentionally keeps old CAAL so the CAAL update is isolated in 07-CAAL2026.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

