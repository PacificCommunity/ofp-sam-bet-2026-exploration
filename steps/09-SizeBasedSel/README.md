# 09 SizeBasedSel

Size-based selectivity step after the main 0.2 KS tag mixing-period setup.

## What Changed

- Uses the same full 2024 `.frq`, `bet.2026.mix-0.2.ini`, 2026 tag file, and updated 2026 CAAL as 08-MixPeriod02.
- Sets fish flag 26 from 2 to 3 in `doitall.sh`, following the YFT 2026 length-based selectivity note.
- Keeps the extraction-fishery selectivity mapping and fishery-specific constraints from 03-RegFish, while index fisheries remain unshared under regional scaling.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 36 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- The all-release-group mixing-period override remains removed.
- `-999 26 3` is applied for size-based selectivity.
- `bet.reg_scaling` is read by MFCL because `parest_flags(77)>0`; flags 77-81 are set in `doitall.sh`.
- Index fisheries 29-33 are assigned separate selectivity groups 25-29 in regional-scaling steps; 03-05 retain the old single index selectivity group.

## Outstanding Checks

- Confirm with the modelling group that BET should use the same flag-26 setting as the YFT 2026 size-based selectivity experiment.
- Not yet reviewed after fitting: upper-age selectivity constraints inherited from 03-RegFish, especially `24.PL.ALL.WEST.3`.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

