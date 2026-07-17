#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT_DIR="${OUTPUT_DIR:-outputs}"
WORK_DIR="${ROOT}/work"
PROGRAM_PATH="${PROGRAM_PATH:-/home/mfcl/mfclo64}"

runtime_package_specs() {
  printf "%s" "${KFLOW_REPO_RUNTIME_PACKAGES:-${KFLOW_RUNTIME_PACKAGES:-}}"
}

runtime_update_mode() {
  printf "%s" "${KFLOW_REPO_RUNTIME_UPDATE:-${TUNA_FLOW_RUNTIME_UPDATE:-${KFLOW_RUNTIME_UPDATE:-auto}}}"
}

runtime_packages_disabled() {
  case "$(runtime_package_specs)" in
    ""|0|false|FALSE|no|NO|off|OFF|none|NONE|skip|SKIP) return 0 ;;
    *) return 1 ;;
  esac
}

runtime_updates_disabled() {
  case "$(runtime_update_mode)" in
    ""|0|false|FALSE|no|NO|off|OFF|none|NONE|skip|SKIP|never|NEVER) return 0 ;;
    *) return 1 ;;
  esac
}

runtime_updates_direct() {
  case "$(runtime_update_mode)" in
    auto|AUTO|always|ALWAYS|token|TOKEN|direct|DIRECT|url|URL|download|DOWNLOAD) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_runtime_library() {
  local preferred="${R_LIBS_USER:-${KFLOW_RUNTIME_LIBRARY:-}}"
  local fallback="${ROOT}/.R-library"
  if [[ -z "$preferred" ]]; then
    preferred="$fallback"
  fi
  if mkdir -p "$preferred" 2>/dev/null && [[ -w "$preferred" ]]; then
    export R_LIBS_USER="$preferred"
  else
    export R_LIBS_USER="$fallback"
    mkdir -p "$R_LIBS_USER"
  fi
  export KFLOW_RUNTIME_LIBRARY="$R_LIBS_USER"
  export KFLOW_RUNTIME_STATE_DIR="${KFLOW_RUNTIME_STATE_DIR:-${ROOT}/.kflow-runtime-cache}"
  mkdir -p "$KFLOW_RUNTIME_STATE_DIR" 2>/dev/null || true
}

runtime_private_packages_required() {
  case "${KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES:-false}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

drop_runtime_tokens() {
  unset GIT_PAT GITHUB_PAT GITHUB_TOKEN GH_TOKEN KFLOW_GITHUB_TOKEN KFLOW_PERSONAL_TOKEN
}

truthy_value() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y|on|ON|always|ALWAYS) return 0 ;;
    *) return 1 ;;
  esac
}

truthy_env() {
  local name="$1"
  local default="${2:-false}"
  local value="${!name:-$default}"
  truthy_value "$value"
}

publish_required() {
  truthy_env STEPWISE_PUBLISH_REQUIRED false
}

publish_fail() {
  local message="$1"
  if publish_required; then
    echo "[stepwise-par-publish] ${message}" >&2
    return 1
  fi
  echo "[stepwise-par-publish] ${message}; continuing because publish is not required." >&2
  return 0
}

first_runtime_token() {
  local name
  for name in GITHUB_PAT GIT_PAT GH_TOKEN KFLOW_GITHUB_TOKEN KFLOW_PERSONAL_TOKEN; do
    if [[ -n "${!name:-}" ]]; then
      printf "%s" "${!name}"
      return 0
    fi
  done
  return 1
}

install_missing_runtime_packages() {
  runtime_packages_disabled && return 0
  runtime_updates_disabled && return 0
  ensure_runtime_library
  Rscript - <<'RS'
truthy <- function(value) tolower(value) %in% c("1", "true", "yes", "y", "on", "always")
spec_text <- Sys.getenv("KFLOW_REPO_RUNTIME_PACKAGES", Sys.getenv("KFLOW_RUNTIME_PACKAGES", ""))
parts <- trimws(strsplit(spec_text, ",", fixed = TRUE)[[1]])
parts <- parts[nzchar(parts) & grepl("=", parts, fixed = TRUE)]
if (!length(parts)) quit(save = "no", status = 0)
specs <- lapply(parts, function(part) {
  eq <- regexpr("=", part, fixed = TRUE)[1]
  package <- trimws(substr(part, 1, eq - 1))
  repo_ref <- trimws(substr(part, eq + 1, nchar(part)))
  at <- regexpr("@", repo_ref, fixed = TRUE)[1]
  if (at > 0) {
    repo <- substr(repo_ref, 1, at - 1)
    ref <- substr(repo_ref, at + 1, nchar(repo_ref))
  } else {
    repo <- repo_ref
    ref <- "main"
  }
  list(package = package, repo = repo, ref = ref)
})
lib <- Sys.getenv("R_LIBS_USER", "")
if (!nzchar(lib)) quit(save = "no", status = 43)
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(lib, .libPaths())))
desc_field <- function(desc, name) {
  value <- tryCatch(desc[[name]], error = function(e) "")
  if (is.null(value) || !length(value) || is.na(value[[1L]])) "" else as.character(value[[1L]])
}
installed_desc <- function(package) {
  desc <- tryCatch(
    suppressWarnings(utils::packageDescription(package, lib.loc = lib)),
    error = function(e) NULL
  )
  if (length(desc) == 1L && is.na(desc[[1L]])) NULL else desc
}
needs_install <- function(spec) {
  desc <- installed_desc(spec$package)
  if (is.null(desc)) return(TRUE)
  installed_sha <- desc_field(desc, "RemoteSha")
  ref_is_sha <- grepl("^[0-9a-f]{7,40}$", spec$ref, ignore.case = TRUE)
  if (ref_is_sha) {
    return(!nzchar(installed_sha) || !startsWith(tolower(installed_sha), tolower(spec$ref)))
  }
  TRUE
}
missing <- specs[vapply(specs, needs_install, logical(1))]
if (!length(missing)) quit(save = "no", status = 0)
options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("remotes", quietly = TRUE)) {
  utils::install.packages("remotes", lib = lib, dependencies = TRUE, repos = getOption("repos"))
}
token <- ""
token_name <- ""
for (name in c("GITHUB_PAT", "GIT_PAT", "GITHUB_TOKEN", "GH_TOKEN", "KFLOW_GITHUB_TOKEN", "KFLOW_PERSONAL_TOKEN")) {
  value <- Sys.getenv(name, "")
  if (nzchar(value)) {
    token <- value
    token_name <- name
    break
  }
}
if (nzchar(token_name)) {
  message("[kflow-runtime-update] Runtime GitHub access has token from ", token_name, ".")
} else {
  message("[kflow-runtime-update] Runtime GitHub access has no token.")
}
download_github_archive <- function(repo, ref) {
  archive <- tempfile(pattern = "kflow-runtime-", fileext = ".tar.gz")
  url <- if (nzchar(token)) {
    sprintf("https://api.github.com/repos/%s/tarball/%s", repo, ref)
  } else {
    sprintf("https://codeload.github.com/%s/tar.gz/%s", repo, ref)
  }
  curl <- Sys.which("curl")
  if (nzchar(curl)) {
    args <- c("-sSL", "--retry", "3", "--retry-delay", "2", "-w", "%{http_code}", "-o", archive)
    if (nzchar(token)) {
      args <- c(
        "-H", paste("Authorization: Bearer", token),
        "-H", "Accept: application/vnd.github+json",
        args
      )
    }
    output <- tryCatch(suppressWarnings(system2(curl, c(args, url), stdout = TRUE, stderr = TRUE)),
      error = function(e) structure(conditionMessage(e), status = 1L))
    status <- attr(output, "status")
    if (is.null(status)) status <- 0L
    code <- tail(grep("^[0-9]{3}$", as.character(output), value = TRUE), 1)
    if (!identical(as.integer(status), 0L) || !length(code) || !grepl("^2", code)) {
      stop("download failed from ", url, " (curl exit ", status, ", http ", ifelse(length(code), code, "unknown"), ")")
    }
  } else {
    headers <- if (nzchar(token)) c(Authorization = paste("Bearer", token)) else NULL
    status <- utils::download.file(url, archive, mode = "wb", quiet = TRUE, method = "libcurl", headers = headers)
    if (!identical(status, 0L)) {
      stop("download failed from ", url)
    }
  }
  archive
}
clone_github_source <- function(repo, ref) {
  git <- Sys.which("git")
  if (!nzchar(git)) {
    stop("git is required for runtime package source fallback", call. = FALSE)
  }
  source_dir <- tempfile(pattern = "kflow-runtime-src-")
  unlink(source_dir, recursive = TRUE, force = TRUE)
  git_url <- sprintf("https://github.com/%s.git", repo)
  askpass <- ""
  if (nzchar(token)) {
    askpass <- tempfile(pattern = "kflow-git-askpass-")
    writeLines(c(
      "#!/bin/sh",
      "case \"$1\" in",
      "  *Username*) printf '%s\\n' x-access-token ;;",
      "  *) printf '%s\\n' \"$KFLOW_GIT_ASKPASS_TOKEN\" ;;",
      "esac"
    ), askpass)
    Sys.chmod(askpass, mode = "0700")
    on.exit(unlink(askpass), add = TRUE)
  }
  run_git <- function(args) {
    env <- character()
    if (nzchar(askpass)) {
      env <- c(
        paste0("GIT_ASKPASS=", askpass),
        "GIT_TERMINAL_PROMPT=0",
        paste0("KFLOW_GIT_ASKPASS_TOKEN=", token)
      )
    }
    status <- system2(git, args, env = env, stdout = FALSE, stderr = FALSE)
    identical(as.integer(status), 0L)
  }
  if (!run_git(c("clone", "--quiet", "--depth", "50", git_url, source_dir))) {
    stop("git clone failed for ", repo, call. = FALSE)
  }
  if (!run_git(c("-C", source_dir, "checkout", "--quiet", ref))) {
    if (!run_git(c("-C", source_dir, "fetch", "--quiet", "--depth", "1", "origin", ref)) ||
        !run_git(c("-C", source_dir, "checkout", "--quiet", "FETCH_HEAD"))) {
      stop("git checkout failed for ", repo, "@", ref, call. = FALSE)
    }
  }
  resolved_sha <- tryCatch(
    trimws(system2(git, c("-C", source_dir, "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE)[[1]]),
    error = function(e) ""
  )
  if (nzchar(resolved_sha)) {
    attr(source_dir, "kflow_resolved_sha") <- resolved_sha
  }
  source_dir
}
install_local_source <- function(path, lib) {
  desc_path <- file.path(path, "DESCRIPTION")
  if (file.exists(desc_path)) {
    desc <- read.dcf(desc_path)
    dep_fields <- intersect(c("Depends", "Imports", "LinkingTo"), colnames(desc))
    deps <- unlist(strsplit(paste(desc[1, dep_fields], collapse = ","), ",", fixed = TRUE), use.names = FALSE)
    deps <- trimws(gsub("\\s*\\([^)]*\\)", "", deps))
    deps <- setdiff(unique(deps[nzchar(deps)]), c("R"))
    missing_deps <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]
    if (length(missing_deps)) {
      message("[kflow-runtime-update] Installing CRAN dependencies for ",
              basename(path), ": ", paste(missing_deps, collapse = ", "), ".")
      utils::install.packages(
        missing_deps,
        lib = lib,
        dependencies = c("Depends", "Imports", "LinkingTo"),
        repos = getOption("repos")
      )
    }
  }
  r_bin <- file.path(R.home("bin"), "R")
  output <- tryCatch(
    system2(
      r_bin,
      c("CMD", "INSTALL", "-l", lib, path),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (!identical(as.integer(status), 0L)) {
    detail <- paste(tail(as.character(output), 30), collapse = "\n")
    stop("R CMD INSTALL failed for ", basename(path), "\n", detail, call. = FALSE)
  }
}
write_remote_metadata <- function(package, repo, ref, sha, lib) {
  desc_path <- system.file("DESCRIPTION", package = package, lib.loc = lib)
  if (!nzchar(desc_path) || !file.exists(desc_path)) return(invisible(FALSE))
  repo_parts <- strsplit(repo, "/", fixed = TRUE)[[1]]
  remote <- list(
    RemoteType = "github",
    RemoteHost = "api.github.com",
    RemoteUsername = repo_parts[[1]],
    RemoteRepo = repo_parts[[length(repo_parts)]],
    RemoteRef = ref,
    RemoteSha = sha
  )
  fields <- as.list(read.dcf(desc_path)[1, ])
  fields[names(remote)] <- remote
  write.dcf(as.data.frame(fields, stringsAsFactors = FALSE, check.names = FALSE), desc_path)
  meta_path <- system.file("Meta", "package.rds", package = package, lib.loc = lib)
  if (file.exists(meta_path)) {
    meta <- readRDS(meta_path)
    meta[["DESCRIPTION"]][names(remote)] <- unlist(remote)
    saveRDS(meta, meta_path)
  }
  invisible(TRUE)
}
for (spec in missing) {
  message("[kflow-runtime-update] Installing/updating runtime package ", spec$package, " from ", spec$repo, "@", spec$ref, ".")
  err <- tryCatch({
    ref_is_sha <- grepl("^[0-9a-f]{7,40}$", spec$ref, ignore.case = TRUE)
    source_path <- if (ref_is_sha) {
      tryCatch(
        download_github_archive(spec$repo, spec$ref),
        error = function(err) {
          message("[kflow-runtime-update] Runtime archive download failed for ", spec$package,
                  "; trying git clone fallback.")
          clone_github_source(spec$repo, spec$ref)
        }
      )
    } else {
      clone_github_source(spec$repo, spec$ref)
    }
    resolved_sha <- attr(source_path, "kflow_resolved_sha", exact = TRUE)
    if (is.null(resolved_sha) || !nzchar(resolved_sha)) {
      resolved_sha <- spec$ref
    }
    if (!identical(resolved_sha, spec$ref)) {
      message("[kflow-runtime-update] Resolved ", spec$repo, "@", spec$ref, " to ", substr(resolved_sha, 1, 12), ".")
    }
    on.exit(unlink(source_path, recursive = TRUE, force = TRUE), add = TRUE)
    install_local_source(source_path, lib)
    write_remote_metadata(spec$package, spec$repo, spec$ref, resolved_sha, lib)
    message("[kflow-runtime-update] Installed ", spec$package, " at ", substr(resolved_sha, 1, 12), ".")
    NULL
  }, error = function(e) e)
  if (inherits(err, "error")) {
    message("[kflow-runtime-update] Runtime package install failed for ", spec$package, ": ", conditionMessage(err))
  }
}
matches_requested_ref <- function(spec) {
  desc <- installed_desc(spec$package)
  if (is.null(desc)) return(FALSE)
  installed_sha <- desc_field(desc, "RemoteSha")
  if (grepl("^[0-9a-f]{7,40}$", spec$ref, ignore.case = TRUE)) {
    return(nzchar(installed_sha) && startsWith(tolower(installed_sha), tolower(spec$ref)))
  }
  installed_ref <- desc_field(desc, "RemoteRef")
  nzchar(installed_sha) && identical(installed_ref, spec$ref)
}
unresolved_after <- specs[!vapply(specs, matches_requested_ref, logical(1))]
if (length(unresolved_after) && truthy(Sys.getenv("KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES", "false"))) {
  message("[kflow-runtime-update] Required runtime package(s) unavailable at the requested ref: ",
          paste(vapply(unresolved_after, function(spec) paste0(spec$package, "@", spec$ref), character(1)), collapse = ", "))
  quit(save = "no", status = 44)
}
quit(save = "no", status = 0)
RS
}

prepare_runtime_packages() {
  runtime_packages_disabled && return 0
  ensure_runtime_library
  if runtime_updates_direct; then
    install_missing_runtime_packages
    drop_runtime_tokens
    return 0
  fi
  if [[ -x /usr/local/bin/30-update-kflow-runtime-packages ]]; then
    if bash /usr/local/bin/30-update-kflow-runtime-packages; then
      :
    else
      update_status=$?
      if runtime_private_packages_required || [[ "$update_status" -eq 42 || "$update_status" -eq 43 ]]; then
        exit "$update_status"
      fi
      echo "[kflow-runtime-update] Runtime package update failed; continuing with bundled packages." >&2
    fi
  else
    echo "[kflow-runtime-update] Runtime updater not found; using bundled packages." >&2
  fi
  install_missing_runtime_packages
}

kflow_job_ref() {
  local job_id="${KFLOW_JOB_ID:-}"
  local job_number="${KFLOW_JOB_NUMBER:-}"
  if [[ -n "$job_number" ]]; then
    if [[ -n "$job_id" ]]; then
      printf "Job %s (%s)" "$job_number" "$job_id"
    else
      printf "Job %s" "$job_number"
    fi
  elif [[ -n "$job_id" ]]; then
    printf "%s" "$job_id"
  else
    printf "manual/local"
  fi
}

saved_par_paths() {
  local manifest="${OUT_DIR}/saved-pars.csv"
  if [[ ! -f "$manifest" ]]; then
    return 0
  fi
  Rscript - "$manifest" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
manifest <- args[[1]]
x <- tryCatch(read.csv(manifest, stringsAsFactors = FALSE), error = function(e) data.frame())
if (!NROW(x) || !"saved_par" %in% names(x)) quit(save = "no", status = 0)
paths <- unique(x$saved_par[nzchar(x$saved_par)])
paths <- paths[grepl("^steps/[^/]+/model/[^/]+[.]par[0-9]*$", paths)]
cat(paths, sep = "\n")
RS
}

saved_par_summary() {
  local manifest="${OUT_DIR}/saved-pars.csv"
  if [[ ! -f "$manifest" ]]; then
    printf -- "- no saved par manifest found"
    return 0
  fi
  Rscript - "$manifest" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
manifest <- args[[1]]
x <- tryCatch(read.csv(manifest, stringsAsFactors = FALSE), error = function(e) data.frame())
if (!NROW(x)) {
  cat("- no final .par files were recorded\n")
  quit(save = "no", status = 0)
}
limit <- 60L
for (i in seq_len(min(NROW(x), limit))) {
  fallback <- if ("par_fallback" %in% names(x) && isTRUE(tolower(as.character(x$par_fallback[[i]])) %in% c("true", "1"))) " (fell back to doitall)" else ""
  cat(sprintf("- %s: %s -> %s%s\n", x$step_id[[i]], x$run_mode[[i]], x$saved_par[[i]], fallback))
}
if (NROW(x) > limit) {
  cat(sprintf("- ... %d more saved .par file(s)\n", NROW(x) - limit))
}
RS
}

changed_par_summary() {
  local -a stage_paths=("$@")
  git diff --cached --name-status -- "${stage_paths[@]}" |
    awk -F '\t' '
      BEGIN { limit = 80 }
      {
        total++
        if (total > limit) next
        status = $1
        label = status
        if (status == "A") label = "added"
        else if (status == "M") label = "modified"
        else if (status == "D") label = "removed"
        else if (status ~ /^R/) label = "renamed"
        else if (status ~ /^C/) label = "copied"
        if (NF >= 3) print "- " label ": " $2 " -> " $3
        else print "- " label ": " $2
      }
      END {
        if (total > limit) print "- ... " (total - limit) " more changed path(s)"
        if (total == 0) print "- no path-level changes detected"
      }
    '
}

publish_final_pars() {
  truthy_env STEPWISE_COMMIT_FINAL_PARS false || return 0
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    publish_fail "Cannot commit final .par files because this is not a git checkout."
    return $?
  fi

  local branch="${GITHUB_BRANCH:-}"
  if [[ -z "$branch" ]]; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  fi
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    publish_fail "Cannot publish final .par files because the target branch is unknown."
    return $?
  fi

  local -a stage_paths=()
  local path
  while IFS= read -r path; do
    [[ -n "$path" && -f "$path" ]] && stage_paths+=("$path")
  done < <(saved_par_paths)

  if [[ "${#stage_paths[@]}" -eq 0 ]]; then
    publish_fail "No final .par files were found to commit."
    return $?
  fi

  git config user.name "${KFLOW_GIT_AUTHOR_NAME:-KflowBot}"
  git config user.email "${KFLOW_GIT_AUTHOR_EMAIL:-kflow-bot@localhost}"
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    git remote set-url origin "https://github.com/${GITHUB_REPOSITORY}.git" >/dev/null 2>&1 || true
  fi

  git add -- "${stage_paths[@]}"
  if git diff --cached --quiet; then
    echo "[stepwise-par-publish] Final .par files are already committed."
    return 0
  fi

  local changed_paths saved_summary job_ref job_subject subject body
  changed_paths="$(changed_par_summary "${stage_paths[@]}")"
  saved_summary="$(saved_par_summary)"
  job_ref="$(kflow_job_ref)"
  job_subject="${job_ref%% (*}"
  subject="Save final stepwise par files from Kflow ${job_subject}"
  body=$(
    cat <<EOF
Kflow:
- task: ${GITHUB_REPOSITORY:-ofp-sam-bet-2026-stepwise}
- job: ${job_ref}
- flow group: ${FLOW_GROUP:-unknown}
- step select: ${STEP_SELECT:-unknown}
- model label: ${MODEL_LABEL:-unknown}
- requested run mode: ${RUN_MODE:-unknown}
- branch: ${branch}

Saved final .par files for future reruns:
${saved_summary}

Changed paths:
${changed_paths}
EOF
  )
  git commit -m "$subject" -m "$body"

  truthy_env STEPWISE_PUSH_FINAL_PARS false || {
    echo "[stepwise-par-publish] Final .par files committed locally; push disabled."
    return 0
  }

  local token=""
  token="$(first_runtime_token || true)"
  if [[ -z "$token" ]]; then
    publish_fail "Cannot push final .par commit because no GitHub token is available."
    return $?
  fi

  local askpass
  askpass="$(mktemp)"
  cat > "$askpass" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  *Username*) printf "%s\n" "x-access-token" ;;
  *Password*) printf "%s\n" "${STEPWISE_GIT_TOKEN:-}" ;;
  *) printf "\n" ;;
esac
EOF
  chmod 700 "$askpass"
  if STEPWISE_GIT_TOKEN="$token" GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 git push origin "HEAD:${branch}"; then
    rm -f "$askpass"
    echo "[stepwise-par-publish] Pushed final .par files to ${GITHUB_REPOSITORY:-origin}:${branch}."
    return 0
  fi
  rm -f "$askpass"
  publish_fail "Final .par commit was created, but git push failed."
}

mkdir -p "${OUT_DIR}" "${WORK_DIR}"
rm -rf "${WORK_DIR}/inputs"
mkdir -p "${WORK_DIR}/inputs"

echo "BET stepwise task"
echo "Model folders: steps/<step-id>/model"
echo "MFCL program: ${PROGRAM_PATH}"

case "${RUN_MODE:-}" in
  attach|attach_outputs|attach-checks|attach_checks|update_outputs|update-outputs)
    Rscript R/attach_outputs.R
    ;;
  *)
    prepare_runtime_packages
    Rscript R/run_stepwise.R
    publish_final_pars
    ;;
esac
drop_runtime_tokens
