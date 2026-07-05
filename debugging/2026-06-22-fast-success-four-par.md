# 2026-06-22 Fast Success With Only 04.par

One 12-DataWeight40 Kflow run finished very quickly and archived only
`04.par`. That was not a real completed model run.

## What Happened

| Symptom | Cause |
| --- | --- |
| Kflow showed success after only `04.par` existed | `doitall.sh` did not stop when an MFCL phase failed, so later missing-input errors were allowed to continue. |
| PHASE 5 failed before creating `05.par` | The regional-scaling prior defaulted to period 1 because `parest_flags(79)=0`. |
| MFCL error mentioned index fishery 32 starts at period 3 | The regional-scaling prior period must be inside the time range covered by every index fishery. |

## Fix

| Area | Change |
| --- | --- |
| Regional scaling period | The early fix changed `parest_flags(79)` from `0` to `290`; current generated steps use `79=240` and `80=220` for periods 53-72. |
| MFCL interpretation | With 292 full-2024 periods, MFCL calculates `preg_start = 292 - 240 + 1 = 53` and `preg_end = 292 - 220 = 72`. |
| Job failure handling | Added `set -eu` to all 12 `doitall.sh` scripts. |
| Generator | Updated `R/prepare_bet_2026_step_inputs.R` so regenerated scripts keep fail-fast behavior and steps 08-15 keep the period 53-72 regional-scaling window. |

## Why This Matters

If MFCL fails in the middle of `doitall.sh`, the Kflow job should fail
immediately. A quick success with only early `.par` files is misleading and
should now be prevented.

## Verification

- `sh -n` passed for every `steps/*/model/doitall.sh`.
- All current regional-scaling `doitall.sh` files contain `1 79 240` and `1 80 220`.
- All 12 `.frq` files have a fishery-region line matching the header fishery
  count.
- All 03-12 `.frq`, `.tag`, and `.ini` tag group counts agree.
- At the time, all regional-scaling `bet.reg_scaling` files were 292 rows x 5 columns;
  this was superseded on 2026-07-06 by writing only the 20-row active window
  for native MFCL compatibility.
