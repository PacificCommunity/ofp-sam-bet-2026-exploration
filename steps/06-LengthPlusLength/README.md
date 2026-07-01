# 06 LengthPlusLength

Data to 2021, global CPUE, adding length compositions that were not used in the past.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/06-LengthPlusLength/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq` from the frq-build repo. |
| 2 | Keeps the 04b-TagReportingMixing `.ini`, tag, and old CAAL inputs so this step isolates the additional length-composition data. |
| 3 | Applies FixM M row from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 through the inherited 04b-TagReportingMixing ini. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq`; terminal year 2021, global CPUE |
| `.ini` | `steps/04b-TagReportingMixing/model/bet.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 |
| `.tag` | `steps/04b-TagReportingMixing/model/bet.tag` |
| `.age_length` | `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records |
| `input_manifest.csv` | machine-readable source/input notes |

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
| 1 | 04b-TagReportingMixing 5-region `doitall.sh` controls retained. |
| 2 | The step inherits 04b's `tag_flags(it,2)=1` treatment so reporting rates are excluded from predicted tag catches during mixing. |
| 3 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Compare directly with 05-ConvertToLength to isolate the extra length-composition records. |

## Checks

| # | Check |
| --- | --- |
| 1 | Review fit impacts before deciding whether length-composition weighting needs adjustment. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
