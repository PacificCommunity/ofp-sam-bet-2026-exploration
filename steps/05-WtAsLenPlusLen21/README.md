# 05 WtAsLenPlusLen21

Transition step using weights converted to lengths plus observed lengths, still chopped to 2021.

## What Changed

- Derived `bet.frq` from `bet.2026.wt.as.len.plus.len.frq` by keeping records with year <= 2021.
- Maintains the old CAAL input while moving the size-composition frequency file to the plus-length variant.
- Keeps the 2026 91-release tag/ini structure for consistency with the `.frq` header.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, chopped to 2021
- `bet.ini`: `bet.2026.ini`, FixM M row applied; inserted MFCL 1007 tag flags for 91 release groups with 2 mixing periods and reporting rates excluded during mixing
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.

## Outstanding Checks

- Confirm the 2021 chop of the plus-length `.frq` matches the stepwise plan's 2023-terminal comparison.
- Compare against 04-WtAsLen21 to isolate the effect of adding observed lengths.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

