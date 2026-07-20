# Generated SUB075 NOCUT DW10 regional-scaling sensitivity configuration.
stepwise_run <-
list(default_step_select = "S001-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW3",
    flow_group = "bet-2026-sub075-dw10-regw310-20260721", trigger_next = FALSE)

stepwise_models <-
structure(list(step_id = c("S001-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW3",
"S002-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW1", "S003-TC1-NOCUT-DW10-SUB075-TAGF2OFF-REGW0",
"S004-TC1-NOCUT-DW10-SUB075-TAGF2ON-REGW3", "S005-TC1-NOCUT-DW10-SUB075-TAGF2ON-REGW1",
"S006-TC1-NOCUT-DW10-SUB075-TAGF2ON-REGW0", "S007-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2ON-NMAX10-REGW3",
"S008-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2ON-NMAX10-REGW1", "S009-DM-G5PROC-CEST-NOCUT-SUB075-TAGF2ON-NMAX10-REGW0"
), enabled = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
TRUE), model_label = c("SUB075 NOCUT DW10 TAGF2OFF REGW3", "SUB075 NOCUT DW10 TAGF2OFF REGW1",
"SUB075 NOCUT DW10 TAGF2OFF REGW0", "SUB075 NOCUT DW10 TAGF2ON REGW3",
"SUB075 NOCUT DW10 TAGF2ON REGW1", "SUB075 NOCUT DW10 TAGF2ON REGW0",
"SUB075 NOCUT TAGF2ON DM G5PROC-CEST Nmax10 REGW3", "SUB075 NOCUT TAGF2ON DM G5PROC-CEST Nmax10 REGW1",
"SUB075 NOCUT TAGF2ON DM G5PROC-CEST Nmax10 REGW0"), run_mode = c("doitall",
"doitall", "doitall", "doitall", "doitall", "doitall", "doitall",
"doitall", "doitall"), frq = c("bet.frq", "bet.frq", "bet.frq",
"bet.frq", "bet.frq", "bet.frq", "bet.frq", "bet.frq", "bet.frq"
), region_count = c(5L, 5L, 5L, 5L, 5L, 5L, 5L, 5L, 5L), age_length_variant = c("SUB075",
"SUB075", "SUB075", "SUB075", "SUB075", "SUB075", "SUB075", "SUB075",
"SUB075"), cutoff_code = c("NOCUT", "NOCUT", "NOCUT", "NOCUT",
"NOCUT", "NOCUT", "NOCUT", "NOCUT", "NOCUT"), tag_flag2 = c(0L,
0L, 0L, 1L, 1L, 1L, 1L, 1L, 1L), lf_likelihood = c("normal",
"normal", "normal", "normal", "normal", "normal", "dm_no_re",
"dm_no_re", "dm_no_re"), lf_downweight_factor = c(10L, 10L, 10L,
10L, 10L, 10L, NA, NA, NA), lf_size_divisor = c(200L, 200L, 200L,
200L, 200L, 200L, NA, NA, NA), dm_grouping = c(NA, NA, NA, NA,
NA, NA, "G5PROC", "G5PROC", "G5PROC"), dm_concentration = c(NA,
NA, NA, NA, NA, NA, "estimated_phase2", "estimated_phase2", "estimated_phase2"
), dm_nmax = c(NA, NA, NA, NA, NA, NA, 10L, 10L, 10L), regional_scaling_weight = c(3L,
1L, 0L, 3L, 1L, 0L, 3L, 1L, 0L), major_step = c("Regional scaling",
"Regional scaling", "Regional scaling", "Regional scaling", "Regional scaling",
"Regional scaling", "Regional scaling", "Regional scaling", "Regional scaling"
), substep = c("DW10 REGW3", "DW10 REGW1", "DW10 REGW0", "DW10 REGW3",
"DW10 REGW1", "DW10 REGW0", "DM Nmax10 REGW3", "DM Nmax10 REGW1",
"DM Nmax10 REGW0"), change_axis = c("regional_scaling_weight",
"regional_scaling_weight", "regional_scaling_weight", "regional_scaling_weight",
"regional_scaling_weight", "regional_scaling_weight", "lf_likelihood+regional_scaling_weight",
"lf_likelihood+regional_scaling_weight", "lf_likelihood+regional_scaling_weight"
)), class = "data.frame", row.names = c(NA, -9L))

stepwise_models_all <- stepwise_models
