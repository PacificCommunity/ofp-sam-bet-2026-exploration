# OPR033-Y72-E2-TP000-S01-R15-I15

This model is one BET 2026 recruitment OPR sensitivity.

## Fixed base controls

- Base model: `S002-TC1-NOCUT-DW1`
- Global LF tail compression: 1%
- F21/F22/F23 upper-length cutoff: none
- F21/F22/F23 LF downweight: 1x (flag-49 divisor 20)
- Regional-scaling weight: 50
- Effort creep: inherited once from Job 5319; not reapplied

## OPR settings

| Control | Value |
| --- | ---: |
| Annual temporal coefficients, parest 155 | 72 |
| Terminal window in calendar years, parest 202 | 2 |
| Season temporal coefficients, parest 217 | 1 |
| Region temporal coefficients, parest 216 | 15 |
| Region-season temporal coefficients, parest 218 | 15 |
| Terminal penalty flag, parest 397 | 0 |

Terminal penalty: OFF: parest 397=0 throughout.
Design role: balanced moderate region and interaction temporal flexibility.
The annual/end pair is saturated for the 1952-2024 annual basis.
No MFCL source code or executable is modified.

Status: generated; not submitted to Kflow.
