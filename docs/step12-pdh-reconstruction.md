# Step 12 PDH reconstruction

This branch reconstructs the reviewed Step 12 PDH model as a reproducible
stepwise sequence. The reference `frq`, `ini`, `tag`, age-length, regional
scaling, and MFCL configuration files are byte-identical to the corresponding
Step 12 files on `main`; the model differences are therefore confined to the
documented `doitall.sh` controls and fitted parameters.

## Step placement

| Step | Change |
| --- | --- |
| `04-NewStructure` | Keeps the first 5-region / 33-fishery model as the clean structural comparison. |
| `04a-SelectivityReview` | Adds the five reviewed fishery-level LF/selectivity controls without changing any data input. |
| `05`-`11` | Inherit `04a` and retain each step's original single change. |
| `12-OrthogonalPoly` | Adds OPR `72-01-50-50`, a two-calendar-year terminal window, and a separate final terminal-recruitment penalty refinement. |
| `13`-`15` | Inherit the reconstructed Step 12 controls and retain each later step's original change. |

## Reviewed LF/selectivity controls

| Fishery | Control | Fit rationale |
| --- | --- | --- |
| F20 | `ff(16)=0`, `ff(3)=37` | Restore flexibility to predict observed large fish. |
| F28 | `ff(16)=0`, `ff(3)=37` | Restore flexibility to predict observed large fish. |
| F26 | `ff(75)=1` | Avoid predicting an unsupported age-class-1 catch. |
| F12 | `ff(75)=2` | Avoid predicting unsupported age-class-1 and age-class-2 catches. |
| F17 | `ff(16)=2`, `ff(3)=6` | Reduce over-prediction of large fish. |

These values reproduce the reference PDH PAR exactly. They are intentionally
not propagated to additional fisheries in this reconstruction.

## OPR and terminal recruitment

| Flag | Value | Role |
| --- | ---: | --- |
| `pf155` | 72 | OPR year effect. |
| `pf217` | 1 | OPR season effect. |
| `pf216` | 50 | OPR region effect. |
| `pf218` | 50 | OPR region-season interaction. |
| `pf202` | 2 | Terminal window in calendar years: 8 quarters with `age_flag(57)=4`. |
| `pf397` | 100 | Activates the terminal-recruitment penalty in MFCL 2.2.7.9; effective coefficient is `100/10=10`. |

The base OPR model is fitted through PHASE 11 with `pf397=0`. PHASE 12 starts
from `11.par`, sets `pf397=100`, and writes `12.par`. The default PHASE 12
evaluation ceiling and convergence criterion (`20000`, `-5`) retain the
optimizer state recorded in the reference PAR. They can be reduced for smoke
tests with `BET_PDH_TERMINAL_EVALUATIONS` and
`BET_PDH_TERMINAL_CONVERGENCE`.

`pf221=72` is retained solely for reference-PAR parity. It is obsolete in the
reviewed source and does not change the verified MFCL 2.2.7.9 objective or
terminal penalty.

## Reference checks

| Check | Result |
| --- | ---: |
| MFCL version | 2.2.7.9 (2026-07-11) |
| MFCL executable SHA-256 | `02e12dbdf2a564983e9fb50baf095ff472ba3831f71ecc0e3082f49478dac723` |
| Objective | -379234.727698822 |
| Maximum absolute gradient | 0.0002299296 |
| Active parameters | 1093 |
| Non-positive Hessian eigenvalues | 0 |
| Reference PAR SHA-256 | `ff9129860ee9545d96f1c5e9e9548358b02d03b52b15eb624bf4ecd5bed54627` |

The fitted parameter values themselves are not copied into earlier steps.
Each step must refit its own model; the reconstruction preserves the observed
control state and phase sequence that produced the PDH reference.
