# 01 Diag23

2023 diagnostic BET model structure, retained as the starting point for the 2026 stepwise transition.

## What Changed

- Uses the inherited 9-region, 41-fishery inputs ending in 2021.
- Natural mortality setup is the pre-FixM diagnostic baseline.
- Run mode is `doitall` so the model can be built from `bet.ini` with the bundled control script.

## Inputs

- `bet.frq`: 2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021
- `bet.ini`: 2023 diagnostic ini before the FixM M-scale row change
- `bet.tag`: 2023 diagnostic tag input
- `bet.age_length`: 2023 diagnostic CAAL input

## Control Notes

- Inherited 9-region `doitall.sh` retained.
- Survey index fishery sigma settings are the BET 2023 region-specific values.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- This is a baseline reference step; no 2026 input updates are intended here.
- Run diagnostics should confirm the archived 2023 behavior before interpreting later deltas.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

