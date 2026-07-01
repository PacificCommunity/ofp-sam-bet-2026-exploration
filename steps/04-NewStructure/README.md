# 04 NewStructure

First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE.

## What Changed

- Uses the new 5-region and new-fishery frequency source from the frq-build repo.
- Represents 28 extraction fisheries plus 5 index fisheries.
- Keeps data through 2021 and uses the global CPUE setup for this structural transition.
- Uses old CAAL re-assigned to the new fisheries.
- Uses the restructured tag setup with 96 release groups.
- Applies FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 while retaining the 5-region `.ini` structure.

## Inputs

- `.frq`: `bet.2023.new-structure.global-cpue.frq`; 5-region, 33-fishery structure, terminal year 2021, global CPUE
- `.ini`: `bet.2023.new.structure.ini`; FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 and explicit default tag flags inserted if needed
- `.tag`: `bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input
- `.age_length`: `bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries; set age_length effective sample size to 0.75 for 112 records
- `input_manifest.csv`: machine-readable source/input notes with source commits

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `d884ce5` - remove len comps from LL from 2023.new.structure
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- This step becomes the 5-region control template for steps 05-15.
- Generated `.frq` files include region locations for every fishery, including index fisheries.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.
- The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
