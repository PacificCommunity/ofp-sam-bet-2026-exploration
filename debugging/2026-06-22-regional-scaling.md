# 2026-06-22 Regional Scaling Alignment

Plan v2 step 6 says the full-2024 transition should add the new regional CPUE
indices and the global regional-scaling CPUE input. The first runnable 12-step
candidate had the five regional index fisheries, but it did not yet activate
MFCL's explicit regional-scaling penalty.

## What Was Missing

| Gap | Why it mattered |
| --- | --- |
| No `bet.reg_scaling` file in 06-12 | MFCL reads `<root>.reg_scaling` only when regional scaling is active. |
| No `parest_flags(77:81)` in 06-12 `doitall.sh` | The regional-scaling penalty was not switched on. |
| README/manifests did not list regional scaling | Restarting later could make the model look plan-compliant when it was not. |

## What Changed

| Area | Fix |
| --- | --- |
| Input file | Copied `BET/bet.2026.reg_scaling` from the frq-build repo to `bet.reg_scaling` in 06-12. |
| File shape | Verified each `bet.reg_scaling` has 292 rows and 5 columns, matching full 1952-2024 quarterly periods and 5 regions. |
| Doitall flags | Added `1 77 1`, `1 78 1`, `1 79 292`, `1 80 0`, and `1 81 1` to 06-12. |
| Index selectivity | In 06-12, index fisheries 29-33 are no longer forced into one common selectivity group. They now use groups 25-29 (`Index R1` to `Index R5`) because `bet.reg_scaling` supplies the regional CPUE scaling penalty. |
| Reproducibility | Updated `R/prepare_bet_2026_step_inputs.R` so regeneration preserves the files, flags, manifests, and READMEs. |

## Current Assumptions

- Regional scaling starts in `06-Full2024`, as described in plan v2.
- Steps `03-05` remain 2021-terminal transition steps and do not use
  `bet.reg_scaling`; they retain one shared index selectivity group as part of
  the old global CPUE transition setup.
- Steps `06-12` use regional scaling and therefore keep extraction selectivity
  mapping from `03-RegFish` but unshare the five index fishery selectivities.
- `parest_flags(77)=1` is an initial low-weight activation because the plan
  does not specify a penalty weight.
- `parest_flags(78)=1` uses the mean target.
- `parest_flags(81)=1` uses the multivariate-normal penalty, matching the MFCL
  manual recommendation.

## Verification

- `Rscript R/prepare_bet_2026_step_inputs.R` completed successfully.
- All 06-12 `bet.reg_scaling` files are byte-identical to the frq-build source.
- `03-RegFish` still has 25 selectivity groups with index fisheries 29-33 in
  group 25; `06-Full2024` through `12-DataWeight40` have 29 selectivity groups
  with index fisheries 29-33 in groups 25-29.
- Local `-switch` smoke reached MFCL sanity checks without a missing
  `bet.reg_scaling` error. It stopped later on existing selectivity/survey
  context checks, so a full Kflow/doitall run is still the real validation.

## Still To Review

- Decide whether regional-scaling penalty weight `77=1` should be increased or
  tuned after diagnostics.
- Review regional-scaling fit/output once the full 06-12 Kflow jobs finish.
- Confirm after fitting that unshared index selectivity plus the regional-scaling
  prior behaves as intended in CPUE residuals and regional scaling diagnostics.
