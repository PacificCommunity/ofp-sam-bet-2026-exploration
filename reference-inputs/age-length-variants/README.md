# BET 2026 age-length variants

These inputs support the five-level age-length factorial on `experiment/tc1-pdh-only`.

Source repository: <https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-age-length-build>

Source commit: `96a06d21ef3c666f39ce456d3a6818b6c17324c4`

| Label | Model input | Meaning |
| --- | --- | --- |
| `BASE075` | `reference-inputs/job-5319/mfcl-inputs/bet.age_length` | Current 2026 base body with the 181 effective-sample-size values set to 0.75 |
| `REG075` | `bet.2026.regional.0.75.age_length` | Exact regional 0.75 source input |
| `REG100` | `bet.2026.regional.1.age_length` | Exact regional 1.00 source input |
| `SUB075` | `bet.2026.sub.basin.0.75.age_length` | Exact sub-basin 0.75 source input |
| `SUB100` | `bet.2026.sub.basin.1.age_length` | Exact sub-basin 1.00 source input |

The source `BET/bet.2026.age_length` is not a sixth factorial level. It is the BASE100 provenance anchor for `BASE075`: the two files have identical structure and body except for the single 181-value `# effective sample size` row, which is all 1 in the source and all 0.75 in the current model input.

`PROVENANCE.csv` records the original paths and SHA-256 checksums. The four files in this directory are byte-identical copies from the pinned source commit.
