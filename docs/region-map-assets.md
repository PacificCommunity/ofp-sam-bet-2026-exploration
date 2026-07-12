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
| `01-Diag2023` through `03-FixM` | 9 | `bet-2023-nine-region.geojson` |
| `04-NewStructure` through `13-DataWeighting` | 5 | `bet-2026-five-region.geojson` |

## 2023 Nine-Region Source

The 01-03 map is the display-only `bet-2023-nine-region.geojson` asset. It is
based on the 2023 9-region `MufArea` rectangles from the size-composition input
repository at commit `31429f83a9119a11e52078a5d7412dc986f5ef38`.

The source rectangles are not kept as a separate asset in this repository; the
generated GeoJSON is the file read by MFCL Shiny and report export.

## Maintenance

The source vertices live in `R/write_bet_region_map_assets.R`. Regenerate the
shared GeoJSON files with:

```bash
Rscript -e 'source("R/write_bet_region_map_assets.R"); write_bet_region_map_assets("assets/maps", "bet-2026-five-region"); write_bet_nine_region_map_assets("assets/maps", "bet-2023-nine-region")'
```
