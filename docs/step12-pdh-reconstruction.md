# Renumbered downstream lineage without OPR or length-based selectivity

This experimental branch tests whether the final assessment changes remain
useful when both the original OPR Step 12 and length-based-selectivity Step 13
are omitted. It preserves the completed lineage through
`11-TimeVaryingCV`, then renumbers the two remaining changes.

| New step | Direct baseline | Added change |
| --- | --- | --- |
| `12-EffortCreep` | `11-TimeVaryingCV` | Effort creep for index fisheries 29-33. |
| `13-DataWeighting` | `12-EffortCreep` | Global LF/WF divisor changes from 20 to 40. |

The new Step 12 and 13 retain the reviewed fishery-level controls introduced at
`04a-SelectivityReview` and the time-varying index-CV controls from Step 11.
They deliberately keep standard age-based selectivity (`-999 26 2`) and leave
OPR flags `155`, `202`, `216`, `217`, `218`, `221`, and `397` inactive.

Each folder remains a complete standalone MFCL case and reruns its own
`doitall.sh`; it does not depend on a fitted PAR from an earlier Kflow job.
Kflow selects only the new Step 12 and 13 by default, so the already completed
Steps 01-11 are not duplicated. A five-part Hessian chain is attached to each
new fitted model after it completes.
