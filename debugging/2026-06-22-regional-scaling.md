# 2026-06-22 Regional Scaling Alignment

Plan v2 step 6 says the full-2024 transition should add the new regional CPUE
indices and the global regional-scaling CPUE input. The first runnable 12-step
candidate had the five regional index fisheries, but the first implementation
turned the regional-scaling penalty on too early and with a placeholder weight.

This note was updated after checking `reg_scaling_MVN_penalty (1).docx`,
MFCL source, and the MFCL manual.

## What Was Missing Or Wrong

| Gap | Why it mattered |
| --- | --- |
| No `bet.reg_scaling` file in 06-12 | MFCL reads `<root>.reg_scaling` only when regional scaling is active. |
| `parest_flags(77:81)` were first added in PHASE 1 | The 09/06/2026 note says the current `CPUE_scaling` approach should be used in early phases, with `Prior_reg_biomass` starting later. |
| `parest_flags(77)=1` was only a placeholder | The note lists tested weights 50, 150, 500, and 3000; 50 is the lightest documented starting point, approximately CV 0.1. |
| Index selectivity was first unshared from PHASE 1 | The note describes the unshared index selectivity as part of the `Prior_reg_biomass` switch, not the early `CPUE_scaling` setup. |
| Index CPUE grouping was still shared under `fish_flags(99)=29` | `Prior_reg_biomass` should ungroup index CPUE likelihood so each regional index has its own catchability/selectivity. |

## What Changed

| Area | Fix |
| --- | --- |
| Input file | Copied `BET/bet.2026.reg_scaling` from the frq-build repo to `bet.reg_scaling` in 06-12. |
| File shape | Verified each `bet.reg_scaling` has 292 rows and 5 columns, matching full 1952-2024 quarterly periods and 5 regions. |
| Early phases | PHASE 1-4 retain the current `CPUE_scaling` setup: index fisheries 29-33 share CPUE group 29 and selectivity group 25. |
| PHASE 5 switch | PHASE 5 switches to `Prior_reg_biomass`: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29. |
| Doitall flags | Added `1 77 50`, `1 78 1`, `1 79 0`, `1 80 0`, and `1 81 1` in PHASE 5 for the MVN regional-scaling penalty. |
| Reproducibility | Updated `R/prepare_bet_2026_step_inputs.R` so regeneration preserves the files, flags, manifests, and READMEs. |

## Flag Interpretation

- `fish_flags(i,92)` activates CPUE likelihood and gives sigma as `n/100`.
- `fish_flags(i,99)` groups CPUE index fisheries that share stationary catchability.
- `fish_flags(i,94)=1` allows unequal assumed sigma values within a grouped CPUE likelihood.
- `parest_flags(77)>0` activates the regional-scaling penalty and sets its weight.
- `parest_flags(78)=1` uses the mean regional-scaling target.
- `parest_flags(79)=0` and `parest_flags(80)=0` use all model periods.
- `parest_flags(81)=1` uses the multivariate-normal penalty.

## Current Assumptions

- Regional scaling starts in `06-Full2024`, as described in plan v2.
- Steps `03-05` remain 2021-terminal transition steps and do not use
  `bet.reg_scaling`; they retain one shared index selectivity group.
- Steps `06-12` use the 09/06/2026 `Prior_reg_biomass` pattern from PHASE 5.
- The initial regional-scaling weight is `parest_flags(77)=50`; 150, 500, and
  3000 remain documented candidates for later sensitivity or tuning.
- Arni's 19/06/2026 sigma values are retained in `fish_flags(92)` unless later
  residual diagnostics indicate they should be changed.

## Verification

- `Rscript R/prepare_bet_2026_step_inputs.R` completed successfully.
- All 06-12 `bet.reg_scaling` files are byte-identical to the frq-build source.
- `03-RegFish` still has 25 selectivity groups with index fisheries 29-33 in
  group 25.
- `06-Full2024` through `12-DataWeight40` now keep that shared index selectivity
  in PHASE 1 and switch to groups 25-29 in PHASE 5.

## Still To Review

- Review regional-scaling output once the full 06-12 Kflow jobs finish.
- Decide whether the `77=50` starting weight should be increased to 150, 500,
  or 3000 after diagnostics.
- Confirm after fitting that unshared index CPUE/selectivity plus the
  regional-scaling prior behaves as intended in CPUE residuals and regional
  scaling diagnostics.
