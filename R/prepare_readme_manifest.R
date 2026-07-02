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

readme_blank <- function(x) {
  x <- as.character(x)
  x[is.na(x) | !nzchar(x)] <- "blank"
  x
}

readme_escape <- function(x) {
  x <- readme_blank(x)
  x <- gsub("\\|", "\\\\|", x)
  x <- gsub("\n", " ", x, fixed = TRUE)
  x
}

readme_table <- function(df, code_columns = character()) {
  if (!nrow(df)) return("_None._")
  headers <- names(df)
  header_line <- paste(headers, collapse = " | ")
  sep_line <- paste(rep("---", length(headers)), collapse = " | ")
  body <- apply(df, 1, function(row) {
    values <- vapply(seq_along(headers), function(i) {
      value <- readme_escape(row[[i]])
      if (headers[[i]] %in% code_columns) value <- paste0("`", value, "`")
      value
    }, character(1))
    paste(values, collapse = " | ")
  })
  c(
    paste0("| ", header_line, " |"),
    paste0("| ", sep_line, " |"),
    paste0("| ", body, " |")
  )
}

numbered_table <- function(values, value_name) {
  values <- values[nzchar(values)]
  out <- data.frame(seq_along(values), values, check.names = FALSE, stringsAsFactors = FALSE)
  names(out) <- c("#", value_name)
  out
}

input_change_table <- function(scope, generated_change, unchanged) {
  data.frame(
    Scope = scope,
    `Generated change` = generated_change,
    `Unchanged` = unchanged,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

named_table <- function(values, key_name, value_name, code_keys = TRUE) {
  out <- data.frame(names(values), unname(values), check.names = FALSE, stringsAsFactors = FALSE)
  names(out) <- c(key_name, value_name)
  out
}

compact_control_notes <- function(notes) {
  common_patterns <- c(
    "^Generated `[.]frq` files include region locations",
    "^Generated `[.]ini` files also validate",
    "^`age_flags\\(128\\)` is kept",
    "^`doitall[.]sh` uses `set -eu`",
    "^PHASE 10/11 convergence is controlled"
  )
  is_common <- Reduce(`|`, lapply(common_patterns, grepl, x = notes))
  out <- notes[!is_common]
  if (any(is_common)) {
    out <- c(
      out,
      "Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch."
    )
  }
  out
}

write_readme <- function(step_dir, title, summary, bullets, inputs, controls,
                         outstanding = character(), status,
                         run_notes = character(),
                         input_changes = NULL,
                         source_revisions = NULL) {
  inputs <- setNames(inputs, readme_input_label(names(inputs)))
  controls <- compact_control_notes(controls)
  input_change_lines <- if (is.data.frame(input_changes) && nrow(input_changes)) {
    c(
      "",
      "## Generated Input Changes",
      "",
      readme_table(input_changes, code_columns = "Scope")
    )
  } else {
    character()
  }
  source_revision_lines <- if (is.data.frame(source_revisions) && nrow(source_revisions)) {
    c(
      "",
      "## Source Revisions",
      "",
      readme_table(
        data.frame(
          Repository = source_revisions$repo,
          Commit = source_revisions$commit,
          Note = source_revisions$subject,
          check.names = FALSE,
          stringsAsFactors = FALSE
        ),
        code_columns = c("Repository", "Commit")
      )
    )
  } else {
    character()
  }
  run_note_lines <- if (length(run_notes)) {
    c(
      "",
      "## Run Notes",
      "",
      readme_table(numbered_table(run_notes, "Note"))
    )
  } else {
    character()
  }
  outstanding <- if (length(outstanding)) outstanding else "No extra unresolved build items for this transition beyond fitting diagnostics."
  step_id <- basename(step_dir)
  lines <- c(
    paste0("# ", title),
    "",
    summary,
    "",
    "## Snapshot",
    "",
    readme_table(
      data.frame(
        Field = c("Step folder", "Status"),
        Value = c(paste0("`", file.path("steps", step_id, "model"), "`"), status),
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
    ),
    "",
    "## Changes",
    "",
    readme_table(numbered_table(bullets, "Change")),
    "",
    "## Inputs",
    "",
    readme_table(named_table(inputs, "File", "Source / note"), code_columns = "File"),
    input_change_lines,
    source_revision_lines,
    "",
    "## Controls",
    "",
    readme_table(numbered_table(controls, "Control")),
    run_note_lines,
    "",
    "## Checks",
    "",
    readme_table(numbered_table(outstanding, "Check"))
  )
  writeLines(lines, file.path(step_dir, "README.md"), useBytes = TRUE)
}
