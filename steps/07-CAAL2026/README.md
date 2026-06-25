# 07 CAAL2026

Full 2024 data step with the updated 2026 CAAL / age_length input.

## What Changed

- Uses the same full 2024 `.frq`, 2026 `.ini`, and 2026 `.tag` as 06-Full2024.
- Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`.
- The 2026 age_length file has 181 records through 2024 and includes Japan/SPC new age data.
- Applies the FixM M row to the 2026 ini.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.ini`, FixM M row applied; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; normalized tag flags marker; padded existing MFCL 1007 tag flags from 91 to 98 release groups with 2 mixing periods and reporting rates excluded during mixing; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `7d636e8` - update frq files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40

## Control Notes

- 03-RegFish 5-region `doitall.sh` controls retained.
- The all-release-group mixing period remains fixed at 2 for this pre-mix step.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; flags 77-81 configure the regional-scaling MVN prior.
- The regional-scaling penalty weight is 50 (`parest_flags(77)=50`); the inline control comment records this as approximately CV 0.1.
- The active `bet.reg_scaling` window is periods 53-72 (1965-1969) because the global CPUE covariance matrices were estimated from data fitted over 1965 through the end of 1969, the period with the highest spatial-temporal coverage.
- For the 292-period full-2024 models, `parest_flags(79)=240` means `292 - 240 + 1 = 53` and `parest_flags(80)=220` means `292 - 220 = 72`, so the regional-scaling prior is limited to that covariance-estimation window.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep the 2026 index-fishery sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.

## Run Note

- The first full-2024 Kflow attempt failed during MFCL `-makepar`, before any fit output was available. The logged fatal sequence was `initial_tag_year(2) 157`, `Error reading region_flags`, and `Bounds error reading pmature(34) in par file value is 0`; downstream payload creation then failed because no MFCL output folder existed.
- The failure was traced to using the 2026 `.frq/.tag` release-group count with a source `bet.2026.ini` whose tag controls were shorter: the selected `.frq` and `.tag` had 98 release groups, while the ini tag flags and tag shed-rate vector only covered 91 groups and the tag reporting-rate matrices were missing the 7 new release rows.
- Generated inputs now repair only the `.ini` alignment: missing tag reporting-rate rows 92-98 are filled by matching tag program, region, year, and month from `bet.2023.new.structure.ini`; explicit MFCL 1007 tag flags are padded to 98 rows; and `# tag shed rate` is padded from 91 to 98 zero shed rates.
- The 2026 tag file itself is kept from `bet.2026.low.recaps.removed.tag`; no tag release or recapture rows were deleted to suppress warnings.
- After the alignment repair, `mfclo64 bet.frq bet.ini 00.par -makepar` exits 0 and creates `00.par` for 06-Full2024 and 07-CAAL2026 in the `tuna-flow:v1.10` image.

## Outstanding Checks

- After fitting, compare CAAL likelihood and age residuals against 06-Full2024.
- Confirm the 2026 CAAL source remains the chosen final CAAL file before later sensitivity runs.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
