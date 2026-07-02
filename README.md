# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

BET 2026 MFCL stepwise model inputs. Each folder under `steps/` is a runnable
model folder with a compact README and input manifest.

## Step Map

Each row is one runnable Kflow model. Lettered rows are deliberate substeps:
they split one scientific change into smaller checks so differences can be
traced without guessing.

| Model | Major step | What changes | Input baseline |
| --- | --- | --- | --- |
| `01-Diag2023` | Diagnostic anchor | Reruns the 2023 diagnostic with the historical MFCL executable. | Archived 2023 diagnostic model. |
| `02a-NewExe` | Executable bridge | Runs the archived 2023 assessment replication inputs with the current MFCL executable. | 2023 assessment replication input set; MFCL 1003 ini. |
| `02b-Ini1007` | Executable bridge | Converts the 02a ini layout from MFCL 1003 to MFCL 1007. | 02a. |
| `02c-LnR0` | Executable bridge | Sets diagnostic total population scale `LN(R0)` to 17. | 02b. |
| `03-FixM` | FixM bridge | Applies fixed natural mortality from the 01 diagnostic `mgc=-5` final run. | 02c. |
| `04-NewStructure` | New structure | Switches to the 5-region / 33-fishery structure with global CPUE. | 2026 new-structure input, terminal year 2021. |
| `05-ConvertToLength` | Size data | Converts existing weight compositions to length. | 04. |
| `06-LengthPlusLength` | Size data | Adds the extra length compositions. | 04. |
| `07-DataTo2024` | Data update | Extends the global-CPUE input to 2024. | 06. |
| `08-RegionalCPUE` | CPUE update | Adds regional CPUE and the regional-scaling prior. | 07. |
| `09-NewOtoliths` | Age data | Adds the updated 2026 CAAL / otolith input. | 08. |
| `10-TagMixingKS` | Tag mixing | Uses release-specific mixing periods from the KS 0.2 build. | 09. |
| `11-TimeVaryingCV` | CPUE CV | Adds time-varying CPUE CV. | 10. |
| `12-OrthogonalPoly` | Recruitment | Applies the orthogonal-polynomial recruitment setting. | 11. |
| `13-LengthBasedSel` | Selectivity | Adds length-based selectivity. | 12. |
| `14-EffortCreep` | Effort creep | Applies agreed effort creep to index fisheries. | 13. |
| `15-DataWeighting` | Weighting | First data-weighting run. | 14. |

## Substep Logic

| Block | Substeps | Reason |
| --- | --- | --- |
| `02` executable bridge | `02a`, `02b`, `02c` | Separates current executable effects, MFCL 1007 ini conversion, and the `LN(R0)=17` scale change. |
| `05`-`15` | one row each | Each row adds one later assessment change on top of the selected baseline. |

## Names Used Here

| Name | Meaning |
| --- | --- |
| 2023 assessment replication input set | The archived 2023 BET replication model inputs stored in `ofp-sam-2026-BET/mfcl/inputs/2023_rep`. |
| MFCL 1003 ini | Older ini layout with no explicit `# tag flags` block; tag mixing is still set in `doitall.sh`. |
| MFCL 1007 ini | Newer ini layout with explicit `# tag flags`, tag shed rates, and reporting-rate matrix sections. |
| `BET_PHASE10_11_CONVERGENCE` | Run-time convergence knob used by Kflow/local runs. Set `-3` for quick checks or `-5` for stricter production reruns; it applies to every selected step/substep. |

## Source Inputs And Generated Edits

These model folders are generated from source input repos, then checked and
edited by `R/prepare_bet_2026_step_inputs.R`. The exact per-step source file and
edit note is in `steps/<step_id>/input_manifest.csv`.

| File | Source repo | Generated edits |
| --- | --- | --- |
| `.frq` | `ofp-sam-2026-BET-YFT-frq-build` | Copied exactly except steps 14-15, where index-fishery effort creep is applied. |
| `.tag` | `ofp-sam-2026-BET-YFT-tag-prep` | Copied exactly. `tag_rep_map.R` is only an audit file. |
| `.age_length` | `ofp-sam-2026-BET-YFT-age-length-build` | Records copied from source; steps 04-15 change effective sample size from `1` to `0.75`. |
| `.ini` | `ofp-sam-2026-BET-YFT-build-ini` and archived diagnostic inputs | Step-specific generated edits apply `LN(R0)`, FixM, tag/RR alignment, and MFCL-reader compatibility checks. |
| `bet.reg_scaling` | `ofp-sam-2026-BET-YFT-frq-build` | Copied exactly for steps 08-15. |

For the exact source-vs-generated comparison, see
[`docs/input-source-audit.md`](docs/input-source-audit.md).

## Generated Input Changes

This is the short audit view for the generated MFCL inputs.

| Scope | What changes from source | What stays unchanged |
| --- | --- | --- |
| `01`, `02a` ini | Nothing. | Historical/replication `.ini` files are unchanged from source. |
| `02b` ini | Promotes MFCL 1003 to 1007 by adding explicit tag flags, shed rates, `LN(R0)=25`, and Richards growth default `0`. | Data files and 2023 tag grouping. |
| `02c` ini | Changes only `LN(R0)` from `25` to `17`. | All other `02b` controls. |
| `03` onward ini | Uses the fixed-M row from the `01` diagnostic `mgc=-5` final par. | Other step-specific structure unless listed below. |
| `07-09` ini | Pads 2026 tag/RR/shed blocks from 91 to 98 release groups, copies RR matrices from `mix-0.2`, sets `tag_flags(it,2)=0`, and repairs fishery 19 RR cells. | Two-quarter tag mixing for all release groups. |
| `10-15` ini | Uses release-specific mixing from `mix-0.2`, sets `tag_flags(it,2)=0`, raises source zero mixing periods to `1`, and repairs fishery 19 RR cells. | Positive release-specific mixing values. |
| `.tag` | Nothing. | Selected source `.tag` files are copied exactly. |
| `.age_length` | Effective sample size changes from `1` to `0.75` in steps 04-15. | CAAL records themselves. |
| `.frq` | Steps 14-15 apply effort creep to index fisheries 29-33. | Steps 01-13 `.frq`; catch and size-composition records. |

## Where To Look

| Path | Use |
| --- | --- |
| `steps/<step_id>/README.md` | short step summary, input table, controls, and checks |
| `steps/<step_id>/input_manifest.csv` | source files, commits, and generated-input notes |
| `steps/<step_id>/model/` | MFCL-ready model folder |
| `docs/run-configuration.md` | Kflow/local-run settings and output layout |
| `docs/input-source-audit.md` | concise source-vs-generated input comparison |
| `docs/tag-reporting-groups.md` | short guide to MFCL tag reporting-rate inputs |
| `R/prepare_bet_2026_step_inputs.R` | reproducible input-generation entry point |
| `debugging/` | troubleshooting records |

## Assessment Notes

| Topic | Note |
| --- | --- |
| Regional scaling | Steps 08-15 use `bet.reg_scaling` over periods 53-72, matching the 1965-1969 global CPUE covariance-estimation window. |
| Effort creep | Steps 14-15 apply 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024 to index fisheries 29-33. |
| Region maps | Steps 01-03 use the 2023 9-region asset; steps 04-15 use the 2026 5-region asset. See [`docs/region-map-assets.md`](docs/region-map-assets.md). |
| Tag reporting rates | MFCL reads the reporting-rate blocks in `bet.ini`; `tag_rep_map.R` is only a human-readable check. See [`docs/tag-reporting-groups.md`](docs/tag-reporting-groups.md). |
