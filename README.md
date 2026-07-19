# BET 2026 initial robust-normal LF sensitivities

This branch contains 26 MFCL sensitivity models derived from
`experiment/dm-nmax20-20260719`. DM, fixed-DW, OPR, and HAC4 variants are
excluded. Thirteen model structures are each paired with tag flag 2 off and
on. These are initial robust-normal fits from which Francis fishery-specific
reweighting can subsequently be estimated.

## Duplicate-use correction

WCPFC-SC22-2026/SA-IP06 Section 2.7 states that input sample sizes were reduced
by 50% for longline samples represented in both extraction and index
fisheries. The retained processed 2026 `bet.frq` therefore already contains
that source-level correction. The inherited model-stage divisor-40 overrides
for F1, F2, F4, F6, F7, F8, F10, and F29-F33 are removed to avoid applying the
same reduction twice.

The common initial controls are:

- MFCL option-3 robust-normal LF likelihood.
- Global LF and WF divisors `-999 49 20` and `-999 50 20`.
- F21/F22/F23 flag-49 divisor 20 in every model.
- No fixed DW sensitivity axis; Francis reweighting follows the initial fit.
- CUT90 changes only observed LF bins above 90 cm for F21/F22/F23.
- Original Job 5319 CPUE observations and sigma values; no HAC4 adjustment.
- Regional-scaling weight 50 and the reviewed phase sequence.

Reference: [WCPFC-SC22-2026/SA-IP06](https://meetings.wcpfc.int/node/32346).

## CPUE sigma retained from Job 5319

| Index fishery | Sigma | Initial fish flag 92 | Temporal precision |
| --- | ---: | ---: | --- |
| F29, Index R1 | 0.354 | 35 | fish flag 66 = 1 |
| F30, Index R2 | 0.237 | 24 | fish flag 66 = 1 |
| F31, Index R3 | 0.212 | 21 | fish flag 66 = 1 |
| F32, Index R4 | 0.239 | 24 | fish flag 66 = 1 |
| F33, Index R5 | 0.225 | 23 | fish flag 66 = 1 |

Fish flag 92 stores the rounded value of `100 * sigma`. In phases 1-4, fish
flag 94 is 1 and the frequency file supplies the time-varying precision
pattern. In phase 5 the regional-scaling setup sets flag 94 to 0 and separates
the five index likelihood groups; the listed sigma controls themselves are
not replaced by HAC values.

## Design

| IDs | Models |
| --- | --- |
| S001-S004 | BASE075: NOCUT and CUT90, each TAGF2OFF/ON |
| S005-S008 | BASE100: NOCUT and CUT90, each TAGF2OFF/ON |
| S009-S012 | REG075: NOCUT and CUT90, each TAGF2OFF/ON |
| S013-S016 | REG100: NOCUT and CUT90, each TAGF2OFF/ON |
| S017-S020 | SUB075: NOCUT and CUT90, each TAGF2OFF/ON |
| S021-S024 | SUB100: NOCUT and CUT90, each TAGF2OFF/ON |
| S025-S026 | BASE075 CUT90 with F12/F13 N8 selectivity, TAGF2OFF/ON |

BASE100 is the official `BET/bet.2026.age_length` at source commit
`96a06d21ef3c666f39ce456d3a6818b6c17324c4`. It differs from BASE075 only on
line 4: all 181 effective-sample-size multipliers are 1 instead of 0.75. The
remaining 17,560 lines are identical. All models use the corrected SA28-N5
selectivity baseline except S025-S026, which change only F12 and F13 from five
to eight nodes.

TAGF2OFF sets all 98 `tag_flags(:,2)` values to 0. TAGF2ON sets the same values
to 1. Every structural comparison therefore has an explicit tag-off/tag-on
pair.

## Rebuild

```sh
Rscript R/prepare_bet_2026_step_inputs.R
```

Generated models are under `sensitivity/`. The Job 5319 reference bundle
remains byte-preserved for provenance; the duplicate-use divisor block is
removed only while generating each model `doitall.sh`.
