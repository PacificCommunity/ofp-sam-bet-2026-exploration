# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

This repository stores the BET 2026 MFCL stepwise model inputs. Each numbered
folder under `steps/` is one model in the stepwise path, with its model folder
and notes.

## Step Path

| Step | Purpose |
| --- | --- |
| `01-Diag2023` | original 2023 diagnostic rerun with historical MFCL |
| `02-NewExe` | current executable compatibility baseline |
| `03-FixM` | FixM update at the 2023 MLE value |
| `04-NewStructure` | 5-region / 33-fishery structure with global CPUE |
| `05-ConvertToLength` | convert existing weight compositions to length |
| `06-LengthPlusLength` | add additional length compositions |
| `07-DataTo2024` | add data to 2024 with global CPUE |
| `08-RegionalCPUE` | regional CPUE and regional-scaling prior |
| `09-NewOtoliths` | updated 2026 CAAL / new otoliths |
| `10-TagMixingKS` | release-group mixing periods from the 0.2 KS cutoff |
| `11-TimeVaryingCV` | time-varying CPUE CV |
| `12-OrthogonalPoly` | OPR recruitment setting selected from BET screening |
| `13-LengthBasedSel` | length-based selectivity |
| `14-EffortCreep` | agreed index-fishery effort creep |
| `15-DataWeighting` | initial data-weighting run |

## Where To Look

- `steps/<step_id>/README.md`: model-specific inputs, controls, and notes.
- `steps/<step_id>/input_manifest.csv`: machine-readable source files and commits for generated 2026 input steps.
- `steps/<step_id>/model/`: MFCL-ready model folder.
- `docs/`: focused notes such as OPR, tag reporting-rate groups, region map assets, and run configuration.
- `debugging/`: troubleshooting records and checks made while preparing the inputs.
- `R/prepare_bet_2026_step_inputs.R`: reproducible input-generation script.

## Assessment Notes

- Steps 08-15 use `bet.reg_scaling` over periods 53-72, matching the 1965-1969 global CPUE covariance-estimation window with the broadest spatial-temporal coverage.
- Steps 14-15 apply the agreed index-fishery effort-creep scenario to fisheries 29-33: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024.
- Steps 01-03 use the 2023 BET 9-region GeoJSON asset; steps 04-15 use the 2026 5-region asset. See [`docs/region-map-assets.md`](docs/region-map-assets.md).
- `tag_rep_map.R` files are generated audit maps derived from `bet.ini` reporting-rate matrices and `bet.tag` release metadata; MFCL reads the `.ini`, not `tag_rep_map.R`. The reporting-rate grouping tables are in [`docs/tag-reporting-groups.md`](docs/tag-reporting-groups.md).

Operational Kflow/local run details are kept in [`docs/run-configuration.md`](docs/run-configuration.md).
