# 01 Diag2023

Original BET 2023 diagnostic model rerun with the historical MFCL executable.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/01-Diag2023/model` |
| Status | Ready for Kflow with the tuna-flow image that includes the historical 2023 diagnostic MFCL executable. |

## Changes

| # | Change |
| --- | --- |
| 1 | Copies the 2023 diagnostic `MFCL` model files without changing the model inputs. |
| 2 | `bet.ini` remains in its original 2023 diagnostic format for the historical `mfclo64` reader. |
| 3 | `doitall.sh` keeps the historical diagnostic control sequence while allowing `BET_PHASE10_11_CONVERGENCE` to set PHASE 10/11 convergence from Kflow. |
| 4 | The runner resolves `mfclo64` to the historical 2023 diagnostic MFCL executable for this step. |
| 5 | This step is the direct reproducibility anchor before moving to the current executable. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | original 2023 diagnostic frequency/catch/size input |
| `.ini` | original 2023 diagnostic ini, not promoted to MFCL 1007 |
| `.tag` | original 2023 diagnostic tag input |
| `.age_length` | original 2023 diagnostic CAAL input |
| `fishery_map.R` | 2023 fishery names copied from the assessment replication input set for viewer labels |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | No generated edit. | Original 2023 diagnostic source file. |
| `.ini` | No generated edit. | Original 2023 diagnostic format. |
| `.tag` | No generated edit. | Original 2023 diagnostic source file. |
| `.age_length` | No generated edit. | Original 2023 diagnostic source file. |
| `fishery_map.R` | Copied from the 2023 assessment replication inputs for display labels. | Fishery names and grouping only; not an MFCL input. |

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
| 1 | The model files come from `ofp-sam-bet-2023-diagnostic/MFCL`. |
| 2 | `fishery_map.R` is copied from the 2023 assessment replication input set because the diagnostic and replication fisheries match; this only supplies viewer/display labels. |
| 3 | The step-specific executable path is set in `job-config.R`; only this step uses the historical MFCL binary. |
| 4 | No FixM, new-executable compatibility edits, new fishery structure, or 2026 input files are applied here. |
| 5 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare this rerun against the archived 2023 diagnostic output before interpreting later deltas. |
| 2 | Apart from the PHASE 10/11 convergence switch, failures will reflect the original diagnostic control sequence. |
