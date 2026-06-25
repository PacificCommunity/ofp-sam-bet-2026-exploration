# 12 DataWeight40

Initial manual strategic data-weighting step with stronger global size-composition downweighting.

## What Changed

- Uses the same effort-creep `.frq`, mix-period `.ini`, tag, and CAAL as 11-EffortCreep.
- Keeps size-based selectivity and OPR controls from 10-OPR.
- Changes global LF and WF sample-size divisors from 20 to 40 in `doitall.sh`.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 36 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `bet.region_map.geojson`: single-file default BET 2026 5-region shape for mfclshiny/report maps
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- `-999 49 40` and `-999 50 40` replace the global LF/WF divisor-20 settings.
- Fishery-specific divisor-40 settings inherited from 03-RegFish are retained.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; `parest_flags(79)` starts the prior at the first period covered by all index fisheries; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- For the 292-period full-2024 models, `parest_flags(79)=290` means `292 - 290 + 1 = 3`, so the regional-scaling prior starts at period 3 instead of the invalid period-1 default.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- This is a first runnable manual weighting scenario, not a final tuned weighting scheme.
- Not yet implemented: alternative divisor scenarios or targeted CAAL/size weighting after diagnostics.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

