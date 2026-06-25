# 03 RegFish

First 5-region / 33-fishery BET input step, ending in 2021.

## What Changed

- Uses `bet.2023.new.structure.*` source inputs from the 2026 input build repos.
- Represents 28 extraction fisheries plus 5 index fisheries.
- Uses the old CAAL data re-assigned to the new fisheries.
- Uses the old/restructured tag setup with 90 release groups and 91 tag-event rows including pooled tags.
- Regenerates `tag_rep_map.R` from the five MFCL reporting-rate matrices in `bet.ini` plus release metadata in `bet.tag`.
- Normalizes 84 old records that had an absent-LF sentinel followed by stray LF bins: 67 with WF data and 17 with no composition data.
- Applies Arni's 19/06/2026 CPUE index sigma suggestions for index fisheries 29-33.
- Applies FixM M row while retaining the 5-region `.ini` structure.
- Inserts default MFCL 1007 tag flags for the pre-mix step: 2 mixing periods and reporting rates excluded during mixing.

## Inputs

- `bet.frq`: 5-region, 33-fishery structure, terminal year 2021
- `bet.ini`: 5-region ini with FixM M row and explicit default tag flags
- `bet.tag`: 90 release-group tag input with low recap groups removed
- `bet.age_length`: old CAAL / age_length re-assigned to new fisheries
- `bet.region_map.geojson`: single-file default BET 2026 5-region shape for mfclshiny/report maps

## Control Notes

- 5-region fishery/tag/selectivity controls are remapped in `doitall.sh`.
- Index fisheries 29-33 use sigmas 0.28, 0.20, 0.22, 0.21, and 0.24.
- The `-9999 1 2` all-release mixing-period setting is retained for this pre-mix step.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.
- The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.
- The 84 normalized absent-LF records should be reviewed against the upstream frq-build script so the source generator can eventually emit MFCL-ready records.
- The upstream non-mix `.ini` files are labelled 1007 but omit `# tag flags`; generated 03-07 inputs now insert explicit default tag flags for MFCL >=2.2.7.5.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

