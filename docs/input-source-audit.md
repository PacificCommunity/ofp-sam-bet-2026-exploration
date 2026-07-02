# Input Source Audit

This page answers one question: after pulling the source input repos, what is
copied as-is and what is intentionally changed in the generated model folders?

## Short Answer

| Input | Source-exact? | Intentional generated change |
| --- | --- | --- |
| `.frq` | Yes for steps 01-13. | Steps 14-15 change only index-fishery effort values for effort creep. |
| `.tag` | Yes for all steps. | None. `tag_rep_map.R` is an audit file, not an MFCL input. |
| `.age_length` | Records are copied from source. | Steps 04-15 set effective sample size from `1` to `0.75`. |
| `.ini` | 01 and 02a are source-exact. Later steps are generated from source baselines. | MFCL 1007 conversion, `LN(R0)`, FixM, tag/RR alignment, and current-reader compatibility edits. |
| `bet.reg_scaling` | Yes for steps 08-15. | None. |

## Source Repos Checked

| Repo | Current source commit | BET-side note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Latest pulled changes affect YFT files only; BET `.frq` sources used here are unchanged. |
| `ofp-sam-2026-BET-YFT-build-ini` | `0443d39` | BET `bet.2023.new.structure.ini` now has `tag_flags(it,2)=0` in source. |
| `ofp-sam-2026-BET-YFT-tag-prep` | `5a4f5fb` | `bet.2026.low.recaps.removed.tag` is used unchanged for steps 07-15. |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | Source CAAL records are used; generated files only change effective sample size. |

## By File Type

| File type | Steps | Source file | Generated difference |
| --- | --- | --- | --- |
| `.frq` | 01-13 | Selected source in `frq-build`, diagnostic repo, or archived 2023 replication inputs. | None found in byte-for-byte source checks. |
| `.frq` | 14-15 | `BET/bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq` | Effort values for index fisheries 29-33 are multiplied by the agreed effort-creep schedule. |
| `.tag` | 01-15 | Selected source `.tag` for each step family. | None. |
| `.age_length` | 01-03 | Diagnostic or archived 2023 replication source. | None. |
| `.age_length` | 04-08 | `BET/bet.2023.new-structure.age_length` | 112 effective-sample-size values change from `1` to `0.75`. |
| `.age_length` | 09-15 | `BET/bet.2026.age_length` | 181 effective-sample-size values change from `1` to `0.75`. |
| `bet.reg_scaling` | 08-15 | `BET/bet.2026.reg_scaling` | None. |

## INI Edits

| Steps | Source baseline | Generated `.ini` edits | Why |
| --- | --- | --- | --- |
| 01 | 2023 diagnostic `bet.ini` | No edit. | Keeps the historical diagnostic input exactly as run in 2023. |
| 02a | Archived 2023 replication `bet.ini` | No edit. The ini remains MFCL 1003 format. | Isolates the current executable effect before changing the ini layout. |
| 02b | 02a generated input | Sets ini version to `1007`; inserts 118 `# tag flags` rows with two-quarter mixing and `tag_flags(it,2)=0`; inserts a zero tag-shed vector; inserts MFCL 1007 defaults for `LN(R0)=25` and Richards growth parameter `0`. | Converts the 2023 replication ini into a current-reader layout without changing the assessment data. |
| 02c | 02b generated input | Changes `# Total population scaling factor (LN(R0))` from `25` to `17`. | Restores the diagnostic-scale initial value selected for this stepwise path. |
| 03 | 02c generated input | Replaces the `# age_pars` natural-mortality row with the fixed-M row from the 01 diagnostic `mgc=-5` final par. | Carries the chosen diagnostic M estimate into later current-executable runs. |
| 04-06 | `BET/bet.2023.new.structure.ini` | Applies the same FixM row and normalizes the `# tag flags` marker/format. Source already has 96 tag groups, two-quarter mixing, and `tag_flags(it,2)=0`; `LN(R0)` remains `17`. | Moves to the 5-region structure while keeping the intended tag treatment and fixed M. |
| 07-09 | `BET/bet.2026.ini`, plus RR blocks from `BET/ini.mix-period/bet.2026.mix-0.2.ini` | Applies FixM; copies the five RR matrix blocks from the mix-period ini; pads tag flags, RR matrices, and tag-shed rates from 91 to 98 release groups; sets all `tag_flags(it,2)` from source `1` to generated `0`; repairs fishery 19 RR cells. Mixing remains two quarters for all 98 groups. | Aligns the 2026 tag file with the 2026 ini/RR shape while keeping the 2023-style RR treatment during mixing. |
| 10-15 | `BET/ini.mix-period/bet.2026.mix-0.2.ini` | Applies FixM; keeps release-specific mixing where positive; sets all `tag_flags(it,2)` from source `1` to generated `0`; raises 41 source zero mixing periods to `1`; repairs fishery 19 RR cells. | Uses release-specific mixing from the KS build but avoids zero-period values that the current MFCL reader rejects. |

Current tag-flag check:

| File | Release rows | Mixing-period column | `tag_flags(it,2)` column |
| --- | ---: | --- | --- |
| Source `bet.2023.new.structure.ini` | 96 | all `2` | all `0` |
| Generated step 04 ini | 96 | all `2` | all `0` |
| Source `bet.2026.ini` | 91 | all `2` | all `1` |
| Generated step 07 ini | 98 | all `2` | all `0` |
| Source `bet.2026.mix-0.2.ini` | 98 | `0`, `1`, `2`, `3`, `4` release-specific values | all `1` |
| Generated step 10 ini | 98 | source `0` values raised to `1`; other values retained | all `0` |

Fishery 19 RR repair applies only where positive fishery 19 recaptures had
inactive zero RR cells: release groups `19`, `20`, `21`, `31`, `35`, and `40`.
Those cells copy the matching fishery 21 RR settings. Details are in
[`tag-reporting-groups.md`](tag-reporting-groups.md).

## Effort Creep Details

| Steps | Fisheries | Records changed | Rule |
| --- | ---: | ---: | --- |
| 14-15 | 29-33 | 1,440 per step | 1%/yr for 1952-1976, then 0.5%/yr for 1977-2024. |

Only positive effort values are changed. Catch, size compositions, tag inputs,
and regional-scaling inputs are not changed by the effort-creep step.
