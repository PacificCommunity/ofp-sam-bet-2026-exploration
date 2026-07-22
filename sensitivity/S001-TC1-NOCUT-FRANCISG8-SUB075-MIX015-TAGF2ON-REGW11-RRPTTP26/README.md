# S001 G8 grouped Francis reweighting

Source fitted model: Kflow Job 12306.

Effort creep was already applied once to the retained `bet.frq` and is not reapplied.
Source `model_payload.rds` SHA-256: `58e60d5185a8633cafd8997c8d92b76cd38305c54b70a92ef098429f18a58c98`.

This sensitivity applies one absolute length-composition divisor to every fishery in each pre-specified G8 group. The calculation starts at divisor 1, so no previous fishery-specific divisor or within-group ratio is retained.

## Applied divisors

| Group | Stratum | Fisheries | Continuous | Applied |
|---:|---|---|---:|---:|
| G1 | Main longline | 1,2,3,4,6,7,8,10,11 | 87.846 | 88 |
| G2 | Offshore longline | 5,9 | 81.126 | 81 |
| G3 | Purse seine, set type unavailable | 12,17,18 | 141.810 | 142 |
| G4 | Associated purse seine | 19,25,26 | 72.480 | 72 |
| G5 | Unassociated purse seine | 20,27,28 | 45.168 | 45 |
| G6 | Handline | 14,15 | 117.673 | 118 |
| G7 | Other extraction fisheries | 13,16,21,22,23,24 | 387.794 | 388 |
| G8 | Regional index fisheries | 29,30,31,32,33 | 72.276 | 72 |

Usable compositions: 2399. Overall mean effective sample size after integer rounding: 8.166.

The derivation, assumptions, references, and reproducibility instructions are in [`GROUPED_FRANCIS_METHOD.md`](../../GROUPED_FRANCIS_METHOD.md).
