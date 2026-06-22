# 10 OPR

Orthogonal polynomial recruitment step after size-based selectivity.

## What Changed

- Uses the same input files as 09-SizeBasedSel.
- Applies OPR controls in PHASE 3 of `doitall.sh`, following John's suggestion to keep early phases on mean-plus-deviate recruitment.
- Uses OPR year effect 70, region effect 4, season effect 3, and no region-season interaction.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 36 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- `-999 26 3` is retained from 09-SizeBasedSel.
- PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.
- `1 149 0`, `1 398 0`, `2 177 0`, and `2 32 0` are applied at PHASE 3 for the OPR transfer.
- `1 155 70`, `1 216 4`, `1 217 3`, and `1 218 0` activate OPR year, region, season, and no region-season interaction.
- `2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; `parest_flags(79)` starts the prior at the first period covered by all index fisheries; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- For the 292-period full-2024 models, `parest_flags(79)=290` means `292 - 290 + 1 = 3`, so the regional-scaling prior starts at period 3 instead of the invalid period-1 default.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- OPR year-effect dimension 70 follows the YFT 2026 experiment and should be revisited if the BET team chooses 50 or 30 instead.
- Not yet implemented: optional OPR region-season interaction (`1 218`) if diagnostics suggest it is needed.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

