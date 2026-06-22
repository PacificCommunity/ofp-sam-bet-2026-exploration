# 07 CAAL2026

Full 2024 data step with the updated 2026 CAAL / age_length input.

## What Changed

- Uses the same full 2024 `.frq`, 2026 `.ini`, and 2026 `.tag` as 06-Full2024.
- Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.
- The 2026 age_length file has 181 records through 2024 and includes Japan/SPC new age data.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.ini`, FixM M row applied; inserted MFCL 1007 tag flags for 91 release groups with 2 mixing periods and reporting rates excluded during mixing
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.

## Outstanding Checks

- After fitting, compare CAAL likelihood and age residuals against 06-Full2024.
- Confirm the 2026 CAAL source remains the chosen final CAAL file before later sensitivity runs.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

