# 04 WtAsLen21

Transition step using the 2026 weights-as-lengths frequency file, chopped back to the 2023 terminal year.

## What Changed

- Derived `bet.frq` from `bet.2026.wt.as.len.frq` by keeping records with year <= 2021 and updating the dataset count.
- Uses 2026 91-release tag/ini structure because the source `.frq` declares 91 tag groups.
- Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.frq`, chopped to 2021
- `bet.ini`: `bet.2026.ini`, FixM M row applied
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.

## Outstanding Checks

- Confirm the 2021 chop of the 2026 weights-as-lengths `.frq` gives the intended transition-only comparison.
- Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

