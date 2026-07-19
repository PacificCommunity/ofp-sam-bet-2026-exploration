# Francis TA1.8 LF reweighting

This branch applies fishery-level Francis TA1.8 length-composition weights
calculated from the fitted output of Kflow job 9764.

- Calculator: `mfclkit::mfk_francis_ta18_from_lenfit()`
- Patcher: `mfclkit::mfk_patch_doitall_francis()`
- mfclkit commit: `b51429c8de9d9b007338250c599bc76086c64f13`
- Authoritative controls: fitted `final.par` paired with its `bet.frq`
- MFCL LF likelihood flag: `141 = 3` (robust normal)
- Tail controls: `311 = 1`, `312 = 50`, `313 = 1`
- MFCL raw-sample cap used by the calculation: `1000`
- Bootstrap: 1,000 record-level replicates with seed 9764
- Upweighting: allowed, following the unconstrained original TA1.8 target

The recommended integer divisors are inserted as fishery-specific flag 49
overrides inside the mfclkit marker block in each selected `doitall.sh`.
The original global and legacy fishery overrides remain visible for audit.
No `.ini`, `.frq`, age-length, tag, or regional-scaling file is changed.

Applied models:
- `S001-TC1-NOCUT-BASE075-TAGF2OFF`
- `S002-TC1-NOCUT-BASE075-TAGF2ON`
- `S003-TC1-CUT90-BASE075-TAGF2OFF`
- `S004-TC1-CUT90-BASE075-TAGF2ON`

Machine-readable values: `job-9764-francis-divisors.csv`.
