# PTTP reporting-rate association split

## Purpose

The source control `S002-TC1-NOCUT-DW10` assigns one PTTP
reporting-rate parameter to F25-F28. This assumes that associated and
unassociated purse-seine fisheries share the same effective probability that a
recovered tag is reported. The focused sensitivity
`S001-TC1-NOCUT-DW10-RRASSOC` relaxes that single parameter
restriction.

| Reporting-rate parameter | Fisheries | Prior target | Penalty weight |
|---|---|---:|---:|
| Associated sets | F25 and F26 | 0.52015 | 242.6 |
| Unassociated sets | F27 and F28 | 0.52015 | 242.6 |

The prior target 0.52015 is the mean of the existing west and east PTTP targets,
0.5121 and 0.5282. Association groups cross those regions: F25/F27 are west and
F26/F28 are east. The regional targets therefore cannot be assigned directly
to associated and unassociated parameters. Both retain the pooled target.

## MFCL prior calculation

MFCL applies the reporting-rate prior once per reporting group as

```text
P_g = w_g (rho_g - mu_g)^2,
```

where `rho_g` is the fitted reporting rate, `mu_g` is the
target expressed as a proportion, and `w_g` is the INI penalty
weight. The source implementation reads the target stored as a percentage and
divides it by 100 before evaluating the quadratic penalty.

The control contribution is

```text
P_control = 485.2 (rho - 0.52015)^2.
```

The focused sensitivity uses

```text
P_split = 242.6 (rho_assoc - 0.52015)^2
        + 242.6 (rho_unassoc - 0.52015)^2.
```

When `rho_assoc = rho_unassoc = rho`,
`P_split = P_control`. Retaining weight 485.2 for each new parameter
would double the common-mode prior information and is therefore not used.

## Exact implementation

| Setting | Source control | Focused sensitivity |
|---|---|---|
| PTTP F25/F26 | group 16 | group 16 |
| PTTP F27/F28 | group 16 | group 17 |
| Groups formerly 17-28 | unchanged | shifted to 18-29 |
| Initial reporting rate | 0.52015 | 0.52015 for both |
| Prior target in INI | 52.015 | 52.015 for both |
| Prior weight | 485.2 | 242.6 for both |

The transformation is restricted to PTTP reporting rows 16-61 and pooled row
99. RTTP and JPTP groups and priors are unchanged. Active reporting-group IDs
remain contiguous from 1 to 29.

Observed recaptures remain pooled by region. The sensitivity does not infer set
association for individual tag recoveries. Data, selectivity, fishing mortality
structure, regional scaling, and estimation phases are unchanged.

## Interpretation and limitations

Allowing two rates can change predicted reported recaptures and the tag
likelihood. Because MFCL jointly reoptimizes active parameters, changes can
also propagate to fishing mortality, biomass, movement, selectivity, and other
likelihood components.

Materially different fitted rates, accompanied by reduced tag or prior tension,
would indicate that the pooled reporting-rate restriction was influential.
This is not direct evidence that set association is the causal process.
Reporting rate remains potentially confounded with local fishing mortality,
selectivity, movement, and release/recovery composition.

If both fitted rates move together toward the same boundary, association
pooling has not isolated the main source of tension. Further splitting would
then be difficult to justify without association-specific recovery data.

The result should be reported with both fitted rates, their prior contributions,
the change in tag likelihood, and any material response in biomass or fishing
mortality. A likelihood improvement alone should not be presented as evidence
of an association effect.

## Report-ready methods text

> We evaluated a focused sensitivity in which the PTTP purse-seine reporting
> rate, pooled across fisheries F25-F28 in the control model, was separated into
> associated (F25-F26) and unassociated (F27-F28) parameters. Observed
> recaptures remained pooled by region because association was not assigned to
> individual recoveries. Both parameters retained the pooled prior mean of
> 0.52015. The pooled quadratic prior weight of 485.2 was divided equally
> between the two parameters, giving a weight of 242.6 each; this preserves the
> control prior contribution when the two reporting rates are equal. All data,
> selectivity, fishing mortality structure, regional scaling, and estimation
> phases were otherwise unchanged.

## Reproducibility

- Source control: `S002-TC1-NOCUT-DW10`
- Source commit: `6654763923ffa8c91b5e3df6aabc9483dc797cbd`
- Focused model: `S001-TC1-NOCUT-DW10-RRASSOC`
- Derived INI SHA-256:
  `3bf7d0260747dd2d65c5d0058268b10a04c782f54a798a2f6fce1f94dcf8f818`
- MFCL implementation checked: `src/callpen.cpp`, reporting-rate prior
- Audit map:
  `sensitivity/S001-TC1-NOCUT-DW10-RRASSOC/model/tag_rep_map.R`
