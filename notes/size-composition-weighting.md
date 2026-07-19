# Size-composition weighting before Francis reweighting

## Decision

Use the processed 2026 size-composition input with global robust-normal divisor
20 and retain divisor-40 overrides for the extraction and index fisheries that
reuse the same longline sampling information. Estimate fishery-specific
Francis weights from this initial fit.

## Evidence

Section 2.7 of WCPFC-SC22-2026/SA-IP06 states that input sample sizes were
further reduced by 50% for longline fisheries where samples were used in both
extraction and index fisheries. The retained `bet.frq` is the processed 2026
assessment input. For option-3 robust normal, MFCL uses

```text
N_eff = min(N_input, 1000) / divisor
```

The divisor is applied after the raw-sample-size cap. A source-level reduction
from `N` to `N / 2` therefore has no model-stage effect when `N / 2` remains at
or above 1000. Divisor 40 replaces the common divisor 20 in duplicated
fisheries, so each extraction/index representation receives half the
model-stage weight and their combined capped contribution matches one ordinary
divisor-20 representation.

An audit of the retained FRQ used the raw composition records, excluded records
below the fitted flag-312 threshold of 50, and retained 1,490 records from F1,
F2, F4, F6, F7, F8, F10, and F29-F33. Of those records, 794 (53.3%) remained at
or above 1000 after source processing. They accounted for 74.1% of effective N
under divisor 20. Using an equal duplicate split after the cap as the reference,
the aggregate effective-N totals were 53,605 for divisor 20, 31,042 for the
reference split, and 26,803 for divisor 40. Thus divisor 40 is conservative for
small records but substantially closer overall than divisor 20.

Reference: WCPFC-SC22-2026/SA-IP06, *Analysis of size frequency data for the
2026 yellowfin and bigeye assessments*, Section 2.7:
https://meetings.wcpfc.int/node/32346

## MFCL implementation

- Retain `-999 49 20` for LF and `-999 50 20` for WF as global defaults.
- Retain divisor-40 overrides for F1, F2, F4, F6, F7, F8, F10, and F29-F33.
- Retain F21/F22/F23 flag-49 divisor 20 in every initial model.
- Do not export DM, DW10, or OPR models.
- Do not modify the archived Job 5319 reference bundle; remove the inherited
  block only when generating each sensitivity `doitall.sh`.
- Retain the original Job 5319 CPUE observations and sigma values; HAC4 is not
  applied.
- Include both tag flag 2 settings for every model structure so the tag-control
  choice is evaluated without changing any other model input.
- Include BASE100 from the official age-length build. It changes only the 181
  effective-sample-size multipliers from 0.75 to 1 relative to BASE075.

This preserves a common divisor-20 starting weight while compensating for the
MFCL cap that can mask the source-level duplicate-use reduction. Divisor 40 is
an explicit initial-fit control; subsequent Francis reweighting remains a
separate residual-based procedure.
