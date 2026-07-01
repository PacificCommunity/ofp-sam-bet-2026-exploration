# 03 FixM

NewExe baseline with the FixM M-scale row applied from the 01-Diag2023 mgc=-5 final run.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/03-FixM/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the 2023 diagnostic 9-region, 41-fishery inputs ending in 2021. |
| 2 | `bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader while retaining the diagnostic values. |
| 3 | The current-executable `doitall.sh` controls match the existing stepwise diagnostic baseline: initial Z uses `2 94 1 2 128 100`, and survey CPUE CV settings are the current BET 2023 values. |
| 4 | Applies the FixM M-scale row from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 with value -2.54930339768360e+00 |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | 2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021 |
| `.ini` | 2023 diagnostic ini promoted for the current reader FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; set ini version to 1007; inserted MFCL 1007 tag flags for 118 release groups with 2 mixing periods and reporting rates retained during mixing; inserted zero tag shed-rate vector for 118 release groups; inserted MFCL 1007 total-population scalar default 25; inserted MFCL 1007 Richards growth parameter default 0 |
| `.tag` | 2023 diagnostic tag input |
| `.age_length` | 2023 diagnostic CAAL input |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `d884ce5` | remove len comps from LL from 2023.new.structure |
| `ofp-sam-2026-BET-YFT-build-ini` | `b39cbfd` | updated ini files to reflect updated tag files |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | assign unassigned gear to PS from canneries |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |

## Controls

| # | Control |
| --- | --- |
| 1 | The current MFCL executable `/home/mfcl/mfclo64` is used. |
| 2 | The step output includes the 2023 nine-region GeoJSON asset as a display-only map asset; it does not change MFCL inputs. |
| 3 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | This step should continue to match the previously generated 2026 stepwise diagnostic baseline. |
| 2 | No fishery, tag, CAAL, or CPUE update is intended in this step. |
