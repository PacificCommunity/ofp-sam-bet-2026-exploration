# BET length-composition Dirichlet-multinomial grouping rationale

**Status:** Pre-fit design note for sensitivity analysis  
**Scope:** WCPO bigeye tuna (BET) only  
**Branch:** `experiment/dm-observation-groups-20260718`  
**Date:** 18 July 2026

## Purpose

This note documents the scientific rationale for the additional
Dirichlet-multinomial (DM) length-composition sensitivities `S086` to `S091`.
It is written before examining their assessment results so that the grouping
choices remain hypotheses about observation processes rather than
post-hoc choices based on model fit.

The central principle is that an MFCL DM group should contain fisheries whose
length compositions are expected to have a broadly similar relationship
between nominal and effective sample size. Fisheries are therefore grouped
primarily by sampling and reweighting process, not simply by similar fitted
length distributions or by whether an aggregate fit looks good.

This follows the general advice that composition weighting should accommodate
correlation and should not prevent an adequate fit to abundance information
(Francis 2011). It also follows the motivation of Thorson et al. (2017), who
used the DM distribution to estimate the relationship between input and
effective sample sizes within an assessment model.

## Evidence used

The design is based on two BET-specific sources.

1. Day et al. (2023) describe the WCPO BET assessment data, weighting choices,
   aggregate composition fits, and an exploratory DM analysis. The assessment
   retained a common size-composition divisor of 20. Its DM trial increased the
   effective influence of composition data but degraded some CPUE fits, so DM
   was not adopted in the 2023 diagnostic model.
2. Peatman et al. (2026) document the preparation of the 2026 BET and YFT size
   inputs. The BET results show materially different sampling, filtering,
   reweighting, and temporal coverage among longline extraction, longline
   index, large-scale purse-seine, domestic purse-seine, and other extraction
   data streams.

The relevant BET evidence from Peatman et al. (2026) includes the following.

| Data stream | Observation-process evidence | Grouping consequence |
|---|---|---|
| Longline extraction | Length records are catch-weighted within spatial, temporal, fleet, and fishery strata. Coverage is generally richer than the smaller surface-fishery data streams but varies by fishery and period. | Keep together as a dedicated extraction group. |
| Longline index | The index compositions are abundance/CPUE-weighted rather than catch-weighted. Some records originate from the same underlying longline samples used for extraction compositions. | Keep separate from longline extraction even when the raw samples overlap. |
| Duplicate longline use | Where the same longline observations contribute to extraction and index compositions, the conventional input treatment reduces their nominal contribution to avoid counting the same observations twice. | Do not interpret an index group as independent raw sampling merely because it has a separate MFCL fishery number. |
| Large-scale purse seine | Compositions are catch-weighted and set-type-specific, with filtering and minimum-sample rules distinct from the longline procedures. BET coverage is much stronger for some associated-set fisheries than for several unassociated-set fisheries. | Separate purse seine from longline; treat associated/unassociated subdivision as exploratory. |
| Philippine domestic purse seine | A particularly stringent sampled-catch criterion is used, both contributing fleets are required, and quarter 3 is excluded in the documented preparation. | A separate domestic group is scientifically plausible. |
| Indonesian domestic purse seine | Spatial information and retained coverage are limited, and the data cannot be treated as having the same complete reweighting procedure as the major purse-seine streams. | Avoid assigning it an independently estimated DM parameter unless the data support that parameter. |
| Other extraction fisheries | Several pole-and-line, handline, and small or domestic extraction streams are not reweighted in the same manner as the major longline or purse-seine streams. | Pool as a lower-dimensional residual extraction group. |
| Regional index fisheries | Regions 1 to 3 have the most useful histories. Regions 4 and 5 are considerably sparser or more historical. | Retain one index group initially; splitting sparse regional indices would add weakly identified DM parameters. |

The figures underlying these judgements are the BET purse-seine, longline
extraction, and index summaries in Peatman et al. (2026). In particular, they
show continuous recent observations for some associated purse-seine streams,
intermittent or absent retained BET compositions for several unassociated
streams, and substantially different coverage among the regional indices.

## Benchmark grouping already in the sensitivity set

The existing `G4` DM sensitivities provide the benchmark:

| G4 group | MFCL fisheries | Interpretation |
|---|---|---|
| 1 | F1-F11 | Longline extraction |
| 2 | F12, F17-F20, F25-F28 | Purse seine |
| 3 | F13-F16, F21-F24 | Other extraction |
| 4 | F29-F33 | Longline index |

This grouping is parsimonious and broadly gear-based. Its main limitation is
that it pools large-scale and domestic purse-seine streams despite their
different preparation and coverage.

## Primary new grouping: G5PROC

`G5PROC` is the preferred new scientific sensitivity because it adds only one
group relative to `G4` and targets a documented observation-process contrast.

| G5PROC group | MFCL fisheries | Interpretation and rationale |
|---|---|---|
| 1 | F1-F11 | Catch-weighted longline extraction compositions |
| 2 | F12, F19-F20, F25-F28 | Large-scale purse-seine compositions, including the associated and unassociated set-type streams |
| 3 | F17-F18 | Domestic Indonesian and Philippine purse-seine compositions |
| 4 | F13-F16, F21-F24 | Other extraction compositions |
| 5 | F29-F33 | Abundance/CPUE-weighted longline index compositions |

Pooling F17 and F18 is a deliberate compromise. Their preparation is not
identical, but estimating separate group parameters would leave the sparse
Indonesian series with little information. `G5PROC` asks the more defensible
first-order question: is the domestic purse-seine observation process
sufficiently different from the large-scale purse-seine process to warrant a
different DM relationship?

## Secondary stress test: G7QUAL

`G7QUAL` is a deliberately more flexible diagnostic, not the preferred base
grouping.

| G7QUAL group | MFCL fisheries | Interpretation and rationale |
|---|---|---|
| 1 | F1-F11 | Longline extraction |
| 2 | F19, F25-F26 | Associated-set purse seine |
| 3 | F20, F27-F28 | Unassociated-set purse seine |
| 4 | F17-F18 | Domestic purse seine |
| 5 | F12-F13 | Japanese purse-seine and pole-and-line streams, isolated because of their distinctive and sometimes multimodal aggregate compositions |
| 6 | F14-F16, F21-F24 | Other extraction |
| 7 | F29-F33 | Longline index |

The name `QUAL` is shorthand for a sampling-coverage stress test; it is not a
formal ranking of data quality. This grouping tests whether a small number of
distinctive or poorly covered streams disproportionately determine a broader
gear-level DM parameter.

The associated/unassociated split is scientifically interpretable because set
type affects both the sampled fish-size distribution and the sampling frame.
For BET, however, several unassociated streams are sparse or absent after
filtering. Group 3 can therefore be weakly identified. Similarly, the Japanese
PS/PL group is a pragmatic diagnostic isolation rather than a claim that the
two fisheries share an identical observation process. These limitations are
why `G7QUAL` must not be selected solely because it produces a lower objective
function value.

## Factorial structure

The new models use the `BASE075` age-length input and preserve all other
assessment settings. Each grouping is crossed with the established length-tail
treatments:

| Models | DM grouping | Tail treatment |
|---|---|---|
| S086, S089 | G5PROC, G7QUAL | No upper-length cutoff |
| S087, S090 | G5PROC, G7QUAL | Established-fishery cutoff above 70 cm |
| S088, S091 | G5PROC, G7QUAL | Established-fishery cutoff above 90 cm |

The three cutoff levels are not additional estimates of the DM grouping
effect. They are crossed with each grouping so that sensitivity to the
observation-process grouping can be distinguished from sensitivity to unusual
upper-tail observations in the established fisheries.

Objective values must not be compared directly between `NOCUT`, `CUT70`, and
`CUT90`, because those models use different observations. Grouping comparisons
should first be made within the same cutoff treatment.

## Important weighting caveat

The DM sensitivities are alternative observation-likelihood models, not exact
reproductions of the fixed multinomial weighting used in the diagnostic model.
In particular, model-estimated DM scaling is not algebraically equivalent to
the conventional fixed 50% correction applied when longline samples contribute
to both extraction and index compositions. Results should therefore be
described as sensitivity to DM self-weighting and grouping, not as the same
duplicate-use correction expressed through another parameterization.

## Evaluation criteria

The models should be evaluated in the following order.

1. Confirm normal completion, a sufficiently small maximum gradient, and a
   positive-definite Hessian.
2. Check that group-level DM parameters are estimable and are not effectively
   at a bound.
3. Compare `G4` and `G5PROC` within each common cutoff treatment.
4. Examine composition residuals and implied effective sample sizes by group,
   fishery, and time rather than relying on aggregate LF likelihood alone.
5. Confirm that improved composition fits do not materially degrade CPUE fits.
6. Compare recruitment, depletion, fishing mortality, and the key management
   quantities with the corresponding non-DM and `G4` runs.
7. Use `G7QUAL` only to diagnose heterogeneity. Retain it for inference only if
   its additional group parameters are identifiable and its effects are
   coherent across diagnostics.

A lower composition likelihood alone is not sufficient evidence for choosing
a grouping. The 2023 BET DM trial is a direct warning: increasing the influence
of size compositions can worsen the fit to abundance information. This is
also consistent with Francis (2011), who emphasizes preserving an adequate fit
to abundance data when weighting composition observations.

## Recommended reporting language

> Alternative Dirichlet-multinomial length-composition likelihoods were
> evaluated using groups defined a priori from the sampling and reweighting
> procedures documented for the 2026 assessment inputs. The primary grouping
> separated catch-weighted longline extraction, large-scale purse-seine,
> domestic purse-seine, other extraction, and abundance-weighted longline
> index compositions. A more highly resolved grouping that separated
> associated and unassociated purse-seine streams was treated as an
> identifiability stress test because several BET series were sparse after
> filtering. Grouping alternatives were compared within common tail-cutoff
> treatments, and were assessed using convergence, Hessian, composition and
> CPUE diagnostics, and key stock-status quantities rather than composition
> likelihood alone.

This paragraph should be revised after the fits are available so that it
reports which candidate group parameters were identifiable and whether any
grouping materially affected CPUE fit or management quantities.

## References

Day, J., Magnusson, A., Teears, T., Hampton, J., Davies, N., Castillo Jordan,
C., Peatman, T., Scott, R., Scutt Phillips, J., McKechnie, S., Scott, F., Yao,
N., Natadra, R., Pilling, G., Williams, P., and Hamer, P. (2023). *Stock
assessment of bigeye tuna in the western and central Pacific Ocean: 2023*.
WCPFC-SC19-2023/SA-WP-05 (Rev. 2). [WCPFC document page](https://meetings.wcpfc.int/node/19353).

Francis, R. I. C. C. (2011). Data weighting in statistical fisheries stock
assessment models. *Canadian Journal of Fisheries and Aquatic Sciences*, 68,
1124-1138. [https://doi.org/10.1139/F2011-025](https://doi.org/10.1139/F2011-025).

Peatman, T., Castillo-Jordan, C., Teears, T., Magnusson, A., Kim, K., Hampton,
J., and Hamer, P. (2026). *Analysis of size frequency data for the 2026 bigeye
and yellowfin assessments*. WCPFC-SC22-2026-SA-IP06. [WCPFC document page](https://meetings.wcpfc.int/node/32346).

Thorson, J. T., Johnson, K. F., Methot, R. D., and Taylor, I. G. (2017).
Model-based estimates of effective sample size in stock assessment models using
the Dirichlet-multinomial distribution. *Fisheries Research*, 192, 84-93.
[https://doi.org/10.1016/j.fishres.2016.06.005](https://doi.org/10.1016/j.fishres.2016.06.005).
