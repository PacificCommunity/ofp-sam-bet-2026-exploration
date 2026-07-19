# Size-composition weighting before Francis reweighting

## Decision

Use the processed 2026 size-composition input without a second model-stage 50%
duplicate-use reduction. Retain global robust-normal divisor 20 as the common
initial fit, then estimate fishery-specific Francis weights from that fit.

## Evidence

Section 2.7 of WCPFC-SC22-2026/SA-IP06 states that input sample sizes were
further reduced by 50% for longline fisheries where samples were used in both
extraction and index fisheries. The retained `bet.frq` is the processed 2026
assessment input. Applying fishery-specific divisor 40 after that processing
would halve those effective sample sizes a second time.

Reference: WCPFC-SC22-2026/SA-IP06, *Analysis of size frequency data for the
2026 yellowfin and bigeye assessments*, Section 2.7:
https://meetings.wcpfc.int/node/32346

## MFCL implementation

- Retain `-999 49 20` for LF and `-999 50 20` for WF.
- Remove inherited divisor-40 overrides for F1, F2, F4, F6, F7, F8, F10, and
  F29-F33.
- Retain F21/F22/F23 flag-49 divisor 20 in every initial model.
- Do not export DM, DW10, or OPR models.
- Do not modify the archived Job 5319 reference bundle; remove the inherited
  block only when generating each sensitivity `doitall.sh`.
- Retain the original Job 5319 CPUE observations and sigma values; HAC4 is not
  applied.

This separates the source-level correction for duplicated sampling information
from the common model-level starting weight used before Francis reweighting.
