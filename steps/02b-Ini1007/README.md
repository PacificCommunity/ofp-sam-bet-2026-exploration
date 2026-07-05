# 02b Ini1007

02a current-executable baseline promoted from MFCL 1003 to MFCL 1007 ini layout.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02b-Ini1007/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Inherits the diagnostic-side 2023 assessment replication model from `02a-NewExe`. |
| 2 | `bet.ini` is promoted from MFCL 1003 to 1007 while retaining the diagnostic values. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/02a-NewExe/model/bet.frq` |
| `.ini` | `steps/02a-NewExe/model/bet.ini`; set ini version to 1007; inserted MFCL 1007 tag-control rows for 118 release groups with 2 mixing periods; inserted zero tag shed-rate vector for 118 release groups; inserted MFCL 1007 total-population scalar default 25; inserted MFCL 1007 Richards growth parameter default 0 |
| `.tag` | `steps/02a-NewExe/model/bet.tag` |
| `.age_length` | `steps/02a-NewExe/model/bet.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.ini` | Promotes MFCL 1003 to 1007 by adding tag flags, tag shed rates, `LN(R0)=25`, and Richards growth default `0`. | Diagnostic data values and tag grouping. |
| `.frq/.tag/.age_length` | No generated edit. | Inherited from `02a-NewExe`. |

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
| 1 | The current MFCL executable configured by the runtime is used. |
| 2 | MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 02a-NewExe to isolate this substep's change. |
| 2 | Later steps inherit this substep unless explicitly documented otherwise. |
