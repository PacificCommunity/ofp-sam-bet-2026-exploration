# 10 OPR

Orthogonal polynomial recruitment step after size-based selectivity.

## What Changed

- Uses the same input files as 09-SizeBasedSel.
- Applies OPR controls in PHASE 3 of `doitall.sh`, following John's suggestion to keep early phases on mean-plus-deviate recruitment.
- Uses OPR year effect 70, region effect 4, season effect 3, and no region-season interaction.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- `-999 26 3` is retained from 09-SizeBasedSel.
- PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.
- `1 149 0`, `1 398 0`, `2 177 0`, and `2 32 0` are applied at PHASE 3 for the OPR transfer.
- `1 155 70`, `1 216 4`, `1 217 3`, and `1 218 0` activate OPR year, region, season, and no region-season interaction.
- `2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.

## Outstanding Checks

- OPR year-effect dimension 70 follows the YFT 2026 experiment and should be revisited if the BET team chooses 50 or 30 instead.
- Not yet implemented: optional OPR region-season interaction (`1 218`) if diagnostics suggest it is needed.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

