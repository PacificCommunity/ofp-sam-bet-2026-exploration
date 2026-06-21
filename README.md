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
- `metadata/`: optional labels used by downstream plots and reports.

Run `make list` after editing `job-config.R`; it refreshes the generated README
tables and checks model folders.

## Run

```bash
make list
make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64
make docker STEP_SELECT=01-base-11par
make kflow STEP_SELECT=01-base-11par
make kflow STEP_SELECT=01-base-11par TRIGGER_NEXT=false
```

Run several folders:

```bash
make kflow STEP_SELECT=01-base-11par,03-review-11par
```

## Add A Model

1. Copy a folder under `steps/`.
2. Rename it with the next numbered ID, for example `04-steepness-low`.
3. Put MFCL inputs in `steps/04-steepness-low/model/`.
4. Add one row in `job-config.R`.
5. Run `make list`.
6. Launch with `STEP_SELECT=04-steepness-low`.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `01-base-11par` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-base` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `mfcl_fevals` | `blank` | Blank uses the row-level `fevals` value; a number overrides selected rows. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v1.6` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `model_label` | `job_title` | `job_key` | `run_mode` | `input_par` | `frq` | `output_par` | `fevals` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `01-base-11par` | `TRUE` | Base 11.par | BET stepwise: Base 11.par | `01-base-11par` | `last_par` | `11.par` | `bet.frq` | `blank` | `1` |
| `02-continue-11par` | `TRUE` | Base 11.par model 02 | BET stepwise: Base 11.par model 02 | `02-continue-11par` | `last_par` | `11.par` | `bet.frq` | `blank` | `1` |
| `03-review-11par` | `TRUE` | Base 11.par model 03 | BET stepwise: Base 11.par model 03 | `03-review-11par` | `last_par` | `11.par` | `bet.frq` | `blank` | `1` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-base-11par` | `steps/01-base-11par/model` | `exists` |
| `02-continue-11par` | `steps/02-continue-11par/model` | `exists` |
| `03-review-11par` | `steps/03-review-11par/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `01-base-11par` | Run one model folder. |
| `STEP_SELECT` | `01-base-11par,03-review-11par` | Run selected model folders. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_FEVALS` | `10` | Override row-level `fevals`. |
| `MFCL_LIVE_LOG` | `true` | Stream MFCL output into the Kflow log. |
| `TRIGGER_NEXT` | `false` | Stop after stepwise; do not launch results/report. |
| `FLOW_GROUP` | `bet-2026-base` | Shared label for the chain. |

## Outputs

Saved artifacts are intentionally compact:

```text
outputs/model-index.csv
outputs/selected-steps.csv
outputs/models/<step_id>/model_payload.rds
outputs/models/<step_id>/<final-par-file>
```

Bulky raw inputs and intermediate files such as `.frq`, `.tag`, and
`temporary_tag_report` are not kept in the Kflow artifact.
