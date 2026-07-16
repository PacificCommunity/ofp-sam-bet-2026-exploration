# BET 2026 recruitment OPR sensitivity design.
#
# Every model starts from S002-TC1-NOCUT-DW1. The annual/end pairs are
# saturated for 73 model years (1952-2024). The main six temporal structures
# are crossed with terminal-penalty OFF/ON; the parsimonious boundary is run
# with the penalty off only.

opr_base_step_id <- "S002-TC1-NOCUT-DW1"

opr_annual_end <- data.frame(
  year_effect = c(73L, 72L, 71L),
  terminal_year_constraint = c(1L, 2L, 3L),
  stringsAsFactors = FALSE
)

opr_main_structures <- data.frame(
  structure_code = c(
    "S01-R50-I50",
    "S03-R50-I50",
    "S05-R50-I50",
    "S01-R15-I50",
    "S01-R50-I15",
    "S01-R15-I15"
  ),
  season_effect = c(1L, 3L, 5L, 1L, 1L, 1L),
  region_effect = c(50L, 50L, 50L, 15L, 50L, 15L),
  region_season_effect = c(50L, 50L, 50L, 50L, 15L, 15L),
  interpretation = c(
    "reviewed OPR temporal structure",
    "quadratic temporal change in seasonal contrasts",
    "quartic temporal change in seasonal contrasts",
    "reduced region temporal flexibility",
    "reduced region-season interaction temporal flexibility",
    "balanced moderate region and interaction temporal flexibility"
  ),
  stringsAsFactors = FALSE
)

main_index <- expand.grid(
  terminal_penalty_flag = c(0L, 100L),
  annual_end_index = seq_len(nrow(opr_annual_end)),
  structure_index = seq_len(nrow(opr_main_structures)),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

main_models <- data.frame(
  year_effect = opr_annual_end$year_effect[main_index$annual_end_index],
  terminal_year_constraint =
    opr_annual_end$terminal_year_constraint[main_index$annual_end_index],
  terminal_penalty_flag = as.integer(main_index$terminal_penalty_flag),
  structure_code = opr_main_structures$structure_code[main_index$structure_index],
  season_effect = opr_main_structures$season_effect[main_index$structure_index],
  region_effect = opr_main_structures$region_effect[main_index$structure_index],
  region_season_effect =
    opr_main_structures$region_season_effect[main_index$structure_index],
  interpretation = opr_main_structures$interpretation[main_index$structure_index],
  design_group = "main penalty factorial",
  stringsAsFactors = FALSE
)

parsimonious_models <- data.frame(
  year_effect = opr_annual_end$year_effect,
  terminal_year_constraint = opr_annual_end$terminal_year_constraint,
  terminal_penalty_flag = 0L,
  structure_code = "S01-R05-I05",
  season_effect = 1L,
  region_effect = 5L,
  region_season_effect = 5L,
  interpretation = "parsimonious region and interaction temporal structure",
  design_group = "parsimonious penalty-off boundary",
  stringsAsFactors = FALSE
)

opr_models <- rbind(main_models, parsimonious_models)
opr_models$model_index <- seq_len(nrow(opr_models))
opr_models$step_id <- sprintf(
  "OPR%03d-Y%02d-E%d-TP%03d-S%02d-R%02d-I%02d",
  opr_models$model_index,
  opr_models$year_effect,
  opr_models$terminal_year_constraint,
  opr_models$terminal_penalty_flag,
  opr_models$season_effect,
  opr_models$region_effect,
  opr_models$region_season_effect
)
opr_models$tail_compression_percent <- 1L
opr_models$cutoff_code <- "NOCUT"
opr_models$lf_downweight_factor <- 1L
opr_models$lf_size_divisor <- 20L
opr_models$regional_scaling_weight <- 50L
opr_models$expected_final_par <- "11.par"
opr_models$job_title <- paste("BET 2026 recruitment OPR sensitivity", opr_models$step_id)

opr_models <- opr_models[, c(
  "model_index", "step_id", "job_title", "design_group",
  "year_effect", "terminal_year_constraint", "terminal_penalty_flag",
  "structure_code", "season_effect", "region_effect",
  "region_season_effect", "interpretation", "tail_compression_percent",
  "cutoff_code", "lf_downweight_factor", "lf_size_divisor",
  "regional_scaling_weight", "expected_final_par"
)]
