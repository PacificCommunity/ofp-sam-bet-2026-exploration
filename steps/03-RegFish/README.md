# 03 RegFish

First 5-region / 33-fishery BET input step, ending in 2021.

## What Changed

- Uses `bet.2023.new.structure.*` source inputs from the 2026 input build repos.
- Represents 28 extraction fisheries plus 5 index fisheries.
- Uses the old CAAL data re-assigned to the new fisheries.
- Uses the old/restructured tag setup with 90 release groups and 91 tag-event rows including pooled tags.
- Regenerates `tag_rep_map.R` from the five MFCL reporting-rate matrices in `bet.ini` plus release metadata in `bet.tag`.
- Applies Arni's 19/06/2026 CPUE index sigma suggestions for index fisheries 29-33.
- Applies FixM M row while retaining the 5-region `.ini` structure.

## Inputs

- `bet.frq`: 5-region, 33-fishery structure, terminal year 2021
- `bet.ini`: 5-region ini with FixM M row
- `bet.tag`: 90 release-group tag input with low recap groups removed
- `bet.age_length`: old CAAL / age_length re-assigned to new fisheries

## Control Notes

- 5-region fishery/tag/selectivity controls are remapped in `doitall.sh`.
- Index fisheries 29-33 use sigmas 0.28, 0.20, 0.22, 0.21, and 0.24.
- The `-9999 1 2` all-release mixing-period setting is retained for this pre-mix step.

## Outstanding Checks

- After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.
- The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

