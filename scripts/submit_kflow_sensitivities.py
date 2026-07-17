#!/usr/bin/env python3
"""Safely submit the 36 BET LF-conflict sensitivity fits and diagnostics.

The default action is an audit-only dry run.  Real Kflow POST requests require
``--submit`` as well as a clean, pushed source/runtime checkout.  Reruns use a
locked atomic JSON state file and reconcile deterministic fit/diagnostic tags
with Kflow before creating more work.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import contextlib
import csv
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Iterable

import yaml


TASK_NAME = "ofp-sam-bet-2026-lf-conflict-sensitivities-standalone"
CHECK_TASK_PREFIX = f"{TASK_NAME}-check"
CAMPAIGN = "lf-conflict-sensitivities-v1"
INPUT_JOB = "5319"
EXPECTED_MODELS = 36

SUVA_HOST = "suvofpsubmit.corp.spc.int"
SUVA_USER = "kyuhank"
SUVA_BASE_DIR = "/home/kyuhank/KflowOutput"
SUVA_SLOT_REQUIREMENT = 'regexp("^suvofp", Machine)'
CPUS = 2
MEMORY = "8GB"
DISK = "10GB"
PROGRAM_PATH = "/home/mfcl/mfclo64"
DOCKER_IMAGE = "ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360"

REPO_ROOT = Path(__file__).resolve().parents[1]
KFLOW_CONFIG = REPO_ROOT / "kflow.yaml"
SENSITIVITY_ROOT = REPO_ROOT / "sensitivity"
CHECKS_REPO = Path("/home/kyuhank/Desktop/SPC/ofp-sam-bet-2026-checks")
CHECKS_HELPER = CHECKS_REPO / "scripts/submit_kflow_checks.py"
CHECKS_BRANCH = os.environ.get("KFLOW_CHECKS_BRANCH", "main").strip() or "main"
KFLOW_REPO = Path("/home/kyuhank/Desktop/SPC/Kflow")
MFCLKIT_REPO = Path("/home/kyuhank/Desktop/SPC/ofp-sam-mfclkit")
MFCLSHINY_REPO = Path("/home/kyuhank/Desktop/SPC/mfclshiny")
MFCL_IMAGE_REPO = Path("/home/kyuhank/Desktop/SPC/ofp-sam-docker-images")
MFCL_BINARY = MFCL_IMAGE_REPO / "tuna-flow/mfclo64"
MFCL_DOCKERFILE = MFCL_IMAGE_REPO / "tuna-flow/Dockerfile"


def runtime_github_token() -> str:
    """Return a local GitHub token for one-request Kflow forwarding."""

    for name in ("KFLOW_GITHUB_TOKEN", "GITHUB_PAT", "GIT_PAT", "GH_TOKEN", "GITHUB_TOKEN"):
        value = str(os.environ.get(name) or "").strip()
        if value:
            return value
    try:
        result = subprocess.run(
            ["gh", "auth", "token"],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
        )
        value = result.stdout.strip()
        if result.returncode == 0 and re.fullmatch(r"(?:gh[pousr]_[A-Za-z0-9]+|github_pat_[A-Za-z0-9_]+)", value):
            return value
    except (FileNotFoundError, subprocess.SubprocessError):
        pass
    config_roots = [
        Path(os.environ.get("GH_CONFIG_DIR", "")),
        Path(os.environ.get("XDG_CONFIG_HOME", "")) / "gh",
        Path.home() / ".config" / "gh",
        Path(os.environ.get("APPDATA", "")) / "GitHub CLI",
        Path.home() / "Library" / "Application Support" / "gh",
    ]
    for root in config_roots:
        if not str(root).strip() or str(root) == ".":
            continue
        path = root / "hosts.yml"
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        match = re.search(r"^\s*oauth_token:\s*['\"]?([^'\"#\s]+)", text, re.MULTILINE)
        if match:
            return match.group(1)
    return ""

DEFAULT_STATE = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    / TASK_NAME
    / "submission-state.json"
)
SHA40_RE = re.compile(r"^[0-9a-f]{40}$", re.IGNORECASE)
SHA256_RE = re.compile(r"^(?:sha256:)?([0-9a-f]{64})$", re.IGNORECASE)
MODEL_RE = re.compile(r"^S([0-9]{3})-[A-Z0-9-]+$")
ACTIVE_JOB_STATES = {"waiting", "pending", "queued", "submitted", "running", "completed"}


class OrchestratorError(RuntimeError):
    """A concise, user-actionable orchestration failure."""


class ApiError(OrchestratorError):
    def __init__(self, message: str, *, transient: bool = False) -> None:
        super().__init__(message)
        self.transient = transient


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def json_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_json(value).encode("ascii")).hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def redact(text: str, secrets: Iterable[str]) -> str:
    out = str(text or "")
    for secret in secrets:
        if secret:
            out = out.replace(secret, "<redacted>")
    return out


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str
    stderr: str


def run_command(
    command: list[str],
    *,
    cwd: Path | None = None,
    timeout: float = 30.0,
    env: dict[str, str] | None = None,
    check: bool = True,
    secrets: Iterable[str] = (),
) -> CommandResult:
    try:
        result = subprocess.run(
            command,
            cwd=str(cwd) if cwd else None,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise OrchestratorError(
            f"Command timed out after {timeout:g}s: {shlex.join(command[:4])}"
        ) from exc
    stdout = redact(result.stdout, secrets)
    stderr = redact(result.stderr, secrets)
    if check and result.returncode != 0:
        detail = (stderr or stdout).strip().splitlines()
        tail = " | ".join(detail[-3:]) if detail else "no output"
        raise OrchestratorError(
            f"Command failed ({result.returncode}): {shlex.join(command[:4])}: {tail}"
        )
    return CommandResult(result.returncode, stdout, stderr)


def git(repo: Path, *args: str, timeout: float = 30.0, check: bool = True) -> CommandResult:
    return run_command(
        ["git", "-C", str(repo), *args], timeout=timeout, check=check
    )


def github_repo_name(remote: str) -> str:
    text = remote.strip()
    if text.endswith(".git"):
        text = text[:-4]
    if text.startswith("git@github.com:"):
        return text.split(":", 1)[1]
    parsed = urllib.parse.urlsplit(text)
    if parsed.hostname == "github.com":
        return parsed.path.strip("/")
    marker = "github.com/"
    if marker in text:
        return text.split(marker, 1)[1].strip("/")
    return ""


@dataclass(frozen=True)
class GitProvenance:
    name: str
    path: str
    repo: str
    commit: str
    branch: str
    upstream: str
    pushed: bool
    clean: bool


def resolve_git_provenance(
    name: str,
    repo: Path,
    *,
    timeout: float,
) -> tuple[GitProvenance, list[str]]:
    if not repo.is_dir():
        raise OrchestratorError(f"{name} repository is missing: {repo}")
    top = Path(git(repo, "rev-parse", "--show-toplevel", timeout=timeout).stdout.strip())
    head = git(repo, "rev-parse", "HEAD", timeout=timeout).stdout.strip().lower()
    if not SHA40_RE.fullmatch(head):
        raise OrchestratorError(f"Could not resolve a committed SHA for {name}.")
    branch = git(repo, "branch", "--show-current", timeout=timeout).stdout.strip()
    status = git(
        repo, "status", "--porcelain=v1", "--untracked-files=all", timeout=timeout
    ).stdout.splitlines()
    clean = not status
    issues: list[str] = []
    if not clean:
        paths = [line[3:] if len(line) > 3 else line for line in status[:5]]
        suffix = ", ".join(paths) + (" ..." if len(status) > 5 else "")
        issues.append(f"{name} repository is dirty ({len(status)} path(s)): {suffix}")

    upstream_result = git(
        repo,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
        timeout=timeout,
        check=False,
    )
    upstream = upstream_result.stdout.strip() if upstream_result.returncode == 0 else ""
    pushed = False
    if not upstream:
        issues.append(f"{name} has no configured upstream branch.")
    else:
        ancestor = git(
            repo,
            "merge-base",
            "--is-ancestor",
            head,
            upstream,
            timeout=timeout,
            check=False,
        )
        pushed = ancestor.returncode == 0
        if not pushed:
            issues.append(f"{name} HEAD {head[:12]} is not contained in {upstream}; push it first.")

    remote = git(repo, "remote", "get-url", "origin", timeout=timeout, check=False)
    repo_name = github_repo_name(remote.stdout) if remote.returncode == 0 else ""
    if not repo_name:
        issues.append(f"{name} origin is not a resolvable GitHub repository.")
    return (
        GitProvenance(
            name=name,
            path=str(top),
            repo=repo_name,
            commit=head,
            branch=branch,
            upstream=upstream,
            pushed=pushed,
            clean=clean,
        ),
        issues,
    )


@dataclass(frozen=True)
class ModelSpec:
    order: int
    name: str
    source_path: str
    git_tree_sha256: str
    manifest_sha256: str
    doitall_sha256: str


def discover_models(repo_commit: str, *, git_timeout: float) -> list[ModelSpec]:
    if not SENSITIVITY_ROOT.is_dir():
        raise OrchestratorError(f"Sensitivity directory is missing: {SENSITIVITY_ROOT}")
    dirs = sorted(path for path in SENSITIVITY_ROOT.iterdir() if path.is_dir())
    if len(dirs) != EXPECTED_MODELS:
        raise OrchestratorError(
            f"Expected exactly {EXPECTED_MODELS} sensitivity model directories; found {len(dirs)}."
        )
    models: list[ModelSpec] = []
    for expected_order, directory in enumerate(dirs, 1):
        match = MODEL_RE.fullmatch(directory.name)
        if not match or int(match.group(1)) != expected_order:
            raise OrchestratorError(
                f"Non-deterministic model set at position {expected_order}: {directory.name}"
            )
        model_dir = directory / "model"
        required = (
            "bet.frq",
            "bet.ini",
            "bet.tag",
            "bet.age_length",
            "bet.reg_scaling",
            "doitall.sh",
        )
        missing = [name for name in required if not (model_dir / name).is_file()]
        if missing:
            raise OrchestratorError(f"{directory.name} is missing: {', '.join(missing)}")
        manifest_path = directory / "input_manifest.csv"
        readme_path = directory / "README.md"
        if not manifest_path.is_file() or not readme_path.is_file():
            raise OrchestratorError(f"{directory.name} lacks README.md or input_manifest.csv.")
        readme = readme_path.read_text(encoding="utf-8").lower()
        no_reapplication_markers = (
            "already applied once",
            "already contains effort creep",
            "effort creep is not reapplied",
            "effort creep was not reapplied",
            "never reapplies effort creep",
        )
        if "effort creep" not in readme or not any(
            marker in readme for marker in no_reapplication_markers
        ):
            raise OrchestratorError(
                f"{directory.name} does not record that effort creep was already applied once."
            )
        with manifest_path.open(newline="", encoding="utf-8") as handle:
            roles = {str(row.get("role") or "").strip() for row in csv.DictReader(handle)}
        if not {"frq", "ini", "tag", "age_length", "reg_scaling", "doitall"}.issubset(roles):
            raise OrchestratorError(f"{directory.name} input manifest is incomplete.")

        rel_model = model_dir.relative_to(REPO_ROOT).as_posix()
        tree = git(
            REPO_ROOT,
            "ls-tree",
            "-r",
            "--full-tree",
            repo_commit,
            "--",
            rel_model,
            timeout=git_timeout,
        ).stdout
        if not tree.strip():
            raise OrchestratorError(f"{rel_model} is not tracked by commit {repo_commit[:12]}.")
        models.append(
            ModelSpec(
                order=expected_order,
                name=directory.name,
                source_path=rel_model,
                git_tree_sha256=hashlib.sha256(tree.encode("utf-8")).hexdigest(),
                manifest_sha256=file_sha256(manifest_path),
                doitall_sha256=file_sha256(model_dir / "doitall.sh"),
            )
        )
    return models


def resolve_mfcl_provenance() -> dict[str, str]:
    if not MFCL_BINARY.is_file() or not MFCL_DOCKERFILE.is_file():
        raise OrchestratorError("Current MFCL binary or tuna-flow Dockerfile is missing.")
    dockerfile = MFCL_DOCKERFILE.read_text(encoding="utf-8")
    digest_match = re.search(
        r"^ARG[ \t]+MFCL_EXECUTABLE_SHA256=([0-9a-f]{64})[ \t]*$",
        dockerfile,
        re.MULTILINE | re.IGNORECASE,
    )
    version_match = re.search(
        r"^ARG[ \t]+MFCL_EXECUTABLE_FULL_VERSION=([^\s]+)", dockerfile, re.MULTILINE
    )
    if not digest_match or not version_match:
        raise OrchestratorError("MFCL digest/version is unresolved in tuna-flow/Dockerfile.")
    actual = file_sha256(MFCL_BINARY)
    declared = digest_match.group(1).lower()
    if actual != declared:
        raise OrchestratorError(
            f"MFCL binary SHA mismatch: Dockerfile={declared}, actual={actual}."
        )
    return {"sha256": actual, "version": version_match.group(1).strip()}


def resolve_local_image_digest(image: str, *, timeout: float) -> str:
    result = run_command(
        ["docker", "image", "inspect", "--format", "{{json .RepoDigests}}", image],
        timeout=timeout,
        check=False,
    )
    if result.returncode != 0:
        return ""
    try:
        refs = json.loads(result.stdout.strip())
    except json.JSONDecodeError:
        return ""
    for ref in refs if isinstance(refs, list) else []:
        if isinstance(ref, str) and re.search(r"@sha256:[0-9a-f]{64}$", ref, re.IGNORECASE):
            return ref.lower()
    return ""


class KflowApi:
    def __init__(
        self,
        base_url: str,
        token: str,
        *,
        timeout: float,
        retries: int,
        semaphore: threading.BoundedSemaphore,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.github_token = runtime_github_token()
        self.timeout = timeout
        self.retries = retries
        self.semaphore = semaphore

    def request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
        *,
        retry: bool | None = None,
    ) -> dict[str, Any]:
        url = f"{self.base_url}/{path.lstrip('/')}"
        data = None
        headers = {"Authorization": f"Bearer {self.token}", "Accept": "application/json"}
        if self.github_token:
            headers["X-GitHub-Token"] = self.github_token
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            headers["Content-Type"] = "application/json"
        attempts = self.retries + 1 if (retry if retry is not None else method == "GET") else 1
        last_error: ApiError | None = None
        for attempt in range(attempts):
            request = urllib.request.Request(url, data=data, headers=headers, method=method)
            try:
                with self.semaphore:
                    with urllib.request.urlopen(request, timeout=self.timeout) as response:
                        raw = response.read(16 * 1024 * 1024 + 1)
                if len(raw) > 16 * 1024 * 1024:
                    raise ApiError(f"{method} {path} returned an oversized response.")
                if not raw:
                    return {}
                parsed = json.loads(raw.decode("utf-8"))
                if not isinstance(parsed, dict):
                    raise ApiError(f"{method} {path} returned non-object JSON.")
                return parsed
            except urllib.error.HTTPError as exc:
                transient = exc.code in {408, 425, 429, 500, 502, 503, 504}
                detail = redact(
                    exc.read(4096).decode("utf-8", errors="replace"),
                    [self.token, self.github_token],
                )
                last_error = ApiError(
                    f"{method} {path} failed with HTTP {exc.code}: {detail[:500]}",
                    transient=transient,
                )
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                last_error = ApiError(
                    f"{method} {path} failed: {redact(str(exc), [self.token, self.github_token])}",
                    transient=True,
                )
            if not last_error.transient or attempt + 1 >= attempts:
                raise last_error
            time.sleep(min(4.0, 0.5 * (2**attempt)))
        raise last_error or ApiError(f"{method} {path} failed.")

    def jobs_by_tags(self, task: str, tags: dict[str, str]) -> list[dict[str, Any]]:
        response = self.request(
            "POST",
            f"/api/jobs/{urllib.parse.quote(task, safe='')}",
            tags,
            retry=True,
        )
        jobs = response.get("jobs", [])
        return [job for job in jobs if isinstance(job, dict)] if isinstance(jobs, list) else []


def nested_values(value: Any, keys: set[str]) -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        for key, child in value.items():
            if str(key).lower() in keys and isinstance(child, (str, int)):
                found.append(str(child))
            found.extend(nested_values(child, keys))
    elif isinstance(value, list):
        for child in value:
            found.extend(nested_values(child, keys))
    return found


def resolve_archive_sha(job: dict[str, Any], *, timeout: float) -> str:
    candidates = nested_values(
        job,
        {
            "archive_sha256",
            "output_archive_sha256",
            "archive_digest",
            "output_archive_digest",
        },
    )
    for candidate in candidates:
        match = SHA256_RE.fullmatch(candidate.strip())
        if match:
            return match.group(1).lower()

    remote_dir = str(job.get("remote_dir") or "").strip()
    remote_host = str(job.get("remote_host") or "").strip()
    remote_user = str(job.get("remote_user") or "").strip()
    if not remote_dir or not remote_host or not remote_user:
        raise OrchestratorError("Job 5319 archive location is unresolved.")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+", remote_host) or not re.fullmatch(
        r"[A-Za-z0-9_.-]+", remote_user
    ):
        raise OrchestratorError("Job 5319 has an unsafe remote archive endpoint.")
    archive = f"{remote_dir.rstrip('/')}/output_archive.tar.gz"
    result = run_command(
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=15",
            "-o",
            "ServerAliveInterval=15",
            f"{remote_user}@{remote_host}",
            f"sha256sum -- {shlex.quote(archive)}",
        ],
        timeout=timeout,
    )
    match = re.match(r"^([0-9a-f]{64})\s", result.stdout.strip(), re.IGNORECASE)
    if not match:
        raise OrchestratorError("Could not parse the Job 5319 archive SHA256.")
    return match.group(1).lower()


def preferred_job_number(job: dict[str, Any]) -> str:
    for key in ("job_number", "number"):
        value = str(job.get(key) or "").strip().lstrip("#")
        if value.isdigit():
            return value
    return ""


def preferred_job_id(job: dict[str, Any]) -> str:
    return str(job.get("id") or preferred_job_number(job)).strip()


def job_metadata(job: dict[str, Any]) -> dict[str, Any]:
    value = job.get("metadata")
    return value if isinstance(value, dict) else {}


def resolve_input_job(api: KflowApi, *, archive_timeout: float) -> dict[str, str]:
    response = api.request("GET", f"/api/job/{INPUT_JOB}")
    job = response.get("job", response)
    if not isinstance(job, dict):
        raise OrchestratorError("Kflow did not return Job 5319.")
    number = preferred_job_number(job)
    if number != INPUT_JOB:
        raise OrchestratorError(f"Input job resolved to #{number or '?'}, not #5319.")
    status = str(job.get("status") or "").strip().lower()
    if status != "completed":
        raise OrchestratorError(f"Input job 5319 must be completed; status is {status or 'unknown'}.")
    source_candidates = nested_values(job.get("details", {}), {"git_commit_sha"})
    source_sha = next(
        (value.lower() for value in source_candidates if SHA40_RE.fullmatch(value.strip())), ""
    )
    if not source_sha:
        raise OrchestratorError("Job 5319 input/source commit SHA is unresolved.")
    return {
        "job_number": number,
        "job_id": preferred_job_id(job),
        "status": status,
        "source_commit": source_sha,
        "archive_sha256": resolve_archive_sha(job, timeout=archive_timeout),
    }


def resolve_workers(raw: str) -> tuple[int, str]:
    text = str(raw or "auto").strip().lower()
    if text not in {"", "auto"}:
        try:
            workers = int(text)
        except ValueError as exc:
            raise OrchestratorError("--submit-workers must be auto or an integer.") from exc
        if workers < 1 or workers > 32:
            raise OrchestratorError("--submit-workers must be between 1 and 32.")
        return workers, "explicit"
    try:
        cpus = len(os.sched_getaffinity(0))
    except (AttributeError, OSError):
        cpus = os.cpu_count() or 1
    try:
        load1 = max(0.0, os.getloadavg()[0])
    except (AttributeError, OSError):
        load1 = 0.0
    cpu_workers = max(1, int(cpus - load1 - 1))
    available_mib = 0.0
    try:
        with Path("/proc/meminfo").open(encoding="ascii") as handle:
            for line in handle:
                if line.startswith("MemAvailable:"):
                    available_mib = float(line.split()[1]) / 1024.0
                    break
    except (OSError, ValueError, IndexError):
        pass
    memory_workers = max(1, int(available_mib // 256)) if available_mib else 32
    workers = max(1, min(32, cpu_workers, memory_workers))
    return workers, f"auto(cpus={cpus},load1={load1:.2f},available_mib={available_mib:.0f})"


def runtime_env(runtime: dict[str, Any]) -> dict[str, str]:
    mfclkit = runtime["mfclkit"]["commit"]
    mfclshiny = runtime["mfclshiny"]["commit"]
    packages = (
        f"mfclkit=PacificCommunity/ofp-sam-mfclkit@{mfclkit},"
        f"mfclshiny=PacificCommunity/mfclshiny@{mfclshiny}"
    )
    return {
        "KFLOW_RUNTIME_UPDATE": "never",
        "TUNA_FLOW_RUNTIME_UPDATE": "never",
        "KFLOW_RUNTIME_PACKAGES": "none",
        "KFLOW_REPO_RUNTIME_UPDATE": "always",
        "KFLOW_REPO_RUNTIME_PACKAGES": packages,
        "MFCLKIT_GITHUB_REF": mfclkit,
        "MFCLSHINY_GITHUB_REF": mfclshiny,
        "KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES": "true",
        "KFLOW_RUNTIME_GITHUB_AUTH": "true",
        "KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME": "true",
        "MFCL_EXECUTABLE_SHA256": runtime["mfcl"]["sha256"],
    }


def local_apps_for_runtime(runtime: dict[str, Any]) -> list[dict[str, Any]]:
    """Load the canonical task apps and pin them to this submission runtime."""
    if not KFLOW_CONFIG.is_file():
        raise OrchestratorError(f"Kflow configuration is missing: {KFLOW_CONFIG}")
    try:
        with KFLOW_CONFIG.open(encoding="utf-8") as handle:
            config = yaml.safe_load(handle) or {}
    except (OSError, yaml.YAMLError) as exc:
        raise OrchestratorError(f"Could not read {KFLOW_CONFIG}: {exc}") from exc
    if not isinstance(config, dict):
        raise OrchestratorError(f"{KFLOW_CONFIG} must contain a YAML mapping.")
    raw_apps = config.get("local_apps")
    if not isinstance(raw_apps, list):
        raise OrchestratorError(f"{KFLOW_CONFIG} must define local_apps as a list.")

    refs = {
        "MFCLKIT_GITHUB_REF": str(runtime["mfclkit"]["commit"]).lower(),
        "MFCLSHINY_GITHUB_REF": str(runtime["mfclshiny"]["commit"]).lower(),
    }
    if any(not SHA40_RE.fullmatch(ref) for ref in refs.values()):
        raise OrchestratorError("MFCL local-app package commits are unresolved.")

    apps = json.loads(json.dumps(raw_apps))
    for app in apps:
        if not isinstance(app, dict):
            raise OrchestratorError(f"{KFLOW_CONFIG} contains an invalid local app.")
        env = app.get("env") if isinstance(app.get("env"), dict) else {}
        app["env"] = {**env, **refs}
    if not any(str(app.get("key") or "").strip() == "mfclshiny" for app in apps):
        raise OrchestratorError(f"{KFLOW_CONFIG} does not define the mfclshiny local app.")
    return apps


def fit_tags(model: ModelSpec, source_sha: str) -> dict[str, str]:
    return {
        "campaign": CAMPAIGN,
        "flow": TASK_NAME,
        "stage": "fit",
        "model": model.name,
        "source_sha": source_sha[:12],
    }


def fit_payload(
    model: ModelSpec,
    *,
    graph_id: str,
    source: dict[str, Any],
    runtime: dict[str, Any],
    input_job: dict[str, str],
) -> dict[str, Any]:
    source_sha = source["model_repo"]["commit"]
    title = f"LF conflict sensitivity fit: {model.name}"
    key = json_sha256({"graph": graph_id, "stage": "fit", "model": model.name})
    env = {
        "STEP_SELECT": model.name,
        "MODEL_ROOT": "sensitivity",
        "RUN_MODE": "doitall",
        "TRIGGER_NEXT": "false",
        "FLOW_GROUP": TASK_NAME,
        "JOB_TITLE": title,
        "JOB_DESCRIPTION": f"Independent production fit for {model.name}.",
        "JOB_KEY": model.name.lower(),
        "MODEL_LABEL": model.name,
        "PROGRAM_PATH": PROGRAM_PATH,
        "MFCL_LIVE_LOG": "true",
        "STEPWISE_BUILD_PAYLOAD": "true",
        "STEPWISE_SAVE_RAW_MFCL_INPUTS": "true",
        "STEPWISE_SAVE_FINAL_PAR": "false",
        "STEPWISE_SINGLE_PAR_REPORT": "true",
        "STEPWISE_CHECK_INPUT_JOBS": "",
        "INPUT_PAR": "",
        "PAR_SOURCE_JOB": "",
        "STEPWISE_PAR_SOURCE_DIR": "",
        "BET_PHASE10_11_CONVERGENCE": "-4",
        "FLOW_SPECIES": "BET",
        "FLOW_SPECIES_LABEL": "bigeye tuna",
        "FLOW_ASSESSMENT_YEAR": "2026",
        **runtime_env(runtime),
    }
    return {
        "repo": source["model_repo"]["repo"],
        "branch": source["model_repo"]["branch"],
        "command": "bash run.sh",
        "docker_image": runtime["container_image"],
        "cpus": CPUS,
        "memory": MEMORY,
        "disk": DISK,
        "remote_host": SUVA_HOST,
        "remote_user": SUVA_USER,
        "remote_base_dir": SUVA_BASE_DIR,
        "slot_requirements": SUVA_SLOT_REQUIREMENT,
        "output_patterns": ["outputs/**"],
        "input_jobs": [],
        "title": title,
        "description": f"Run {model.name} through the repository-supported bash run.sh runner.",
        "batch_name": f"{TASK_NAME}-{model.name}",
        "env": {key_: value for key_, value in env.items() if value != ""},
        "metadata": {
            "campaign": CAMPAIGN,
            "graph_id": graph_id,
            "submission_key": key,
            "stage": "fit",
            "model_selector": model.name,
            "model_source_path": model.source_path,
            "model_source_commit": source_sha,
            "model_git_tree_sha256": model.git_tree_sha256,
            "input_manifest_sha256": model.manifest_sha256,
            "doitall_sha256": model.doitall_sha256,
            "input_job": INPUT_JOB,
            "input_job_id": input_job["job_id"],
            "input_archive_sha256": input_job["archive_sha256"],
            "input_source_commit": input_job["source_commit"],
            "effort_creep_application_count": 1,
            "effort_creep_source": "committed sensitivity model input",
            "parent_archive_used_as_model_input": False,
            "runner": "bash run.sh",
            "runtime_provenance": runtime,
        },
        "tags": fit_tags(model, source_sha),
    }


def graph_material(
    models: list[ModelSpec],
    source: dict[str, Any],
    runtime: dict[str, Any],
    input_job: dict[str, str],
) -> dict[str, Any]:
    return {
        "schema": 1,
        "task": TASK_NAME,
        "input_job": input_job,
        "source": source,
        "runtime": runtime,
        "resources": {
            "cpus": CPUS,
            "memory": MEMORY,
            "disk": DISK,
            "host": SUVA_HOST,
            "user": SUVA_USER,
            "base_dir": SUVA_BASE_DIR,
            "slot_requirements": SUVA_SLOT_REQUIREMENT,
        },
        "models": [asdict(model) for model in models],
        "diagnostics": {
            "hessian_partitions": 5,
            "profile_chains": ["downstream", "upstream"],
            "profile_execution_mode": "continuation",
            "parallel_units": True,
            "auto_merge": True,
            "auto_attach": True,
        },
    }


def diagnostic_nodes(model: str, fit_ref: str) -> list[dict[str, Any]]:
    nodes = [
        {
            "task": f"{CHECK_TASK_PREFIX}-hessian",
            "kind": "hessian-part",
            "unit": str(part),
            "input_jobs": [fit_ref],
        }
        for part in range(1, 6)
    ]
    nodes.extend(
        {
            "task": f"{CHECK_TASK_PREFIX}-profile",
            "kind": "profile-chain",
            "unit": side,
            "input_jobs": [fit_ref],
        }
        for side in ("downstream", "upstream")
    )
    nodes.extend(
        [
            {
                "task": f"{CHECK_TASK_PREFIX}-hessian-merge",
                "kind": "hessian-merge-attach",
                "input_jobs": [fit_ref, "five hessian partition jobs"],
            },
            {
                "task": f"{CHECK_TASK_PREFIX}-profile-merge",
                "kind": "profile-merge-attach",
                "input_jobs": [fit_ref, "two profile chain jobs"],
            },
        ]
    )
    for node in nodes:
        node["model"] = model
        node["submitter"] = SUVA_HOST
        node["memory"] = MEMORY
        node["disk"] = DISK
    return nodes


class StateStore:
    def __init__(self, path: Path, graph_id: str, initial: dict[str, Any]) -> None:
        self.path = path
        self.graph_id = graph_id
        self.initial = initial
        self.data: dict[str, Any] = {}
        self._mutex = threading.RLock()
        self._lock_handle: Any = None

    def __enter__(self) -> "StateStore":
        self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        lock_path = self.path.parent / f"{TASK_NAME}.lock"
        self._lock_handle = lock_path.open("a+", encoding="ascii")
        try:
            fcntl.flock(self._lock_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise OrchestratorError(f"Another orchestrator holds {lock_path}.") from exc
        if self.path.exists():
            try:
                self.data = json.loads(self.path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                raise OrchestratorError(f"State file is unreadable: {self.path}") from exc
            if self.data.get("graph_id") != self.graph_id:
                raise OrchestratorError(
                    f"State graph mismatch in {self.path}; do not reuse it for a changed commit/input graph."
                )
        else:
            self.data = self.initial
            self.save()
        return self

    def __exit__(self, exc_type: Any, exc: Any, traceback: Any) -> None:
        if self._lock_handle is not None:
            fcntl.flock(self._lock_handle.fileno(), fcntl.LOCK_UN)
            self._lock_handle.close()

    def save(self) -> None:
        with self._mutex:
            self.data["updated_at"] = utc_now()
            fd, temp_name = tempfile.mkstemp(
                prefix=f".{self.path.name}.", suffix=".tmp", dir=str(self.path.parent)
            )
            try:
                os.fchmod(fd, 0o600)
                with os.fdopen(fd, "w", encoding="utf-8") as handle:
                    json.dump(self.data, handle, indent=2, sort_keys=True)
                    handle.write("\n")
                    handle.flush()
                    os.fsync(handle.fileno())
                os.replace(temp_name, self.path)
                dir_fd = os.open(self.path.parent, os.O_RDONLY)
                try:
                    os.fsync(dir_fd)
                finally:
                    os.close(dir_fd)
            finally:
                with contextlib.suppress(FileNotFoundError):
                    os.unlink(temp_name)

    def update_stage(self, stage: str, model: str, values: dict[str, Any]) -> None:
        with self._mutex:
            table = self.data.setdefault(stage, {})
            current = table.setdefault(model, {})
            current.update(values)
            self.save()


def validate_existing_fit(
    jobs: list[dict[str, Any]], model: ModelSpec, payload: dict[str, Any]
) -> dict[str, Any] | None:
    title = payload["title"]
    source_sha = payload["metadata"]["model_source_commit"]
    matching: list[dict[str, Any]] = []
    for job in jobs:
        metadata = job_metadata(job)
        if (
            str(job.get("title") or metadata.get("job_title") or "") == title
            and str(metadata.get("model_selector") or "") == model.name
            and str(metadata.get("model_source_commit") or "") == source_sha
            and str(metadata.get("input_job") or "") == INPUT_JOB
        ):
            matching.append(job)
    if len(matching) > 1:
        raise OrchestratorError(f"Duplicate reconciled fit jobs exist for {model.name}.")
    return matching[0] if matching else None


def wait_for_job_number(api: KflowApi, job: dict[str, Any], *, timeout: float) -> dict[str, Any]:
    deadline = time.monotonic() + timeout
    current = job
    while not preferred_job_number(current):
        job_id = preferred_job_id(current)
        if not job_id or time.monotonic() >= deadline:
            raise OrchestratorError("Kflow accepted a fit but did not assign a job number in time.")
        time.sleep(0.5)
        response = api.request("GET", f"/api/job/{urllib.parse.quote(job_id, safe='')}")
        value = response.get("job", response)
        if isinstance(value, dict):
            current = value
    return current


def submit_or_reconcile_fit(
    api: KflowApi,
    store: StateStore,
    model: ModelSpec,
    payload: dict[str, Any],
    *,
    number_timeout: float,
) -> tuple[str, str]:
    tags = payload["tags"]
    existing = validate_existing_fit(api.jobs_by_tags(TASK_NAME, tags), model, payload)
    if existing is None:
        store.update_stage("fits", model.name, {"status": "submitting", "started_at": utc_now()})
        try:
            response = api.request(
                "POST",
                f"/api/job/{urllib.parse.quote(TASK_NAME, safe='')}",
                payload,
                retry=False,
            )
            candidate = response.get("job", response)
            if not isinstance(candidate, dict):
                raise OrchestratorError(f"Kflow returned no fit job for {model.name}.")
            existing = candidate
        except Exception:
            # A timeout may occur after Kflow committed the job. Reconcile once
            # before reporting failure; never blindly repeat the POST.
            reconciled = validate_existing_fit(api.jobs_by_tags(TASK_NAME, tags), model, payload)
            if reconciled is None:
                raise
            existing = reconciled
    existing = wait_for_job_number(api, existing, timeout=number_timeout)
    number = preferred_job_number(existing)
    status = str(existing.get("status") or "unknown").lower()
    store.update_stage(
        "fits",
        model.name,
        {
            "status": "submitted",
            "scheduler_status": status,
            "job_number": number,
            "job_id": preferred_job_id(existing),
            "reconciled_at": utc_now(),
        },
    )
    return number, status


def diagnostic_inventory(
    api: KflowApi, model: str, flow_group: str
) -> tuple[str, dict[str, list[str]]]:
    expected = {
        f"{CHECK_TASK_PREFIX}-hessian": {"1", "2", "3", "4", "5"},
        f"{CHECK_TASK_PREFIX}-profile": {"downstream", "upstream"},
        f"{CHECK_TASK_PREFIX}-hessian-merge": {"merge"},
        f"{CHECK_TASK_PREFIX}-profile-merge": {"merge"},
    }
    inventory: dict[str, list[str]] = {}
    total = 0
    valid = 0
    for task, expected_units in expected.items():
        jobs = api.jobs_by_tags(
            task, {"stage": "checks", "flow": flow_group, "model": model}
        )
        units: list[str] = []
        for job in jobs:
            metadata = job_metadata(job)
            unit = str(metadata.get("check_unit") or "")
            if task.endswith("-merge"):
                unit = "merge"
            if unit in expected_units:
                number = preferred_job_number(job)
                if number:
                    units.append(f"{unit}:#{number}")
                    valid += 1
        inventory[task] = sorted(set(units))
        total += len(jobs)
    if valid == 9 and total == 9:
        return "complete", inventory
    if total == 0:
        return "absent", inventory
    return "partial", inventory


def checks_command(
    *,
    kflow_url: str,
    model: ModelSpec,
    fit_number: str,
    flow_group: str,
    source: dict[str, Any],
    runtime: dict[str, Any],
) -> list[str]:
    return [
        sys.executable,
        str(CHECKS_HELPER),
        "--kflow-url",
        kflow_url,
        "--task-prefix",
        CHECK_TASK_PREFIX,
        "--checks",
        "hessian profile",
        "--models",
        model.name,
        "--input-jobs",
        fit_number,
        "--flow-group",
        flow_group,
        "--repo-full-name",
        source["checks_repo"]["repo"],
        "--branch",
        CHECKS_BRANCH,
        "--docker-image",
        runtime["container_image"],
        "--cpus",
        str(CPUS),
        "--memory",
        MEMORY,
        "--disk",
        DISK,
        "--model-source-repo",
        source["model_repo"]["repo"],
        "--model-source-ref",
        source["model_repo"]["commit"],
        "--model-source-path",
        model.source_path,
        "--program-path",
        PROGRAM_PATH,
        "--submitter",
        SUVA_HOST,
        "--remote-user",
        SUVA_USER,
        "--remote-base-dir",
        SUVA_BASE_DIR,
        "--parallel-units",
        "true",
        "--auto-merge",
        "true",
        "--auto-attach",
        "true",
        # Keep aggregate API pressure bounded by the orchestrator's worker
        # pool rather than multiplying concurrency inside every helper.
        "--submit-workers",
        "1",
    ]


def checks_environment(token: str, runtime: dict[str, Any]) -> dict[str, str]:
    keep = ("PATH", "HOME", "LANG", "LC_ALL", "TMPDIR", "SSL_CERT_FILE", "SSL_CERT_DIR")
    env = {key: os.environ[key] for key in keep if key in os.environ}
    env.update(
        {
            "KFLOW_API_TOKEN": token,
            "HESSIAN_NSPLIT": "5",
            "HESSIAN_PARTS": "",
            "HESSIAN_PART": "",
            "PROFILE_PARALLEL_MODE": "chains",
            "PROFILE_EXECUTION_MODE": "continuation",
            "PROFILE_VALUE_MODE": "percent",
            "PROFILE_CENTER": "100",
            "PROFILE_VALUES": " ".join(
                [f"{value / 2:g}" for value in range(120, 201, 5) if value != 200]
                + [f"{value / 2:g}" for value in range(205, 281, 5)]
            ),
            "PROFILE_INCLUDE_BASE_ANCHOR": "false",
            "ATTACH_OUTPUT_MODE": "delta",
            "FLOW_SPECIES": "BET",
            "FLOW_SPECIES_LABEL": "bigeye tuna",
            "FLOW_ASSESSMENT_YEAR": "2026",
            **runtime_env(runtime),
        }
    )
    return env


def run_checks_helper(
    command: list[str],
    env: dict[str, str],
    *,
    timeout: float,
    token: str,
) -> str:
    process = subprocess.Popen(
        command,
        cwd=str(CHECKS_REPO),
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
    )
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            stdout, stderr = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate()
        raise OrchestratorError(f"Checks helper timed out after {timeout:g}s.") from exc
    stdout = redact(stdout, [token])
    stderr = redact(stderr, [token])
    if process.returncode != 0:
        tail = "\n".join((stderr or stdout).splitlines()[-20:])
        raise OrchestratorError(f"Checks helper failed ({process.returncode}):\n{tail}")
    return "\n".join(stdout.splitlines()[-20:])


def submit_diagnostics(
    api: KflowApi,
    store: StateStore,
    model: ModelSpec,
    fit_number: str,
    *,
    flow_group: str,
    source: dict[str, Any],
    runtime: dict[str, Any],
    token: str,
    kflow_url: str,
    timeout: float,
) -> str:
    inventory_status, inventory = diagnostic_inventory(api, model.name, flow_group)
    if inventory_status == "complete":
        store.update_stage(
            "diagnostics",
            model.name,
            {"status": "submitted", "inventory": inventory, "reconciled_at": utc_now()},
        )
        return "reconciled"
    if inventory_status == "partial":
        raise OrchestratorError(
            f"Partial diagnostics already exist for {model.name}; refusing to rerun the non-idempotent helper. "
            "Inspect state/Kflow and complete or remove that one model's partial diagnostic set."
        )
    command = checks_command(
        kflow_url=kflow_url,
        model=model,
        fit_number=fit_number,
        flow_group=flow_group,
        source=source,
        runtime=runtime,
    )
    store.update_stage(
        "diagnostics",
        model.name,
        {
            "status": "submitting",
            "fit_job_number": fit_number,
            "started_at": utc_now(),
        },
    )
    output = run_checks_helper(
        command, checks_environment(token, runtime), timeout=timeout, token=token
    )
    inventory_status, inventory = diagnostic_inventory(api, model.name, flow_group)
    if inventory_status != "complete":
        raise OrchestratorError(
            f"Checks helper returned successfully for {model.name}, but its 9-job graph is {inventory_status}."
        )
    store.update_stage(
        "diagnostics",
        model.name,
        {
            "status": "submitted",
            "fit_job_number": fit_number,
            "inventory": inventory,
            "helper_output_tail": output,
            "completed_at": utc_now(),
        },
    )
    return "submitted"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  submit_kflow_sensitivities.py --offline\n"
            "  submit_kflow_sensitivities.py --submit --fits-only\n"
            "  submit_kflow_sensitivities.py --submit --diagnostics-only --resume\n\n"
            "KFLOW_URL and KFLOW_API_TOKEN are required for every run. Tokens are read only\n"
            "from the environment and are never printed or stored. --offline is dry-run only."
        ),
    )
    parser.add_argument(
        "--submit", action="store_true", help="Perform Kflow submissions; otherwise print an audit dry run."
    )
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--fits-only", action="store_true", help="Submit/audit fits without diagnostics.")
    modes.add_argument(
        "--diagnostics-only",
        action="store_true",
        help="Resume/audit diagnostics using reconciled fit job numbers.",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Explicitly request resume behavior (safe reconciliation is always enabled).",
    )
    parser.add_argument(
        "--offline",
        action="store_true",
        help="Do not contact Kflow or SSH; valid only for a dry-run graph audit.",
    )
    parser.add_argument(
        "--submit-workers",
        default=os.environ.get("KFLOW_SUBMIT_WORKERS", "auto"),
        help="Bounded local fit/helper concurrency: auto or 1-32 (default: auto).",
    )
    parser.add_argument("--state-file", type=Path, default=DEFAULT_STATE)
    parser.add_argument("--api-timeout", type=float, default=60.0)
    parser.add_argument("--api-retries", type=int, default=3)
    parser.add_argument("--git-timeout", type=float, default=30.0)
    parser.add_argument("--archive-timeout", type=float, default=180.0)
    parser.add_argument("--job-number-timeout", type=float, default=60.0)
    parser.add_argument("--helper-timeout", type=float, default=900.0)
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if args.submit and args.offline:
        raise OrchestratorError("--offline cannot be combined with --submit.")
    for name in (
        "api_timeout",
        "git_timeout",
        "archive_timeout",
        "job_number_timeout",
        "helper_timeout",
    ):
        if getattr(args, name) <= 0:
            raise OrchestratorError(f"--{name.replace('_', '-')} must be positive.")
    if args.api_retries < 0 or args.api_retries > 10:
        raise OrchestratorError("--api-retries must be between 0 and 10.")


def preflight(args: argparse.Namespace) -> tuple[
    list[ModelSpec], dict[str, Any], dict[str, Any], dict[str, str], list[str], int, str
]:
    issues: list[str] = []
    git_repos: dict[str, dict[str, Any]] = {}
    repo_specs = (
        ("model_repo", "model", REPO_ROOT),
        ("checks_repo", "checks", CHECKS_REPO),
        ("kflow", "Kflow", KFLOW_REPO),
        ("mfcl_image_source", "MFCL image source", MFCL_IMAGE_REPO),
        ("mfclkit", "mfclkit", MFCLKIT_REPO),
        ("mfclshiny", "mfclshiny", MFCLSHINY_REPO),
    )
    for key, label, path in repo_specs:
        try:
            provenance, repo_issues = resolve_git_provenance(
                label, path, timeout=args.git_timeout
            )
            git_repos[key] = asdict(provenance)
            if key not in {"model_repo", "checks_repo"}:
                repo_issues = [
                    issue for issue in repo_issues if "repository is dirty" not in issue
                ]
            issues.extend(repo_issues)
        except OrchestratorError as exc:
            issues.append(str(exc))
            git_repos[key] = {
                "name": label,
                "path": str(path),
                "repo": "UNRESOLVED",
                "commit": "UNRESOLVED",
                "branch": "",
                "upstream": "",
                "pushed": False,
                "clean": False,
            }

    model_commit = git_repos["model_repo"]["commit"]
    if not SHA40_RE.fullmatch(model_commit):
        raise OrchestratorError("Cannot audit models without the committed model-repository SHA.")
    models = discover_models(model_commit, git_timeout=args.git_timeout)

    try:
        mfcl = resolve_mfcl_provenance()
    except OrchestratorError as exc:
        issues.append(str(exc))
        mfcl = {"sha256": "UNRESOLVED", "version": "UNRESOLVED"}
    image_ref = resolve_local_image_digest(DOCKER_IMAGE, timeout=args.git_timeout)
    if not image_ref:
        issues.append(
            f"Container digest for {DOCKER_IMAGE} is unresolved locally; pull/inspect the production image first."
        )
        image_ref = DOCKER_IMAGE if args.offline else "UNRESOLVED"

    runtime = {
        "container_image": image_ref,
        "kflow": git_repos["kflow"],
        "mfcl_image_source": git_repos["mfcl_image_source"],
        "mfcl": mfcl,
        "mfclkit": git_repos["mfclkit"],
        "mfclshiny": git_repos["mfclshiny"],
    }
    source = {
        "model_repo": git_repos["model_repo"],
        "checks_repo": git_repos["checks_repo"],
    }

    url = str(os.environ.get("KFLOW_URL") or "").strip()
    token = str(os.environ.get("KFLOW_API_TOKEN") or "").strip()
    if not url:
        issues.append("KFLOW_URL is required.")
    else:
        parsed = urllib.parse.urlsplit(url)
        if parsed.scheme not in {"http", "https"} or not parsed.hostname or parsed.username:
            issues.append("KFLOW_URL must be an http(s) URL without embedded credentials.")
    if not token:
        issues.append("KFLOW_API_TOKEN is required.")
    if not args.offline and not runtime_github_token():
        issues.append(
            "GitHub authentication is required for private runtime packages. "
            "Run `gh auth login` or set KFLOW_GITHUB_TOKEN/GITHUB_PAT."
        )

    workers, worker_source = resolve_workers(args.submit_workers)
    input_job = {
        "job_number": INPUT_JOB,
        "job_id": "UNRESOLVED_OFFLINE",
        "status": "UNRESOLVED_OFFLINE",
        "source_commit": "UNRESOLVED_OFFLINE",
        "archive_sha256": "UNRESOLVED_OFFLINE",
    }
    if not args.offline and url and token:
        semaphore = threading.BoundedSemaphore(workers)
        api = KflowApi(
            url,
            token,
            timeout=args.api_timeout,
            retries=args.api_retries,
            semaphore=semaphore,
        )
        try:
            input_job = resolve_input_job(api, archive_timeout=args.archive_timeout)
        except OrchestratorError as exc:
            issues.append(str(exc))
            input_job = {
                "job_number": INPUT_JOB,
                "job_id": "UNRESOLVED",
                "status": "UNRESOLVED",
                "source_commit": "UNRESOLVED",
                "archive_sha256": "UNRESOLVED",
            }
    return models, source, runtime, input_job, issues, workers, worker_source


def dry_run_audit(
    args: argparse.Namespace,
    models: list[ModelSpec],
    source: dict[str, Any],
    runtime: dict[str, Any],
    input_job: dict[str, str],
    issues: list[str],
    workers: int,
    worker_source: str,
) -> int:
    material = graph_material(models, source, runtime, input_job)
    graph_id = json_sha256(material)
    flow_group = f"{TASK_NAME}-{source['model_repo']['commit'][:12]}"
    entries: list[dict[str, Any]] = []
    for model in models:
        payload = fit_payload(
            model,
            graph_id=graph_id,
            source=source,
            runtime=runtime,
            input_job=input_job,
        )
        fit_ref = f"FIT_JOB_NUMBER({model.name})"
        command = checks_command(
            kflow_url="<KFLOW_URL>",
            model=model,
            fit_number=fit_ref,
            flow_group=flow_group,
            source=source,
            runtime=runtime,
        )
        entries.append(
            {
                "order": model.order,
                "model": model.name,
                "fit": {"task": TASK_NAME, "payload": payload},
                "diagnostics": {
                    "helper_invocations": 0 if args.fits_only else 1,
                    "one_parent_only": fit_ref,
                    "command": command if not args.fits_only else [],
                    "environment": {
                        "KFLOW_API_TOKEN": "<required; redacted>",
                        "HESSIAN_NSPLIT": "5",
                        "PROFILE_PARALLEL_MODE": "chains",
                        "PROFILE_EXECUTION_MODE": "continuation",
                        "ATTACH_OUTPUT_MODE": "delta",
                    },
                    "nodes": diagnostic_nodes(model.name, fit_ref) if not args.fits_only else [],
                },
            }
        )
    audit = {
        "schema": "kflow-sensitivity-orchestrator-audit/v1",
        "action": "DRY_RUN_NO_SUBMISSION",
        "offline": args.offline,
        "ready_for_submit": not issues,
        "issues": issues,
        "task": TASK_NAME,
        "graph_id": graph_id,
        "mode": "fits-only" if args.fits_only else "diagnostics-only" if args.diagnostics_only else "fits-and-diagnostics",
        "state_file": str(args.state_file.expanduser()),
        "workers": {"value": workers, "source": worker_source},
        "model_count": len(models),
        "source": source,
        "runtime": runtime,
        "input_job": input_job,
        "graph": entries,
    }
    json.dump(audit, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0 if not issues else 2


def assert_submit_preflight(issues: list[str], runtime: dict[str, Any]) -> None:
    if issues:
        raise OrchestratorError("Submission preflight failed:\n- " + "\n- ".join(issues))
    if "@sha256:" not in str(runtime.get("container_image") or ""):
        raise OrchestratorError("Submission requires an immutable container image digest.")


def submit_graph(
    args: argparse.Namespace,
    models: list[ModelSpec],
    source: dict[str, Any],
    runtime: dict[str, Any],
    input_job: dict[str, str],
    workers: int,
) -> int:
    url = os.environ["KFLOW_URL"].strip()
    token = os.environ["KFLOW_API_TOKEN"].strip()
    material = graph_material(models, source, runtime, input_job)
    graph_id = json_sha256(material)
    flow_group = f"{TASK_NAME}-{source['model_repo']['commit'][:12]}"
    state_initial = {
        "schema": "kflow-sensitivity-orchestrator-state/v1",
        "task": TASK_NAME,
        "graph_id": graph_id,
        "created_at": utc_now(),
        "updated_at": utc_now(),
        "source": source,
        "runtime": runtime,
        "input_job": input_job,
        "models": [model.name for model in models],
        "fits": {},
        "diagnostics": {},
        "failures": [],
    }
    semaphore = threading.BoundedSemaphore(workers)
    api = KflowApi(
        url,
        token,
        timeout=args.api_timeout,
        retries=args.api_retries,
        semaphore=semaphore,
    )
    task_response = api.request(
        "POST",
        f"/api/report/{urllib.parse.quote(TASK_NAME, safe='')}",
        {
            "name": "BET 2026 LF conflict sensitivities",
            "description": (
                "Evaluate LF tail compression, upper-tail observed-count cutoffs, "
                "and F21/F22/F23 LF downweighting from committed Job 5319-derived inputs."
            ),
            "owner_login": "kyuhank",
            "repo": source["model_repo"]["repo"],
            "branch": source["model_repo"]["branch"],
            "command": "bash run.sh",
            "checkout": {"mode": "full", "paths": []},
            "remote_user": SUVA_USER,
            "remote_host": SUVA_HOST,
            "remote_base_dir": SUVA_BASE_DIR,
            "docker_image": runtime["container_image"],
            "cpus": CPUS,
            "memory": MEMORY,
            "disk": DISK,
            "slot_requirements": SUVA_SLOT_REQUIREMENT,
            "env": {},
            "tags": {"assessment": "BET 2026", "campaign": CAMPAIGN},
            "metadata": {
                "graph_id": graph_id,
                "model_count": len(models),
                "model_source_commit": source["model_repo"]["commit"],
                "provenance_job_number": input_job["job_number"],
                "standalone_inputs": True,
                "local_apps": local_apps_for_runtime(runtime),
            },
            "output_patterns": ["outputs/**"],
            "input_jobs": [],
            "triggers": {},
        },
        retry=True,
    )
    registered_task = task_response.get("report", {})
    if not isinstance(registered_task, dict) or registered_task.get("code") != TASK_NAME:
        raise OrchestratorError(f"Kflow did not confirm task registration for {TASK_NAME}.")
    print(f"task {TASK_NAME}: registered")
    failures: list[str] = []
    fit_numbers: dict[str, str] = {}
    state_path = args.state_file.expanduser().resolve()
    with StateStore(state_path, graph_id, state_initial) as store:
        if not args.diagnostics_only:
            payloads = {
                model.name: fit_payload(
                    model,
                    graph_id=graph_id,
                    source=source,
                    runtime=runtime,
                    input_job=input_job,
                )
                for model in models
            }
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {
                    executor.submit(
                        submit_or_reconcile_fit,
                        api,
                        store,
                        model,
                        payloads[model.name],
                        number_timeout=args.job_number_timeout,
                    ): model
                    for model in models
                }
                for future in as_completed(futures):
                    model = futures[future]
                    try:
                        number, status = future.result()
                        fit_numbers[model.name] = number
                        print(f"fit {model.name}: job #{number} ({status})")
                    except Exception as exc:
                        message = f"fit {model.name}: {redact(str(exc), [token])}"
                        failures.append(message)
                        store.update_stage("fits", model.name, {"status": "failed", "error": message})
        else:
            # Diagnostics-only still reconciles every fit by the same stable
            # title/tags; it never groups parent jobs into a batch helper call.
            for model in models:
                payload = fit_payload(
                    model,
                    graph_id=graph_id,
                    source=source,
                    runtime=runtime,
                    input_job=input_job,
                )
                try:
                    existing = validate_existing_fit(
                        api.jobs_by_tags(TASK_NAME, payload["tags"]), model, payload
                    )
                    if existing is None:
                        raise OrchestratorError("fit job not found")
                    existing = wait_for_job_number(
                        api, existing, timeout=args.job_number_timeout
                    )
                    fit_numbers[model.name] = preferred_job_number(existing)
                except Exception as exc:
                    failures.append(f"fit reconciliation {model.name}: {redact(str(exc), [token])}")

        if not args.fits_only:
            eligible = [model for model in models if model.name in fit_numbers]
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {
                    executor.submit(
                        submit_diagnostics,
                        api,
                        store,
                        model,
                        fit_numbers[model.name],
                        flow_group=flow_group,
                        source=source,
                        runtime=runtime,
                        token=token,
                        kflow_url=url,
                        timeout=args.helper_timeout,
                    ): model
                    for model in eligible
                }
                for future in as_completed(futures):
                    model = futures[future]
                    try:
                        result = future.result()
                        print(
                            f"diagnostics {model.name}: {result} for fit #{fit_numbers[model.name]}"
                        )
                    except Exception as exc:
                        message = f"diagnostics {model.name}: {redact(str(exc), [token])}"
                        failures.append(message)
                        store.update_stage(
                            "diagnostics", model.name, {"status": "failed", "error": message}
                        )
        if failures:
            store.data["failures"] = failures
            store.save()
    if failures:
        print("Submission completed with failures:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print(
        f"Submission graph accepted: {len(fit_numbers)} fit parent(s), state={state_path}"
    )
    return 0


def main() -> int:
    args = parse_args()
    validate_args(args)
    models, source, runtime, input_job, issues, workers, worker_source = preflight(args)
    if not args.submit:
        return dry_run_audit(
            args,
            models,
            source,
            runtime,
            input_job,
            issues,
            workers,
            worker_source,
        )
    assert_submit_preflight(issues, runtime)
    if not CHECKS_HELPER.is_file():
        raise OrchestratorError(f"Checks helper is missing: {CHECKS_HELPER}")
    print(f"submission workers: {workers} ({worker_source})")
    return submit_graph(args, models, source, runtime, input_job, workers)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted; atomic state preserves completed submissions.", file=sys.stderr)
        raise SystemExit(130)
    except OrchestratorError as exc:
        token = str(os.environ.get("KFLOW_API_TOKEN") or "")
        print(f"ERROR: {redact(str(exc), [token])}", file=sys.stderr)
        raise SystemExit(2)
