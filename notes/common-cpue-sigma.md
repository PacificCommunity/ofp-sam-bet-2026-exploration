# Common CPUE sigma

The common values are the index-wise medians across the eight parent model
settings. S001-S004 are MFCL-equivalent MLE estimates. S005-S008 are the fixed
sigma inputs inherited by the four DM models.

| Model | R1 | R2 | R3 | R4 | R5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| S001 | 0.381873 | 0.254967 | 0.197776 | 0.232217 | 0.212907 |
| S002 | 0.378651 | 0.255050 | 0.204009 | 0.232095 | 0.216712 |
| S003 | 0.381165 | 0.253890 | 0.196217 | 0.229608 | 0.212053 |
| S004 | 0.376786 | 0.255231 | 0.199048 | 0.234440 | 0.212942 |
| S005 | 0.350000 | 0.240000 | 0.212000 | 0.239000 | 0.225000 |
| S006 | 0.350000 | 0.240000 | 0.212000 | 0.239000 | 0.225000 |
| S007 | 0.350000 | 0.240000 | 0.212000 | 0.239000 | 0.225000 |
| S008 | 0.350000 | 0.240000 | 0.212000 | 0.239000 | 0.225000 |
| **Median sigma** | **0.363393** | **0.246945** | **0.208005** | **0.236720** | **0.220856** |
| **Applied flag 92** | **36** | **25** | **21** | **24** | **22** |

The continuous median is retained for provenance. MFCL stores this control as
integer fish flag 92, calculated as round(100 times sigma).
