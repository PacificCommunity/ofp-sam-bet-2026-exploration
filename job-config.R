# BET 2026 Francis TA1.8 and CPUE MLE refit
# Source fitted model: S022; Kflow Job 12306.
stepwise_models_all <-
structure(list(step_id = "S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26",
    enabled = TRUE, model_label = "SUB075 NOCUT full Francis TA1.8 + CPUE MLE TAGF2ON REGW11 PTTP26",
    run_mode = "doitall", frq = "bet.frq", region_count = 5L,
    age_length_variant = "SUB075", cutoff_code = "NOCUT", tag_flag2 = 1L,
    lf_likelihood = "normal", lf_downweight_factor = NA_real_,
    lf_size_divisor = NA_real_, dm_grouping = NA_character_,
    dm_concentration = NA_character_, dm_nmax = NA_integer_,
    regional_scaling_weight = 11L, reporting_rate_prior = "Tom_Peatman_2026_PTTP",
    major_step = 1L, substep = 1L, change_axis = "full Francis TA1.8 LF divisors plus CPUE likelihood MLE sigma"), row.names = "1", class = "data.frame")

stepwise_models <- stepwise_models_all[stepwise_models_all$enabled, , drop = FALSE]

stepwise_run <- list(default_step_select = "S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-REGW11-RRPTTP26", flow_group = "bet-2026-francis-cpue-mle-20260722", trigger_next = FALSE)
