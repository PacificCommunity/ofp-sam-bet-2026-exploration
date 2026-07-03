# 05 ConvertToLength

Data to 2021, global CPUE, converting existing weight compositions to length.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/05-ConvertToLength/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses `bet.2023.new-structure.global-cpue.wt-as-len.frq` from the frq-build repo. |
| 2 | Keeps the 04-NewStructure `.ini`, tag, and old CAAL inputs so this step isolates the weight-to-length conversion. |
| 3 | Applies FixM M row from the 01-Diag2023 mgc=-5 diagnostic final par through the inherited 04-NewStructure ini. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2023.new-structure.global-cpue.wt-as-len.frq`; terminal year 2021, global CPUE |
| `.ini` | `steps/04-NewStructure/model/bet.ini`, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par |
| `.tag` | `steps/04-NewStructure/model/bet.tag` |
| `.age_length` | `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | Uses the selected length-composition source file; no extra generated edit. | Catch, effort, and composition records from the selected source. |
| `.ini` | Inherits the generated 04 `.ini` with fixed M and 5-region tag controls. | All other 04-NewStructure ini controls. |
| `.tag` | No generated edit. | 04-NewStructure source tag file. |
| `.age_length` | Changes effective sample size from `1` to `0.75`. | CAAL records themselves. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `a6e932d` | Updated mixing periods based on Joe's updates |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | assign unassigned gear to PS from canneries |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | 04-NewStructure 5-region `doitall.sh` controls retained. |
| 2 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Compare directly with 04-NewStructure to isolate the effect of converting existing weight compositions to length. |

## Checks

| # | Check |
| --- | --- |
| 1 | Review fit impacts before deciding whether any size-composition weighting needs adjustment at this stage. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
