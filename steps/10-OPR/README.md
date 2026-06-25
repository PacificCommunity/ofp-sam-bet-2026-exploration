# 10 OPR

Orthogonal polynomial recruitment step using the best BET OPR setting from John Hampton's OPR.pptx exploration.

## What Changed

- Uses the same input files as 09-SizeBasedSel.
- Applies the BIGEYE AIC rank-1 OPR model from `OPR.pptx`: `69-01-50-50`.
- The OPR comparison was run on the BET 4R model, but this step carries the best-ranked setting into the current 5-region stepwise path.
- OPR controls are applied in PHASE 3 of `doitall.sh`, so early phases still use the pre-OPR recruitment setup before the transfer.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
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

- `-999 26 3` is retained from 09-SizeBasedSel.
- PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.
- `1 149 0`, `1 398 0`, `2 177 0`, and `2 32 0` are applied at PHASE 3 for the OPR transfer.
- `1 155 69` and `1 221 69` set the OPR year effect from the `69-01-50-50` setting.
- `1 217 1`, `1 216 50`, and `1 218 50` set season, region, and region-season interaction effects.
- `1 202 2`, `1 210 0`, `1 212 0`, and `1 214 0` apply the terminal constraints shown in John's example `do-OPR` file.
- `2 30 1` is deliberately retained at the OPR phase because John Hampton's 25/05/2026 note says `age_flag(30)=1` is currently needed for MFCL to activate the OPR polynomial coefficients.
- `2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- The active `bet.reg_scaling` window is periods 53-72 (1965-1969) because Thom's global CPUE covariance matrices were estimated from data fitted over 1965 through the end of 1969, the period with the highest spatial-temporal coverage.
- For the 292-period full-2024 models, `parest_flags(79)=240` means `292 - 240 + 1 = 53` and `parest_flags(80)=220` means `292 - 220 = 72`, so the regional-scaling prior is limited to that covariance-estimation window.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.
- Following John Hampton's June 2026 MFCL input checks, generated `.frq` files must include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files must carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- Following Nick Davies's June 2026 MFCL-version note, `age_flags(128)` is kept at 100 so the latest MFCL interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- These steps were audited after the 06/07 full-2024 failure because they use the same 98-release 2026 `.frq` and `.tag` family.
- The mix-period ini family already carries release-group-specific tag controls, so the generated `doitall.sh` removes the inherited `-9999 1 2` override and lets the ini tag flags drive the mixing-period settings.
- Generation still validates the same release-group alignment checks as 06/07: tag flags, tag shed rate, and the five tag reporting-rate matrices must match the 98 selected release groups plus the pooled reporting row where appropriate.
- Zero mixing-period values in the source mix-period ini are raised to 1 because the current MFCL reader disallows 0; this is an ini-control normalization, not a deletion of tag data.
- Local `mfclo64 bet.frq bet.ini 00.par -makepar` smoke tests now exit 0 and create `00.par` for 08-MixPeriod02 through 12-DataWeight40 in the `tuna-flow:v1.10` image.
- The step-specific OPR change follows John Hampton's `OPR.pptx` screening: the BET 4R rank-1 AIC setting `69-01-50-50` is carried into this 5-region path. The README records that this is an applied transfer from the 4R screening, not a separate 5-region OPR search.
- John's 25/05/2026 email notes that Nick and John expected DEVS-related flags to be off for OPR, but found `age_flag(30)=1` must remain on or MFCL does not activate the OPR recruitment-polynomial coefficients; the step therefore keeps `2 30 1` while turning off `2 70`, `2 71`, `2 178`, and the `-100000 1:5` regional recruitment-distribution flags.

## Outstanding Checks

- After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result.
- If diagnostics disagree with the 4R screening, revisit the other BET-ranked options from `OPR.pptx`.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
