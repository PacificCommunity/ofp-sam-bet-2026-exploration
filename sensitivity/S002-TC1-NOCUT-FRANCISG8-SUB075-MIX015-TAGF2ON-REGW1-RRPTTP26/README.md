# S002 G8 grouped Francis reweighting

Source fitted model: Kflow Job 12307.

Effort creep was already applied once to the retained `bet.frq` and is not reapplied.
Source `model_payload.rds` SHA-256: `8bdc65f02cce1871641e07e7c952b01588dad4ea3c1956a4289e71c1bbbd4196`.

This sensitivity applies one absolute length-composition divisor to every fishery in each pre-specified G8 group. The calculation starts at divisor 1, so no previous fishery-specific divisor or within-group ratio is retained.

## Applied divisors

| Group | Stratum | Fisheries | Continuous | Applied |
|---:|---|---|---:|---:|
| G1 | Main longline | 1,2,3,4,6,7,8,10,11 | 89.812 | 90 |
| G2 | Offshore longline | 5,9 | 83.900 | 84 |
| G3 | Purse seine, set type unavailable | 12,17,18 | 138.809 | 139 |
| G4 | Associated purse seine | 19,25,26 | 69.405 | 69 |
| G5 | Unassociated purse seine | 20,27,28 | 46.803 | 47 |
| G6 | Handline | 14,15 | 119.276 | 119 |
| G7 | Other extraction fisheries | 13,16,21,22,23,24 | 411.048 | 411 |
| G8 | Regional index fisheries | 29,30,31,32,33 | 64.621 | 65 |

Usable compositions: 2399. Overall mean effective sample size after integer rounding: 8.370.

The derivation, assumptions, references, and reproducibility instructions are in [`GROUPED_FRANCIS_METHOD.md`](../../GROUPED_FRANCIS_METHOD.md).
