# 04 WtAsLen21

Transition step using the 2026 weights-as-lengths frequency file, chopped back to the 2023 terminal year.

## What Changed

- Derived `bet.frq` from `bet.2026.wt.as.len.frq` by keeping records with year <= 2021 and updating the dataset count.
- Uses 2026 91-release tag/ini structure because the source `.frq` declares 91 tag groups.
- Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.frq`, chopped to 2021
- `bet.ini`: `bet.2026.ini`, FixM M row applied; inserted MFCL 1007 tag flags for 91 release groups with 2 mixing periods and reporting rates excluded during mixing; set terminal-year tag release groups 18,58 to 1 mixing period so chopped terminal-year models do not exceed the terminal period
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing-period override is removed so terminal-year release groups 18 and 58 can use the 1-period `.ini` setting.

## Outstanding Checks

- Confirm the 2021 chop of the 2026 weights-as-lengths `.frq` gives the intended transition-only comparison.
- Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

