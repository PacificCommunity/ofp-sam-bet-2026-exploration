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
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 90-release tag set.

## Outstanding Checks

- Confirm the 2021 chop of the plus-length `.frq` matches the stepwise plan's 2023-terminal comparison.
- Confirm with the modelling group that 05 should isolate the plus-length transition while holding the 03-RegFish tag/ini structure.
- Compare against 04-WtAsLen21 to isolate the effect of adding observed lengths.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

