# 01 Diag23

2023 diagnostic BET model structure, retained as the starting point for the 2026 stepwise transition.

## What Changed

- Uses the inherited 9-region, 41-fishery inputs ending in 2021.
- Natural mortality setup is the pre-FixM diagnostic baseline.
- `bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the diagnostic values.
- Run mode is `doitall` so the model can be built from `bet.ini` with the bundled control script.

## Inputs

- `bet.frq`: 2023 diagnostic frequency/catch/size input, 9 regions, 41 fisheries, terminal year 2021
- `bet.ini`: 2023 diagnostic ini before the FixM M-scale row change; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0
- `bet.tag`: 2023 diagnostic tag input
- `bet.age_length`: 2023 diagnostic CAAL input
- Region map output asset: `bet-2023-nine-region.geojson`, generated from the `regions_BET_2023_9R.csv` `MufArea` rectangles and copied into Kflow outputs for MFCL Shiny.

## Control Notes

- Inherited 9-region `doitall.sh` retained.
- The 9-region map is an output-only GeoJSON asset; it does not change MFCL inputs. Its exterior polygons are generated from the 2023 9R `MufArea` rectangles documented in `docs/region-map-assets.md`.
- `bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.
- Survey index fishery sigma settings are the BET 2023 region-specific values.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- This is a baseline reference step; no 2026 input updates are intended here.
- Run diagnostics should confirm the archived 2023 behavior before interpreting later deltas.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
