# BET 2026 LF observation-model sensitivities

This branch defines a focused set of **39 non-duplicate BET sensitivity models**. Generated model inputs live under `sensitivity/` and should be rebuilt from the scripts rather than edited by hand.

## Final design

The core design crosses five age-length variants with six LF configurations, giving 30 models (`S001`-`S030`).

| Age-length variant | Description |
|---|---|
| `BASE075` | Base age-length input with the established 0.75 setting |
| `REG075` | Regional age-length variant with the 0.75 setting |
| `REG100` | Regional age-length variant with the 1.00 setting |
| `SUB075` | Sub-basin age-length variant with the 0.75 setting |
| `SUB100` | Sub-basin age-length variant with the 1.00 setting |

Each age-length variant uses exactly these six configurations:

| Likelihood | LF treatment |
|---|---|
| Normal | `NOCUT-DW1` |
| Normal | `NOCUT-DW10` |
| Normal | `CUT90-DW1` |
| Normal | `CUT90-DW10` |
| Dirichlet-multinomial | `G5PROC-CEST-NOCUT` |
| Dirichlet-multinomial | `G5PROC-CEST-CUT90` |

All 30 core models use the corrected single-area-derived N5 selectivity baseline. The former exploration selectivity is retained in provenance, but it is no longer the core baseline.

The complete corrected baseline has these audited rules:

- F1-F28 extraction coefficients are independent: F1-F24 use groups 1:24 and F25-F28 use groups 30:33.
- F29-F33 regional indices share group 25 in phases 1-4 and split into groups 25:29 in phase 5.
- Early ages are fixed to zero for F1-F12 (first two), F13 (first one), F15 (first five), and every regional index F29-F33 (first two).
- Monotonicity is applied only to F9.
- Upper-age settings are F12=25, F13=30, F15-F19=25, F21=10, F22=7, F23=6, F24-F26=25, and F27=30. F20 and F28 have no override.
- The common oldest age is 37, with length-dependent cubic-spline selectivity and five nodes by default.

Two genuinely distinct `BASE075` selectivity comparisons remain:

- `S032` and `S035` are the normal and DM N8 comparisons. Only F12 `PS.JP.1` and F13 `PL.JP.1` change from five to eight nodes.

The former standalone N5 sensitivities `S031` and `S034` became exact duplicates after corrected N5 was promoted to core. The former `IDX-Z2` sensitivities `S033` and `S036` also became exact duplicates after the F29-F33 first-two-age constraints were promoted into that common baseline. All four are intentionally retired, and their generated directories are removed during reconciliation.

Five `BASE075` tag-flag tests use the same corrected N5 baseline. Each is identical to its listed flag-column-2=0 control except that all 98 `tag_flags(:,2)` values are restored to upstream value 1:

| Test | Exact control | Explicit dimensions |
|---|---|---|
| `S037` | `S001` | Normal, TC1, NOCUT, DW1 |
| `S038` | `S003` | Normal, TC1, CUT90, DW1 |
| `S039` | `S005` | DM noRE, G5PROC, C estimated, NOCUT |
| `S040` | `S006` | DM noRE, G5PROC, C estimated, CUT90 |
| `S041` | `S002` | Normal, TC1, NOCUT, DW10 |

Two additional `BASE075` models form one fixed-structure recruitment OPR tag pair:

| Model | Tag flag column 2 | OPR structure |
|---|---:|---|
| `S042-OPR-Y72-E2-S01-R50-I50` | 0 | Y72-E2-S01-R50-I50 |
| `S043-OPR-Y72-E2-S01-R50-I50-TAGF2ON` | 1 | Y72-E2-S01-R50-I50 |

Both OPR models inherit the normal `S001` controls: TC1, NOCUT, DW1, BASE075, corrected N5 selectivity, and F29-F33 first-two-age zeros. They use the reviewed BET `apply_opr()` semantics with parest 155=72, 221=72, 202=2, 217=1, 216=50, 218=50, and 397=0. Terminal penalty is disabled in both models and is not a sensitivity axis. `S043` differs from `S042` only in all 98 `tag_flags(:,2)` values.

There are no `DW5`, `CUT70`, fixed-`C0`, or non-`G5PROC` models in the final design.

## DM settings

`G5PROC` uses the repository's predefined five process-oriented LF groups. It lets observations assigned to a broadly similar observation process share a DM dispersion relationship; it does not assert that every dataset within a group has identical sampling quality.

`CEST` estimates the relative sample-size exponent rather than fixing that exponent. This is an observation-model sensitivity, not an independent correction for duplicated data use or a guarantee that the grouping is optimal.

## INI provenance

The reference INI is taken from [`BET/ini.mix-period/bet.2026.mix-0.2.ini`](https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-build-ini/blob/548de05aff9bdc96a9ee7a817bbfd8068020ba26/BET/ini.mix-period/bet.2026.mix-0.2.ini) at commit `548de05aff9bdc96a9ee7a817bbfd8068020ba26` of `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`.

For the 33 flag-column-2=0 models, the only intentional deviation from that file is in `# tag flags`: column 2 is changed from `1` to `0` for all 98 tag-release rows. `S037`-`S041` and `S043` restore those 98 values to the upstream value 1. Column 1, columns 3 onward, and all non-tag-flag INI settings remain unchanged. In particular, the upstream common prior for fisheries F25-F28 remains reporting group `16`, target `52.015`, and penalty `485.2`.

Reference checksums:

```text
Reference input bundle: 66532e40a12135811e23ef92434e7d011a3db3a8846e56928ec4080106b97fa3
Derived bet.ini:        932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117
```

## Generate and validate

From the repository root:

```bash
Rscript R/prepare_bet_2026_step_inputs.R
Rscript R/validate_sensitivities.R
```

The first command rebuilds the sensitivity inputs. The second checks the model design, provenance-sensitive inputs, and generated directories.

These models have **not yet been submitted to Kflow**.
