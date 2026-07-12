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
| `12-OrthogonalPoly` | Adds OPR `72-01-50-50`, a two-calendar-year terminal window, and the terminal-recruitment penalty in final PHASE 11. |
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

The base OPR controls are fitted through PHASE 10 with `pf397=0`. Final
PHASE 11 starts from `10.par`, sets `pf397=100`, and writes `11.par`; no
PHASE 12 or `12.par` is used. Its default evaluation ceiling is `20000`, which
can be reduced with `BET_PDH_TERMINAL_EVALUATIONS`. Convergence uses the same
`BET_PHASE10_11_CONVERGENCE` setting as every other final step (`-4` for the
planned parallel run; `-5` for a stricter reference comparison).

This shorter staging preserves the reviewed final controls but is not the
same optimizer path as the reference run, which added the penalty after an
unpenalized `11.par`. The objective and PDH status therefore need to be
confirmed from the new PHASE-11-only fit rather than assumed from the reference.

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
