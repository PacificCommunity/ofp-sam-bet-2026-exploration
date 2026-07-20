# BET 2026 S001-TC1-NOCUT-DW10-RRASSOC

This is the only model in this focused branch. It is derived from
`S002-TC1-NOCUT-DW10` at commit
`6654763923ffa8c91b5e3df6aabc9483dc797cbd`.

## Model design

| Setting | Value |
|---|---|
| Age-length input | BASE075 |
| LF likelihood | Robust normal |
| Tail compression | 1% |
| Upper-length cutoff | None |
| F21-F23 divisor | 200 |
| Regional-scaling weight | 50 |
| Selectivity | Corrected N5 baseline |
| Tag flag column 2 | 0 |

## PTTP reporting-rate change

| Reporting-rate parameter | Fisheries | Prior target | Penalty weight |
|---|---|---:|---:|
| Associated sets | F25, F26 | 0.52015 | 242.6 |
| Unassociated sets | F27, F28 | 0.52015 | 242.6 |

The source control pools F25-F28 at target 0.52015 with penalty weight 485.2.
The split retains the same target and divides the penalty equally, preserving
the control prior contribution when both fitted rates are equal.

Observed recaptures remain pooled by region. RTTP, JPTP, all data, selectivity,
fishing mortality structure, regional scaling, and `doitall.sh` are
unchanged. Reporting-group identifiers above 16 are shifted by one to remain
contiguous.

This is a diagnostic parameterization. Different fitted rates can indicate
that the pooling restriction matters, but cannot by themselves identify set
association as the cause. Interpretation must also consider fishing mortality,
selectivity, movement, and release/recovery composition.

See
[`../../notes/tag-reporting-association-split.md`](../../notes/tag-reporting-association-split.md)
for the equation, exact transformation, limitations, and report-ready methods
text.

Status: generated and ready for validation; Kflow has not been submitted.

Derived `bet.ini` SHA-256:
`3bf7d0260747dd2d65c5d0058268b10a04c782f54a798a2f6fce1f94dcf8f818`.
