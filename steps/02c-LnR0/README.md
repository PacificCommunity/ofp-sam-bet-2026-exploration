# 02c LnR0

02b 1007 ini baseline with total population scaling factor LN(R0) set to 17.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02c-LnR0/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Inherits the diagnostic-side 2023 assessment replication model from `02b-Ini1007`. |
| 2 | Sets the total population scaling factor LN(R0) to 17. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/02b-Ini1007/model/bet.frq` |
| `.ini` | `steps/02b-Ini1007/model/bet.ini`; set total population scaling factor LN(R0) from 25 to 17 |
| `.tag` | `steps/02b-Ini1007/model/bet.tag` |
| `.age_length` | `steps/02b-Ini1007/model/bet.age_length` |
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
| 2 | MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 02b-Ini1007 to isolate this substep's change. |
| 2 | Later steps inherit this substep unless explicitly documented otherwise. |
