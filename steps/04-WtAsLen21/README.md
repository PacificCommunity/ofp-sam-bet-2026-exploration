# 04 WtAsLen21

Transition step using the 2026 weights-as-lengths frequency file, chopped back to the 2023 terminal year.

## What Changed

- Derived `bet.frq` from `bet.2026.wt.as.len.frq` by keeping records with year <= 2021 and updating the dataset count.
- Keeps the 03-RegFish 90-release tag/ini structure because this step remains a 2021-terminal comparison.
- Resets the chopped `.frq` tag-group header from 91 to 90 to match the selected tag file.
- Keeps old CAAL (`bet.2023.new-structure.age_length`) as requested by the stepwise plan.
- Applies the FixM M row to the 03-RegFish-compatible ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.frq`, chopped to 2021 with tag-group header reset to 90
- `bet.ini`: `steps/03-RegFish/model/bet.ini`, FixM M row applied
- `bet.tag`: `steps/03-RegFish/model/bet.tag`
- `bet.age_length`: `bet.2023.new-structure.age_length` (old CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group `-9999 1 2` mixing-period override is retained because this step uses the 03-RegFish 90-release tag set.

## Run Note

- Kflow failed when this 2021-chopped `.frq` was paired with the 2026 91-release `.ini/.tag`; MFCL stopped at tag release group 18 because its mixing period reached the terminal model period.
- To make the step runnable as a 2021-terminal transition, `bet.ini` and `bet.tag` now come from 03-RegFish's 90-release setup, and the chopped `.frq` tag-group header is reset from 91 to 90.
- Local `mfclo64 bet.frq bet.ini 00.par -makepar` now exits 0 and creates `00.par`; the remaining 30 `caught before it was released` messages are the known upstream tag-prep warnings also seen in 03.

## Outstanding Checks

- Confirm the 2021 chop of the 2026 weights-as-lengths `.frq` gives the intended transition-only comparison.
- Confirm with the modelling group that 04 should isolate the frequency-file transition while holding the 03-RegFish tag/ini structure.
- Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

