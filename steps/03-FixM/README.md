# 03 FixM

02c baseline with the FixM M-scale row applied from the 01-Diag2023 mgc=-5 final run.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/03-FixM/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Inherits the diagnostic-side 2023 assessment replication model from `02c-LnR0`. |
| 2 | Applies the FixM M-scale row from the 01-Diag2023 mgc=-5 diagnostic final par with value -2.54930339768360e+00 |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/02c-LnR0/model/bet.frq` |
| `.ini` | `steps/02c-LnR0/model/bet.ini`; FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par |
| `.tag` | `steps/02c-LnR0/model/bet.tag` |
| `.age_length` | `steps/02c-LnR0/model/bet.age_length` |
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
| 2 | MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 02c-LnR0 to isolate this substep's change. |
| 2 | No fishery, tag, CAAL, or CPUE update is intended in this step. |
