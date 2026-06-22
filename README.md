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
```

Run several folders:

```bash
make kflow STEP_SELECT=03-RegFish,07-CAAL2026,12-DataWeight40
```

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
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v1.7` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |


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
