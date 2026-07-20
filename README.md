# BET 2026 PTTP reporting-rate association sensitivity

This focused branch contains one model:

`S001-TC1-NOCUT-DW10-RRASSOC`

It is derived from `S002-TC1-NOCUT-DW10` at commit
`6654763923ffa8c91b5e3df6aabc9483dc797cbd`. The control is referenced as
provenance and is not duplicated under `sensitivity/`.

## Question

The control estimates one PTTP purse-seine reporting rate for F25-F28. This
requires associated and unassociated purse-seine fisheries to share the same
effective reporting process. The focused model relaxes only that restriction.

| Reporting-rate parameter | Fisheries | Prior target | Penalty weight |
|---|---|---:|---:|
| Associated sets | F25, F26 | 0.52015 | 242.6 |
| Unassociated sets | F27, F28 | 0.52015 | 242.6 |

The control uses target 0.52015 and penalty weight 485.2 for the pooled F25-F28
parameter. Both new parameters retain the pooled target because the available
prior information is regional rather than association-specific. Dividing the
pooled weight equally preserves the original quadratic prior contribution when
the two fitted rates are equal.

Observed recaptures remain pooled by region because set association is not
assigned to individual recoveries. The split therefore tests a parameter
restriction; it does not reconstruct association-specific recovery data.

## What is unchanged

The following are identical to the source control:

- `bet.frq`, `bet.tag`, and `bet.age_length`
- regional-scaling inputs and weight 50
- normal LF likelihood with 1% tail compression
- no upper-length cutoff
- divisor 200 for F21-F23
- N5 selectivity and index-selectivity phasing
- tag flag column 2 set to 0
- optimization phases and `doitall.sh`

RTTP and JPTP reporting-rate definitions are unchanged. Reporting-group IDs
above the inserted group are shifted by one so that active IDs remain
contiguous from 1 to 29.

## Interpretation

A lower tag or reporting-prior contribution, together with materially different
fitted rates, would show that pooling F25-F28 was influential. It would not by
itself prove that set association caused the difference. Reporting rate can
remain confounded with fishing mortality, selectivity, movement, and the
release/recovery composition.

If both rates move together toward the same boundary, the main tension is
unlikely to be resolved by association-based pooling alone.

Detailed methods, equations, limitations, and report-ready wording are in
[`notes/tag-reporting-association-split.md`](notes/tag-reporting-association-split.md).

## Reproduce and validate

```bash
Rscript R/prepare_bet_2026_step_inputs.R
Rscript R/validate_sensitivities.R
```

The generated INI SHA-256 is:

```text
3bf7d0260747dd2d65c5d0058268b10a04c782f54a798a2f6fce1f94dcf8f818
```

Kflow uses the digest-pinned Tuna Flow v2.5 runtime configured in
`kflow.yaml`.
