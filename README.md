# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

BET 2026 MFCL stepwise model inputs. Each folder under `steps/` is a runnable
model folder with a compact README and input manifest.

## Step Path

| Step | Adds / isolates | Tag treatment |
| --- | --- | --- |
| `01-Diag2023` | 2023 diagnostic rerun with historical MFCL | historical |
| `02a-NewExe` | current executable using `2023_rep` and 1003 ini | doitall `-9999 1 2` |
| `02b-Ini1007` | promote the 02a diagnostic ini to 1007 | `tag_flags(it,2)=0` |
| `02c-LnR0` | set diagnostic LN(R0) to 17 | inherits 02b |
| `03-FixM` | FixM update at the 2023 MLE value after 02c | inherits 02c |
| `04a-NewStructure` | 5-region / 33-fishery structure, global CPUE | `tag_flags(it,2)=0` |
| `04b-TagReportingMixing` | reporting-rate treatment during tag mixing | `tag_flags(it,2)=1` |
| `05-ConvertToLength` | existing weight comps converted to length | inherits 04b |
| `06-LengthPlusLength` | additional length comps | inherits 04b |
| `07-DataTo2024` | 2024 global-CPUE data | inherits 04b |
| `08-RegionalCPUE` | regional CPUE and regional-scaling prior | inherits 04b |
| `09-NewOtoliths` | updated 2026 CAAL / otoliths | inherits 04b |
| `10-TagMixingKS` | release-specific mixing from KS 0.2 | release-specific, `it2=1` |
| `11-TimeVaryingCV` | time-varying CPUE CV | release-specific, `it2=1` |
| `12-OrthogonalPoly` | OPR recruitment setting | release-specific, `it2=1` |
| `13-LengthBasedSel` | length-based selectivity | release-specific, `it2=1` |
| `14-EffortCreep` | agreed index-fishery effort creep | release-specific, `it2=1` |
| `15-DataWeighting` | first data-weighting run | release-specific, `it2=1` |

## Where To Look

| Path | Use |
| --- | --- |
| `steps/<step_id>/README.md` | short step summary, input table, controls, and checks |
| `steps/<step_id>/input_manifest.csv` | source files, commits, and generated-input notes |
| `steps/<step_id>/model/` | MFCL-ready model folder |
| `docs/run-configuration.md` | Kflow/local-run settings and output layout |
| `docs/tag-reporting-groups.md` | tag reporting-rate grouping audit |
| `R/prepare_bet_2026_step_inputs.R` | reproducible input-generation entry point |
| `debugging/` | troubleshooting records |

## Assessment Notes

| Topic | Note |
| --- | --- |
| Regional scaling | Steps 08-15 use `bet.reg_scaling` over periods 53-72, matching the 1965-1969 global CPUE covariance-estimation window. |
| Effort creep | Steps 14-15 apply 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024 to index fisheries 29-33. |
| Region maps | Steps 01-03 use the 2023 9-region asset; steps 04a-15 use the 2026 5-region asset. See [`docs/region-map-assets.md`](docs/region-map-assets.md). |
| Tag audit maps | `tag_rep_map.R` is an audit output from `.ini` and `.tag`; MFCL reads the `.ini`. See [`docs/tag-reporting-groups.md`](docs/tag-reporting-groups.md). |
