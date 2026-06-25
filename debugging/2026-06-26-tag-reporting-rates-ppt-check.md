# Tag Reporting Rates PPT Check

Date: 2026-06-26  
Reference: `tag_rep_rates.pptx` slide deck provided during input preparation

## PPT Points Used

The presentation describes MFCL tag reporting-rate parameters as five `.ini`
matrices:

- `# tag fish rep`: initial reporting-rate values
- `# tag fish rep group flags`: reporting-rate grouping by tag event and fishery
- `# tag_fish_rep active flags`: estimation switch
- `# tag_fish_rep target`: prior mean
- `# tag_fish_rep penalty`: penalty on deviations from the prior

For these five matrices, rows are tag release/reporting events and columns are
fisheries. The expected shape is:

```text
(number of release groups + 1 pooled tagged-population row) x number of fisheries
```

The `+1` row is the pooled tagged population. This is separate from the MFCL
1007 `# tag flags` block, which is a release-group control matrix and should
match the number of release groups, not the reporting-matrix pooled-row count.

## Current Stepwise Check

The generated inputs currently match the PPT shape:

| Steps | Release groups | Reporting matrix rows | Fishery columns | Tag flag rows |
| --- | ---: | ---: | ---: | ---: |
| 01-Diag23, 02-FixM | 118 | 119 | 41 | not explicit |
| 03-RegFish, 04-WtAsLen21, 05-WtAsLenPlusLen21 | 96 | 97 | 33 | 96 |
| 06-Full2024 through 12-DataWeight40 | 98 | 99 | 33 | 98 |

All five reporting-rate matrices have matching dimensions in each checked
model folder, and group IDs are positive.

## Fixes From This Check

No model input logic needed changing after this PPT check. The generator already
validates:

- all five reporting matrices have consistent dimensions;
- reporting matrix row count equals release groups plus one pooled row;
- `# tag flags` row count equals release groups;
- generated `tag_rep_map.R` is rebuilt from the selected `.ini` and `.tag`.

The correction made here was documentation cleanup. Older notes still described
03 as having 90 release groups and 91 reporting rows from an earlier input-prep
state. Current generated 03 has 96 release groups and 97 reporting rows, so the
notes and validation snippets were updated.

## Verification Command

The shape check was run across all generated step folders:

```r
for each steps/*/model:
  releases <- nrow(bet.tag release groups)
  reporting_rows <- nrow(# tag fish rep group flags)
  tag_flags_rows <- nrow(# tag flags), when present
  stopifnot(reporting_rows == releases + 1)
  stopifnot(is.na(tag_flags_rows) || tag_flags_rows == releases)
```

Observed output:

```text
01-Diag23, 02-FixM: releases 118, reporting rows 119, fisheries 41
03-RegFish through 05-WtAsLenPlusLen21: releases 96, reporting rows 97, fisheries 33
06-Full2024 through 12-DataWeight40: releases 98, reporting rows 99, fisheries 33
```
