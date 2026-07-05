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
| 4 | Uses the 2026 low-recapture-removed tag file and latest 2026 tag-reporting matrices, with FixM M row from the 01-Diag2023 mgc=-5 diagnostic final par. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq`, full 2024 with global CPUE |
| `.ini` | `bet.2026.ini` with RR/active/target/penalty matrices from `bet.2026.mix-0.2.ini`; two-quarter tag mixing retained, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; harmonized initial RR values only in 1 tag reporting-rate group(s) so grouped starts are native-MFCL compatible; group flags, targets, and penalties unchanged; normalized MFCL 1007 tag-control rows for 98 release groups |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR groups and canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | No generated edit; full 2024 source is used. | Catch, effort, CPUE, and composition records from the selected source. |
| `.ini` | Copies latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, applies fixed M, and validates positive recapture cells. | Two-quarter tag mixing for all release groups. |
| `.tag` | No generated edit. | 2026 low-recapture-removed source tag file. |
| `.age_length` | Changes effective sample size from `1` to `0.75`. | Old CAAL records themselves. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `f8faf7c` | updated RR groupings |
| `ofp-sam-2026-BET-YFT-tag-prep` | `e0b427d` | updated RR groups |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | 04-NewStructure 5-region `doitall.sh` controls retained. |
| 2 | The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period. |
| 3 | The latest 2026 RR, active, target, and penalty matrices are copied from `bet.2026.mix-0.2.ini` before final alignment checks. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Generated inputs only repair `.ini` alignment: reporting-rate matrices, tag flags, and shed rates are matched to the selected release-group count. |
| 2 | The latest `bet.2026.low.recaps.removed.tag` is kept; the tag build assigns missing-gear canneries recaptures to purse-seine before low-recap filtering. |
| 3 | The latest 2026 reporting-rate, active, target, and penalty matrices are copied from the mix-period ini source before Kflow runs. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |

## Checks

| # | Check |
| --- | --- |
| 1 | Full 2024 input behavior still needs a real MFCL fit and residual/CPUE-sigma review. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
