# OPR008-Y73-E1-TP100-S03-R50-I50

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
| Annual temporal coefficients, parest 155 | 73 |
| Terminal window in calendar years, parest 202 | 1 |
| Season temporal coefficients, parest 217 | 3 |
| Region temporal coefficients, parest 216 | 50 |
| Region-season temporal coefficients, parest 218 | 50 |
| Terminal penalty flag, parest 397 | 100 |

Terminal penalty: ON: parest 397=100 (native MFCL weight 10), activated in the final refinement.
Design role: quadratic temporal change in seasonal contrasts.
The annual/end pair is saturated for the 1952-2024 annual basis.
No MFCL source code or executable is modified.

Status: generated; not submitted to Kflow.
