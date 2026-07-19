# CPUE HAC4 sigma sensitivity

## Purpose

This branch evaluates whether residual serial dependence in the five regional
CPUE indices is materially understated by the existing independent-residual
sigma controls. It changes only fish flag 92 for F29-F33. The CPUE data,
time-varying FRQ multipliers, and all biological and observation-model settings
remain unchanged.

## MFCL implementation checked

The calculation was checked against committed `ongoing-dev` source at
`PacificCommunity/ofp-sam-mfcl@de4abeca920063bf234ce66ec3a0f043c56e885f`:

- [`newmaux4.cpp`](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/newmaux4.cpp#L87-L104) reads the FRQ effort weight.
- [`lmult.cpp`](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/lmult.cpp#L834-L912) validates the temporal weights and normalizes them by their fishery mean.
- [`newl2.cpp`](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/newl2.cpp#L870-L956) uses `lambda_t * sigma^2` in the catch-conditioned CPUE likelihood when fish flag 66 is 1 and parest flag 371 is 0.

Thus `lambda_t` is a variance multiplier, not a precision multiplier. The
existing estimator `mean(residual^2 / lambda_t)` is the sigma-squared
estimator under that likelihood. Earlier generated comments called lambda a
"precision pattern"; the formula and model inputs were correct, but that label
was not. The generated comments are corrected on this branch while the archived
reference bundle remains immutable.

## Residual calculation

The residual anchor is the converged
`S014-TC1-NOCUT-DW10-REG100` fit from Kflow job 9777. For each index:

1. Order quarterly log residuals as 1952 Q1-Q4, 1953 Q1-Q4, and so on.
2. Form `u_t = residual_t / sqrt(lambda_t)`.
3. Calculate Bartlett-weighted residual autocorrelations through lag 4.
4. Calculate `DE4 = 1 + 2 * sum((1 - k / 5) * rho_k)` for `k = 1,...,4`.
5. Set `sigma_HAC4 = sigma_base * sqrt(DE4)`.
6. Encode the result as integer fish flag 92, `round(100 * sigma_HAC4)`.

MFCL normalizes lambda to mean one within each fishery. Dividing all lambda
values by the same fishery-specific mean multiplies every `u_t` by one constant,
so autocorrelations, DE4, and the resulting HAC4 adjustment are invariant to
that normalization.

## Why this sensitivity

The five abundance indices are quarterly. Consecutive standardized index
observations can therefore retain short-lag dependence that is not represented
by MFCL's conditionally independent CPUE likelihood. If positive dependence is
ignored, a time series can contribute more apparent independent information
than its residual sequence supports. Inflating sigma by `sqrt(DE4)` reduces
that effective information without changing the standardized observations or
their relative quarter-specific variances.

Lag 4 was selected before comparing model outcomes because it spans one full
year of quarterly observations. This gives a transparent annual-cycle window,
avoids choosing a different lag for each region after seeing results, and is
short relative to the 72-73 year index histories. Bartlett weights taper the
contribution of more distant lags rather than applying a sharp equal-weight
cutoff.

One converged anchor fit is used for all 41 models so that HAC weighting is one
controlled branch-level axis. Re-estimating a different sigma adjustment from
every sensitivity would mix changes in age-length, LF likelihood, tag control,
or selectivity with the CPUE weighting treatment and would prevent paired
comparisons.

A fitted AR(1) observation model would be a more direct representation of
serial correlation, but that would require changing the MFCL likelihood and
estimating additional correlation parameters. HAC4 is used here as a practical
and reproducible robustness sensitivity within the existing executable, not as
evidence that an AR(1) process is the true data-generating model.

## Results

| Fishery | Index | n | Base flag 92 | DE4 | HAC4 sigma | Applied flag 92 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| F29 | R1 | 292 | 35 | 1.294765 | 0.398257 | 40 |
| F30 | R2 | 292 | 24 | 1.587703 | 0.302410 | 30 |
| F31 | R3 | 292 | 21 | 2.820362 | 0.352673 | 35 |
| F32 | R4 | 290 | 24 | 1.797746 | 0.321792 | 32 |
| F33 | R5 | 292 | 23 | 1.686407 | 0.298682 | 30 |

All 41 generated FRQ files contain byte-identical F29-F33 records through the
effort-weight field. Every multiplier is finite and positive. The applied
flags therefore use one common audited CPUE treatment across the complete
41-model design.

## Interpretation

This is a model-weighting sensitivity, not a replacement for the CPUE
standardization model and not a full correlated-error likelihood. HAC4 inflates
the marginal sigma to reflect the effective information loss implied by short
lag residual dependence while preserving MFCL's existing independent-error
likelihood. Results should be compared with the unadjusted branch rather than
treated as a new default without assessment-team review.

The lag-4 Bartlett estimator follows Newey and West (1987), *A Simple,
Positive Semi-definite, Heteroskedasticity and Autocorrelation Consistent
Covariance Matrix*, Econometrica 55:703-708,
<https://doi.org/10.2307/1913610>.
