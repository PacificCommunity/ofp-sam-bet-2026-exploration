# 07 DataTo2024

Data to 2024, global CPUE, isolating the effect of adding three years of data.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/07-DataTo2024/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq` without year chopping. |
| 2 | Moves from the 2021 transition steps to the full 2024 frequency/catch/size series. |
| 3 | Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths. |
| 4 | Uses the 2026 low-recapture-removed tag file and 2026 reporting-rate matrix, with FixM M row from the 01-Diag2023 mgc=-5 diagnostic final par. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq`, full 2024 with global CPUE |
| `.ini` | `bet.2026.ini` with tag reporting-rate matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; copied 5 tag reporting-rate matrix block(s) from bet.2026.mix-0.2.ini without changing tag_flags; filled fishery 19 reporting-rate cells for positive tag recaptures from fishery 21 settings in release groups 19-21,31,35,40; normalized tag flags marker; padded existing MFCL 1007 tag-control rows from 91 to 98 release groups with 2 mixing periods; normalized MFCL 1007 tag-control rows for 91 release groups; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build, including canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records |
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
| 1 | 04-NewStructure 5-region `doitall.sh` controls retained. |
| 2 | The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period. |
| 3 | The 2026 reporting-rate matrix is copied from `bet.2026.mix-0.2.ini` before final alignment checks. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

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
| 1 | Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
