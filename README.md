# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

Kflow task for running numbered BET 2026 MFCL model folders and saving compact
model payloads for downstream results and report jobs.

## Workflow Role

```text
ofp-sam-bet-2026-stepwise -> ofp-sam-bet-2026-results -> ofp-sam-bet-2026-report
```

Each folder under `steps/` is an independent model run. Run one folder, a
comma-separated set, or all enabled rows.

## Edit Here

- `job-config.R`: model list, labels, defaults, input/output filenames, and
  evaluation counts.
- `steps/<step_id>/model/`: MFCL input files for one model.
- `steps/<step_id>/patch.R`: optional scripted edit before MFCL runs.

Run `make list` after editing `job-config.R`; it refreshes the generated README
tables and checks model folders.

## Run

```bash
make list
make local STEP_SELECT=all PROGRAM_PATH=/path/to/mfclo64
make docker STEP_SELECT=all
make kflow STEP_SELECT=all
make kflow STEP_SELECT=all TRIGGER_NEXT=false
make kflow-register-chain
```

Run several folders:

```bash
make kflow STEP_SELECT=03-RegFish,07-CAAL2026,12-DataWeight40
```

Refresh the Kflow task definitions after editing `kflow.yaml`:

```bash
export KFLOW_API_TOKEN=...
make kflow-register-chain
```

That reads each `kflow.yaml` from `KFLOW_CHAIN_REPOS` and upserts the matching
Kflow task registration. Override `KFLOW_CHAIN_REPOS` if the sibling repo paths
are different on a machine.

## Add A Model

1. Copy a folder under `steps/`.
2. Rename it with the next numbered ID, for example `13-SensitivityName`.
3. Put MFCL inputs in `steps/13-SensitivityName/model/`.
4. Add one row in `job-config.R`.
5. Run `make list`.
6. Launch with `STEP_SELECT=13-SensitivityName`.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-v2` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `mfcl_fevals` | `blank` | Blank uses the row-level `fevals` value; a number overrides selected rows. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v1.9` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `steps/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par`. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing `RUN_MODE=job_par` outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach. For `.par` reruns, set this to the same previous same-step job as `PAR_SOURCE_JOB`. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `model_label` | `job_title` | `job_key` | `run_mode` | `input_par` | `frq` | `output_par` | `fevals` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `01-Diag23` | `TRUE` | 2023 diagnostic | BET stepwise: 2023 diagnostic | `01-diag23` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `02-FixM` | `TRUE` | FixM | BET stepwise: FixM | `02-fixm` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `03-RegFish` | `TRUE` | New regions/fisheries | BET stepwise: New regions/fisheries | `03-regfish` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `04-WtAsLen21` | `TRUE` | Weights as lengths, 2021 | BET stepwise: Weights as lengths to 2021 | `04-wtaslen21` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `05-WtAsLenPlusLen21` | `TRUE` | Weights as lengths plus lengths, 2021 | BET stepwise: Weights as lengths plus lengths to 2021 | `05-wtaslenpluslen21` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `06-Full2024` | `TRUE` | Full 2024 data | BET stepwise: Full 2024 data | `06-full2024` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `07-CAAL2026` | `TRUE` | Updated CAAL | BET stepwise: Updated CAAL | `07-caal2026` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `08-MixPeriod02` | `TRUE` | Mixing periods 0.2 | BET stepwise: Mixing periods 0.2 | `08-mixperiod02` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `09-SizeBasedSel` | `TRUE` | Size-based selectivity | BET stepwise: Size-based selectivity | `09-sizebasedsel` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `10-OPR` | `TRUE` | OPR | BET stepwise: OPR | `10-opr` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `11-EffortCreep` | `TRUE` | Effort creep | BET stepwise: Effort creep | `11-effortcreep` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |
| `12-DataWeight40` | `TRUE` | Data weighting 40 | BET stepwise: Data weighting 40 | `12-dataweight40` | `doitall` | `blank` | `bet.frq` | `blank` | `1` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag23` | `steps/01-Diag23/model` | `exists` |
| `02-FixM` | `steps/02-FixM/model` | `exists` |
| `03-RegFish` | `steps/03-RegFish/model` | `exists` |
| `04-WtAsLen21` | `steps/04-WtAsLen21/model` | `exists` |
| `05-WtAsLenPlusLen21` | `steps/05-WtAsLenPlusLen21/model` | `exists` |
| `06-Full2024` | `steps/06-Full2024/model` | `exists` |
| `07-CAAL2026` | `steps/07-CAAL2026/model` | `exists` |
| `08-MixPeriod02` | `steps/08-MixPeriod02/model` | `exists` |
| `09-SizeBasedSel` | `steps/09-SizeBasedSel/model` | `exists` |
| `10-OPR` | `steps/10-OPR/model` | `exists` |
| `11-EffortCreep` | `steps/11-EffortCreep/model` | `exists` |
| `12-DataWeight40` | `steps/12-DataWeight40/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `12-DataWeight40` | Run one model folder. |
| `STEP_SELECT` | `03-RegFish,07-CAAL2026` | Run selected model folders. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_FEVALS` | `10` | Override row-level `fevals`. |
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

Map assets are stored beside each model payload as `bet.region_map.geojson` so
MFCL Shiny can find the map whether it opens the whole output root or an
individual model folder. Source assets live under `assets/maps/`, and the runner
copies only the structure needed by the selected model:

- `bet-2023-nine-region.geojson` for the legacy 01/02 diagnostic/FixM models.
- `bet-2026-five-region.geojson` for the 03+ 5-region models. This file uses
  the 2026 BET label convention where old Region 4 is labelled Region 5 and old
  Region 5 is labelled Region 4.

Kflow also exposes an `MFCL Shiny` local app on stepwise jobs. Open it from a
completed model job to inspect the selected model payload directly, without
waiting for the downstream results/report tasks. The app runs in local Docker
on your computer and reads the compact payload from the submitter over SSH.
