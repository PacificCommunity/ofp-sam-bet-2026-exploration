# BET extraction-fishery selectivity comparison

**Status:** Design note; no selectivity sensitivity has been fitted  
**Scope:** Extraction fisheries F1-F28 only; index fisheries are excluded  
**Date:** 18 July 2026

## Models compared

This note compares the extraction-fishery selectivity configuration in the
five-region BET exploration model with the reference 2026 BET single-area
model.

| Model | Source |
|---|---|
| Five-region exploration reference | `S005-TC1-CUT70-DW5` on `experiment/dm-observation-groups-20260718` |
| Single-area BET model | `BET-YFT-2026`, commit [`5363029b509cacf902aef2866efdc04634c89045`](https://github.com/PacificCommunity/ofp-sam-bet-yft-2026-single-area/tree/5363029b509cacf902aef2866efdc04634c89045/steps/BET/model) |

The fishery sequence is the same for F1-F28. The regional suffixes retained in
the single-area display labels describe the historical data source, while all
single-area fisheries are assigned to MFCL region 1. The structural comparison
is therefore valid for extraction fisheries. The index structure is not
comparable: the single-area model has one index fishery (F29), whereas the
five-region model has five regional index fisheries (F29-F33).

## Common settings

Both configurations use the following general selectivity settings:

| Setting | Value |
|---|---|
| Oldest age with common selectivity | Age class 37 and older |
| Primary formulation | Length-dependent selectivity |
| Spline type | Cubic spline |
| Default spline complexity | Five nodes |

These common settings do not imply that the fishery-specific selectivities are
the same. Group sharing, zero-at-young-age constraints, monotonicity, spline
complexity, and upper-age constraints differ substantially.

## Selectivity grouping

The five-region model has 24 extraction selectivity groups. It shares
selectivity for four pairs whose members were derived from common historical
fishery sources:

| Shared group in five-region model | Fisheries |
|---|---|
| HL ID/PH | F14 and F15 |
| Domestic PS ID/PH | F17 and F18 |
| Associated PS west/region 2 | F19 and F25 |
| Unassociated PS west/region 2 | F20 and F27 |

The single-area model assigns a separate selectivity group to every extraction
fishery F1-F28. It therefore estimates 28 extraction selectivity groups.

This difference is scientifically meaningful. Sharing is a parsimonious way to
represent fisheries with a common historical source, but it assumes their
selectivity shapes remain exchangeable after the 2026 fishery redefinition.
The single-area configuration instead allows the data for each redefined
fishery to determine a separate shape, at the cost of four additional
selectivity blocks.

## Fishery-specific differences

The main differences read from the two `doitall.sh` files are summarized below.

| Fisheries | Five-region exploration | Single-area model | Interpretation |
|---|---|---|---|
| F1-F11 longline | First two ages fixed to zero only for F2, F4-F5, and F7-F10 | First two ages fixed to zero for all F1-F11 | The single-area model imposes a more uniform exclusion of the youngest fish from longline selectivity. |
| F5 and F9 | Non-decreasing constraint on F5 | Non-decreasing constraint on F9 | The monotonic longline reference differs. This should be checked against the observed LF support, not copied solely for consistency. |
| F12 PS.JP.1 | Five default nodes; age-based spline to age 25; first two ages zero | Eight nodes; age-based spline to age 25; first two ages zero | The single-area script explicitly treats the extra flexibility as compensation for modal structure associated with northern seasonal recruitment. |
| F13 PL.JP.1 | Five default nodes; age-based spline to age 25 | Eight nodes; age-based spline to age 30; first age zero | Both spline complexity and support constraints differ. |
| F14-F15 handline | One shared selectivity; first five ages zero for both | Separate selectivities; first five ages zero for F15 only | The five-region model imposes stronger pooling and a common young-age exclusion. |
| F16 PL.ALL.2 | Age-based spline to age 7 | Age-based spline to age 25 | This is a large difference in allowed upper-age support. |
| F17 PS.ID.2 | Shared with F18; age-based spline to age 6 | Independent; age-based spline to age 25 | The five-region constraint is much more restrictive. |
| F18 PS.PH.2 | Shared with F17; age-based spline to age 12 | Independent; age-based spline to age 25 | The single-area model allows a broader age range and country-specific shape. |
| F19 and F25 associated PS | Shared; age-based spline to age 25 | Independent; both to age 25 | The support is similar, but sharing differs. |
| F20 and F27 unassociated PS | Shared; F20 effectively unconstrained to age 37 and F27 to age 30 | Independent; F20 left without the age-spline override and F27 to age 30 | The principal difference is group sharing. |
| F21 MISC.ID.2 | Age-based spline to age 6 | Age-based spline to age 10 | The five-region model truncates support earlier. |
| F22 MISC.PH.2 | Age-based spline to age 9 | Age-based spline to age 7 | The single-area model truncates support earlier. |
| F23 MISC.VN.2 | Age-based spline to age 9 | Age-based spline to age 6 | The single-area model truncates support earlier. |
| F24 PL.ALL.WEST.3 | Age-based spline to age 10 | Age-based spline to age 25 | This is another large upper-age support difference. |
| F26 associated PS east | Independent, to age 25, first age zero | Independent, to age 25 | The young-age constraint differs. |
| F28 unassociated PS east | Independent and effectively unconstrained to age 37 | Independent and left without the age-spline override | Broadly similar treatment. |

The phase sequence, recruitment model, movement/regional-scaling treatment,
tag settings, and composition weighting also differ between the repositories.
Those differences must not be imported as part of a selectivity comparison.

## Interpretation

The single-area selectivity configuration is not automatically preferable for
the five-region assessment. In particular, its comments state that the
eight-node F12/F13 splines are needed to represent modal LF characteristics
that arise from seasonal recruitment in the north but cannot be represented by
a single-region population structure. A spatial model may already represent
part of that mechanism. Copying the extra spline flexibility into the
five-region model could therefore transfer a compensatory single-area feature
rather than a generally superior observation model.

Conversely, several five-region upper-age constraints are much more restrictive
than the single-area settings, especially for F16, F17, F18, and F24. Because
the underlying extraction fisheries and 2026 compositions are the same, these
constraints are legitimate candidates for sensitivity testing. The four
shared selectivity pairs are also testable assumptions rather than fixed facts.

## Recommended sensitivity design

The cleanest first test is not to replace the five-region selectivity wholesale.
Use two staged extraction-only alternatives while preserving F29-F33 and every
non-selectivity setting from the five-region reference.

| Candidate | Extraction configuration | Question answered |
|---|---|---|
| `SA28-N5` | Unshare F1-F28 and adopt the single-area fishery-specific young-age, monotonicity, and upper-age constraints, but retain five spline nodes for F12/F13 | Do the independent groups and support constraints improve the spatial model without adding the single-area compensatory spline complexity? |
| `SA28-N8` | Exact single-area extraction selectivity settings for F1-F28, including eight nodes for F12/F13 | Does the full single-area configuration materially change fit and management quantities beyond `SA28-N5`? |

The current five-region model remains the reference. Comparing the three in
this order separates the effect of extraction support/grouping from the extra
F12/F13 flexibility.

The fitted `final.par` from the single-area model must not be transplanted. The
alternative models should be rebuilt and estimated from the five-region input
sequence because the population dimension, index structure, parameter layout,
and recruitment/spatial processes differ.

## Evaluation criteria

1. Compare models using identical LF cutoff, weighting, age-length, tag, and
   recruitment settings.
2. Confirm convergence and positive-definite Hessians before interpreting LF
   improvements.
3. Plot extraction selectivity and LF residuals fishery by fishery, especially
   F12-F18, F21-F24, and the four currently shared pairs.
4. Check whether independent paired selectivities are genuinely distinct or
   merely weakly identified.
5. Check CPUE fit and recruitment because additional selectivity flexibility
   can absorb conflicts that would otherwise appear in population processes.
6. Compare depletion, recent fishing mortality, recruitment, and other key
   management quantities, not only the total or LF objective value.
7. Prefer the simpler configuration when the more flexible model does not
   produce a coherent and diagnostically supported improvement.

## Recommended reporting language

> Extraction-fishery selectivity was compared with a contemporary single-area
> BET model because both assessments used the same F1-F28 fishery definitions.
> The comparison was restricted to extraction fisheries; the single-area index
> fishery was not comparable with the five regional indices. The single-area
> model estimated independent selectivity for all 28 extraction fisheries,
> whereas the spatial model shared four pairs derived from common historical
> fishery sources. It also used different young- and upper-age constraints and
> additional spline nodes for the Japanese purse-seine and pole-and-line
> fisheries. Because the latter flexibility was introduced partly to represent
> seasonal recruitment structure absent from a single-region model, five-node
> and exact eight-node variants were evaluated separately.

## Source files

- [Single-area BET `doitall.sh` at the reviewed commit](https://github.com/PacificCommunity/ofp-sam-bet-yft-2026-single-area/blob/5363029b509cacf902aef2866efdc04634c89045/steps/BET/model/doitall.sh)
- [Single-area BET `fishery_map.R` at the reviewed commit](https://github.com/PacificCommunity/ofp-sam-bet-yft-2026-single-area/blob/5363029b509cacf902aef2866efdc04634c89045/steps/BET/model/fishery_map.R)
- [Five-region exploration reference `doitall.sh`](https://github.com/PacificCommunity/ofp-sam-bet-2026-exploration/blob/experiment/dm-observation-groups-20260718/sensitivity/S005-TC1-CUT70-DW5/model/doitall.sh)
- [Five-region exploration fishery map](https://github.com/PacificCommunity/ofp-sam-bet-2026-exploration/blob/experiment/dm-observation-groups-20260718/sensitivity/S005-TC1-CUT70-DW5/model/fishery_map.R)
