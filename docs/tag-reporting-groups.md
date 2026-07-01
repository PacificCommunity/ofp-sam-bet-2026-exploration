# Tag Reporting Rates

This note is only about the tag reporting-rate inputs used by MFCL. It is a
short map for checking which file matters and which step family uses which tag
setup.

## What MFCL Reads

MFCL reads tag reporting rates from `bet.ini`, not from `tag_rep_map.R`.

The relevant `bet.ini` blocks are:

| Block | Meaning |
| --- | --- |
| `# tag fish rep` | Initial reporting-rate values. |
| `# tag fish rep group flags` | Group IDs linking release rows and fisheries. |
| `# tag_fish_rep active flags` | Estimation switches. |
| `# tag_fish_rep target` | Prior targets. |
| `# tag_fish_rep penalty` | Prior penalties. |

Rows are tag release groups plus one pooled tagged-population row. Columns are
fisheries.

```text
expected reporting-rate rows = tag release groups + 1 pooled row
```

`tag_rep_map.R` is generated only as an audit lookup. It helps humans inspect
the `.ini` grouping, but MFCL does not read it.

## Step Families

| Steps | Fisheries | Release groups | Reporting-rate rows | Tag setting | What to check |
| --- | ---: | ---: | ---: | --- | --- |
| `01-Diag2023`, `02a-NewExe` | 41 | 118 | 119 | Historical / MFCL 1003 controls | 2023 diagnostic shape retained. |
| `02b-Ini1007`, `02c-LnR0`, `03-FixM` | 41 | 118 | 119 | MFCL 1007, `tag_flags(it,2)=0` | Ini layout changes without changing the diagnostic tag grouping. |
| `04a-NewStructure` | 33 | 96 | 97 | `tag_flags(it,2)=0` | 5-region structure isolated before the tag-treatment switch. |
| `04b-TagReportingMixing`, `05-ConvertToLength`, `06-LengthPlusLength` | 33 | 96 | 97 | `tag_flags(it,2)=1` | Same 5-region tag grouping; reporting rates excluded during mixing. |
| `07-DataTo2024`, `08-RegionalCPUE`, `09-NewOtoliths` | 33 | 98 | 99 | `tag_flags(it,2)=1` | 2026 tag build has 98 release groups; `.ini` matrices are padded/aligned to 99 rows. |
| `10-TagMixingKS` to `15-DataWeighting` | 33 | 98 | 99 | release-specific mixing, `it2=1` | Release-specific mixing periods are read from the mix-period `.ini`. |

## Why 04b Exists

`04a-NewStructure` keeps `tag_flags(it,2)=0` so the 5-region structural change
can be compared cleanly.

`04b-TagReportingMixing` changes only `tag_flags(it,2)` from `0` to `1`. With
`1`, reporting rates are excluded from predicted tag recaptures during the tag
mixing period. Steps `05` onward inherit this runnable setting.

## Alignment Checks

Generated inputs check three tag sections before Kflow submission:

| Check | Pass condition |
| --- | --- |
| Reporting-rate matrices | Each matrix has `release groups + 1` rows and one column per fishery. |
| `# tag flags` | One row per release group. |
| `# tag shed rate` | One value per release group. |

For `07`-`09`, the selected 2026 tag file has 98 release groups while the source
`bet.2026.ini` reporting matrices had fewer rows. The generator fills the
missing release rows by matching `(program, region, year, month)` from the
previous new-structure ini, then keeps the pooled row last.

The full cell-by-cell audit remains in each model folder as
`steps/<step_id>/model/tag_rep_map.R`.
