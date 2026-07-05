# BET 2026 Stepwise Input Alignment and Kflow Rerun Notes

Date: 2026-06-26  
Repository: `PacificCommunity/ofp-sam-bet-2026-stepwise`  
Fix commit: `80e3297` (`Fix BET 2026 tag shed-rate alignment`)

## Source Input Revisions

The generated stepwise folders record the exact source commits in each
`steps/<step>/input_manifest.csv` and README. At the time of this rerun the
input repos were:

- `ofp-sam-2026-BET-YFT-frq-build`: `7d636e8` - update frq files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40

## What Failed

### 04 and 05: chopped 2026 `.frq` paired with the wrong tag family

The first 2021-terminal transition setup chopped the 2026 frequency files
directly. That did two things that were not intended for steps 04 and 05:

- It carried the 2026 CPUE/index records into a step that should still isolate
  the old `bet.2023.new.structure.frq` CPUE/index records.
- It could be paired with a 2026 tag/ini family even though these steps are
  2021-terminal comparison models.

The Kflow failure observed for this family occurred while MFCL was reading tag
release groups. MFCL stopped around tag release group 18 because the inherited
mixing-period setup reached the terminal model period for the chopped model.

The correction is to build a hybrid `.frq`:

- non-index records come from the 2026 size/catch source chopped to 2021;
- index fisheries 29-33 are copied from `bet.2023.new.structure.frq`;
- `bet.ini` and `bet.tag` come from 03-RegFish's 96-release setup;
- the chopped `.frq` header tag-group count is reset to 96.

No tag release or recapture rows were deleted to silence warnings.

### 06 and 07: full-2024 `.frq/.tag` count did not align with `bet.2026.ini`

The first full-2024 Kflow attempt failed during MFCL `-makepar`, before a fit
output folder existed. The important log sequence was:

- `initial_tag_year(2) 157`
- `Error reading region_flags`
- `Bounds error reading pmature(34) in par file value is 0`
- payload creation then failed because no MFCL output folders existed

This was traced to a numeric stream alignment problem in the `.ini`, not to the
`.frq` records themselves. The selected 2026 `.frq` and `.tag` had 98 release
groups, but source `bet.2026.ini` still had shorter tag controls:

- tag flags covered 91 release groups;
- `# tag shed rate` had 91 values;
- the tag reporting-rate matrices were missing rows for release groups 92-98
  before the pooled row.

The generated inputs now repair only the `.ini` alignment:

- fill missing tag reporting-rate rows 92-98 by matching tag program, region,
  year, and month from `bet.2023.new.structure.ini`;
- normalize the MFCL 1007 `# tag flags` marker and pad the tag flags to 98 rows;
- pad `# tag shed rate` from 91 to 98 zero shed-rate values;
- keep `bet.2026.low.recaps.removed.tag` unchanged.

After this repair, `mfclo64 bet.frq bet.ini 00.par -makepar` exits 0 and creates
`00.par` for both 06-Full2024 and 07-CAAL2026 in `tuna-flow:v1.10`.

### 08 to 12: same 98-release family audited before rerun

Steps 08-12 use the same full-2024 98-release `.frq` and `.tag` family, so they
were checked after the 06/07 failure even though the mix-period ini is a
different source file.

The mix-period ini already carries release-group-specific tag controls. The
generated `doitall.sh` therefore removes the inherited `-9999 1 2` override so
MFCL reads the ini release-specific mixing-period flags. Any zero mixing-period
values in the source ini are raised to 1 because the current MFCL reader
disallows 0. That is an ini-control normalization, not a tag-data deletion.

Local `-makepar` smoke tests now pass for all downstream steps:

- 08-MixPeriod02
- 09-SizeBasedSel
- 10-OPR
- 11-EffortCreep
- 12-DataWeight40

## John and Nick Email/PPT Suggestions Applied

John Hampton's June 2026 input checks are applied in the generator:

- generated `.frq` files must include fishery-region locations for every
  fishery, including index fisheries;
- MFCL 1007 `.ini` files carry explicit tag flags immediately after
  `# number of age classes`;
- OPR step 10 applies the BIGEYE AIC rank-1 OPR setting from John Hampton's BET OPR screening,
  `69-01-50-50`, transferring the 4R screening result to the 5-region path.

Nick Davies's MFCL-version note is also applied:

- `age_flags(128)` is kept at 100 so the latest MFCL interprets the initial
  equilibrium natural-mortality multiplier as 1.0;
- regional-scaling controls use `bet.reg_scaling` with `parest_flags(77)=50`
  and the active period 53-72 window for the 292-period full-2024 runs.

## Warnings Left Intact

The remaining tag recapture timing or fishery-realization warnings are not
suppressed by deleting data. They remain documented as upstream tag-prep review
items. This keeps the generated model inputs traceable to the prepared input
repos while making only the minimum structural changes needed for MFCL to read
the files correctly.

## Verification Before Rerun

Before submitting the clean Kflow group, the generated steps were checked with:

```bash
mfclo64 bet.frq bet.ini 00.par -makepar
```

The smoke test exited 0 and created `00.par` for 06-Full2024 through
12-DataWeight40 in `ghcr.io/pacificcommunity/tuna-flow:v1.10`.

Clean Kflow rerun submitted:

- flow group: `bet-2026-doitall-20260626-053013`
- stepwise jobs: `431` through `442`
- results job: `443`, waiting for all 12 stepwise jobs
- results job has the report trigger for `ofp-sam-bet-2026-report`
