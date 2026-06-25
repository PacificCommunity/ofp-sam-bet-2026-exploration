# R Helpers

These scripts keep the BET 2026 stepwise inputs, Kflow notes, and map assets
reproducible.

| Script | Purpose |
| --- | --- |
| `prepare_bet_2026_step_inputs.R` | Rebuilds `steps/` inputs from the source repos, writes manifests/READMEs, and removes generated `.par` files. |
| `run_stepwise.R` | Kflow/local runner for selected step folders; runs MFCL and writes compact outputs. |
| `stepwise_config_helpers.R` | Helpers used by the Makefile to read `job-config.R` and derive Kflow labels/keys. |
| `update_readme.R` | Regenerates `docs/run-configuration.md` from `job-config.R` and `kflow.yaml`. |
| `write_bet_region_map_assets.R` | Writes lightweight GeoJSON/map preview assets used by mfclshiny. |

Routine step edits usually belong in `job-config.R` or
`prepare_bet_2026_step_inputs.R`; Kflow/runtime defaults belong in `kflow.yaml`.
