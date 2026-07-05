# Tag Reporting-Rate Inputs

This note is a compact map of the MFCL tag reporting-rate inputs. It is for
checking file structure, not for defining extra stepwise model changes.

## What MFCL Reads

MFCL reads tag reporting rates from `bet.ini`. `tag_rep_map.R` is generated
only as a human-readable audit lookup.

| `bet.ini` block | Meaning |
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

## Step Families

| Steps | Fisheries | Release groups | Reporting-rate rows | What to check |
| --- | ---: | ---: | ---: | --- |
| `01-Diag2023`, `02a-NewExe` | 41 | 118 | 119 | 2023 diagnostic shape retained. |
| `02b-Ini1007`, `02c-LengthWeight`, `03-FixM` | 41 | 118 | 119 | MFCL 1007 layout without changing the diagnostic tag grouping. |
| `04-NewStructure`, `05-ConvertToLength`, `06-LengthPlusLength` | 33 | 96 | 97 | 5-region tag grouping. |
| `07-DataTo2024`, `08-RegionalCPUE`, `09-NewOtoliths` | 33 | 98 | 99 | 2026 tag build with aligned reporting-rate matrices. |
| `10-TagMixingKS` to `15-DataWeighting` | 33 | 98 | 99 | Release-specific mixing periods are read from the mix-period `.ini`. |

## Alignment Checks

Generated inputs check three tag sections before Kflow submission:

| Check | Pass condition |
| --- | --- |
| Reporting-rate matrices | Each matrix has `release groups + 1` rows and one column per fishery. |
| Tag-control rows | One row per release group. |
| Tag shed rate | One value per release group. |

For `07`-`09`, the selected 2026 tag file has 98 release groups and the latest
source reporting matrices already have 99 rows, including the pooled row. The
generator copies the latest RR/active/target/penalty blocks from the mix-period
ini, then checks the dimensions and positive-recapture cells before writing the
model folder.

## Generated Changes To Tag Inputs

The `.tag` file is copied unchanged for steps 07-15. The changes below are
edits to generated `bet.ini` files so MFCL sees tag controls and RR matrices
that match the selected `.tag`.

| Scope | Source | Change in generated `bet.ini` |
| --- | --- | --- |
| `.tag`, steps 07-15 | `bet.2026.low.recaps.removed.tag` | Copied unchanged from the tag-prep repo. |
| Tag flags, steps 04-06 | `bet.2023.new.structure.ini` | Source has 98 identical tag-control rows for a 96-release-group tag file; generated rows are trimmed to 96. |
| Tag flags, steps 07-09 | `bet.2026.ini` | Latest 98 rows kept; column 2 `tag_flags(it,2)` set from `1` to `0`. |
| RR matrices, steps 07-09 | `bet.2026.mix-0.2.ini` | Five RR/active/target/penalty blocks copied into the 07-09 `.ini`, then kept at 99 rows. |
| Tag flags, steps 10-15 | `bet.2026.mix-0.2.ini` | Column 2 `tag_flags(it,2)` set from `1` to `0`. |
| Mixing periods, steps 10-15 | `bet.2026.mix-0.2.ini` | Source `0` mixing periods are raised to `1` for groups `43` and `46`. |
| Positive recapture RR check, steps 04-15 | Generated `.ini` and selected `.tag` | Every positive recapture must have nonzero RR, active, target, and penalty cells. |

The older fishery 19 repair helper remains available for older upstream inputs
that still have inactive RR cells, but the latest `f8faf7c` / `e0b427d` source
combination passes by validation rather than by applying that repair.

The full cell-by-cell audit remains in each model folder as
`steps/<step_id>/model/tag_rep_map.R`.
