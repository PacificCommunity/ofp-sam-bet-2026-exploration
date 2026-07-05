# 02c LengthWeight

02b 1007 ini baseline with BET bias-corrected 2026 length-weight parameters.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02c-LengthWeight/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Inherits the diagnostic-side 2023 assessment replication model from `02b-Ini1007`. |
| 2 | Sets the BET bias-corrected 2026 length-weight parameters to `3.073533e-05 2.932410`. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/02b-Ini1007/model/bet.frq` |
| `.ini` | `steps/02b-Ini1007/model/bet.ini`; set Length-weight parameters from `3.063397e-05 2.932384` to `3.073533e-05 2.932410` |
| `.tag` | `steps/02b-Ini1007/model/bet.tag` |
| `.age_length` | `steps/02b-Ini1007/model/bet.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.ini` | Changes only `# Length-weight parameters` to `3.073533e-05 2.932410`. | All other `02b-Ini1007` ini controls. |
| `.frq/.tag/.age_length` | No generated edit. | Inherited from `02b-Ini1007`. |

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
| 1 | Compare directly with 02b-Ini1007 to isolate this substep's change. |
| 2 | Later steps inherit this substep unless explicitly documented otherwise. |
