# BET 2026 TC1 PDH sensitivity shortlist

This branch retains the four `TC=1` LF-conflict sensitivities with a positive-definite Hessian (PDH). The full 36-model factorial design remains on `main`.

## Selected models

| Model | LF cutoff | LF downweight | Hessian PDH | Non-positive eigenvalues | Smallest eigenvalue |
|---|---:|---:|:---:|---:|---:|
| `S010-TC1-CUT70-DW1` | 70 cm | 1 | Yes | 0 | 1.719e-7 |
| `S014-TC1-NOCUT-DW10` | None | 10 | Yes | 0 | 6.438e-8 |
| `S022-TC1-CUT70-DW10` | 70 cm | 10 | Yes | 0 | 1.328e-7 |
| `S034-TC1-CUT70-DW100` | 70 cm | 100 | Yes | 0 | 1.091e-7 |

The machine-readable selection is in [`PDH_SELECTION.csv`](PDH_SELECTION.csv).

## Input provenance

- Model snapshots are inherited from exploration `main` commit `ef267dc`.
- The tag-group `.ini` is from stepwise commit `26c74dc6f303faa951b1ab331d7de14ea20b7489`.
- The tag observations are from tag-prep commit `79733c429b320e84ed5047aa6c932c8f19dab187`.
- The archived Job 5319 FRQ and `doitall.sh` are retained; effort creep is not reapplied.
- Active regional scaling is `20 x 5`; the complete `292 x 5` source matrix is retained for alternative period sensitivities.

Only the four directories listed above are run candidates on this branch. Use `main` to regenerate or inspect the complete 36-model design.
