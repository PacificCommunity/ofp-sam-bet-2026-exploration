# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-regw-grid-f25-f26-separate-n7-20260723` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `false` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `sensitivity/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_save_raw_mfcl_inputs` | `true` | Preserve the full raw MFCL input folder under `outputs/models/<step_id>/mfcl-inputs/` for native-style auditability. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par`. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing `RUN_MODE=job_par` outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach. For `.par` reruns, set this to the same previous same-step job as `PAR_SOURCE_JOB`. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `major_step` | `substep` | `change_axis` | `model_label` | `run_mode` | `frq` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `S001-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RRPTTP26` | `TRUE` | 1 |  1 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW11, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S002-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RRPTTP26` | `TRUE` | 1 |  2 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW25, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S003-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RR8-10` | `TRUE` | 1 |  3 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW11, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S004-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RR8-10` | `TRUE` | 1 |  4 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW25, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S005-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RRPTTP26` | `TRUE` | 2 |  5 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW11, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RRPTTP26` | `TRUE` | 2 |  6 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW25, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10` | `TRUE` | 2 |  7 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW11, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S008-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RR8-10` | `TRUE` | 2 |  8 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW25, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S009-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RRPTTP26` | `TRUE` | 1 |  9 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW100, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S010-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RR8-10` | `TRUE` | 1 | 10 | DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax15, REGW100, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S011-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RRPTTP26` | `TRUE` | 2 | 11 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW100, PTTP26, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |
| `S012-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RR8-10` | `TRUE` | 2 | 12 | DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities | DM G8PSSET Nmax25, REGW100, RR8/10, F25/F26 separate N7, common CPUE sigma | `doitall` | `bet.frq` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `S001-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RRPTTP26` | `steps/S001-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RRPTTP26/model` | `missing` |
| `S002-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RRPTTP26` | `steps/S002-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RRPTTP26/model` | `missing` |
| `S003-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RR8-10` | `steps/S003-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RR8-10/model` | `missing` |
| `S004-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RR8-10` | `steps/S004-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RR8-10/model` | `missing` |
| `S005-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RRPTTP26` | `steps/S005-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RRPTTP26/model` | `missing` |
| `S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RRPTTP26` | `steps/S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RRPTTP26/model` | `missing` |
| `S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10` | `steps/S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10/model` | `missing` |
| `S008-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RR8-10` | `steps/S008-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RR8-10/model` | `missing` |
| `S009-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RRPTTP26` | `steps/S009-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RRPTTP26/model` | `missing` |
| `S010-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RR8-10` | `steps/S010-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RR8-10/model` | `missing` |
| `S011-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RRPTTP26` | `steps/S011-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RRPTTP26/model` | `missing` |
| `S012-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RR8-10` | `steps/S012-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RR8-10/model` | `missing` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `13-DataWeighting` | Run one model folder. |
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

Saved artifacts include compact plot payloads plus the raw MFCL input folder
used for the run:

```text
outputs/model-index.csv
outputs/selected-steps.csv
outputs/saved-pars.csv
outputs/region-map/<project-map>.geojson
outputs/models/<step_id>/model_payload.rds
outputs/models/<step_id>/model_payload_manifest.json
outputs/models/<step_id>/final.par
outputs/models/<step_id>/mfcl-inputs/
outputs/models/<step_id>/bet.region_map.geojson
```

Final `.par` files are archived in the Kflow output as
`outputs/models/<step_id>/final.par`. For a later rerun, set `RUN_MODE=job_par`,
set `PAR_SOURCE_JOB` to the previous same-step job number, and attach that same
job with `KFLOW_INPUT_JOBS`.

The raw MFCL inputs are preserved under
`outputs/models/<step_id>/mfcl-inputs/` so files such as `.frq`, `.tag`,
`.age_length`, and `.reg_scaling` can be audited exactly as read by native MFCL.

Region-map assets are copied from `assets/maps/`. The root `outputs/region-map/`
folder stores shared project-specific GeoJSON files, and each model output also
gets `bet.region_map.geojson` beside its payload.
