# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-v2` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.1` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `steps/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par`. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing `RUN_MODE=job_par` outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach. For `.par` reruns, set this to the same previous same-step job as `PAR_SOURCE_JOB`. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `major_step` | `substep` | `change_axis` | `model_label` | `job_title` | `job_key` | `run_mode` | `mfcl_program_path` | `input_par` | `frq` | `output_par` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `01-Diag2023` | `TRUE` | 01-Diagnostic | 01a | historical diagnostic | Diag2023 | 01 Diag2023 | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02a-NewExe` | `TRUE` | 02-Executable | 02a | current MFCL executable with 1003 ini | NewExe 1003 | 02a NewExe 1003 | `02a-newexe` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `02b-Ini1007` | `TRUE` | 02-Executable | 02b | promote diagnostic ini to 1007 | Ini 1007 | 02b Ini 1007 | `02b-ini1007` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `02c-LengthWeight` | `TRUE` | 02-Executable | 02c | bias-corrected 2026 length-weight parameters | Length-weight | 02c Length-weight | `02c-lengthweight` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `03-FixM` | `TRUE` | 03-FixM | 03a | fixed natural mortality from mgc=-5 diagnostic after 02c | FixM | 03 FixM | `03-fixm` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `04-NewStructure` | `TRUE` | 04-NewStructure | 04 | 5-region structure with global CPUE | New structure | 04 New structure | `04-newstructure` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `05-ConvertToLength` | `TRUE` | 05-ConvertToLength | 05a | convert weight compositions to length | Convert to length | 05 Convert to length | `05-converttolength` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `06-LengthPlusLength` | `TRUE` | 06-LengthPlusLength | 06a | add additional length compositions | Length plus length | 06 Length plus length | `06-lengthpluslength` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `07-DataTo2024` | `TRUE` | 07-DataTo2024 | 07a | 2024 data with global CPUE | Data to 2024 | 07 Data to 2024 | `07-datato2024` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `08-RegionalCPUE` | `TRUE` | 08-RegionalCPUE | 08a | regional CPUE and regional-scaling prior | Regional CPUE | 08 Regional CPUE | `08-regionalcpue` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `09-NewOtoliths` | `TRUE` | 09-NewOtoliths | 09a | new otolith/CAAL input | New otoliths | 09 New otoliths | `09-newotoliths` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `10-TagMixingKS` | `TRUE` | 10-TagMixing | 10a | release-specific tag mixing periods | Tag mixing KS | 10 Tag mixing KS | `10-tagmixingks` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11-TimeVaryingCV` | `TRUE` | 11-TimeVaryingCV | 11a | time-varying CPUE CV | Time-varying CV | 11 Time-varying CV | `11-timevaryingcv` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12-OrthogonalPoly` | `TRUE` | 12-OrthogonalPoly | 12a | orthogonal-polynomial recruitment | Orthogonal polynomial | 12 Orthogonal polynomial | `12-orthogonalpoly` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13-LengthBasedSel` | `TRUE` | 13-LengthBasedSel | 13a | length-based selectivity | Length-based selectivity | 13 Length-based selectivity | `13-lengthbasedsel` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `14-EffortCreep` | `TRUE` | 14-EffortCreep | 14a | effort creep | Effort creep | 14 Effort creep | `14-effortcreep` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |
| `15-DataWeighting` | `TRUE` | 15-DataWeighting | 15a | data weighting | Data weighting | 15 Data weighting | `15-dataweighting` | `mfclrtmb_doitall` | blank | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02a-NewExe` | `steps/02a-NewExe/model` | `exists` |
| `02b-Ini1007` | `steps/02b-Ini1007/model` | `exists` |
| `02c-LengthWeight` | `steps/02c-LengthWeight/model` | `exists` |
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
