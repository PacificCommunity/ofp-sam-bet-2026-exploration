# R Helpers

These scripts keep the BET 2026 stepwise inputs, Kflow notes, and map assets
reproducible.

| Script | Purpose |
| --- | --- |
| `prepare_bet_2026_step_inputs.R` | Entry point for rebuilding `steps/`; holds input-root setup and the step definitions. |
| `prepare_common.R` | Shared file, provenance, regional-scaling, and small text helpers. |
| `prepare_mfcl_inputs.R` | MFCL `.frq`, `.ini`, `.tag`, tag-reporting, and effort-creep input helpers. |
| `prepare_readme_manifest.R` | Writers for `input_manifest.csv` and per-step README files. |
| `prepare_doitall.R` | `doitall.sh` patch helpers for convergence, OPR, data weighting, regional scaling, and selectivity. |
| `prepare_step_builder.R` | The `make_step()` constructor used by the generated 2026 steps. |
| `run_stepwise.R` | Kflow/local runner for selected step folders; runs MFCL and writes compact outputs. |
| `stepwise_config_helpers.R` | Helpers used by the Makefile to read `job-config.R` and derive Kflow labels/keys. |
| `update_readme.R` | Regenerates `docs/run-configuration.md` from `job-config.R` and `kflow.yaml`. |
| `write_bet_region_map_assets.R` | Writes lightweight GeoJSON/map preview assets used by mfclshiny. |

Routine step edits usually belong in `job-config.R` or
`prepare_bet_2026_step_inputs.R`; reusable input transformations belong in the
`prepare_*` helper files. Kflow/runtime defaults belong in `kflow.yaml`.
