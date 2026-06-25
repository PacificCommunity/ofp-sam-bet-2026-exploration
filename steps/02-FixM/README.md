# 02 FixM

2023 diagnostic structure with the FixM M-scale row applied.

## What Changed

- Same 9-region, 41-fishery input structure as 01-Diag23.
- The M-related age parameter row is set to `-2.54917483258212e+00 -1 ...`.
- `bet.ini` is promoted from MFCL 1003 to 1007 layout for the current MFCL reader, while retaining the FixM diagnostic values.
- This is the M source used when preparing later 5-region inputs.

## Inputs

- `bet.frq`: same structural input as 01-Diag23, terminal year 2021
- `bet.ini`: FixM version of the diagnostic ini; promoted from 1003 to 1007 by adding explicit tag flags, zero tag shed rates, total-population scalar default 25, and Richards default 0
- `bet.tag`: same tag structure as 01-Diag23
- `bet.age_length`: same CAAL structure as 01-Diag23
- Region map output asset: `bet-2023-nine-region.geojson`, generated from the `regions_BET_2023_9R.csv` `MufArea` rectangles and copied into Kflow outputs for MFCL Shiny.

## Control Notes

- Inherited 9-region `doitall.sh` retained.
- The 9-region map is an output-only GeoJSON asset; it does not change MFCL inputs. Its exterior polygons are generated from the 2023 9R `MufArea` rectangles documented in `docs/region-map-assets.md`.
- This step is used as the reference for the M row copied into 03+.
- `bet.ini` now carries 118 explicit MFCL 1007 tag-flag rows matching `bet.tag`; the inherited `-9999 1 2` control remains consistent with those rows.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- Confirm the FixM M row reproduces the intended fixed-M diagnostic before comparing against 03+.
- No fishery, tag, CAAL, or CPUE update is intended in this step.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
