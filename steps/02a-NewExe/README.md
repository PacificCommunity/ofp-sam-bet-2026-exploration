# 02a NewExe

2023_rep inputs run with the current MFCL executable while keeping the MFCL 1003 ini.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02a-NewExe/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses `ofp-sam-2026-BET/mfcl/inputs/2023_rep` as the source model. |
| 2 | Keeps `bet.ini` as version 1003 so this substep isolates the current executable and 2023_rep control script. |
| 3 | Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block. |
| 4 | Adds the usual Kflow safety wrapper: `set -eu`, PROGRAM_PATH guard, and `BET_PHASE10_11_CONVERGENCE` for PHASE 10/11. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `ofp-sam-2026-BET/mfcl/inputs/2023_rep/bet.frq`; 9 regions, 41 fisheries, terminal year 2021 |
| `.ini` | `ofp-sam-2026-BET/mfcl/inputs/2023_rep/bet.ini`; MFCL 1003, no explicit tag flags |
| `.tag` | `ofp-sam-2026-BET/mfcl/inputs/2023_rep/bet.tag` |
| `.age_length` | `ofp-sam-2026-BET/mfcl/inputs/2023_rep/bet.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `d884ce5` | remove len comps from LL from 2023.new.structure |
| `ofp-sam-2026-BET-YFT-build-ini` | `b39cbfd` | updated ini files to reflect updated tag files |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | assign unassigned gear to PS from canneries |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The current MFCL executable `/home/mfcl/mfclo64` is used. |
| 2 | This substep is the executable/control-script bridge before changing the ini layout. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 01-Diag2023 to isolate historical-executable versus current-executable/control effects. |
| 2 | Do not interpret this as a 1007 ini test; that is isolated in 02b-Ini1007. |
