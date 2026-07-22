# S004 G8 grouped Francis reweighting

Source fitted model: Kflow Job 12291.

Effort creep was already applied once to the retained `bet.frq` and is not reapplied.
Source `model_payload.rds` SHA-256: `d9880c240702c3ff97846ae477e5a2a645f6076be67717e39acfb87ead78dc79`.

This sensitivity applies one absolute length-composition divisor to every fishery in each pre-specified G8 group. The calculation starts at divisor 1, so no previous fishery-specific divisor or within-group ratio is retained.

## Applied divisors

| Group | Stratum | Fisheries | Continuous | Applied |
|---:|---|---|---:|---:|
| G1 | Main longline | 1,2,3,4,6,7,8,10,11 | 87.523 | 88 |
| G2 | Offshore longline | 5,9 | 85.534 | 86 |
| G3 | Purse seine, set type unavailable | 12,17,18 | 133.671 | 134 |
| G4 | Associated purse seine | 19,25,26 | 73.731 | 74 |
| G5 | Unassociated purse seine | 20,27,28 | 44.553 | 45 |
| G6 | Handline | 14,15 | 115.238 | 115 |
| G7 | Other extraction fisheries | 13,16,21,22,23,24 | 397.066 | 397 |
| G8 | Regional index fisheries | 29,30,31,32,33 | 63.713 | 64 |

Usable compositions: 2399. Overall mean effective sample size after integer rounding: 8.469.

The derivation, assumptions, references, and reproducibility instructions are in [`GROUPED_FRANCIS_METHOD.md`](../../GROUPED_FRANCIS_METHOD.md).
