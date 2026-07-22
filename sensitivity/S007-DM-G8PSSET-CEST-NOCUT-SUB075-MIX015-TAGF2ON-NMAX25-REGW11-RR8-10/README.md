# S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10

Public BET 2026 DM sensitivity derived from Kflow Job 12751 and source model
`S014-DM-G7OSHL-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX10-REGW11` at commit `8df6a0e4b9856c5cd1e06ab7010c6e71c773f428`.

- Source-job status: fit completed; payload build failed
- Regional scaling: REGW11
- Reporting-rate prior: manual RR8/10
- LF likelihood: Dirichlet-multinomial without random effects
- DM grouping: G8PSSET
- Nmax: 25

The source FRQ already contains effort creep; effort creep is not reapplied.
All source inputs and controls are retained except DM fish flag 68, parest
flag 342, and the F25/F26 selectivity sensitivity documented below. The root README documents the G8 mapping and Nmax25 rationale.

## F25-F26 selectivity sensitivity

This branch pairs this model with parent Kflow Job ${parent_jobs[S007]} from
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
