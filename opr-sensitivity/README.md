# BET 2026 Recruitment OPR Sensitivities

These 39 models start from `S002-TC1-NOCUT-DW1` and change only the
recruitment orthogonal-polynomial controls in `doitall.sh`.

## Fixed controls

- Global LF tail compression: 1%
- F21/F22/F23 cutoff: none
- F21/F22/F23 LF downweight: 1x
- Regional-scaling weight: 50
- Job 5319 effort-creep FRQ inherited unchanged; no duplicate transform

## OPR design

- Saturated annual/end pairs: Y73-E1, Y72-E2, Y71-E3
- Terminal penalty: parest 397=0 or 100 (native weight 0 or 10)
- Season time-basis sizes: 1 (constant), 3 (quadratic), 5 (quartic)
- Region and interaction time-basis sizes: 50, 15, and 5

The complete machine-readable design is in `manifest.csv`.
No model in this directory has been submitted to Kflow.
