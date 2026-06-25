# 05 WtAsLenPlusLen21

Transition step using weights converted to lengths plus observed lengths, still chopped to 2021.

## What Changed

- Derived `bet.frq` from `bet.2026.wt.as.len.plus.len.frq` by keeping records with year <= 2021.
- Maintains the old CAAL input while moving the size-composition frequency file to the plus-length variant.
- Keeps the 03-RegFish 90-release tag/ini structure because this step remains a 2021-terminal comparison.
- Resets the chopped `.frq` tag-group header from 91 to 90 to match the selected tag file.
- Applies the FixM M row to the 03-RegFish-compatible ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, chopped to 2021 with tag-group header reset to 90
- `bet.ini`: `steps/03-RegFish/model/bet.ini`, FixM M row applied
- `bet.tag`: `steps/03-RegFish/model/bet.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `bet.region_map.geojson`: single-file default BET 2026 5-region shape for mfclshiny/report maps
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 90-release tag set.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- Kflow failed when this 2021-chopped `.frq` was paired with the 2026 91-release `.ini/.tag`; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.
- To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's 90-release setup, and the chopped `.frq` tag-group header is reset from 91 to 90.
- Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03.

## Outstanding Checks

- Confirm the 2021 chop of the plus-length `.frq` matches the stepwise plan's 2023-terminal comparison.
- Confirm with the modelling group that 05 should isolate the plus-length transition while holding the 03-RegFish tag/ini structure.
- Compare against 04-WtAsLen21 to isolate the effect of adding observed lengths.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

