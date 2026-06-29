# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-v2` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.0` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `steps/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par`. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing `RUN_MODE=job_par` outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach. For `.par` reruns, set this to the same previous same-step job as `PAR_SOURCE_JOB`. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `model_label` | `job_title` | `job_key` | `run_mode` | `mfcl_program_path` | `input_par` | `frq` | `output_par` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `01-Diag2023` | `TRUE` | Diag2023 | Diag2023 | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02-NewExe` | `TRUE` | NewExe | NewExe | `02-newexe` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `03-FixM` | `TRUE` | FixM | FixM | `03-fixm` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `04-NewStructure` | `TRUE` | New structure | New structure | `04-newstructure` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `05-ConvertToLength` | `TRUE` | Convert to length | Convert to length | `05-converttolength` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `06-LengthPlusLength` | `TRUE` | Length plus length | Length plus length | `06-lengthpluslength` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `07-DataTo2024` | `TRUE` | Data to 2024 | Data to 2024 | `07-datato2024` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `08-RegionalCPUE` | `TRUE` | Regional CPUE | Regional CPUE | `08-regionalcpue` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `09-NewOtoliths` | `TRUE` | New otoliths | New otoliths | `09-newotoliths` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `10-TagMixingKS` | `TRUE` | Tag mixing KS | Tag mixing KS | `10-tagmixingks` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11-TimeVaryingCV` | `TRUE` | Time-varying CV | Time-varying CV | `11-timevaryingcv` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12-OrthogonalPoly` | `TRUE` | Orthogonal polynomial | Orthogonal polynomial | `12-orthogonalpoly` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13-LengthBasedSel` | `TRUE` | Length-based selectivity | Length-based selectivity | `13-lengthbasedsel` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `14-EffortCreep` | `TRUE` | Effort creep | Effort creep | `14-effortcreep` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `15-DataWeighting` | `TRUE` | Data weighting | Data weighting | `15-dataweighting` | `doitall` | blank | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02-NewExe` | `steps/02-NewExe/model` | `exists` |
| `03-FixM` | `steps/03-FixM/model` | `exists` |
| `04-NewStructure` | `steps/04-NewStructure/model` | `exists` |
| `05-ConvertToLength` | `steps/05-ConvertToLength/model` | `exists` |
| `06-LengthPlusLength` | `steps/06-LengthPlusLength/model` | `exists` |
| `07-DataTo2024` | `steps/07-DataTo2024/model` | `exists` |
| `08-RegionalCPUE` | `steps/08-RegionalCPUE/model` | `exists` |
| `09-NewOtoliths` | `steps/09-NewOtoliths/model` | `exists` |
| `10-TagMixingKS` | `steps/10-TagMixingKS/model` | `exists` |
| `11-TimeVaryingCV` | `steps/11-TimeVaryingCV/model` | `exists` |
| `12-OrthogonalPoly` | `steps/12-OrthogonalPoly/model` | `exists` |
| `13-LengthBasedSel` | `steps/13-LengthBasedSel/model` | `exists` |
| `14-EffortCreep` | `steps/14-EffortCreep/model` | `exists` |
| `15-DataWeighting` | `steps/15-DataWeighting/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `15-DataWeighting` | Run one model folder. |
| `STEP_SELECT` | `08-RegionalCPUE,09-NewOtoliths` | Run selected model folders. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_LIVE_LOG` | `true` | Stream MFCL output into the Kflow log. |
| `RUN_MODE` | `job_par` | Rerun from a previous Kflow job output `.par`. Use this with `PAR_SOURCE_JOB` and `KFLOW_INPUT_JOBS`. |
| `PAR_SOURCE_JOB` | `354` | Previous same-step job number to search for `outputs/models/<step_id>/final.par`. |
| `KFLOW_INPUT_JOBS` | `354` | Previous job number to attach as an input archive for the rerun. Usually the same value as `PAR_SOURCE_JOB`. |
| `INPUT_PAR` | `123.par` | Continue from one specific `.par` already in the selected model folder; if it is missing, the runner logs that and falls back to `doitall`. |
| `STEPWISE_COMMIT_FINAL_PARS` | `false` | Optional legacy path to commit final `.par` files back to this repo. Keep off for parallel Kflow runs. |
| `STEPWISE_PUSH_FINAL_PARS` | `false` | Optional legacy path to push the `.par` commit to GitHub. Keep off for parallel Kflow runs. |
| `TRIGGER_NEXT` | `false` | Stop after stepwise; do not launch results/report. |
| `FLOW_GROUP` | `bet-2026-base` | Shared label for the chain. |

## Outputs

Saved artifacts are intentionally compact:

```text
outputs/model-index.csv
outputs/selected-steps.csv
outputs/saved-pars.csv
outputs/region-map/<project-map>.geojson
outputs/models/<step_id>/model_payload.rds
outputs/models/<step_id>/model_payload_manifest.json
outputs/models/<step_id>/final.par
outputs/models/<step_id>/bet.region_map.geojson
```

Final `.par` files are archived in the Kflow output as
`outputs/models/<step_id>/final.par`. For a later rerun, set `RUN_MODE=job_par`,
set `PAR_SOURCE_JOB` to the previous same-step job number, and attach that same
job with `KFLOW_INPUT_JOBS`.

Bulky raw inputs and intermediate files such as `.frq`, `.tag`, and
`temporary_tag_report` are not kept in the Kflow artifact.

Region-map assets are copied from `assets/maps/`. The root `outputs/region-map/`
folder stores shared project-specific GeoJSON files, and each model output also
gets `bet.region_map.geojson` beside its payload.
