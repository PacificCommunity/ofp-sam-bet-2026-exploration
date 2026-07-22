# BET 2026 public composition-weighting comparison.
stepwise_models_all <- data.frame(
  step_id = c(
    "S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26",
    "S002-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26",
    "S003-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RR8-10",
    "S004-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW1-RR8-10",
    "S005-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RRPTTP26",
    "S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW1-RRPTTP26",
    "S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10",
    "S008-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW1-RR8-10"
  ),
  enabled = rep(TRUE, 8),
  model_label = c("Francis TA1.8 + CPUE MLE, REGW11, PTTP26, F25/F26 shared N7, common CPUE sigma", "Francis TA1.8 + CPUE MLE, REGW1, PTTP26, F25/F26 shared N7, common CPUE sigma", "Francis TA1.8 + CPUE MLE, REGW11, RR8/10, F25/F26 shared N7, common CPUE sigma", "Francis TA1.8 + CPUE MLE, REGW1, RR8/10, F25/F26 shared N7, common CPUE sigma", "DM G8PSSET Nmax25, REGW11, PTTP26, F25/F26 shared N7, common CPUE sigma", "DM G8PSSET Nmax25, REGW1, PTTP26, F25/F26 shared N7, common CPUE sigma", "DM G8PSSET Nmax25, REGW11, RR8/10, F25/F26 shared N7, common CPUE sigma", "DM G8PSSET Nmax25, REGW1, RR8/10, F25/F26 shared N7, common CPUE sigma"),
  run_mode = rep("doitall", 8), frq = rep("bet.frq", 8), region_count = rep(5L, 8),
  age_length_variant = rep("SUB075", 8), cutoff_code = rep("NOCUT", 8), tag_flag2 = rep(1L, 8),
  lf_likelihood = c(rep("normal", 4), rep("dm_no_re", 4)), lf_downweight_factor = rep(NA_real_, 8), lf_size_divisor = rep(NA_real_, 8),
  dm_grouping = c(rep(NA_character_, 4), rep("G8PSSET", 4)), dm_concentration = c(rep(NA_character_, 4), rep("group-specific", 4)), dm_nmax = c(rep(NA_integer_, 4), rep(25L, 4)),
  regional_scaling_weight = rep(c(11L, 1L), 4),
  reporting_rate_prior = rep(c("Tom_Peatman_2026_PTTP", "Tom_Peatman_2026_PTTP", "manual_8_10", "manual_8_10"), 2),
  source_job = c(12306L, 12307L, 12292L, 12291L, 12314L, 12313L, 12751L, 12299L),
  major_step = c(rep(1L, 4), rep(2L, 4)), substep = 1:8,
  change_axis = c(rep("full Francis TA1.8 LF divisors, common R1-R5 CPUE sigma, and shared seven-node F25/F26 selectivity", 4), rep("DM set-type G8PSSET grouping with Francis-calibrated Nmax25 cap, common R1-R5 CPUE sigma, and shared seven-node F25/F26 selectivity", 4)),
  stringsAsFactors = FALSE
)
stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]
stepwise_run <- list(default_step_select = "all", flow_group = "bet-2026-psassoc-selectivity-n7-20260722", trigger_next = FALSE)
