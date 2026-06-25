# 2026-06-22 Initial Run Failures

Most early failures were not because Kflow itself was broken. The MFCL input
files were present, but several files did not describe the same model structure.

## Symptom

- Kflow started normally, including the `mfclshiny` runtime update.
- MFCL then failed or became unstable because `.frq`, `.ini`, `.tag`, and
  `doitall.sh` did not always agree.
- The clearest fatal error was in 04/05:
  `tag release group 18` hit the terminal model period.

## Fix Map

| Problem | Fix | Simple example |
| --- | --- | --- |
| `.frq` said 33 fisheries, but fishery-region line had only 28 entries | Added index fishery regions | Region line now ends with `1 2 3 4 5` for fisheries 29-33 |
| 1007 `.ini` files had no `# tag flags` block | Inserted explicit tag flag rows for 03-07 | One `# tag flags` row per tag release group |
| Mix-period `.ini` files had zero mixing periods | Changed zero mixing periods to 1 for 08-12 | First value in affected rows: `0 -> 1` |
| Some old `.frq` records had `-1` plus leftover LF bins | Normalized 84 absent-LF records | After `-1`, MFCL no longer reads stray LF bins as data |
| 04/05 used 2021-chopped `.frq` with the full 2026 `.ini/.tag` family | Re-paired 04/05 to the 03-RegFish 96-release `.ini/.tag` family and reset the chopped `.frq` tag count | 04/05 tag groups now match 03-RegFish: `96` |

## Core Rule

MFCL needs `.frq`, `.ini`, `.tag`, `.age_length`, and `doitall.sh` to agree on
the same structure: fishery count, tag group count, terminal year, and tag
mixing setup.

The fixes were mostly contract alignment across those files.

## Remaining Noise

- `caught before it was released` tag warnings still appear in local `-makepar`
  smoke checks. These are known upstream tag-prep warnings and are also noted
  in model READMEs.
- Submit results/report only after the active 12 input jobs finish
  successfully.
