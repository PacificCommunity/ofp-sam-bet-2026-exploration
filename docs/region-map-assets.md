# Region Map Assets

This repository ships lightweight GeoJSON map assets for MFCL Shiny and report
export. They are output assets only; they do not change MFCL inputs or fitted
model behavior.

## Output Layout

Stepwise runs copy map assets to:

```text
outputs/region-map/<project-map>.geojson
outputs/models/<step_id>/bet.region_map.geojson
```

The root `region-map/` folder lets MFCL Shiny select the correct shared map for
the loaded model structure. The per-model `bet.region_map.geojson` keeps a
self-contained map beside each payload.

## Asset Selection

| Steps | Region count | Output asset |
| --- | ---: | --- |
| `01-Diag23`, `02-FixM` | 9 | `bet-2023-nine-region.geojson` |
| `03-RegFish` through `12-DataWeight40` | 5 | `bet-2026-five-region.geojson` |

## 2023 Nine-Region Vertices

The 01/02 map is derived from `assets/maps/regions_BET_2023_9R.csv`, copied
from `PacificCommunity/ofp-sam-bet-yft-2026-size-comps` commit
`31429f83a9119a11e52078a5d7412dc986f5ef38`. That CSV stores `MufArea`
rectangles, not polygon vertices, so the GeoJSON uses the exterior union of
those rectangles for each region. Longitudes use 0-360 notation, so `210` is
`150W`.

| Region | Vertices |
| ---: | --- |
| 1 | `(170E,10N) -> (170E,50N) -> (120E,50N) -> (120E,20N) -> (140E,20N) -> (140E,10N)` |
| 2 | `(150W,50N) -> (170E,50N) -> (170E,10N) -> (150W,10N)` |
| 3 | `(170E,10S) -> (170E,10N) -> (140E,10N) -> (140E,0) -> (155E,0) -> (155E,5S) -> (160E,5S) -> (160E,10S)` |
| 4 | `(150W,10N) -> (170E,10N) -> (170E,10S) -> (150W,10S)` |
| 5 | `(170E,10S) -> (140E,10S) -> (140E,15S) -> (150E,15S) -> (150E,20S) -> (140E,20S) -> (140E,40S) -> (170E,40S)` |
| 6 | `(150W,10S) -> (170E,10S) -> (170E,40S) -> (150W,40S)` |
| 7 | `(110E,20N) -> (110E,10S) -> (140E,10S) -> (140E,20N)` |
| 8 | `(160E,5S) -> (155E,5S) -> (155E,0) -> (140E,0) -> (140E,10S) -> (160E,10S)` |
| 9 | `(150E,15S) -> (140E,15S) -> (140E,20S) -> (150E,20S)` |

## Maintenance

The source vertices live in `R/write_bet_region_map_assets.R`. Regenerate the
shared GeoJSON files with:

```bash
Rscript -e 'source("R/write_bet_region_map_assets.R"); write_bet_region_map_assets("assets/maps", "bet-2026-five-region"); write_bet_nine_region_map_assets("assets/maps", "bet-2023-nine-region")'
```
