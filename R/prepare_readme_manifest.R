## Writers for generated step README files and machine-readable manifests.

write_manifest <- function(step_dir, entries) {
  manifest <- do.call(rbind, lapply(entries, function(x) {
    data.frame(
      role = x$role,
      file = x$file,
      source = public_source_path(x$source),
      source_commit = source_commit_for_path(x$source),
      note = x$note,
      stringsAsFactors = FALSE
    )
  }))
  write.csv(manifest, file.path(step_dir, "input_manifest.csv"), row.names = FALSE)
}

readme_input_label <- function(file) {
  sub("^bet[.]", ".", file)
}

write_readme <- function(step_dir, title, summary, bullets, inputs, controls,
                         outstanding = character(), status,
                         run_notes = character(),
                         source_revisions = NULL) {
  bullet_lines <- paste0("- ", bullets)
  input_lines <- paste0("- `", readme_input_label(names(inputs)), "`: ", unname(inputs))
  source_revision_lines <- if (is.data.frame(source_revisions) && nrow(source_revisions)) {
    c(
      "",
      "## Source Revisions",
      "",
      paste0(
        "- `", source_revisions$repo, "`: `", source_revisions$commit, "`",
        ifelse(nzchar(source_revisions$subject), paste0(" - ", source_revisions$subject), "")
      )
    )
  } else {
    character()
  }
  control_lines <- paste0("- ", controls)
  run_note_lines <- if (length(run_notes)) {
    c("", "## Run Note", "", paste0("- ", run_notes))
  } else {
    character()
  }
  outstanding_lines <- if (length(outstanding)) {
    paste0("- ", outstanding)
  } else {
    "- No extra unresolved build items for this transition beyond fitting diagnostics."
  }
  lines <- c(
    paste0("# ", title),
    "",
    summary,
    "",
    "## What Changed",
    "",
    bullet_lines,
    "",
    "## Inputs",
    "",
    input_lines,
    source_revision_lines,
    "",
    "## Control Notes",
    "",
    control_lines,
    run_note_lines,
    "",
    "## Outstanding Checks",
    "",
    outstanding_lines,
    "",
    "## Status",
    "",
    status
  )
  writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
}
