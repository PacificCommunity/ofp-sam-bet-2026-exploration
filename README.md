# BET 2026 Stepwise

This repository stores the BET 2026 MFCL stepwise model inputs. Each numbered
folder under `steps/` is one model in the stepwise path, with its model folder
and notes.

## Step Path

| Step | Purpose |
| --- | --- |
| `01-Diag23` | 2023 diagnostic starting point |
| `02-FixM` | FixM update |
| `03-RegFish` | 5-region / 33-fishery structure |
| `04-WtAsLen21` | weights-as-lengths data to 2021 |
| `05-WtAsLenPlusLen21` | weights-as-lengths plus lengths to 2021 |
| `06-Full2024` | full 2024 data |
| `07-CAAL2026` | updated 2026 CAAL |
| `08-MixPeriod02` | release-group mixing periods from the 0.2 KS cutoff |
| `09-SizeBasedSel` | size-based selectivity |
| `10-OPR` | OPR recruitment setting selected from BET screening |
| `11-EffortCreep` | agreed index-fishery effort creep |
| `12-DataWeight40` | initial LF/WF divisor-40 weighting run |

## Where To Look

- `steps/<step_id>/README.md`: model-specific inputs, controls, and notes.
- `steps/<step_id>/input_manifest.csv`: machine-readable source files and commits for generated 2026 input steps.
- `steps/<step_id>/model/`: MFCL-ready model folder.
- `docs/`: focused notes such as OPR, tag reporting-rate groups, region map assets, and run configuration.
- `debugging/`: troubleshooting records and checks made while preparing the inputs.
- `R/prepare_bet_2026_step_inputs.R`: reproducible input-generation script.

## Current Notes

- Steps 06-12 use `bet.reg_scaling` over periods 53-72, matching Thom's 1965-1969 global CPUE covariance window.
- Step 11 applies John Hampton's effort-creep note to index fisheries 29-33: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.
- Steps 01-02 use the 2023 BET 9-region GeoJSON asset; steps 03-12 use the 2026 5-region asset. See [`docs/region-map-assets.md`](docs/region-map-assets.md).
- `tag_rep_map.R` files are generated audit maps derived from `bet.ini` reporting-rate matrices and `bet.tag` release metadata; MFCL reads the `.ini`, not `tag_rep_map.R`. The reporting-rate grouping tables are in [`docs/tag-reporting-groups.md`](docs/tag-reporting-groups.md).

Operational Kflow/local run details are kept in [`docs/run-configuration.md`](docs/run-configuration.md).
