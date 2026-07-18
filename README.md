# BET 2026 LF observation-model sensitivities

This branch defines a focused set of **36 BET sensitivity models**. Generated model inputs live under `sensitivity/` and should be rebuilt from the scripts rather than edited by hand.

## Final design

The core design crosses five age-length variants with six LF configurations, giving 30 models.

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

The remaining six models are `BASE075` selectivity sensitivities. Three selectivity alternatives (`SA28-N5`, `SA28-N8`, and `IDX-Z2`) are each evaluated as a pair:

- Normal likelihood with `CUT90-DW1`.
- Dirichlet-multinomial likelihood with `G5PROC-CEST-CUT90`.

There are no `DW5`, `CUT70`, fixed-`C0`, or non-`G5PROC` models in the final design.

## DM settings

`G5PROC` uses the repository's predefined five process-oriented LF groups. It lets observations assigned to a broadly similar observation process share a DM dispersion relationship; it does not assert that every dataset within a group has identical sampling quality.

`CEST` estimates the relative sample-size exponent rather than fixing that exponent. This is an observation-model sensitivity, not an independent correction for duplicated data use or a guarantee that the grouping is optimal.

## INI provenance

The reference INI is taken from [`BET/ini.mix-period/bet.2026.mix-0.2.ini`](https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-build-ini/blob/548de05aff9bdc96a9ee7a817bbfd8068020ba26/BET/ini.mix-period/bet.2026.mix-0.2.ini) at commit `548de05aff9bdc96a9ee7a817bbfd8068020ba26` of `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`.

The only intentional deviation from that file is in `# tag flags`: column 2 is changed from `1` to `0` for all 98 tag-release rows. All other INI settings are retained. In particular, the upstream common prior for fisheries F25-F28 remains reporting group `16`, target `52.015`, and penalty `485.2`.

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
