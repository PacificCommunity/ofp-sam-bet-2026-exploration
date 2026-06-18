# BET 2026 Stepwise

Kflow task repository for BET 2026 model runs.

The task runs numbered model folders under `steps/`. Each folder is one
independent model. To add a model, copy an existing folder, give it the next
number, and edit only `config.env` and optional `patch.R`.

Current starter sequence:

- `steps/01-base-11par`: quick base run from `11.par` in
  the bundled `mfcl/inputs/2023_4region_1007` folder.
- `steps/02-continue-11par`: independent model folder from the same `11.par`.
- `steps/03-review-11par`: independent model folder from the same `11.par`.

Useful `config.env` fields:

- `INPUT_SUBDIR`: source folder bundled in this repo.
- `INPUT_PAR`: starting par file, or `latest`.
- `OUTPUT_PAR`: final par file name for this step.
- `SMOKE_FEVALS`: fast test evaluations for the current model.
- `ENABLED=false`: keep a folder documented without running it.

Outputs are written under `outputs/models/<step-id>/` and include
`model_payload.rds`, `depletion.csv`, summaries, logs, and the final par file.

The default input files are copied into this repository under `mfcl/` and
`metadata/`, so a Kflow run does not need to clone
`PacificCommunity/ofp-sam-bet2026-inputs`.
