#!/usr/bin/env python3
"""Register or refresh a Kflow task from a repository kflow.yaml."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[1]


def run_git(repo_root: Path, *args: str) -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return ""
    return result.stdout.strip()


def repo_full_name(repo_root: Path) -> str:
    remote = run_git(repo_root, "remote", "get-url", "origin")
    if remote.endswith(".git"):
        remote = remote[:-4]
    if remote.startswith("git@github.com:"):
        return remote.split(":", 1)[1]
    marker = "github.com/"
    if marker in remote:
        return remote.split(marker, 1)[1].strip("/")
    return ""


def read_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a YAML mapping")
    return data


def api_json(
    method: str,
    url: str,
    token: str,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    headers = {"Authorization": f"Bearer {token}"}
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc
    if not raw:
        return {}
    return json.loads(raw.decode("utf-8"))


def existing_report(base_url: str, token: str, task_name: str) -> dict[str, Any]:
    try:
        payload = api_json("GET", f"{base_url}/api/report/{task_name}", token)
    except Exception:
        return {}
    report = payload.get("report", payload)
    return report if isinstance(report, dict) else {}


def first_present(*values: Any) -> Any:
    for value in values:
        if value not in (None, ""):
            return value
    return None


def build_payload(
    config: dict[str, Any],
    repo_root: Path,
    existing: dict[str, Any],
    args: argparse.Namespace,
) -> dict[str, Any]:
    task_name = args.task_name or config.get("name")
    if not task_name:
        raise ValueError("Task name is missing; set name in kflow.yaml or pass --task-name.")

    resources = config.get("resources") or {}
    metadata = dict(config.get("metadata") or {})
    if config.get("job_config") is not None:
        metadata["job_config"] = config["job_config"]
    if config.get("local_apps") is not None:
        metadata["local_apps"] = config["local_apps"]

    branch = first_present(args.branch, config.get("branch"), run_git(repo_root, "branch", "--show-current"), "main")
    full_name = first_present(args.repo_full_name, config.get("repo_full_name"), repo_full_name(repo_root))

    payload: dict[str, Any] = {
        "name": task_name,
        "description": config.get("description", ""),
        "repo_full_name": full_name,
        "branch": branch,
        "make_target": config.get("make_target", existing.get("make_target", "all")),
        "command": config.get("command", existing.get("command")),
        "target_folder": config.get("target_folder", existing.get("target_folder", "")),
        "docker_image": config.get("docker_image", existing.get("docker_image")),
        "cpus": resources.get("cpus", existing.get("cpus")),
        "memory": resources.get("memory", existing.get("memory")),
        "disk": resources.get("disk", existing.get("disk")),
        "stream_error": config.get("stream_error", existing.get("stream_error", True)),
        "ghcr_login": config.get("ghcr_login", existing.get("ghcr_login", False)),
        "slot_requirements": config.get("slot_requirements", existing.get("slot_requirements", "")),
        # Do not preserve stale node exclusions from an existing Kflow task.
        # If a repo wants a fixed exclusion it must say so explicitly in
        # kflow.yaml; otherwise the registered task should launch without
        # manual exclusions and let scheduler-health auto-exclude bad nodes.
        "exclude_machines": config.get("exclude_machines", []),
        "exclude_slots": config.get("exclude_slots", []),
        "env": config.get("env", {}),
        "tags": config.get("tags", {}),
        "metadata": metadata,
        "output_patterns": config.get("output_patterns", []),
        "artifacts": config.get("artifacts", []),
        "input_jobs": config.get("input_jobs", []),
        "triggers": config.get("triggers", {}),
    }

    checkout = config.get("checkout", existing.get("checkout"))
    if checkout is not None:
        payload["checkout"] = checkout

    for key, env_name in (
        ("owner_login", "KFLOW_OWNER_LOGIN"),
        ("remote_user", "KFLOW_REMOTE_USER"),
        ("remote_host", "KFLOW_REMOTE_HOST"),
        ("remote_base_dir", "KFLOW_REMOTE_BASE_DIR"),
    ):
        value = first_present(config.get(key), os.environ.get(env_name), existing.get(key))
        if value is not None:
            payload[key] = value

    return {key: value for key, value in payload.items() if value is not None}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="kflow.yaml", help="Path to kflow.yaml.")
    parser.add_argument("--repo-root", default=".", help="Repository root used for git metadata.")
    parser.add_argument("--task-name", default="", help="Override the task name from kflow.yaml.")
    parser.add_argument("--repo-full-name", default="", help="Override GitHub owner/repo.")
    parser.add_argument("--branch", default="", help="Override branch.")
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--dry-run", action="store_true", help="Print payload without registering.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = (ROOT / args.repo_root).resolve()
    config_path = (ROOT / args.config).resolve()
    token = os.environ.get("KFLOW_API_TOKEN", "")
    base_url = args.kflow_url.rstrip("/")

    config = read_yaml(config_path)
    task_name = args.task_name or config.get("name")
    if not task_name:
        raise SystemExit("Task name is missing.")

    existing = {}
    if token:
        existing = existing_report(base_url, token, task_name)
    payload = build_payload(config, repo_root, existing, args)

    if args.dry_run:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0

    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before registering Kflow tasks.")

    response = api_json("POST", f"{base_url}/api/report/{task_name}", token, payload)
    report = response.get("report", response)
    code = report.get("code", task_name) if isinstance(report, dict) else task_name
    repo = payload.get("repo_full_name", "")
    branch = payload.get("branch", "")
    print(f"registered {code}: {repo}@{branch}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
