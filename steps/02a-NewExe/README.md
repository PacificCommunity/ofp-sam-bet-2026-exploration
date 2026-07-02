# 02a NewExe

2023 assessment replication inputs run with the current MFCL executable while keeping the MFCL 1003 ini.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02a-NewExe/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the archived 2023 assessment replication input set as the source model (`ofp-sam-2026-BET/mfcl/inputs/2023_rep`). |
| 2 | Keeps `bet.ini` as version 1003 so this substep isolates the current executable and the original 2023 control script. |
| 3 | Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block. |
| 4 | Adds the usual Kflow safety wrapper: `set -eu`, PROGRAM_PATH guard, and `BET_PHASE10_11_CONVERGENCE` for PHASE 10/11. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | 2023 assessment replication `.frq`; 9 regions, 41 fisheries, terminal year 2021 |
| `.ini` | 2023 assessment replication `.ini`; MFCL 1003, no explicit tag flags |
| `.tag` | 2023 assessment replication `.tag` |
| `.age_length` | 2023 assessment replication `.age_length` |
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
| 1 | The current MFCL executable configured by the runtime is used. |
| 2 | This substep is the executable/control-script bridge before changing the ini layout. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 01-Diag2023 to isolate historical-executable versus current-executable/control effects. |
| 2 | Do not interpret this as a 1007 ini test; that is isolated in 02b-Ini1007. |
