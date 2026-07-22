# S004-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RR8-10

Public BET 2026 DM sensitivity derived from Kflow Job 12299 and source model
`S015-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX10-REGW1` at commit `84afb5a52536b1043c47a66dc65c0c4f054ee44e`.

- Source-job status: completed
- Regional scaling: REGW1
- Reporting-rate prior: manual RR8/10
- LF likelihood: Dirichlet-multinomial without random effects
- DM grouping: G8PSSET
- Nmax: 25

The source FRQ already contains effort creep; effort creep is not reapplied.
All source inputs and controls are retained except DM fish flag 68, parest
flag 342, and the F25/F26 selectivity sensitivity documented below. The root README documents the G8 mapping and Nmax15 rationale.

## F25-F26 selectivity sensitivity

This branch pairs this model with parent Kflow Job 12299 from
the parent selectivity sensitivity. F25 (PS.ASSOC.WEST.3) and F26
(PS.ASSOC.EAST.4) use separate selectivity groups 25 and 26, respectively. Both use independent seven-node cubic-spline
selectivities and retain fish flags 16 = 2, 3 = 25, 26 = 2, 57 = 3, and 75 = 0.
Subsequent selectivity groups are renumbered contiguously; other fishery
selectivity controls are unchanged. See
[notes/f25-f26-selectivity.md](../../notes/f25-f26-selectivity.md).

## Common CPUE sigma

For the matched eight-model comparison, R1-R5 use common fish flag 92 values
36, 25, 21, 24, and 22. These are the rounded index-wise medians across the
eight parent settings. S001-S004 provide MFCL-equivalent MLE estimates and
S005-S008 provide inherited fixed sigma inputs. Any earlier model-specific
sigma table above documents the parent calculation; this median vector is the
final setting applied by this branch. The shared calculation is in
[notes/common-cpue-sigma.md](../../notes/common-cpue-sigma.md).

## Regional-scaling sensitivity

This sensitivity sets MFCL parest flag 77 to 25. This is a precision
multiplier on the external regional-scaling covariance and is equivalent to a
standardized SD multiplier of 1/sqrt(25) = 0.2000. The regional target
and covariance inputs are unchanged.
