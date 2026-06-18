# BET 2026 Stepwise

Kflow task repository for BET 2026 model runs.

The task runs numbered model folders under `steps/`. Each folder is one
independent model. To add a model, copy an existing folder, give it the next
number, and add the row to `stepwise-config.R`.

Current starter sequence:

- `steps/01-base-11par`: quick base run from `11.par` in
  `steps/01-base-11par/model/`.
- `steps/02-continue-11par`: independent model folder from the same `11.par`.
- `steps/03-review-11par`: independent model folder from the same `11.par`.

The main user-editable file is `stepwise-config.R` in the repo root:

- `step_id`: folder name under `steps/`.
- `enabled`: set `false` to keep a model documented without running it.
- `model_label`: short label used in Kflow and downstream plots.
- `run_mode`: how to run the model. Use `last_par` to continue from the latest
  numbered `.par` and write the next number, `doitall` to run `doitall.sh`, or
  `single` to use the listed `input_par` and `output_par`.
- `source_dir`: optional source folder. Leave blank to auto-detect files in
  `steps/<step-id>/model`, then directly in `steps/<step-id>/`.
- `input_par`: starting par file, or `latest`.
- `frq`: MFCL frequency file name.
- `output_par`: optional explicit output par for `single` or `last_par`. Leave
  blank with `last_par` to write the next numbered par, for example `11.par`
  to `12.par`.
- `fevals`: quick test evaluations for the current model.

Manual model editing workflow:

1. Copy a folder under `steps/` and give it the next numbered name.
2. Put that model's MFCL files in `steps/<step-id>/model/`, or directly in the
   step folder if you prefer the shortest path.
3. Add or duplicate the matching row in `stepwise-config.R`.
4. Launch Kflow with `STEP_SELECT=<step-id>` for just that model, or a comma
   separated list for several independent models.
5. Add `patch.R` inside the step folder only when a model needs scripted edits.

Useful Kflow job config fields:

- `STEP_SELECT=01-base-11par`: run one folder.
- `STEP_SELECT=01-base-11par,03-review-11par`: run selected folders.
- `STEP_SELECT=all`: run every enabled numbered folder.
- `MFCL_FEVALS=10`: override `fevals` for the submitted job.
- `MFCL_LIVE_LOG=true`: stream the full MFCL log into the Kflow log view.
- `MFCL_LIVE_LOG=false`: suppress the live MFCL stream in the Kflow log.

Dependency triggers:

- The saved Kflow task has an `on_success` trigger that launches
  `ofp-sam-bet-2026-plot`, which then launches `ofp-sam-bet-2026-report`.
- For command-line submissions, `stepwise-config.R` controls the default with
  `stepwise_run$trigger_next`.
- Use `make kflow TRIGGER_NEXT=false` to submit only the selected model without
  launching plot/report afterward.
- In the Kflow app, the same behavior is visible in the task's trigger/job
  settings; use it when a one-off run should stop after stepwise.

The saved Kflow task defaults to `STEP_SELECT=01-base-11par`, so adding a new
folder does not automatically submit every model. Select the folders explicitly
in the job config when launching from Kflow.

Shortcut commands:

- `make list`: show the rows in `stepwise-config.R`.
- `make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64`: run on
  this machine.
- `make docker STEP_SELECT=01-base-11par`: run on this machine inside
  `ghcr.io/pacificcommunity/tuna-flow:v1.5`.
- `make kflow STEP_SELECT=01-base-11par KFLOW_API_TOKEN=...`: submit the same
  selected model folder to Kflow.
- `make fix-permissions`: repair root-owned `outputs/`, `work/`, or runtime
  cache files left by older local Docker runs, then run `make clean`.

Kflow API token:

- On the Kflow app host, the token lives in
  `/home/kyuhank/apps/kflow-app/.env` as `KFLOW_API_TOKEN=...`.
- Do not put the token in this repo or in `stepwise-config.R`.
- For command-line submission from your machine, export it for the shell session:

```bash
export KFLOW_API_TOKEN="$(ssh nouofpsubmit.corp.spc.int 'grep "^KFLOW_API_TOKEN=" /home/kyuhank/apps/kflow-app/.env | cut -d= -f2-')"
make kflow STEP_SELECT=01-base-11par
```

Outputs are written under `outputs/models/<step-id>/` and include
only `model_payload.rds` and the final `.par` file from the run. The top-level
`outputs/model-index.csv` and `outputs/selected-steps.csv` give a compact run
summary for Kflow and the downstream plot task. MFCL detail is visible in the
live Kflow log but is not kept as an artifact.

The default input files are copied into each starter model folder under
`steps/<step-id>/model/`, so every model folder is self-contained. Docker runs
use the MFCL executable bundled in the tuna-flow image at `/home/mfcl/mfclo64`
by default. Local Docker runs use your host UID/GID so generated files can be
cleaned up without `sudo`. For local non-Docker testing, override the executable
with `PROGRAM_PATH=/path/to/mfclo64`.
