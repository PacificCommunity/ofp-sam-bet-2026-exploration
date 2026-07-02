# 09 NewOtoliths

New Japanese otoliths and 2026 CAAL input on the regional CPUE model.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/09-NewOtoliths/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same regional CPUE `.frq`, 2026 reporting-rate matrix, and 2026 `.tag` as 08-RegionalCPUE. |
| 2 | Switches CAAL from `bet.2023.new-structure.age_length` to `bet.2026.age_length`. |
| 3 | The 2026 age_length file includes the new otolith data used for this step. |
| 4 | Applies FixM M row from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 to the 2026 ini. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.ini` with tag reporting-rate matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; copied 5 tag reporting-rate matrix block(s) from bet.2026.mix-0.2.ini without changing tag_flags; filled fishery 19 reporting-rate cells for positive tag recaptures from fishery 21 settings in release groups 19-21,31,35,40; normalized tag flags marker; padded existing MFCL 1007 tag-control rows from 91 to 98 release groups with 2 mixing periods; normalized MFCL 1007 tag-control rows for 91 release groups; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build, including canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL/new otoliths); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions |
| `input_manifest.csv` | machine-readable source/input notes |

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
| 1 | 08-RegionalCPUE controls retained. |
| 2 | The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period. |
| 3 | The 2026 reporting-rate matrix is copied from `bet.2026.mix-0.2.ini` before final alignment checks. |
| 4 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 5 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 6 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 7 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Generated inputs only repair `.ini` alignment: reporting-rate matrices, tag flags, and shed rates are matched to the selected release-group count. |
| 2 | The latest `bet.2026.low.recaps.removed.tag` is kept; the tag build assigns missing-gear canneries recaptures to purse-seine before low-recap filtering. |
| 3 | The 2026 reporting-rate matrix is copied from the mix-period ini source before Kflow runs. |
| 4 | Positive fishery 19 tag recaptures with inactive zero reporting-rate cells are assigned the matching fishery 21 reporting-rate settings. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, compare CAAL likelihood and age residuals against 08-RegionalCPUE. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
