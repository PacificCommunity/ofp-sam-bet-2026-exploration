# 08 RegionalCPUE

Regional CPUE step using the 2024 regional CPUE frequency file and regional-scaling prior.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/08-RegionalCPUE/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the full 2024 regional CPUE `.frq` from the frq-build repo. |
| 2 | Adds `bet.reg_scaling` and switches to the regional-scaling prior in PHASE 5. |
| 3 | Keeps old CAAL so the new otolith update is isolated in 09-NewOtoliths. |
| 4 | Uses the 2026 low-recapture-removed tag file and 2026 ini, with FixM M row from 01-Diag2023 mgc=-5 final.par from Kflow job 000604. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; filled 7 missing tag reporting-rate matrix rows before the pooled row for release groups 92-98 by matching tag program/region/year/month rows from bet.2023.new.structure.ini; normalized tag flags marker; padded existing MFCL 1007 tag flags from 91 to 98 release groups with 2 mixing periods and reporting rates excluded during mixing; padded tag shed-rate vector from 91 to 98 release groups with zero shed rates |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build, including canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records |
| `.reg_scaling` | `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions |
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
| 1 | 04b-TagReportingMixing 5-region `doitall.sh` controls retained until PHASE 5. |
| 2 | PHASE 5 switches index CPUE/selectivity grouping for the regional-scaling prior. |
| 3 | The inherited all-release-group `-9999 1 2` mixing-period override is removed; `tag_flags(it,1)=2` in `bet.ini` supplies the same two-quarter mixing period. |
| 4 | The step inherits 04b's `tag_flags(it,2)=1` treatment so reporting rates are excluded from predicted tag catches during mixing. |
| 5 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 6 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 7 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 8 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | Generated inputs only repair `.ini` alignment: reporting-rate matrices, tag flags, and shed rates are matched to the selected release-group count. |
| 2 | The latest `bet.2026.low.recaps.removed.tag` is kept; the tag build assigns missing-gear canneries recaptures to purse-seine before low-recap filtering. |
| 3 | Steps 07-09 use `tag_flags(it,2)=1` because paired Kflow checks failed with 0 and completed with 1. |

## Checks

| # | Check |
| --- | --- |
| 1 | Evaluate and test different regional CPUE prior values after this runnable baseline fit. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
