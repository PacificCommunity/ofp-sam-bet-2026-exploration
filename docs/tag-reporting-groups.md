# Tag Reporting-Rate Groups

This note separates the actual MFCL input from the generated audit map. The
layout follows the SAM 12 June 2026 tag reporting-rate presentation and the
current model `.ini/.tag` files.

- MFCL reads the five tag reporting-rate matrices in `bet.ini`: `# tag fish rep`, `# tag fish rep group flags`, `# tag_fish_rep active flags`, `# tag_fish_rep target`, and `# tag_fish_rep penalty`.
- Rows are tag release/reporting events and columns are fisheries. The final row is the pooled tagged-population row, so the expected row count is release groups + 1.
- `tag_rep_map.R` is generated from those `.ini` matrices plus `bet.tag` release metadata. It is an audit/lookup file, not an MFCL input file. It mirrors the presentation's `tag_summary.R` idea: make the group/event/fishery structure readable, then keep MFCL input in the `.ini`.

## PPT Basis

The presentation defines tag reporting rates as release-event and fishery
specific. The parameter matrix is:

```text
(number of release events + 1 pooled tagged-population row) x number of fisheries
```

The `# tag fish rep group flags` matrix is the grouping map. For a group ID,
the matching cells in `# tag fish rep`, `# tag_fish_rep active flags`,
`# tag_fish_rep target`, and `# tag_fish_rep penalty` give the initial value,
estimation switch, prior target, and penalty. The presentation's BET2023
example is a 41-group setup with 118 release events, one pooled row, and 41
fisheries; steps 01-02 match that event/fishery grouping exactly.

## Step Families

| steps | source | fisheries | release_groups | reporting_rows | groups | note |
| --- | --- | --- | --- | --- | --- | --- |
| 01-02 | legacy 2023 diagnostic/FixM inputs | 41 | 118 | 119 | 41 | old model grouping retained |
| 03-05 | `bet.2023.new.structure.ini` + low-recapture-removed 2023 new-structure tag | 33 | 96 | 97 | 33 | new-structure grouping from upstream `.ini`; 04/05 inherit 03 |
| 06-07 | `bet.2026.ini` + 2026 low-recapture-removed tag | 33 | 98 | 99 | 33 | 7 missing release rows in source `.ini` are filled by exact program/region/year/month matches |
| 08-12 | `bet.2026.mix-0.2.ini` + 2026 low-recapture-removed tag | 33 | 98 | 99 | 33 | mix-period `.ini` already carries complete reporting matrices |

## 01-02 Legacy Groups

These are the inherited BET2023 diagnostic/FixM groups from the presentation.
The event/fishery grouping below was checked against the current 01 `.ini`;
there were no row or fishery mismatches. The active/initial/target/penalty
values are read from `bet.ini`.

| group | program rows | tag events | fisheries | active | initial | target | penalty |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | RTTP/PTTP/pooled | 1-76,119 | 1-2,4-9,11-12,29 | TRUE | 0.5 | 50 | 1 |
| 2 | RTTP/PTTP/pooled | 1-76,119 | 3 | FALSE | 0 | 0 | 0 |
| 3 | RTTP/PTTP/pooled | 1-76,119 | 10,27 | TRUE | 0.5 | 50 | 1 |
| 4 | RTTP | 1-25 | 13-14 | TRUE | 0.586 | 58.6 | 244 |
| 5 | RTTP | 1-25 | 15-16 | TRUE | 0.586 | 58.6 | 244 |
| 6 | RTTP | 1-25 | 17-18,23-24 | TRUE | 0.5 | 50 | 1 |
| 7 | RTTP | 1-25 | 19 | FALSE | 0 | 0 | 0 |
| 8 | RTTP | 1-25 | 20 | FALSE | 0 | 0 | 0 |
| 9 | RTTP | 1-25 | 21 | FALSE | 0 | 0 | 0 |
| 10 | RTTP | 1-25 | 22 | FALSE | 0 | 0 | 0 |
| 11 | RTTP | 1-25 | 25 | TRUE | 0.586 | 58.6 | 244 |
| 12 | RTTP | 1-25 | 26 | TRUE | 0.586 | 58.6 | 244 |
| 13 | RTTP | 1-25 | 28 | TRUE | 0.5 | 50 | 1 |
| 14 | RTTP | 1-25 | 30-31 | FALSE | 0 | 0 | 0 |
| 15 | RTTP | 1-25 | 32 | FALSE | 0 | 0 | 0 |
| 16 | RTTP/PTTP/JPTP/pooled | 1-119 | 33-41 | FALSE | 0 | 0 | 0 |
| 17 | PTTP/pooled | 26-76,119 | 13-14 | TRUE | 0.5719155 | 57.19155 | 463 |
| 18 | PTTP/pooled | 26-76,119 | 15-16 | TRUE | 0.6195912 | 61.95912 | 510 |
| 19 | PTTP/pooled | 26-76,119 | 17-18,23-24 | TRUE | 0.5 | 50 | 1 |
| 20 | PTTP/pooled | 26-76,119 | 19 | FALSE | 0 | 0 | 0 |
| 21 | PTTP/pooled | 26-76,119 | 20 | FALSE | 0 | 0 | 0 |
| 22 | PTTP/pooled | 26-76,119 | 21 | FALSE | 0 | 0 | 0 |
| 23 | PTTP/pooled | 26-76,119 | 22 | FALSE | 0 | 0 | 0 |
| 24 | PTTP/pooled | 26-76,119 | 25-26 | TRUE | 0.7093884 | 70.93884 | 798 |
| 25 | PTTP/pooled | 26-76,119 | 28 | TRUE | 0.5 | 50 | 1 |
| 26 | PTTP/pooled | 26-76,119 | 30-31 | FALSE | 0 | 0 | 0 |
| 27 | PTTP/pooled | 26-76,119 | 32 | FALSE | 0 | 0 | 0 |
| 28 | JPTP | 77-118 | 1-2,4-9,11-12,29 | TRUE | 0.5 | 50 | 1 |
| 29 | JPTP | 77-118 | 3 | FALSE | 0 | 0 | 0 |
| 30 | JPTP | 77-118 | 10,27 | FALSE | 0 | 0 | 0 |
| 31 | JPTP | 77-118 | 13-14 | FALSE | 0 | 0 | 0 |
| 32 | JPTP | 77-118 | 15-16 | TRUE | 0.5 | 50 | 1 |
| 33 | JPTP | 77-118 | 17-18,23-24 | FALSE | 0 | 0 | 0 |
| 34 | JPTP | 77-118 | 19 | TRUE | 0.5 | 50 | 1 |
| 35 | JPTP | 77-118 | 20 | TRUE | 0.5 | 50 | 1 |
| 36 | JPTP | 77-118 | 21 | FALSE | 0 | 0 | 0 |
| 37 | JPTP | 77-118 | 22 | FALSE | 0 | 0 | 0 |
| 38 | JPTP | 77-118 | 25-26 | FALSE | 0 | 0 | 0 |
| 39 | JPTP | 77-118 | 28 | FALSE | 0 | 0 | 0 |
| 40 | JPTP | 77-118 | 30-31 | FALSE | 0 | 0 | 0 |
| 41 | JPTP | 77-118 | 32 | FALSE | 0 | 0 | 0 |

## 03-05 New-Structure Groups

Steps 03-05 use the 33-fishery new-structure reporting-rate grouping. Step 03 reads it from `bet.2023.new.structure.ini`; steps 04-05 inherit the 03 `.ini/.tag` family.

| group | program_rows | fishery_group | fisheries | event_rows | release_groups | active | initial | target | penalty |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | RTTP/PTTP/pooled | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 1-56,97 | 1-56 | TRUE | 0.5 | 50 | 1 |
| 2 | RTTP/PTTP/pooled | LL.US.1 | 3 | 1-56,97 | 1-56 | FALSE | 0 | 0 | 0 |
| 3 | RTTP/PTTP/pooled | LL.AU.5 | 11 | 1-56,97 | 1-56 | FALSE | 0 | 0 | 0 |
| 4 | RTTP | PS.JP.1 | 12 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 5 | RTTP | PL.JP.1 | 13 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 6 | RTTP | PHID.2 | 14-15,17-18,21-22 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 7 | RTTP | PL.ALL.2 | 16 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 8 | RTTP | PS.2 | 19-20 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 9 | RTTP | DOM.VN.2 | 23 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 10 | RTTP | PL.ALL.WEST.3 | 24 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 11 | RTTP | PS.WEST.3 | 25,27 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 12 | RTTP | PS.EAST.3 | 26,28 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 13 | PTTP/pooled | PS.JP.1 | 12 | 16-56,97 | 16-56 | FALSE | 0 | 0 | 0 |
| 14 | PTTP/pooled | PL.JP.1 | 13 | 16-56,97 | 16-56 | FALSE | 0 | 0 | 0 |
| 15 | PTTP/pooled | PHID.2 | 14-15,17-18,21-22 | 16-56,97 | 16-56 | TRUE | 0.5 | 50 | 1 |
| 16 | PTTP/pooled | PL.ALL.2; PS.2 | 16,19-20 | 16-56,97 | 16-56 | FALSE | 0 | 0 | 0 |
| 17 | PTTP/pooled | DOM.VN.2 | 23 | 16-56,97 | 16-56 | FALSE | 0 | 0 | 0 |
| 18 | PTTP/pooled | PL.ALL.WEST.3 | 24 | 16-56,97 | 16-56 | TRUE | 0.5 | 50 | 1 |
| 19 | PTTP/pooled | PS.WEST.3 | 25,27 | 16-56,97 | 16-56 | TRUE | 0.595 | 59.5 | 676 |
| 20 | PTTP/pooled | PS.EAST.3 | 26,28 | 16-56,97 | 16-56 | TRUE | 0.7 | 70 | 195 |
| 21 | JPTP | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 57-96 | 57-96 | TRUE | 0.5 | 50 | 1 |
| 22 | JPTP | LL.US.1 | 3 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 23 | JPTP | LL.AU.5 | 11 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 24 | JPTP | PS.JP.1 | 12 | 57-96 | 57-96 | TRUE | 0.5 | 50 | 1 |
| 25 | JPTP | PL.JP.1 | 13 | 57-96 | 57-96 | TRUE | 0.5 | 50 | 1 |
| 26 | JPTP | PHID.2 | 14-15,17-18,21-22 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 27 | JPTP | PL.ALL.2 | 16 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 28 | JPTP | PS.2 | 19-20 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 29 | JPTP | DOM.VN.2 | 23 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 30 | JPTP | PL.ALL.WEST.3 | 24 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 31 | JPTP | PS.WEST.3 | 25,27 | 57-96 | 57-96 | TRUE | 0.5 | 50 | 1 |
| 32 | JPTP | PS.EAST.3 | 26,28 | 57-96 | 57-96 | FALSE | 0 | 0 | 0 |
| 33 | RTTP/PTTP/JPTP/pooled | Index | 29-33 | 1-97 | 1-96 | FALSE | 0 | 0 | 0 |

## 06-07 Full-2024 Non-Mix Groups

Steps 06-07 use `bet.2026.ini`. The source `.ini` had 91 reporting rows, while the selected `.tag` had 98 release groups. Rows 92-98 were filled before the pooled row by matching the release key `(program, region, year, month)` against `bet.2023.new.structure.ini`.

| release_group | region | year | month | program |
| --- | --- | --- | --- | --- |
| 92 | 1 | 2012 | 2 | JPTP |
| 93 | 1 | 2012 | 5 | JPTP |
| 94 | 1 | 2014 | 5 | JPTP |
| 95 | 1 | 2017 | 2 | JPTP |
| 96 | 3 | 2001 | 8 | JPTP |
| 97 | 3 | 2003 | 11 | JPTP |
| 98 | 3 | 2005 | 8 | JPTP |

| group | program_rows | fishery_group | fisheries | event_rows | release_groups | active | initial | target | penalty |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | RTTP/PTTP/pooled | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 1-59,99 | 1-59 | TRUE | 0.5 | 50 | 1 |
| 2 | RTTP/PTTP/pooled | LL.US.1 | 3 | 1-59,99 | 1-59 | FALSE | 0 | 0 | 0 |
| 3 | RTTP/PTTP/pooled | LL.AU.5 | 11 | 1-59,99 | 1-59 | FALSE | 0 | 0 | 0 |
| 4 | RTTP | PS.JP.1 | 12 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 5 | RTTP | PL.JP.1 | 13 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 6 | RTTP | PHID.2 | 14-15,17-18,21-22 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 7 | RTTP | PL.ALL.2 | 16 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 8 | RTTP | PS.2 | 19-20 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 9 | RTTP | DOM.VN.2 | 23 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 10 | RTTP | PL.ALL.WEST.3 | 24 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 11 | RTTP | PS.WEST.3 | 25,27 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 12 | RTTP | PS.EAST.3 | 26,28 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 13 | PTTP/pooled | PS.JP.1 | 12 | 16-59,99 | 16-59 | FALSE | 0 | 0 | 0 |
| 14 | PTTP/pooled | PL.JP.1 | 13 | 16-59,99 | 16-59 | FALSE | 0 | 0 | 0 |
| 15 | PTTP/pooled | PHID.2 | 14-15,17-18,21-22 | 16-59,99 | 16-59 | FALSE | 0 | 0 | 0 |
| 16 | PTTP/pooled | PL.ALL.2; PS.2 | 16,19-20 | 16-59,99 | 16-59 | FALSE | 0 | 0 | 0 |
| 17 | PTTP/pooled | DOM.VN.2 | 23 | 16-59,99 | 16-59 | FALSE | 0 | 0 | 0 |
| 18 | PTTP/pooled | PL.ALL.WEST.3 | 24 | 16-59,99 | 16-59 | TRUE | 0.5 | 50 | 1 |
| 19 | PTTP/pooled | PS.WEST.3 | 25,27 | 16-59,99 | 16-59 | TRUE | 0.5121 | 51.21 | 739.2 |
| 20 | PTTP/pooled | PS.EAST.3 | 26,28 | 16-59,99 | 16-59 | TRUE | 0.5282 | 52.82 | 231.2 |
| 21 | PTTP/JPTP | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 60-98 | 60-98 | TRUE | 0.5 | 50 | 1 |
| 22 | PTTP/JPTP | LL.US.1 | 3 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 23 | PTTP/JPTP | LL.AU.5 | 11 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 24 | PTTP/JPTP | PS.JP.1 | 12 | 60-98 | 60-98 | TRUE | 0.5 | 50 | 1 |
| 25 | PTTP/JPTP | PL.JP.1 | 13 | 60-98 | 60-98 | TRUE | 0.5 | 50 | 1 |
| 26 | PTTP/JPTP | PHID.2 | 14-15,17-18,21-22 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 27 | PTTP/JPTP | PL.ALL.2 | 16 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 28 | PTTP/JPTP | PS.2 | 19-20 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 29 | PTTP/JPTP | DOM.VN.2 | 23 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 30 | PTTP/JPTP | PL.ALL.WEST.3 | 24 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 31 | PTTP/JPTP | PS.WEST.3 | 25,27 | 60-98 | 60-98 | TRUE | 0.5 | 50 | 1 |
| 32 | PTTP/JPTP | PS.EAST.3 | 26,28 | 60-98 | 60-98 | FALSE | 0 | 0 | 0 |
| 33 | RTTP/PTTP/JPTP/pooled | Index | 29-33 | 1-99 | 1-98 | FALSE | 0 | 0 | 0 |

## 08-12 Mix-Period Groups

Steps 08-12 use the mix-period `.ini` family. The reporting-rate matrix shape is already complete for the 98 selected release groups plus pooled row.

| group | program_rows | fishery_group | fisheries | event_rows | release_groups | active | initial | target | penalty |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | RTTP/PTTP/pooled | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 1-61,99 | 1-61 | TRUE | 0.5 | 50 | 1 |
| 2 | RTTP/PTTP/pooled | LL.US.1 | 3 | 1-61,99 | 1-61 | FALSE | 0 | 0 | 0 |
| 3 | RTTP/PTTP/pooled | LL.AU.5 | 11 | 1-61,99 | 1-61 | FALSE | 0 | 0 | 0 |
| 4 | RTTP | PS.JP.1 | 12 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 5 | RTTP | PL.JP.1 | 13 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 6 | RTTP | PHID.2 | 14-15,17-18,21-22 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 7 | RTTP | PL.ALL.2 | 16 | 1-15 | 1-15 | TRUE | 0.5 | 50 | 1 |
| 8 | RTTP | PS.2 | 19-20 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 9 | RTTP | DOM.VN.2 | 23 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 10 | RTTP | PL.ALL.WEST.3 | 24 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 11 | RTTP | PS.WEST.3 | 25,27 | 1-15 | 1-15 | TRUE | 0.586 | 58.6 | 244 |
| 12 | RTTP | PS.EAST.3 | 26,28 | 1-15 | 1-15 | FALSE | 0 | 0 | 0 |
| 13 | PTTP/pooled | PS.JP.1 | 12 | 16-61,99 | 16-61 | FALSE | 0 | 0 | 0 |
| 14 | PTTP/pooled | PL.JP.1 | 13 | 16-61,99 | 16-61 | FALSE | 0 | 0 | 0 |
| 15 | PTTP/pooled | PHID.2 | 14-15,17-18,21-22 | 16-61,99 | 16-61 | TRUE | 0.5 | 50 | 1 |
| 16 | PTTP/pooled | PL.ALL.2; PS.2 | 16,19-20 | 16-61,99 | 16-61 | FALSE | 0 | 0 | 0 |
| 17 | PTTP/pooled | DOM.VN.2 | 23 | 16-61,99 | 16-61 | FALSE | 0 | 0 | 0 |
| 18 | PTTP/pooled | PL.ALL.WEST.3 | 24 | 16-61,99 | 16-61 | TRUE | 0.5 | 50 | 1 |
| 19 | PTTP/pooled | PS.WEST.3 | 25,27 | 16-61,99 | 16-61 | TRUE | 0.5121 | 51.21 | 739.2 |
| 20 | PTTP/pooled | PS.EAST.3 | 26,28 | 16-61,99 | 16-61 | TRUE | 0.5282 | 52.82 | 231.2 |
| 21 | JPTP | LL.WEST.1; LL.EAST.1; LL.ALL.2; LL.OS.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.OS.3; LL.ALL.5 | 1-2,4-10 | 62-98 | 62-98 | TRUE | 0.5 | 50 | 1 |
| 22 | JPTP | LL.US.1 | 3 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 23 | JPTP | LL.AU.5 | 11 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 24 | JPTP | PS.JP.1 | 12 | 62-98 | 62-98 | TRUE | 0.5 | 50 | 1 |
| 25 | JPTP | PL.JP.1 | 13 | 62-98 | 62-98 | TRUE | 0.5 | 50 | 1 |
| 26 | JPTP | PHID.2 | 14-15,17-18,21-22 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 27 | JPTP | PL.ALL.2 | 16 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 28 | JPTP | PS.2 | 19-20 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 29 | JPTP | DOM.VN.2 | 23 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 30 | JPTP | PL.ALL.WEST.3 | 24 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 31 | JPTP | PS.WEST.3 | 25,27 | 62-98 | 62-98 | TRUE | 0.5 | 50 | 1 |
| 32 | JPTP | PS.EAST.3 | 26,28 | 62-98 | 62-98 | FALSE | 0 | 0 | 0 |
| 33 | RTTP/PTTP/JPTP/pooled | Index | 29-33 | 1-99 | 1-98 | FALSE | 0 | 0 | 0 |
