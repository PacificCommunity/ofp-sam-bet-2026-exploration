# BET 2026 LF observation-model sensitivities

This branch defines a focused set of **41 non-duplicate BET sensitivity models**. Generated model inputs live under `sensitivity/` and should be rebuilt from the scripts rather than edited by hand.

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

All 41 models share the single-area-derived F1-F28 selectivity structure. Public labels therefore show only the meaningful node contrast, `N5` or `N8`, and omit the former common `SA28` prefix.

The complete corrected baseline has these audited rules:

- F1-F28 extraction coefficients are independent and use contiguous groups 1:28.
- F29-F33 regional indices share group 29 through phases 1-4 for stable initialization. In phase 5 they split into groups 29:33, so their final selectivities are estimated separately. This relabel preserves the original partition and parameter count while satisfying MFCL's contiguous-group requirement. All five retain the first-two-age zero baseline.
- Early ages are fixed to zero for F1-F12 (first two), F13 (first one), F15 (first five), and every regional index F29-F33 (first two).
- Monotonicity is applied only to F9.
- Upper-age tail penalties start at F12=25, F13=30, F16-F19=25, F21=10, F22=7, F23=6, F24-F26=25, and F27=30. F14, F15, F20, and F28 have no tail penalty.
- Fish flag 26 is intentionally retained at `2` from the single-area-derived structure. MFCL evaluates the cubic selectivity spline on scaled mean length-at-age and uses the result as final selectivity-at-age in the catch and population equations. This is neither the ordinary normalized-age coordinate used by flag 26=`0` nor fully length-bin-specific selectivity under flag 26=`3`.
- Fish flag 57=`3` selects the cubic spline. The default flag 61=`5` nodes, or the targeted F12/F13 flag 61=`8` nodes, lie on the scaled mean-length-at-age coordinate under flag 26=`2`.
- Flags 75, 3, and 16 remain age constraints. The LF likelihood choice is separate from these selectivity controls, so this design is not described as pure age-axis selectivity.
- The common oldest age is 37.

Two genuinely distinct `BASE075` selectivity comparisons remain:

- `S031` and `S032` are the normal and DM N8 comparisons. Only F12 `PS.JP.1` and F13 `PL.JP.1` change from five to eight nodes.

Exact duplicate standalone N5 and index-zero candidates are not retained. The final public identifiers are contiguous from `S001` through `S041`.

Five `BASE075` tag-flag tests use the same corrected N5 baseline. Each is identical to its listed flag-column-2=0 control except that all 98 `tag_flags(:,2)` values are restored to upstream value 1:

| Test | Exact control | Explicit dimensions |
|---|---|---|
| `S033` | `S001` | Normal, TC1, NOCUT, DW1 |
| `S034` | `S003` | Normal, TC1, CUT90, DW1 |
| `S035` | `S005` | DM noRE, G5PROC, C estimated, NOCUT |
| `S036` | `S006` | DM noRE, G5PROC, C estimated, CUT90 |
| `S037` | `S002` | Normal, TC1, NOCUT, DW10 |

Two additional `BASE075` models form a normal-LF fixed-structure recruitment OPR tag pair:

| Model | Tag flag column 2 | OPR structure |
|---|---:|---|
| `S038-OPR-Y72-E2-S01-R50-I50` | 0 | Y72-E2-S01-R50-I50 |
| `S039-OPR-Y72-E2-S01-R50-I50-TAGF2ON` | 1 | Y72-E2-S01-R50-I50 |

Two more `BASE075` models apply the same OPR structure to the exact `S005` DM control:

| Model | Tag flag column 2 | DM and OPR structure |
|---|---:|---|
| `S040-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50` | 0 | DM-noRE, G5PROC, C estimated, NOCUT; Y72-E2-S01-R50-I50 |
| `S041-OPR-DM-G5PROC-CEST-Y72-E2-S01-R50-I50-TAGF2ON` | 1 | Same as S040 |

All four OPR models use the reviewed BET `apply_opr()` semantics with parest 155=72, 221=72, 202=2, 217=1, 216=50, 218=50, and 397=0. OPR is activated in phase 3, movement remains in phase 4, and regional scaling remains in phase 5. Terminal penalty is disabled in every OPR model and is not a sensitivity axis. `S039` differs from `S038`, and `S041` differs from `S040`, only in all 98 `tag_flags(:,2)` values. Apart from the reviewed OPR transform and metadata, `S040` is identical to `S005`, including DM grouping, C-estimation phase controls, Nmax, age-length input, and selectivity/index constraints.

There are no `DW5`, `CUT70`, fixed-`C0`, or non-`G5PROC` models in the final design.

## DM settings

`G5PROC` uses the repository's predefined five process-oriented LF groups. It lets observations assigned to a broadly similar observation process share a DM dispersion relationship; it does not assert that every dataset within a group has identical sampling quality.

`CEST` estimates the relative sample-size exponent rather than fixing that exponent. This is an observation-model sensitivity, not an independent correction for duplicated data use or a guarantee that the grouping is optimal.

## CPUE HAC4 sigma sensitivity

This branch changes only the F29-F33 CPUE sigma controls relative to
`experiment/dm-nmax20-20260719`. The adjustment uses weighted log-residuals
from the converged `S014-TC1-NOCUT-DW10-REG100` fit (Kflow job 9777), a
Bartlett Newey-West design effect at lag 4, and
`sigma_HAC4 = sigma_base * sqrt(DE4)`.

Lag 4 is fixed a priori because the indices are quarterly, so it spans one
annual cycle. The same anchor adjustment is used across all 41 models to keep
HAC weighting as a single paired sensitivity axis rather than recalculating a
different weight after each model change.

| Fishery | Index | Base sigma | DE4 | HAC4 target | Applied flag 92 |
| --- | --- | ---: | ---: | ---: | ---: |
| F29 | R1 | 0.35 | 1.294765 | 0.398 | 40 |
| F30 | R2 | 0.24 | 1.587703 | 0.302 | 30 |
| F31 | R3 | 0.21 | 2.820362 | 0.353 | 35 |
| F32 | R4 | 0.24 | 1.797746 | 0.322 | 32 |
| F33 | R5 | 0.23 | 1.686407 | 0.299 | 30 |

Fish flag 66 remains 1. MFCL therefore retains each FRQ `effort_weight` as a
temporal variance multiplier, normalizes it to mean one within fishery, and
uses `lambda_t * sigma^2` because parest flag 371 remains zero. No CPUE
observations, FRQ weights, model phases, selectivity settings, LF settings,
tag settings, or regional-scaling controls are changed. See
[`notes/cpue-hac4-weighting.md`](notes/cpue-hac4-weighting.md) for the audit.

## INI provenance

The reference INI is taken from [`BET/ini.mix-period/bet.2026.mix-0.2.ini`](https://github.com/PacificCommunity/ofp-sam-2026-BET-YFT-build-ini/blob/548de05aff9bdc96a9ee7a817bbfd8068020ba26/BET/ini.mix-period/bet.2026.mix-0.2.ini) at commit `548de05aff9bdc96a9ee7a817bbfd8068020ba26` of `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`.

For the 34 flag-column-2=0 models, the only intentional deviation from that file is in `# tag flags`: column 2 is changed from `1` to `0` for all 98 tag-release rows. `S033`-`S037`, `S039`, and `S041` restore those 98 values to the upstream value 1. Column 1, columns 3 onward, and all non-tag-flag INI settings remain unchanged. In particular, the upstream common prior for fisheries F25-F28 remains reporting group `16`, target `52.015`, and penalty `485.2`.

Reference checksums:

```text
Reference input bundle: a864b81f4d07321e977454a0d4c8389c8008b00159f374601f40ad6a6f7379d7
Derived bet.ini:        932f57a96140400ae327cc47291316840c63c492542724a967c48ed002157117
```

## Runtime compatibility

DM final-report and model-payload generation requires Tuna Flow v2.5. Kflow uses the tested image `ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360`; the digest pin should remain unchanged unless a replacement image has passed the same compatibility checks.

## Generate and validate

From the repository root:

```bash
Rscript R/prepare_bet_2026_step_inputs.R
Rscript R/validate_sensitivities.R
```

The first command rebuilds the sensitivity inputs. The second checks the model design, provenance-sensitive inputs, and generated directories.

These models have **not yet been submitted to Kflow**.
