# BET 2026 Francis TA1.8 and MFCL-equivalent CPUE MLE refits
# S001/S002 use PTTP26 reporting-rate priors; S003/S004 use manual 8/10 priors.
stepwise_models_all <- data.frame(
  step_id = c(
    "S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26",
    "S002-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26",
    "S003-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RR8-10",
    "S004-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RR8-10"
  ),
  enabled = rep(TRUE, 4),
  model_label = c(
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW11 PTTP26",
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW1 PTTP26",
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW11 RR8/10",
    "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW1 RR8/10"
  ),
  run_mode = rep("doitall", 4),
  frq = rep("bet.frq", 4),
  region_count = rep(5L, 4),
  age_length_variant = rep("SUB075", 4),
  cutoff_code = rep("NOCUT", 4),
  tag_flag2 = rep(1L, 4),
  lf_likelihood = rep("normal", 4),
  lf_downweight_factor = rep(NA_real_, 4),
  lf_size_divisor = rep(NA_real_, 4),
  dm_grouping = rep(NA_character_, 4),
  dm_concentration = rep(NA_character_, 4),
  dm_nmax = rep(NA_integer_, 4),
  regional_scaling_weight = c(11L, 1L, 11L, 1L),
  reporting_rate_prior = c(
    "Tom_Peatman_2026_PTTP",
    "Tom_Peatman_2026_PTTP",
    "manual_8_10",
    "manual_8_10"
  ),
  major_step = rep(1L, 4),
  substep = 1:4,
  change_axis = rep(
    "full Francis TA1.8 LF divisors plus MFCL-equivalent normalized-lambda CPUE MLE sigma",
    4
  ),
  stringsAsFactors = FALSE
)

stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-francis-cpue-mle-20260722",
  trigger_next = FALSE
)
