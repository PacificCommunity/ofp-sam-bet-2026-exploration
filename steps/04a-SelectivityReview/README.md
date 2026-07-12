# 04a SelectivityReview

Fishery-level LF/selectivity review on the unchanged 04-NewStructure inputs.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/04a-SelectivityReview/model` |
| Status | Reference PDH controls reconstructed; full stepwise rerun pending. |

## Changes

| # | Change |
| --- | --- |
| 1 | Keeps every MFCL data input identical to 04-NewStructure so this substep isolates the control changes. |
| 2 | Restores upper-size prediction flexibility for F20 and F28, which have observed large fish outside the previous selectable range. |
| 3 | Prevents unsupported young-age predictions for F26 (age class 1) and F12 (age classes 1-2). |
| 4 | Moves the first zero-selectivity age for F17 from 12 to 6 to reduce over-prediction of large fish. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | byte-identical to `steps/04-NewStructure/model/bet.frq` |
| `.ini` | byte-identical to `steps/04-NewStructure/model/bet.ini` |
| `.tag` | byte-identical to `steps/04-NewStructure/model/bet.tag` |
| `.age_length` | byte-identical to `steps/04-NewStructure/model/bet.age_length` |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq/.ini/.tag/.age_length` | No change; files are copied byte-for-byte from 04-NewStructure. | All data, tag, growth, mortality, CPUE, and recruitment inputs and controls. |
| `doitall.sh` | Applies only the five documented fishery-level LF/selectivity controls. | Every other 04-NewStructure control. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `386d169` | Correct RR init values |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` | Correct RR group init values |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | F20: `ff(16)=0`, `ff(3)=37`; F28: `ff(16)=0`, `ff(3)=37`. |
| 2 | F26: `ff(75)=1`; F12: `ff(75)=2`. |
| 3 | F17: `ff(16)=2`, `ff(3)=6`. |
| 4 | The settings reproduce the reviewed PDH Step 12 parameter state exactly; no additional fisheries are modified. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Compare directly with 04-NewStructure to isolate the likelihood and fit effect of the reviewed LF/selectivity controls. |
| 2 | Steps 05-15 inherit this substep; OPR and the terminal-recruitment penalty are not activated until Step 12. |

## Checks

| # | Check |
| --- | --- |
| 1 | Confirm the intended LF fit improvement before promoting the settings beyond this reconstruction branch. |
