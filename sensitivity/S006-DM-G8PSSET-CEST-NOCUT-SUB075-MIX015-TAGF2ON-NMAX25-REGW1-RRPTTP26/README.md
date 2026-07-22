# S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW1-RRPTTP26

Public BET 2026 DM sensitivity derived from Kflow Job 12313 and source model
`S031-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX10-REGW1-RRPTTP26` at commit `84afb5a52536b1043c47a66dc65c0c4f054ee44e`.

- Source-job status: completed
- Regional scaling: REGW1
- Reporting-rate prior: PTTP26
- LF likelihood: Dirichlet-multinomial without random effects
- DM grouping: G8PSSET
- Nmax: 25

The source FRQ already contains effort creep; effort creep is not reapplied.
All source inputs and controls are retained except DM fish flag 68, parest
flag 342, and the F25/F26 selectivity sensitivity documented below. The root README documents the G8 mapping and Nmax25 rationale.

## F25-F26 selectivity sensitivity

This branch pairs this model with parent Kflow Job ${parent_jobs[S006]} from
BET 2026 Francis + CPUE MLE. F25 (PS.ASSOC.WEST.3) and F26
(PS.ASSOC.EAST.4) now share selectivity group 25 and use seven cubic-spline
nodes. Both retain fish flags 16 = 2, 3 = 25, 26 = 2, 57 = 3, and 75 = 0.
Subsequent selectivity groups are renumbered contiguously; other fishery
selectivity controls are unchanged. See
[notes/f25-f26-selectivity.md](../../notes/f25-f26-selectivity.md).
