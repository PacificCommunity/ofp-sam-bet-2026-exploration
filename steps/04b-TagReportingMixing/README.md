# 04b TagReportingMixing

04a new-structure input with `tag_flags(it,2)=1` so reporting rates are excluded during tag mixing periods.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/04b-TagReportingMixing/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same `.frq`, `.tag`, CAAL, FixM, LN(R0), and 5-region controls as 04a-NewStructure. |
| 2 | Changes only the second tag-flag column: `tag_flags(it,2)=1`. |
| 3 | This excludes tag reporting rates from predicted tag recaptures only during the specified tag mixing periods. |
| 4 | Later steps inherit this 04b tag-treatment setting. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/04a-NewStructure/model/bet.frq`; 04a 5-region, 33-fishery structure, terminal year 2021, global CPUE |
| `.ini` | `steps/04a-NewStructure/model/bet.ini`, with `tag_flags(it,2)=1` applied; FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; set tag_flags(it,2)=1 for 96 release groups so reporting rates are excluded from predicted tag catches during mixing |
| `.tag` | `steps/04a-NewStructure/model/bet.tag`; same 04a low-recapture-removed tag input |
| `.age_length` | `steps/04a-NewStructure/model/bet.age_length`; same 04a old CAAL / age_length input; set age_length effective sample size to 0.75 for 112 records |
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
| 1 | 04a-NewStructure 5-region `doitall.sh` controls retained. |
| 2 | `tag_flags(it,1)=2` still supplies the two-quarter tag mixing period. |
| 3 | `tag_flags(it,2)=1` excludes reporting rates from predicted tag recaptures during those mixing periods. |
| 4 | This follows the MFCL warning/recommended treatment and keeps the change separate from the 04a structural transition. |
| 5 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Compare directly with 04a-NewStructure to isolate the effect of excluding reporting rates during tag mixing periods. |
| 2 | This substep is the inherited tag-treatment baseline for steps 05-15. |

## Checks

| # | Check |
| --- | --- |
| 1 | After fitting, compare the tag likelihood and early time-at-liberty residuals against 04a-NewStructure. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
