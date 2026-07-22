# BET 2026 independent F25-F26 selectivity sensitivity

## Scope and provenance

This public sensitivity is derived from
`experiment/s001-s012-regw-grid-initlf-20260722` at commit
`2817578b88a5f3248750b595dca41a7890b4e644`. It retains the twelve matched
initial-LF/DM, REGW11/25/100, and reporting-rate combinations from that branch.

| Model | Parent Kflow Job |
| --- | ---: |
| S001 | 13201 |
| S002 | 13199 |
| S003 | 13200 |
| S004 | 13198 |
| S005 | 13202 |
| S006 | 13203 |
| S007 | 13204 |
| S008 | 13205 |
| S009 | 13206 |
| S010 | 13207 |
| S011 | 13208 |
| S012 | 13209 |

The parent S011 Hessian attached by Job 13312 contained one negative eigenvalue
(-9.96497e-4). Its eigenvector was 99.9888% concentrated on
`region_rec_diffs(4,244)`. The parameter was not at a bound and its gradient was
small. Because F26 represents the eastern associated-set fishery in region 4,
this branch tests whether sharing the F25/F26 selectivity indirectly induced
that recruitment direction. This is a controlled diagnostic sensitivity, not a
claim of causation before fitting.

## Implemented change

F25 (PS.ASSOC.WEST.3) and F26 (PS.ASSOC.EAST.4) retain the same cubic-spline
basis, seven nodes, and dome-tail regularisation, but their coefficients are now
estimated independently.

| Control | F25 | F26 | Interpretation |
| --- | ---: | ---: | --- |
| Fish flag 24 | 25 | 26 | Independent selectivity groups |
| Fish flag 57 | 3 | 3 | Cubic-spline selectivity |
| Fish flag 61 | 7 | 7 | Seven spline nodes |
| Fish flag 16 | 2 | 2 | Old-age dome-tail penalty |
| Fish flag 3 | 25 | 25 | Upper-age boundary used by the tail treatment |
| Fish flag 26 | 2 | 2 | Selectivity-at-age evaluated with length-at-age overlap |
| Fish flag 75 | 0 | 0 | No youngest age forced to numerical zero |

F27 and F28 use groups 27 and 28. Regional indices share initialization group
29 through Phase 4 and use independent final groups 29-33 from Phase 5. These
renumberings keep MFCL group labels contiguous and do not change their
selectivity structures.

The parent shared configuration estimated seven coefficients jointly for
F25/F26. This branch estimates fourteen coefficients, adding seven parameters.
All likelihood, DM, CPUE, tag, regional-scaling, effort-creep, age-length, and
reporting-rate settings are unchanged.

## Evaluation

The change should be judged using convergence, Hessian behavior, the loading of
`region_rec_diffs(4,244)`, time-resolved F25/F26 residuals, aggregate length
fits, and changes in management quantities. Recovery of a positive-definite
Hessian would support selectivity-recruitment confounding in the shared model;
persistence of the same mode would indicate that another structural or
numerical source should be investigated.
