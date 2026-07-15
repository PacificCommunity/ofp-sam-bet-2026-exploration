# BET 2026 Model Exploration

This public repository contains focused sensitivities derived from the reviewed
BET 2026 stepwise assessment workflow. It keeps each scientific change narrow,
reproducible, and separate from the reference stepwise repository.

## Active exploration

| Field | Value |
| --- | --- |
| Model | Regional-scaling input-window alignment |
| Active folder | `steps/12-EffortCreep/model` |
| Reference repository | `PacificCommunity/ofp-sam-bet-2026-stepwise` |
| Reference commit | `63679506e74ba86526fd05267fb5aec2d25b996b` |
| Kflow selector | `12-EffortCreep` |
| Status | Input prepared; model not fitted in this repository yet |

Only this model is present in `job-config.R`. Earlier step folders are retained
as input lineage and generation templates, but they are not Kflow model rows in
this repository.

## Regional-scaling alignment

The regional-scaling prediction window is model periods 53-72, selected by
`parest_flags(79)=240` and `parest_flags(80)=220` in a 292-period model. Native
MFCL allocates a 20-row regional-scaling matrix for that window and streams the
external `.reg_scaling` file into it. The MFCL manual specifies that the input
file row count must equal the number of periods used by the prior.

This exploration therefore makes one input change:

- `bet.reg_scaling` contains source rows 53-72 only, in their original order.
- The resulting file has 20 rows and 5 regional-index columns.
- Regional CPUE values, flags, model controls, and all other Step 12 inputs are
  unchanged from the reference lineage.

Official implementation and file-format references:

- [MFCL regional-scaling input reader](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/de4abeca920063bf234ce66ec3a0f043c56e885f/src/nnewlan.cpp#L2827-L2850)
- [MFCL `.reg_scaling` file specification](https://github.com/PacificCommunity/ofp-sam-mfcl-manual/blob/4503c2abd234f3be95ec73e4375cf19df69859e2/manual-sections/MFCL-manual_running-mfcl.tex#L2047-L2079)
- [MFCL flags 77-81](https://github.com/PacificCommunity/ofp-sam-mfcl-manual/blob/4503c2abd234f3be95ec73e4375cf19df69859e2/manual-sections/MFCL-manual_running-mfcl.tex#L5074-L5084)

## Reproducibility

The source regional-scaling matrix is provided by
`ofp-sam-2026-BET-YFT-frq-build` at commit `f89e066`. Input generation is
implemented in `R/prepare_step_builder.R` using the explicit active-period
bounds in `R/prepare_bet_2026_step_inputs.R`.

No likelihood-component reweighting, composition filtering, or selectivity
change is included in this first exploration. Those questions will be assessed
as separate sensitivities after the aligned regional-scaling model is fitted.
