# G8 grouped Francis length-composition reweighting

## Purpose

These four BET 2026 sensitivities replace the previous fishery-specific
length-composition divisors with one absolute divisor for each of eight
pre-specified fishery strata. No previous divisor, including the former
divisor of 200 for fisheries 21-23, contributes to the new estimate.

The grouping is a model design choice based on fishery and sampling strata.
It is not a grouping prescribed by Francis (2011). Within each group, the
method assumes that composition-level mean-length residuals share one common
overdispersion parameter.

## Statistical definition

For composition sample i, let O_i and E_i be the observed and predicted mean
lengths, V_i the multinomial variance of mean length under the fitted
composition, and N_i the raw sample size. With the MFCL sample-size cap of
1,000, the unit-divisor standardized residual is

```
u_i = (O_i - E_i) / sqrt(V_i / min(N_i, 1000)).
```

For group g, the continuous absolute divisor is

```
d_g = Var(u_i : i belongs to g),
```

and the corresponding sample-size multiplier is `1 / d_g`. MFCL flag 49 is
integer-valued. `mfclkit` chooses the positive floor or ceiling with the
smallest log-scale distance to `d_g`, which minimizes multiplicative weighting
error and prevents an accidental zero/default-divisor interpretation. After
applying the continuous value, the pooled residual variance is exactly one;
after integer realization it remains approximately one.

This is the Francis TA1.8 variance-matching principle applied to a shared
group-level dispersion parameter. Setting `current_divisor = 1` is essential:
it removes all inherited within-group relative weighting. Pooling residuals
that still contain the old divisors would answer a different question and
would preserve those old ratios.

The calculation is a one-step reweighting estimate based on predictions from
the source fitted model. Consequently, the old divisors are absent from the
new variance formula but may have influenced those fitted predictions. The
models must be refitted after changing the divisors. A second calculation from
each refit is the appropriate stability check; it is not silently folded into
this first iteration.

## MFCL composition controls

The calculation follows the fitted BET model settings used by `mfclkit`. The
script reads `ParOut` from each payload and stops unless all four controls are
present with these exact values:

- Robust-normal length likelihood: flag 141 = 3.
- Observed-tail mapping enabled: flags 311 = 1 and 313 = 1.
- Raw-sample tail threshold: flag 312 = 50.
- Sample-size cap: 1,000.
- Number of usable compositions in each source fit: 2,399.

## G8 strata

| Group | Stratum | Fisheries |
|---:|---|---|
| G1 | Main longline | 1-4, 6-8, 10-11 |
| G2 | Offshore longline | 5, 9 |
| G3 | Purse seine, set type unavailable | 12, 17-18 |
| G4 | Associated purse seine | 19, 25-26 |
| G5 | Unassociated purse seine | 20, 27-28 |
| G6 | Handline | 14-15 |
| G7 | Other extraction fisheries | 13, 16, 21-24 |
| G8 | Regional index fisheries | 29-33 |

## Source provenance

| Sensitivity | Source Job | Source model | `model_payload.rds` SHA-256 |
|---|---:|---|---|
| S001 | 12306 | S022-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26 | `58e60d5185a8633cafd8997c8d92b76cd38305c54b70a92ef098429f18a58c98` |
| S002 | 12307 | S023-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26 | `8bdc65f02cce1871641e07e7c952b01588dad4ea3c1956a4289e71c1bbbd4196` |
| S003 | 12292 | S006-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW11 | `9fe718ec7cd280e4a5b12f7717e76461cf31c1a0d8a1845a65997de1a1b7ee9d` |
| S004 | 12291 | S007-TC1-NOCUT-DW10-SUB075-MIX015-TAGF2ON-REGW1 | `d9880c240702c3ff97846ae477e5a2a645f6076be67717e39acfb87ead78dc79` |

## Applied divisors

| Sensitivity | G1 | G2 | G3 | G4 | G5 | G6 | G7 | G8 | Mean ESS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| S001 | 88 | 81 | 142 | 72 | 45 | 118 | 388 | 72 | 8.166 |
| S002 | 90 | 84 | 139 | 69 | 47 | 119 | 411 | 65 | 8.370 |
| S003 | 88 | 82 | 139 | 69 | 45 | 118 | 400 | 73 | 8.136 |
| S004 | 88 | 86 | 134 | 74 | 45 | 115 | 397 | 64 | 8.469 |

The group CSV in each model directory records the continuous estimate, applied
integer divisor, number of compositions, multiplier, post-rounding residual
variance, and ESS summary.

## Independent numerical checks

For every source model, the direct grouped calculation
`mfk_francis_ta18(..., pool_cols = "group", current_divisor = 1)` was compared
with an independent reconstruction from the source-standardized residuals:

```
Var(z_old * sqrt(d_old)).
```

The maximum absolute differences were `2.84e-14`, `1.42e-14`, `5.68e-14`, and
`5.68e-14` for S001-S004, respectively. This identity confirms that the old
divisors are algebraically removed rather than retained as relative weights.

The fishery-specific reference implementation was also reproduced exactly for
all 33 fisheries before grouping, using 2,399 compositions per model.

## Reproduction

Use `mfclkit` containing `mfk_francis_ta18()` and provide the source fitted
model payload:

```bash
Rscript scripts/calculate_grouped_francis.R \
  /path/to/model_payload.rds \
  grouped-francis-output \
  12306
```

The script writes group, fishery, and ESS audit tables. The committed
calculations used `mfclkit` source commit
`0272c9dabf7810326f650b1377d5e8a747e1ed26`.

When the pinned package is not installed, the same calculation can be audited
directly from its source file by setting `MFCLKIT_FRANCIS_R` to `R/francis.R`
in a checkout of that commit.

## References

- Francis, R. I. C. C. (2011). Data weighting in statistical fisheries stock
  assessment models. *Canadian Journal of Fisheries and Aquatic Sciences*,
  68, 1124-1138. <https://doi.org/10.1139/F2011-025>
- Francis, R. I. C. C. (2017). Revisiting data weighting in fisheries stock
  assessment models. *Fisheries Research*, 192, 5-15.
  <https://doi.org/10.1016/j.fishres.2016.06.006>
- Punt, A. E. (2017). Some insights into data weighting in integrated stock
  assessments. *Fisheries Research*, 192, 52-65.
  <https://doi.org/10.1016/j.fishres.2015.12.006>
