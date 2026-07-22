# BET 2026 G8 grouped Francis reweighting

This public branch contains four robust-normal G8 grouped Francis TA1.8 refits.
Each model uses composition residuals from its own fitted source job; no
grouped divisor is copied between source fits. Only fishery flag 49 changes.
CPUE flag 92 remains 35, 24, 21, 24, 23 in all four models.

## Models

| Model | Source Job | Design | Mean ESS | Full-Francis reproduction error |
|---|---:|---|---:|---:|
| S001 | 12306 | REGW11 PTTP26 | 8.63 | 5.77e-15 |
| S002 | 12307 | REGW1 PTTP26 | 8.80 | 4.88e-15 |
| S003 | 12292 | REGW11 RR8/10 | 8.60 | 4.00e-15 |
| S004 | 12291 | REGW1 RR8/10 | 8.93 | 4.66e-15 |

All four payloads contain 2,399 usable compositions. The previous 33
fishery-specific multipliers and all rounded divisors were reproduced exactly
before changing only the pooling unit to G8.

## Method and outputs

GROUPED_FRANCIS_METHOD.md records the equations, pooling assumption, MFCL tail
mapping, validation, limitations, provenance, and literature. Every model
contains grouped_francis_groups.csv, grouped_francis_fisheries.csv, and
grouped_francis_ess.csv in its model directory.

Only length-composition weighting changes. FRQ, INI, tag, SUB075 age-length,
regional scaling, reporting-rate priors, selectivity, effort creep, and CPUE
settings are retained from each source fit.
