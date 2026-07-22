# S003 G8 grouped Francis reweighting

Source fitted model: Kflow Job 12292.

Effort creep was already applied once to the retained `bet.frq` and is not reapplied.
Source `model_payload.rds` SHA-256: `9fe718ec7cd280e4a5b12f7717e76461cf31c1a0d8a1845a65997de1a1b7ee9d`.

This sensitivity applies one absolute length-composition divisor to every fishery in each pre-specified G8 group. The calculation starts at divisor 1, so no previous fishery-specific divisor or within-group ratio is retained.

## Applied divisors

| Group | Stratum | Fisheries | Continuous | Applied |
|---:|---|---|---:|---:|
| G1 | Main longline | 1,2,3,4,6,7,8,10,11 | 87.617 | 88 |
| G2 | Offshore longline | 5,9 | 82.292 | 82 |
| G3 | Purse seine, set type unavailable | 12,17,18 | 139.034 | 139 |
| G4 | Associated purse seine | 19,25,26 | 68.667 | 69 |
| G5 | Unassociated purse seine | 20,27,28 | 45.176 | 45 |
| G6 | Handline | 14,15 | 118.160 | 118 |
| G7 | Other extraction fisheries | 13,16,21,22,23,24 | 399.851 | 400 |
| G8 | Regional index fisheries | 29,30,31,32,33 | 72.706 | 73 |

Usable compositions: 2399. Overall mean effective sample size after integer rounding: 8.136.

The derivation, assumptions, references, and reproducibility instructions are in [`GROUPED_FRANCIS_METHOD.md`](../../GROUPED_FRANCIS_METHOD.md).
