# 06 Full2024

Full 2024 data step with weights-as-lengths plus lengths, new regional CPUE/index inputs, and 2026 tag reporting priors.

## What Changed

- Uses `bet.2026.wt.as.len.plus.len.frq` without year chopping.
- Moves from the 2021-chopped transition steps to the full 2024 frequency/catch/size series.
- Keeps old CAAL for this step, matching the plan's 'no change to CAAL file' instruction.
- Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row applied.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.ini`, FixM M row applied; inserted MFCL 1007 tag flags for 91 release groups with 2 mixing periods and reporting rates excluded during mixing
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.
- `bet.reg_scaling` is read by MFCL because `parest_flags(77)>0`; flags 77-81 are set in `doitall.sh`.
- Index fisheries 29-33 are assigned separate selectivity groups 25-29 in regional-scaling steps; 03-05 retain the old single index selectivity group.

## Outstanding Checks

- Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review.
- This step intentionally keeps old CAAL so the CAAL update is isolated in 07-CAAL2026.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

