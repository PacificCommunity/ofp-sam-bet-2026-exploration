## Constructor for generated BET 2026 step folders.

make_step <- function(step_id, frq_source, ini_source, tag_source, age_source,
                      frq_chop_year = NA_integer_, mix_from_ini = TRUE,
                      force_tag_mixing_period = NA_integer_,
                      retain_reporting_rates_during_mixing = TRUE,
                      tag_reporting_source = "",
                      tag_reporting_cell_repairs = list(),
                      frq_tag_groups = NA_integer_,
                      frq_transform = NULL, index_cpue_source = "",
                      doitall_edits = list(),
                      reg_scaling_source = "",
                      title, summary, bullets, input_notes, control_notes,
                      input_changes = NULL,
                      run_notes = character(),
                      outstanding = character(),
                      status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  # Main constructor for generated 2026 step folders.
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  remove_model_par_files(model_dir)

  frq_out <- file.path(model_dir, "bet.frq")
  if (identical(frq_transform, "effort_creep")) {
    if (!is.na(frq_chop_year)) {
      stop("Effort-creep transform is only implemented for full-year frq files", call. = FALSE)
    }
    write_frq_with_effort_creep(frq_source, frq_out)
    frq_note <- "copied with agreed effort-creep multiplier applied to index fisheries 29-33: 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024"
  } else if (is.na(frq_chop_year)) {
    copy_one(frq_source, frq_out)
    frq_note <- "copied without year chopping"
  } else {
    chop_frq(frq_source, frq_out, max_year = frq_chop_year)
    frq_note <- paste0("chopped to records with year <= ", frq_chop_year)
  }
  if (nzchar(index_cpue_source)) {
    replaced_cpue <- replace_frq_index_cpue_records(
      frq_out,
      index_cpue_source,
      max_year = frq_chop_year,
      index_fisheries = 29:33
    )
    frq_note <- paste0(
      frq_note,
      "; replaced ", replaced_cpue,
      " CPUE/index records for fisheries 29-33 with records from ",
      basename(index_cpue_source)
    )
  }
  n_normalized <- normalize_frq_absent_lf_records(frq_out)
  if (n_normalized) {
    frq_note <- paste0(
      frq_note,
      "; normalized ", n_normalized,
      " records with stray absent-LF bins"
    )
  }
  fixed_fishery_regions <- ensure_frq_fishery_region_locations(frq_out)
  if (isTRUE(fixed_fishery_regions)) {
    frq_note <- paste0(
      frq_note,
      "; completed the fishery-region location line for all fisheries, including index fisheries"
    )
  }
  if (!is.na(frq_tag_groups) && set_frq_tag_group_count(frq_out, frq_tag_groups)) {
    frq_note <- paste0(
      frq_note,
      "; reset frq tag-group header to ", frq_tag_groups,
      " to match the selected tag input"
    )
  }
  frq_counts <- frq_header_counts(readLines(frq_out, warn = FALSE), frq_out)
  ini_out <- file.path(model_dir, "bet.ini")
  tag_out <- file.path(model_dir, "bet.tag")
  copy_one(ini_source, ini_out)
  copy_one(tag_source, tag_out)
  tag_rep_repair_note <- repair_tag_reporting_matrices(
    ini_out,
    tag_out,
    reference_ini = if (exists("regfish_ini_source")) regfish_ini_source else "",
    reference_tag = if (exists("regfish_tag_source")) regfish_tag_source else ""
  )
  tag_reporting_note <- ""
  if (nzchar(tag_reporting_source)) {
    tag_reporting_note <- copy_tag_reporting_matrices(ini_out, tag_reporting_source)
  }
  tag_reporting_cell_notes <- character()
  if (length(tag_reporting_cell_repairs)) {
    for (repair in tag_reporting_cell_repairs) {
      tag_reporting_cell_notes <- c(
        tag_reporting_cell_notes,
        repair_positive_tag_recapture_reporting_rates(
          ini_out,
          tag_out,
          target_fishery = repair$target_fishery,
          source_fishery = repair$source_fishery
        )
      )
    }
    tag_reporting_cell_notes <- tag_reporting_cell_notes[nzchar(tag_reporting_cell_notes)]
  }
  validate_positive_tag_recapture_reporting_rates(ini_out, tag_out)
  tag_reporting_group_note <- repair_tag_reporting_grouped_initial_values(ini_out)
  validate_tag_reporting_grouped_initial_values(ini_out)
  apply_fixm_m(ini_out)
  total_population_note <- set_total_population_scalar(
    ini_out,
    get0("five_region_total_population_scalar", ifnotfound = 17L)
  )
  length_weight_note <- ""
  length_weight_parameters <- get0("bias_corrected_length_weight_parameters", ifnotfound = character())
  if (length(length_weight_parameters)) {
    length_weight_note <- set_length_weight_parameters(ini_out, length_weight_parameters)
  }
  ini_tag_note <- ensure_ini_tag_flags(
    ini_out,
    frq_counts$n_tag_groups,
    tag_path = tag_out,
    terminal_year = frq_chop_year,
    retain_reporting_rates_during_mixing = retain_reporting_rates_during_mixing,
    force_mixing_period = force_tag_mixing_period
  )
  ini_shed_note <- ensure_ini_tag_shed_rates(ini_out, frq_counts$n_tag_groups)
  fixm_note <- "FixM M row applied"
  fixm_source <- get0("fixm_age_par_source", ifnotfound = "")
  if (nzchar(fixm_source)) {
    fixm_note <- paste(fixm_note, "from", fixm_source)
  }
  ini_notes <- c(
    fixm_note,
    total_population_note,
    length_weight_note,
    tag_rep_repair_note,
    tag_reporting_note,
    tag_reporting_cell_notes,
    tag_reporting_group_note,
    ini_tag_note,
    ini_shed_note
  )
  ini_note <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  visible_ini_notes <- c(
    total_population_note,
    length_weight_note,
    tag_rep_repair_note,
    tag_reporting_note,
    tag_reporting_cell_notes,
    tag_reporting_group_note,
    ini_tag_note,
    ini_shed_note
  )
  visible_ini_notes <- visible_ini_notes[nzchar(visible_ini_notes)]
  if (length(visible_ini_notes) && "bet.ini" %in% names(input_notes)) {
    input_notes[["bet.ini"]] <- paste(
      c(input_notes[["bet.ini"]], visible_ini_notes),
      collapse = "; "
    )
  }
  age_out <- file.path(model_dir, "bet.age_length")
  copy_one(age_source, age_out)
  age_note <- set_age_length_effective_sample_size(age_out)
  if ("bet.age_length" %in% names(input_notes)) {
    input_notes[["bet.age_length"]] <- paste(
      c(input_notes[["bet.age_length"]], age_note),
      collapse = "; "
    )
  }
  has_reg_scaling <- nzchar(reg_scaling_source)
  if (has_reg_scaling) {
    regional_scaling_periods <- length(readLines(reg_scaling_source, warn = FALSE))
    copy_one(reg_scaling_source, file.path(model_dir, "bet.reg_scaling"))
    if (!"bet.reg_scaling" %in% names(input_notes)) {
      input_notes[["bet.reg_scaling"]] <-
        paste0(
          "Full `bet.2026.reg_scaling` global CPUE regional-scaling matrix; ",
          "parest flags select active periods ",
          reg_scaling_active_start_period, "-", reg_scaling_active_end_period,
          " (", reg_scaling_active_years, ") for the prior"
        )
    }
  }
  control_notes <- c(
    control_notes,
    "Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.",
    "Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.",
    "`age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
  )
  template_step_id <- get0("stepwise_5_region_template_step_id", ifnotfound = "04-NewStructure")
  template_model_dir <- file.path(root, "steps", template_step_id, "model")
  copy_one(file.path(template_model_dir, "mfcl.cfg"), file.path(model_dir, "mfcl.cfg"))
  fishery_map_out <- file.path(model_dir, "fishery_map.R")
  copy_one(file.path(template_model_dir, "fishery_map.R"), fishery_map_out)
  if (has_reg_scaling) {
    apply_regional_index_selectivity_map(fishery_map_out)
  }
  write_generated_tag_rep_map(model_dir)
  write_doitall(
    file.path(template_model_dir, "doitall.sh"),
    file.path(model_dir, "doitall.sh"),
    mix_from_ini = mix_from_ini,
    size_based_selectivity = isTRUE(doitall_edits$size_based_selectivity),
    time_varying_cv = isTRUE(doitall_edits$time_varying_cv),
    opr = isTRUE(doitall_edits$opr),
    data_weighting = isTRUE(doitall_edits$data_weighting),
    regional_scaling = has_reg_scaling,
    regional_scaling_periods = if (has_reg_scaling) regional_scaling_periods else 292L
  )
  reg_scaling_flags <- NULL
  reg_scaling_window <- NULL
  if (has_reg_scaling) {
    doitall_out <- file.path(model_dir, "doitall.sh")
    reg_scaling_flags <- parse_doitall_parest_flags(doitall_out, 77:81)
    reg_scaling_window <- regional_scaling_period_window(reg_scaling_flags, regional_scaling_periods)
    control_notes <- c(
      control_notes,
      regional_scaling_control_notes(doitall_out, regional_scaling_periods, reg_scaling_active_years)
    )
  }

  entries <- list(
    list(role = "frq", file = "bet.frq", source = frq_source, note = frq_note),
    list(role = "ini", file = "bet.ini", source = ini_source, note = ini_note),
    list(role = "tag", file = "bet.tag", source = tag_source, note = "tag reporting map regenerated from ini/tag; five MFCL reporting-rate matrices parsed"),
    list(role = "age_length", file = "bet.age_length", source = age_source, note = paste("CAAL input", age_note, sep = "; ")),
    list(role = "doitall", file = "doitall.sh", source = file.path("steps", template_step_id, "model", "doitall.sh"), note = paste(c(
      ifelse(mix_from_ini, "mixing override removed", paste0(template_step_id, " 5-region controls retained")),
      if (has_reg_scaling) paste0(
        "regional scaling Prior_reg_biomass switch applied in PHASE 5 with ",
        "flags 77=", format_flag_value(reg_scaling_flags[["77"]]),
        ", 78=", format_flag_value(reg_scaling_flags[["78"]]),
        ", 79=", format_flag_value(reg_scaling_flags[["79"]]),
        ", 80=", format_flag_value(reg_scaling_flags[["80"]]),
        ", 81=", format_flag_value(reg_scaling_flags[["81"]]),
        "; active periods ", reg_scaling_window$start, "-", reg_scaling_window$end,
        " (", reg_scaling_active_years, ")"
      ),
      if (has_reg_scaling) "index CPUE/selectivity groups unshared from PHASE 5",
      "doitall exits immediately on MFCL command failure",
      if (isTRUE(doitall_edits$time_varying_cv)) "index fishery time-varying CPUE CV flags enabled",
      if (isTRUE(doitall_edits$size_based_selectivity)) "fish flag 26 set to 3",
      if (isTRUE(doitall_edits$opr)) "OPR recruitment flags applied",
      if (isTRUE(doitall_edits$data_weighting)) "global LF/WF divisors set to 40"
    ), collapse = "; "))
  )
  if (nzchar(index_cpue_source)) {
    entries <- append(entries, list(list(
      role = "frq_cpue",
      file = "bet.frq",
      source = index_cpue_source,
      note = "CPUE/index fishery records 29-33 retained from the 2023 new-structure frq while non-index size/catch records come from the 2026 frq source"
    )), after = 1L)
  }
  if (has_reg_scaling) {
    entries <- append(entries, list(list(
      role = "reg_scaling",
      file = "bet.reg_scaling",
      source = reg_scaling_source,
      note = paste0(
        "full global CPUE regional-scaling matrix copied unchanged; parest ",
        "flags 77-81 define active periods ", reg_scaling_window$start, "-",
        reg_scaling_window$end,
        " so native MFCL takes only the flagged rows internally"
      )
    )), after = 4L)
  }
  write_manifest(step_dir, entries)
  outstanding <- c(
    outstanding,
    "Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs."
  )
  write_readme(
    step_dir = step_dir,
    title = title,
    summary = summary,
    bullets = bullets,
    inputs = c(input_notes, "input_manifest.csv" = "machine-readable source/input notes"),
    controls = control_notes,
    outstanding = outstanding,
    status = status,
    run_notes = run_notes,
    input_changes = input_changes,
    source_revisions = input_repo_revision_table()
  )
}
