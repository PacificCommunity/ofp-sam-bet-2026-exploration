# Interpreting the MFCL regional-scaling weight

This note documents how `parest flag 77` (`REGW`) controls the regional-scaling
penalty used by these sensitivities. It was checked against the MFCL
regional-scaling implementation and the regional-scaling equations in the MFCL
manual on 21 July 2026.

## Active formulation

These models set `parest flag 81 = 1`, selecting the multivariate-normal (MVN)
regional-scaling penalty. MFCL first calculates a target vector of mean regional
CPUE proportions over the configured period and its empirical covariance matrix
`Sigma`. The model prediction is compared with that target using

```text
d = predicted regional proportions - target regional proportions
Penalty = (REGW / 2) * transpose(d) * inverse(Sigma) * d
```

Equivalently, after Cholesky standardization, `z = inverse(L) * d` with
`Sigma = L * transpose(L)`, the penalty is

```text
Penalty = (REGW / 2) * sum(z^2).
```

Matching this expression to a Gaussian penalty,

```text
sum(z^2) / (2 * s^2),
```

gives

```text
s = 1 / sqrt(REGW).
```

Thus a positive `REGW` is a precision multiplier:

```text
effective covariance = Sigma / REGW
effective SD          = empirical SD / sqrt(REGW)
```

The penalty is soft, not a hard bound. Predictions can move farther from the
target, but the objective-function cost increases quadratically.

## Values used in this design

| REGW | Standardized SD multiplier | Effective covariance | Interpretation |
| ---: | ---: | ---: | --- |
| 50 | 0.1414 | `Sigma / 50` | Retains the inherited strong constraint |
| 11 | 0.3015 | `Sigma / 11` | Nearest integer setting to 30-percent standardized SD |
| 1 | 1.0000 | `Sigma` | Uses the empirical covariance directly |
| 0 | Not finite | Not applicable | Disables the regional-scaling penalty |

The exact continuous weight for a 30% standardized SD is 11.1111. Because
`parest flag 77` is integer-valued, `REGW = 11` is the nearest available
setting and gives 30.1511%. For reference, a 10% standardized SD would use
`REGW = 100`, and a 5% standardized SD would require `REGW = 400`.

At a Mahalanobis distance of one empirical MVN SD, the objective-function
increments are `REGW / 2`: 25.0 for `REGW50`, 5.5 for `REGW11`, and 0.5 for
`REGW1`. At `REGW0`, this penalty is not evaluated.

## What the percentage does and does not mean

The percentage from `1 / sqrt(REGW)` is the allowed SD **relative to the
empirical covariance used by the MVN penalty**. For example, `REGW = 50`
allows 0.1414 times the empirical SD in a standardized direction. It does not
mean that every regional target value has a CV of 14.14%, and it is not a CV on
absolute regional biomass.

For region `r`, a marginal target-relative Gaussian CV can be calculated, when
that quantity is scientifically useful, as

```text
CV_r(REGW) = sqrt(Sigma[r,r] / REGW) / target[r].
```

This value differs among regions because both `Sigma[r,r]` and `target[r]`
differ. Consequently, no single `REGW` generally gives exactly the same
target-relative CV in every region. The five proportions also sum to one, so
MFCL removes the final region when inverting the covariance; its deviation is
implicitly determined by the other regions.

## Manual notation

The MFCL manual's generic normal-penalty derivation writes a direct
squared-error coefficient `p` and obtains `s = 1 / sqrt(2p)`. In the active
regional-scaling MVN equation, that direct coefficient is `p = REGW / 2`.
Substitution therefore gives

```text
1 / sqrt(2 * (REGW / 2)) = 1 / sqrt(REGW).
```

The generic lookup table must not be applied by substituting `REGW` directly
for `p`. The regional-specific manual equation and the native MFCL source both
use the `REGW / 2` formulation.

## Implementation references

- MFCL source: `src/regscalpen.cpp`, target and covariance construction near
  lines 14-99, reduced covariance near lines 374-392, and the active penalty
  near lines 394 and 423.
- MFCL source: `src/callpen.cpp`, regional scaling is skipped when flag 77 is
  zero near line 151.
- MFCL manual: `manual-sections/MFCL-manual_appendix-A.tex`, regional MVN
  equations near lines 2629 and 2673, and the generic penalty derivation near
  lines 2705-2710.
- MFCL manual: `manual-sections/MFCL-manual_likelihood-functions.tex`, the
  generic coefficient lookup near lines 566-572.

## Sensitivity rationale

The selected values separate four interpretable cases rather than treating
`REGW` as a literal CV:

- `REGW50` retains the inherited strong regional-scaling constraint.
- `REGW11` gives the closest integer approximation to a 30% standardized SD.
- `REGW1` uses the observed covariance without an additional precision
  multiplier.
- `REGW0` removes the penalty as a diagnostic endpoint.

Model results should be described using these weight values and standardized
SD multipliers, not by assigning a single regional biomass CV to each model.
