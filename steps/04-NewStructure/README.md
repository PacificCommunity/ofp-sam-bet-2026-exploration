# 04 NewStructure

First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/04-NewStructure/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the new 5-region and new-fishery frequency source from the frq-build repo. |
| 2 | Represents 28 extraction fisheries plus 5 index fisheries. |
| 3 | Keeps data through 2021 and uses the global CPUE setup for this structural transition. |
| 4 | Uses old CAAL re-assigned to the new fisheries. |
| 5 | Uses the restructured tag setup with 96 release groups. |
| 6 | Applies FixM M row from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 while retaining the 5-region `.ini` structure. |
| 7 | Sets total population scaling factor LN(R0) to 17. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2023.new-structure.global-cpue.frq`; 5-region, 33-fishery structure, terminal year 2021, global CPUE |
| `.ini` | `bet.2023.new.structure.ini`; FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604  and explicit default tag flags inserted if needed |
| `.tag` | `bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input |
| `.age_length` | `bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries; set age_length effective sample size to 0.75 for 112 records |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `0443d39` | adjust tag_flags(it,2)=0 to be in line with 2023 |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | assign unassigned gear to PS from canneries |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | This step is the 5-region control template for steps 05-15. |
| 2 | MFCL 1007 `# tag flags` supply tag mixing periods directly; the inherited `-9999 1 2` doitall override is removed. |
| 3 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping. |
| 2 | The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5. |
