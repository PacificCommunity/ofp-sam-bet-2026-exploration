# Tag reporting Group 17 prior harmonization

## Decision

Reporting Group 17 covers PTTP/pooled recaptures for F25-F28. Its archived
input contains two geographically derived candidate priors:

| Candidate | Fisheries | Mean | Penalty lambda | Implied SD |
|---|---|---:|---:|---:|
| West | F25/F27 | 0.5121 | 739.2 | 0.026008 |
| East | F26/F28 | 0.5282 | 231.2 | 0.046504 |

These are alternative, equally plausible priors for one reporting group. They
are not independent evidence, so their penalties must not be added as though
both priors were observed.

## Moment match

The equal-weight mixture mean is:

    mu = (0.5121 + 0.5282) / 2 = 0.52015

Its variance includes each component variance and the between-candidate
dispersion:

    sigma^2 = 0.5 * (sigma_W^2 + (mu_W - mu)^2)
            + 0.5 * (sigma_E^2 + (mu_E - mu)^2)

This gives SD 0.038527. MFCL stores the target on the percentage scale and
uses the quadratic penalty lambda * (r - mu)^2 with
sigma^2 = 1 / (2 * lambda). The harmonized values are therefore:

    target = 100 * mu = 52.015
    lambda = 1 / (2 * sigma^2) = 336.854

## Why every cell is harmonized

MFCL applies only the first positive reporting-rate penalty it encounters for
a reporting group. Different positive targets or penalties within Group 17
therefore make the effective prior depend on release/fishery ordering.

The generator rewrites every Group 17 cell in tag event rows 16-61 and pooled
row 99 for F25-F28 to target 52.015 and penalty 336.854. Initial reporting-rate
values and every other reporting group remain unchanged. Each model receives
tag_reporting_group17_prior_audit.csv, and generation fails if Group 17 has an
unexpected source pair, a non-positive cell, or more than one final positive
target/penalty pair.

## Rerun implication

This changes bet.ini for all 97 models and therefore changes the effective
Group 17 prior for every fit. Results produced from pre-harmonization inputs
are stale for comparisons using this model set. All 97 models must be rerun
from the regenerated inputs before likelihood or biological comparisons are
updated.
