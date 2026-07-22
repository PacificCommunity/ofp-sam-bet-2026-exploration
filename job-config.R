# BET 2026 public DM Nmax comparison.
stepwise_models_all <- data.frame(
  step_id = c(
    "S001-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RRPTTP26",
    "S002-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RRPTTP26",
    "S003-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW11-RR8-10",
    "S004-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW25-RR8-10",
    "S005-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RRPTTP26",
    "S006-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RRPTTP26",
    "S007-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW11-RR8-10",
    "S008-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW25-RR8-10",
    "S009-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RRPTTP26",
    "S010-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX15-REGW100-RR8-10",
    "S011-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RRPTTP26",
    "S012-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-NMAX25-REGW100-RR8-10"
  ),
  enabled = rep(TRUE, 12),
  model_label = c(
    "DM G8PSSET Nmax15, REGW11, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax15, REGW25, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax15, REGW11, RR8/10, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax15, REGW25, RR8/10, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW11, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW25, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW11, RR8/10, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW25, RR8/10, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax15, REGW100, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax15, REGW100, RR8/10, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW100, PTTP26, F25/F26 separate N7, common CPUE sigma",
    "DM G8PSSET Nmax25, REGW100, RR8/10, F25/F26 separate N7, common CPUE sigma"
  ),
  run_mode = rep("doitall", 12),
  frq = rep("bet.frq", 12),
  region_count = rep(5L, 12),
  age_length_variant = rep("SUB075", 12),
  cutoff_code = rep("NOCUT", 12),
  tag_flag2 = rep(1L, 12),
  lf_likelihood = rep("dm_no_re", 12),
  lf_downweight_factor = rep(NA_real_, 12),
  lf_size_divisor = rep(NA_real_, 12),
  dm_grouping = rep("G8PSSET", 12),
  dm_concentration = rep("group-specific", 12),
  dm_nmax = c(rep(15L, 4), rep(25L, 4), rep(15L, 2), rep(25L, 2)),
  regional_scaling_weight = c(11L, 25L, 11L, 25L, 11L, 25L, 11L, 25L, 100L, 100L, 100L, 100L),
  reporting_rate_prior = c(
    "Tom_Peatman_2026_PTTP", "Tom_Peatman_2026_PTTP", "manual_8_10", "manual_8_10",
    "Tom_Peatman_2026_PTTP", "Tom_Peatman_2026_PTTP", "manual_8_10", "manual_8_10",
    "Tom_Peatman_2026_PTTP", "manual_8_10", "Tom_Peatman_2026_PTTP", "manual_8_10"
  ),
  source_job = c(12314L, 12313L, 12751L, 12299L, 12314L, 12313L, 12751L, 12299L, 12314L, 12751L, 12314L, 12751L),
  major_step = c(rep(1L, 4), rep(2L, 4), 1L, 1L, 2L, 2L),
  substep = 1:12,
  change_axis = c(
    rep("DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities", 4),
    rep("DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities", 4),
    rep("DM G8PSSET Nmax15 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities", 2),
    rep("DM G8PSSET Nmax25 cap, common R1-R5 CPUE sigma, and independent seven-node F25/F26 selectivities", 2)
  ),
  stringsAsFactors = FALSE
)
stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]
stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-regw-grid-f25-f26-separate-n7-20260723",
  trigger_next = FALSE
)
