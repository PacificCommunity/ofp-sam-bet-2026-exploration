# BET 2026 Stepwise

Kflow task repository for BET 2026 stepwise MFCL model runs.

This repository is organized around numbered model folders under `steps/`. Each
folder is one independent model that can be run alone, together with selected
other folders, or as part of the full stepwise -> plot -> report Kflow chain.

## What To Edit

Most routine edits should happen in only two places:

- `job-config.R`: choose default settings and register each model row.
- `steps/<step_id>/model/`: keep the MFCL input files for that model.

README tables are refreshed automatically before the main Makefile run targets.
Those targets also enable the local pre-commit hook for later commits in the
checkout.

Internal R helper functions live in `R/stepwise_config_helpers.R`; they should
not be edited when adding ordinary model runs.

Use `patch.R` inside a step folder only when a model needs a small scripted edit
before MFCL runs. Each step folder is independent, so a new sensitivity, review,
self-test, or diagnostic-style model should usually be a new numbered folder
under `steps/`.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `01-base-11par` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-x111` | Kflow group label used to connect stepwise, plot, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream plot/report chain. |
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


## Run Modes

`last_par` continues from a numbered `.par` file and writes the next numbered
file. For example, `11.par` becomes `12.par`. This is the usual quick
model-check mode.

`single` runs exactly the listed input and output `.par` files. Use it when the
output name should be explicit instead of inferred.

`doitall` runs `doitall.sh` from the model folder. `MFCL_FEVALS` is only passed
as an environment variable in this mode; the script must read it explicitly if a
quick test should use it.

## Launch Examples

```bash
make list
make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64
make docker STEP_SELECT=01-base-11par
make kflow STEP_SELECT=01-base-11par
make kflow STEP_SELECT=01-base-11par TRIGGER_NEXT=false
```

Use comma-separated model IDs to run several independent folders in one job:

```bash
make docker STEP_SELECT=01-base-11par,03-review-11par
make kflow STEP_SELECT=01-base-11par,03-review-11par
```

## Adding A Model

1. Copy an existing folder under `steps/`.
2. Rename it with the next numbered ID, such as `04-steepness-low`.
3. Put the model's MFCL inputs in `steps/04-steepness-low/model/`.
4. Copy one row in `job-config.R`.
5. Update `step_id`, `model_label`, `job_title`, `job_key`, `run_mode`,
   `input_par`, `frq`, `output_par`, and `fevals`.
6. Run `make list` to refresh the README tables and check the row.
7. Launch the selected model with `STEP_SELECT=04-steepness-low`.

## Useful Launch Fields

| Field | Example | Meaning |
| --- | --- | --- |
| `STEP_SELECT` | `01-base-11par` | Run one model folder. |
| `STEP_SELECT` | `01-base-11par,03-review-11par` | Run selected independent folders. |
| `STEP_SELECT` | `all` | Run every row where `enabled` is `TRUE`. |
| `MFCL_FEVALS` | `10` | Override `fevals` for `last_par` and `single` jobs. |
| `MFCL_LIVE_LOG` | `true` | Stream the full MFCL output into the Kflow log view. |
| `MFCL_LIVE_LOG` | `false` | Keep the Kflow log quieter. |
| `JOB_TITLE` | `BET stepwise: Base 11.par` | Human title shown in Kflow. |
| `JOB_KEY` | `01-base-11par` | Stable label used by Kflow dependency selectors. |
| `TRIGGER_NEXT` | `false` | Command-line override to submit only the selected stepwise model without plot/report follow-up. |

## Downstream Jobs

Kflow stores the normal dependency chain as `stepwise -> plot -> report`. The
`stepwise_run$trigger_next` value controls the default behavior for command-line
submissions through `make kflow`.

Set `TRIGGER_NEXT=false` for a one-off model-only run:

```bash
make kflow STEP_SELECT=01-base-11par TRIGGER_NEXT=false
```

Keep `TRIGGER_NEXT=true` when the selected model should feed the plot and report
tasks after the stepwise job succeeds.

## Shortcut Commands

| Command | Purpose |
| --- | --- |
| `make readme` | Force-refresh README tables from `job-config.R`. |
| `make list` | Refresh README tables, enable the commit hook, then show the rows in `job-config.R`. |
| `make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64` | Run directly on this machine. |
| `make docker STEP_SELECT=01-base-11par` | Run locally inside `ghcr.io/pacificcommunity/tuna-flow:v1.5`. |
| `make kflow STEP_SELECT=01-base-11par` | Submit the selected model folder to Kflow from a configured shell. |
| `make fix-permissions` | Repair root-owned local Docker outputs or runtime cache files. |
| `make clean` | Remove generated local outputs and runtime cache folders. |

## Outputs

Outputs are written under `outputs/models/<step_id>/` and include only
`model_payload.rds` and the final `.par` file from the run. The top-level
`outputs/model-index.csv` and `outputs/selected-steps.csv` give a compact run
summary for Kflow and the downstream plot task. MFCL detail is visible in the
live Kflow log but is not kept as a saved artifact.

The default input files are copied into each starter model folder under
`steps/<step_id>/model/`, so every model folder is self-contained. Docker runs
use the MFCL executable bundled in the tuna-flow image at `/home/mfcl/mfclo64`
by default. Local Docker runs use your host UID/GID so generated files can be
cleaned up without `sudo`. For local non-Docker testing, override the executable
with `PROGRAM_PATH=/path/to/mfclo64`.
