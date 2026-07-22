# BET 2026 four-model G8 grouped Francis TA1.8 refit.
# Each model uses residuals from its own fitted source job.
stepwise_models_all <-
structure(list(step_id = c("S001-TC1-NOCUT-FRANCISG8-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26",
"S002-TC1-NOCUT-FRANCISG8-SUB075-MIX015-TAGF2ON-REGW1-RRPTTP26",
"S003-TC1-NOCUT-FRANCISG8-SUB075-MIX015-TAGF2ON-REGW11-RR8-10",
"S004-TC1-NOCUT-FRANCISG8-SUB075-MIX015-TAGF2ON-REGW1-RR8-10"
), enabled = c(TRUE, TRUE, TRUE, TRUE), model_label = c("G8 grouped Francis TA1.8 REGW11 PTTP26",
"G8 grouped Francis TA1.8 REGW1 PTTP26", "G8 grouped Francis TA1.8 REGW11 RR8/10",
"G8 grouped Francis TA1.8 REGW1 RR8/10"), run_mode = c("doitall",
"doitall", "doitall", "doitall"), frq = c("bet.frq", "bet.frq",
"bet.frq", "bet.frq"), region_count = c(5L, 5L, 5L, 5L), age_length_variant = c("SUB075",
"SUB075", "SUB075", "SUB075"), cutoff_code = c("NOCUT", "NOCUT",
"NOCUT", "NOCUT"), tag_flag2 = c(1L, 1L, 1L, 1L), lf_likelihood = c("normal",
"normal", "normal", "normal"), lf_downweight_factor = c(NA_real_,
NA_real_, NA_real_, NA_real_), lf_size_divisor = c(NA_real_,
NA_real_, NA_real_, NA_real_), dm_grouping = c(NA_character_,
NA_character_, NA_character_, NA_character_), dm_concentration = c(NA_character_,
NA_character_, NA_character_, NA_character_), dm_nmax = c(NA_integer_,
NA_integer_, NA_integer_, NA_integer_), regional_scaling_weight = c(11L,
1L, 11L, 1L), reporting_rate_prior = c("Tom_Peatman_2026_PTTP",
"Tom_Peatman_2026_PTTP", "manual_8_10", "manual_8_10"), source_job = c(12306L,
12307L, 12292L, 12291L), major_step = c(1L, 1L, 1L, 1L), substep = 1:4,
    change_axis = c("G8 pooled Francis TA1.8 LF divisors; source CPUE sigma retained",
    "G8 pooled Francis TA1.8 LF divisors; source CPUE sigma retained",
    "G8 pooled Francis TA1.8 LF divisors; source CPUE sigma retained",
    "G8 pooled Francis TA1.8 LF divisors; source CPUE sigma retained"
    )), class = "data.frame", row.names = c(NA, -4L))

stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-g8-grouped-francis-20260722",
  trigger_next = FALSE
)
