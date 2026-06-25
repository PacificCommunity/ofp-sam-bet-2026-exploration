# 09 SizeBasedSel

Size-based selectivity step after the main 0.2 KS tag mixing-period setup.

## What Changed

- Uses the same full 2024 `.frq`, `bet.2026.mix-0.2.ini`, 2026 tag file, and updated 2026 CAAL as 08-MixPeriod02.
- Sets fish flag 26 from 2 to 3 in `doitall.sh`, following the YFT 2026 length-based selectivity note.
- Keeps the extraction-fishery selectivity mapping and fishery-specific constraints from 03-RegFish, while index fisheries unshare from PHASE 5 under regional scaling.

## Inputs

- `.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `.tag`: `bet.2026.low.recaps.removed.tag`
- `.age_length`: `bet.2026.age_length` (updated CAAL)
- `.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `7d636e8` - update frq files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40

## Control Notes

- The all-release-group mixing-period override remains removed.
- `-999 26 3` is applied for size-based selectivity.
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

- These steps were audited after the 06/07 full-2024 failure because they use the same 98-release 2026 `.frq` and `.tag` family.
- The mix-period ini family already carries release-group-specific tag controls, so the generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive the mixing-period settings.
- Generation still validates the same release-group alignment checks as 06/07: tag flags, tag shed rate, and the five tag reporting-rate matrices must match the 98 selected release groups plus the pooled reporting row where appropriate.
- Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0; this is an ini-control normalization, not a deletion of tag data.
- Local `mfclo64 bet.frq bet.ini 00.par -makepar` smoke tests now exit 0 and create `00.par` for 08-MixPeriod02 through 12-DataWeight40 in the `tuna-flow:v1.10` image.
- The extra step-specific change after the mix-period audit is limited to fish flag 26: `doitall.sh` sets `-999 26 3` for the size-based selectivity experiment.

## Outstanding Checks

- Confirm with the modelling group that BET should use the same flag-26 setting as the YFT 2026 size-based selectivity experiment.
- Not yet reviewed after fitting: upper-age selectivity constraints inherited from 03-RegFish, especially `24.PL.ALL.WEST.3`.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
