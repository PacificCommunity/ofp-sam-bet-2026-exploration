# Regional-scaling precision grid

The public sensitivity grid uses MFCL parest flag 77 values 11, 25, and 100.
In MFCL ongoing-dev, the multivariate-normal regional-scaling contribution is

`0.5 * w * (theta - mu)' Sigma^-1 (theta - mu)`,

where `w` is parest flag 77. Equivalently, the covariance is `Sigma / w` and
the standardized SD multiplier is `1 / sqrt(w)`.

| REGW | Standardized SD multiplier | Approximate interpretation |
|---:|---:|---:|
| 11 | 0.3015 | 0.30 |
| 25 | 0.2000 | 0.20 |
| 100 | 0.1000 | 0.10 |

The external regional target, covariance matrix, and period window are held
fixed. The grid changes only the precision multiplier so its effect can be
separated from LF likelihood and reporting-rate assumptions.
