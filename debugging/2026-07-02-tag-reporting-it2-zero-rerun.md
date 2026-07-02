# Tag Reporting `it2=0` Rerun

## Question

Steps 07-09 failed when `tag_flags(it,2)=0`, while step 10 could run. This
note records the rerun setup used to test whether the failure was caused by
stale zero reporting-rate cells rather than by `it2=0` alone.

## What `it2` Controls

`tag_flags(it,2)=0` keeps tag reporting rates active during the tag mixing
period. MFCL therefore adjusts predicted tag recaptures by the reporting-rate
matrix during mixing.

`tag_flags(it,2)=1` excludes reporting rates during the mixing period. This
avoids inflated adjusted recaptures when early recaptures are high and the
reporting rate is low or zero.

## Why 07-09 Failed Before

The 2026 data steps used the 2026 tag file with the base `bet.2026.ini`
reporting-rate matrix. Several recaptures were inside the mixing period while
their reporting-rate cells were `RR=0` and inactive. With `it2=0`, MFCL applies
the reporting-rate correction in that period, so those recaptures are divided
by an effectively zero reporting rate.

The largest problematic cell was release group 60, fishery 26, with 264
recaptures in the mixing period.

## Why Step 10 Was Different

Step 10 did not merely change `it2`. It used `bet.2026.mix-0.2.ini`, which has
the updated 2026 reporting-rate matrix. In that source, the problematic cells
are active and have non-zero initial reporting rates.

Examples:

| Release group | Fishery | Base 2026 ini | Step 10 source ini |
| --- | --- | --- | --- |
| 60 | 26 | `RR=0`, inactive | `RR=0.5282`, active |
| 20 | 21 | `RR=0`, inactive | `RR=0.5000`, active |
| 21 | 21 | `RR=0`, inactive | `RR=0.5000`, active |

The `0.5282` value is from the 2026 reporting-rate build, not from stepwise
code. It corresponds to the PTTP pooled PS.EAST.3 reporting-rate group.

## Rerun Setup

For this rerun, steps 07-09 keep the same model structure and two-quarter tag
mixing periods, but copy these reporting-rate blocks from
`bet.2026.mix-0.2.ini` before setting tag flags:

- `# tag fish rep`
- `# tag fish rep group flags`
- `# tag_fish_rep active flags`
- `# tag_fish_rep target`
- `# tag_fish_rep penalty`

Then `tag_flags(it,2)=0` is set for all release groups in 07-09.

## Expected Check

After copying the updated matrix, the remaining `RR=0` recaptures inside mixing
are small:

| Step | `RR=0` mixing rows | Recaptures |
| --- | ---: | ---: |
| 07-DataTo2024 | 8 | 8 |
| 08-RegionalCPUE | 8 | 8 |
| 09-NewOtoliths | 8 | 8 |

If these Kflow jobs still fail, inspect those remaining eight one-recapture
cells before deciding whether `it2=1` is scientifically required for 07-09.

## Kflow Rerun

Pending submission after regenerating the step folders.
