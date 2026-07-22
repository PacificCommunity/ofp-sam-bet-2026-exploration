# BET 2026 Francis TA1.8 and CPUE MLE refits
# S001 source: Kflow Job 12306 (S022 REGW11).
# S002 source: Kflow Job 12307 (S023 REGW1).
stepwise_models_all <- data.frame(
  step_id = c(
    "S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26",
    "S002-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26"
  ),
  enabled = c(TRUE, TRUE),
  model_label = c(
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW11 PTTP26",
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW1 PTTP26"
  ),
  run_mode = c("doitall", "doitall"),
  frq = c("bet.frq", "bet.frq"),
  region_count = c(5L, 5L),
  age_length_variant = c("SUB075", "SUB075"),
  cutoff_code = c("NOCUT", "NOCUT"),
  tag_flag2 = c(1L, 1L),
  lf_likelihood = c("normal", "normal"),
  lf_downweight_factor = c(NA_real_, NA_real_),
  lf_size_divisor = c(NA_real_, NA_real_),
  dm_grouping = c(NA_character_, NA_character_),
  dm_concentration = c(NA_character_, NA_character_),
  dm_nmax = c(NA_integer_, NA_integer_),
  regional_scaling_weight = c(11L, 1L),
  reporting_rate_prior = c("Tom_Peatman_2026_PTTP", "Tom_Peatman_2026_PTTP"),
  major_step = c(1L, 1L),
  substep = c(1L, 2L),
  change_axis = c(
    "full Francis TA1.8 LF divisors plus CPUE likelihood MLE sigma",
    "full Francis TA1.8 LF divisors plus CPUE likelihood MLE sigma"
  ),
  stringsAsFactors = FALSE
)

stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-francis-cpue-mle-20260722",
  trigger_next = FALSE
)
