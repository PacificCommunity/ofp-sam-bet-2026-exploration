# 08 MixPeriod02

Release-group-specific tag mixing periods using the 0.2 KS diagnostic cutoff.

## What Changed

- Uses `bet.2026.mix-0.2.ini` from the ini-build repo.
- Keeps the full 2024 `.frq`, 2026 tag file, and updated 2026 CAAL.
- Applies the FixM M row to the mix-period ini.
- Removes the inherited `-9999 1 2` line from `doitall.sh` so the release-group-specific tag flags in the ini are not overwritten.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 36 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `input_manifest.csv`: machine-readable source/input notes

## Control Notes

- The all-release-group mixing-period override is removed.
- All other 03-RegFish 5-region fishery, tag recapture, selectivity, and CPUE sigma controls are retained.

## Outstanding Checks

- Confirm that the 0.2 KS mix-period ini is the main 12-step path; the 0.15 version remains a sensitivity candidate.
- After fitting, inspect tag residuals and release-group behavior before tuning tag-reporting assumptions further.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

