# BET 2026 F25-F26 associated-purse-seine selectivity sensitivity

## Scope and provenance

This public sensitivity is based on all eight model fits in Kflow task
BET 2026 Francis + CPUE MLE.

| Model | Parent Kflow Job |
| --- | ---: |
| S001 | 12774 |
| S002 | 12793 |
| S003 | 12794 |
| S004 | 12795 |
| S005 | 12835 |
| S006 | 12833 |
| S007 | 12832 |
| S008 | 12834 |

S001-S004 restore the initial robust-normal LF divisors; S005-S008 retain\ntheir DM likelihood settings. All models preserve their regional-scaling weight, reporting-rate controls, tag inputs,
age-length inputs, and all non-selectivity settings.

## Common CPUE sigma\n\nAll eight models use fish flag 92 values 38, 25, 20, 23, and 21 for R1-R5.\nThe continuous reference is the arithmetic mean of the four S001-S004\nMFCL-equivalent MLE sigma estimates. See common-cpue-sigma.csv in this directory.\n\n## Implemented change

F25 (PS.ASSOC.WEST.3) and F26 (PS.ASSOC.EAST.4) now share selectivity
group 25. Their common cubic spline uses seven nodes rather than the global
five-node default.

| Control | F25 | F26 | Interpretation |
| --- | ---: | ---: | --- |
| Fish flag 24 | 25 | 25 | Common selectivity group |
| Fish flag 57 | 3 | 3 | Cubic-spline selectivity |
| Fish flag 61 | 7 | 7 | Seven spline nodes |
| Fish flag 16 | 2 | 2 | Old-age dome-tail penalty |
| Fish flag 3 | 25 | 25 | Upper-age boundary used by the tail treatment |
| Fish flag 26 | 2 | 2 | Age selectivity evaluated with length-at-age overlap |
| Fish flag 75 | 0 | 0 | No youngest age forced to numerical zero |

Merging two five-node groups would otherwise leave a gap in MFCL's group
labels. F27 and F28 are therefore relabelled 26 and 27. The shared index group
is relabelled 28 through Phase 4, and the five final index groups are relabelled
28-32 from Phase 5. These are label-only changes outside F25/F26.

The original two independent five-node splines contained ten selectivity
coefficients. The shared seven-node spline contains seven, adding local shape
resolution while reducing the combined parameter dimension by three.

## Empirical rationale

The source-model length fits showed the same persistent broad-tail mismatch in
both associated-purse-seine fisheries. In the Job 12292 audit:

| Diagnostic | F25 | F26 |
| --- | ---: | ---: |
| Fitted compositions | 48 | 27 |
| Observed mean length (cm) | 53.7 | 53.9 |
| Predicted mean length (cm) | 56.9 | 57.8 |
| Predicted minus observed mean (cm) | 3.2 | 3.9 |
| Observed SD (cm) | 14.5 | 13.5 |
| Predicted SD (cm) | 17.5 | 19.3 |
| Predicted/observed width | 1.29 | 1.52 |
| Excess predicted probability at >=80 cm | 4.4 percentage points | 9.0 percentage points |

The similarity of observed distributions supports pooling the two recent
associated-set fisheries. Seven nodes allow the common curve to represent the
narrow mode and upper tail more flexibly without adding net parameters.

## Dome-selectivity audit

MFCL fish flag 57 = 2 is the explicit double-normal form. It is not used in
these eight models. The models use cubic splines (flag 57 = 3).

MFCL labels fish flag 16 = 2 as dome-shaped selectivity, but the implementation
is a penalty on old-age selectivity from the flag-3 boundary onward. It
encourages a declining old-age tail; it is not a hard mathematical constraint
to a single peak. F25 and F26 already used this treatment, and it is retained.

The explicit dome-tail treatment is also retained for F12, F13, F15-F19,
F21-F27 where configured. Longline, sparse, unassociated-set, and regional-index
selectivities retain their existing controls. Aggregate fits for most of those
fisheries do not show the persistent paired broad-tail pattern seen in F25/F26,
so no broader selectivity change is made in this targeted sensitivity.

## Interpretation

This is a structural sensitivity, not a claim that the shared seven-node curve
is preferred before fitting. It should be judged against the parent models
using convergence, Hessian behavior, time-resolved F25/F26 residuals, aggregate
length fits, CPUE fit, and changes in management quantities. The same change is
applied to all eight models so its effect can be separated from LF likelihood,
regional scaling, and reporting-rate assumptions.
