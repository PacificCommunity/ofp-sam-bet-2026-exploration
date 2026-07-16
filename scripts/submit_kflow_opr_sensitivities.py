#!/usr/bin/env python3
"""Register and submit the BET 2026 OPR sensitivity campaign to Kflow.

The campaign contains 39 independent model fits.  Every fit owns two
independent diagnostic branches:

* five Hessian partitions followed by one Hessian merge;
* two profile chains followed by one profile merge.

The merge jobs are attached directly to their fit job so Kflow can display
both diagnostic families independently and MFCLShiny can open the promoted
diagnostic payload without replacing the other family.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Iterable


TASK_CODE = "ofp-sam-bet-2026-opr-recruitment-sensitivities"
TASK_NAME = "BET 2026 OPR recruitment sensitivities"
CAMPAIGN = "opr-recruitment-sensitivities-v1"
MODEL_REPO = "PacificCommunity/ofp-sam-bet-2026-exploration"
MODEL_BRANCH = "experiment/opr-recruitment-sensitivities"
MODEL_ROOT = "opr-sensitivity"
CHECK_REPO = "PacificCommunity/ofp-sam-bet-2026-checks"
CHECK_BRANCH = "main"
REMOTE_USER = "kyuhank"
REMOTE_HOST = "suvofpsubmit.corp.spc.int"
REMOTE_BASE_DIR = "/home/kyuhank/KflowOutput"
SUVA_REQUIREMENTS = 'regexp("^suvofp", Machine)'
DOCKER_IMAGE = (
    "ghcr.io/pacificcommunity/tuna-flow@"
    "sha256:71b97b4bdefa091a55284e45bbddfa330171a0674e8e4a32895424d6c8a100de"
)
MFCL_EXECUTABLE_SHA256 = (
    "02e12dbdf2a564983e9fb50baf095ff472ba3831f71ecc0e3082f49478dac723"
)
MFCLKIT_REF = "e487c069a8bba7b23a64928eb7d60c1dfbd75bb5"
MFCLSHINY_REF = "236a9cf96e1148446b2a650db0991d9661f7d9a7"
CHECK_SOURCE_REF = "117dc295ab127cc50690e0edd3b868f43739ed4f"
EXPECTED_MODELS = 39
HESSIAN_PARTS = 5

PROFILE_CENTER = "100"
PROFILE_DOWNSTREAM = "97.5 95 92.5 90 87.5 85 82.5 80 77.5 75 72.5 70 67.5 65 62.5 60"
PROFILE_UPSTREAM = "102.5 105 107.5 110 112.5 115 117.5 120 122.5 125 127.5 130 132.5 135 137.5 140"
PROFILE_VALUES = (
    "60 62.5 65 67.5 70 72.5 75 77.5 80 82.5 85 87.5 90 92.5 95 97.5 "
    "102.5 105 107.5 110 112.5 115 117.5 120 122.5 125 127.5 130 132.5 135 137.5 140"
)

TERMINAL_JOB_STATUSES = {
    "completed",
    "failed",
    "held",
    "removed",
    "submit-failed",
    "cancelled",
    "replaced",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--submit",
        action="store_true",
        help="Create the task and jobs. Without this flag, only print the plan.",
    )
    parser.add_argument(
        "--api-url",
        default=os.environ.get("KFLOW_API_URL", "http://127.0.0.1:8089"),
        help="Kflow API base URL.",
    )
    parser.add_argument(
        "--api-token",
        default=os.environ.get("KFLOW_API_TOKEN", ""),
        help="Kflow bearer token. Defaults to KFLOW_API_TOKEN.",
    )
    parser.add_argument(
        "--github-token",
        default=(
            os.environ.get("KFLOW_GITHUB_TOKEN")
            or os.environ.get("GITHUB_TOKEN")
            or os.environ.get("GH_TOKEN")
            or ""
        ),
        help="Optional GitHub token used to identify the API actor.",
    )
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--task-code", default=TASK_CODE)
    parser.add_argument("--mfclkit-ref", default=MFCLKIT_REF)
    parser.add_argument("--mfclshiny-ref", default=MFCLSHINY_REF)
    parser.add_argument("--check-source-ref", default=CHECK_SOURCE_REF)
    parser.add_argument("--expected-models", type=int, default=EXPECTED_MODELS)
    return parser.parse_args()


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def git_head(repo_root: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=repo_root,
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        raise RuntimeError(f"Cannot resolve the model source commit: {exc}") from exc


def model_names(repo_root: Path, expected: int) -> list[str]:
    root = repo_root / MODEL_ROOT
    if not root.is_dir():
        raise RuntimeError(f"Missing model root: {root}")
    names = sorted(
        path.name
        for path in root.iterdir()
        if path.is_dir()
        and path.name.startswith("OPR")
        and (path / "model" / "doitall.sh").is_file()
    )
    if len(names) != expected:
        raise RuntimeError(f"Expected {expected} complete OPR models, found {len(names)} in {root}")
    if len(names) != len(set(names)):
        raise RuntimeError("Duplicate OPR model names were discovered.")
    return names


def model_key(model: str) -> str:
    return model.lower().replace("_", "-")


class KflowAPI:
    def __init__(self, base_url: str, api_token: str, github_token: str = "") -> None:
        self.base_url = base_url.rstrip("/")
        self.api_token = api_token.strip()
        self.github_token = github_token.strip()
        if not self.api_token:
            raise RuntimeError("KFLOW_API_TOKEN or --api-token is required for submission.")

    def request(self, method: str, path: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        body = None if payload is None else json.dumps(payload).encode("utf-8")
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {self.api_token}",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        if self.github_token:
            headers["X-GitHub-Token"] = self.github_token
        request = urllib.request.Request(
            f"{self.base_url}{path}",
            data=body,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request, timeout=300) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Kflow {method} {path} returned HTTP {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise RuntimeError(f"Kflow {method} {path} failed: {exc}") from exc
        return json.loads(raw) if raw else {}

    def register_task(self, code: str, payload: dict[str, Any]) -> dict[str, Any]:
        return self.request("POST", f"/api/report/{urllib.parse.quote(code)}", payload)["report"]

    def create_job(self, code: str, payload: dict[str, Any]) -> dict[str, Any]:
        return self.request("POST", f"/api/job/{urllib.parse.quote(code)}", payload)["job"]

    def list_jobs(self, code: str) -> list[dict[str, Any]]:
        jobs: list[dict[str, Any]] = []
        for page in range(1, 101):
            response = self.request(
                "GET",
                f"/api/jobs/{urllib.parse.quote(code)}?page={page}",
            )
            batch = response.get("jobs") if isinstance(response.get("jobs"), list) else []
            if not batch:
                break
            jobs.extend(job for job in batch if isinstance(job, dict))
        return jobs


def job_number(job: dict[str, Any]) -> str:
    value = job.get("job_number") or job.get("run_number") or job.get("id")
    if value is None:
        raise RuntimeError(f"Kflow response has no usable job reference: {job}")
    return str(value)


def current_jobs(jobs: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    return [job for job in jobs if str(job.get("status") or "").lower() != "replaced"]


def tagged_job(
    jobs: Iterable[dict[str, Any]],
    *,
    model: str,
    check_type: str = "",
    check_unit: str = "",
    stage: str = "",
    source_short: str,
) -> dict[str, Any] | None:
    matches: list[dict[str, Any]] = []
    for job in current_jobs(jobs):
        tags = job.get("tags") if isinstance(job.get("tags"), dict) else {}
        metadata = job.get("metadata") if isinstance(job.get("metadata"), dict) else {}
        if str(tags.get("campaign") or metadata.get("campaign") or "") != CAMPAIGN:
            continue
        if str(tags.get("model") or metadata.get("model_selector") or "") != model:
            continue
        if source_short and str(tags.get("source_sha") or metadata.get("source_sha") or "") != source_short:
            continue
        if stage and str(tags.get("stage") or metadata.get("stage") or "") != stage:
            continue
        actual_type = str(tags.get("check_type") or metadata.get("check_type") or "")
        if check_type and actual_type != check_type:
            continue
        actual_unit = str(tags.get("check_unit") or metadata.get("check_unit") or "")
        if check_unit and actual_unit != check_unit:
            continue
        matches.append(job)
    if not matches:
        return None
    return max(matches, key=lambda item: int(item.get("job_number") or item.get("run_number") or 0))


def runtime_env(mfclkit_ref: str, mfclshiny_ref: str) -> dict[str, str]:
    return {
        "KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME": "true",
        "KFLOW_REPO_RUNTIME_PACKAGES": (
            f"mfclkit=PacificCommunity/ofp-sam-mfclkit@{mfclkit_ref},"
            f"mfclshiny=PacificCommunity/mfclshiny@{mfclshiny_ref}"
        ),
        "KFLOW_REPO_RUNTIME_UPDATE": "always",
        "KFLOW_RUNTIME_GITHUB_AUTH": "true",
        "KFLOW_RUNTIME_PACKAGES": "none",
        "KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES": "true",
        "KFLOW_RUNTIME_UPDATE": "never",
        "KFLOW_RUNTIME_UPDATE_INTERVAL_HOURS": "0",
        "MFCLKIT_GITHUB_REF": mfclkit_ref,
        "MFCLSHINY_GITHUB_REF": mfclshiny_ref,
        "MFCL_EXECUTABLE_SHA256": MFCL_EXECUTABLE_SHA256,
        "PROGRAM_PATH": "/home/mfcl/mfclo64",
        "TUNA_FLOW_RUNTIME_UPDATE": "never",
    }


def common_job_payload(*, repo: str, branch: str) -> dict[str, Any]:
    return {
        "repo": repo,
        "branch": branch,
        "command": "bash run.sh",
        "remote_user": REMOTE_USER,
        "remote_host": REMOTE_HOST,
        "remote_base_dir": REMOTE_BASE_DIR,
        "docker_image": DOCKER_IMAGE,
        "cpus": 2,
        "memory": "8GB",
        "disk": "10GB",
        "slot_requirements": SUVA_REQUIREMENTS,
        "checkout": {"mode": "full", "paths": []},
        "output_patterns": ["outputs/**"],
    }


def fit_payload(
    *,
    model: str,
    source_sha: str,
    flow_group: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, Any]:
    key = model_key(model)
    title = f"OPR recruitment sensitivity fit: {model}"
    description = f"Independent production fit for {model}."
    env = {
        **runtime_env(mfclkit_ref, mfclshiny_ref),
        "BET_PHASE10_11_CONVERGENCE": "-4",
        "FLOW_ASSESSMENT_YEAR": "2026",
        "FLOW_GROUP": flow_group,
        "FLOW_SPECIES": "BET",
        "FLOW_SPECIES_LABEL": "bigeye tuna",
        "JOB_DESCRIPTION": description,
        "JOB_KEY": key,
        "JOB_TITLE": title,
        "MFCL_LIVE_LOG": "true",
        "MODEL_LABEL": model,
        "MODEL_ROOT": MODEL_ROOT,
        "RUN_MODE": "doitall",
        "STEPWISE_BUILD_PAYLOAD": "true",
        "STEPWISE_SAVE_FINAL_PAR": "false",
        "STEPWISE_SAVE_RAW_MFCL_INPUTS": "true",
        "STEPWISE_SINGLE_PAR_REPORT": "true",
        "STEP_SELECT": model,
        "TRIGGER_NEXT": "false",
    }
    metadata = {
        "campaign": CAMPAIGN,
        "effort_creep_application_count": 1,
        "effort_creep_source": "committed OPR sensitivity model input",
        "flow_group": flow_group,
        "job_description": description,
        "job_key": key,
        "job_title": title,
        "model_selector": model,
        "model_source_commit": source_sha,
        "model_source_path": f"{MODEL_ROOT}/{model}/model",
        "parent_archive_used_as_model_input": False,
        "runner": "bash run.sh",
        "source_sha": source_sha[:12],
        "stage": "fit",
        "submission_key": sha256_text(f"{CAMPAIGN}:{source_sha}:{model}:fit"),
    }
    return {
        **common_job_payload(repo=MODEL_REPO, branch=MODEL_BRANCH),
        "batch_name": f"{TASK_CODE}-{model}",
        "env": env,
        "job_config": env,
        "tags": {
            "campaign": CAMPAIGN,
            "flow": flow_group,
            "model": model,
            "source_sha": source_sha[:12],
            "stage": "fit",
        },
        "metadata": metadata,
    }


def diagnostic_common_env(
    *,
    model: str,
    source_sha: str,
    flow_group: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, str]:
    return {
        **runtime_env(mfclkit_ref, mfclshiny_ref),
        "FLOW_ASSESSMENT_YEAR": "2026",
        "FLOW_GROUP": flow_group,
        "FLOW_SPECIES": "BET",
        "FLOW_SPECIES_LABEL": "bigeye tuna",
        "HESSIAN_NSPLIT": str(HESSIAN_PARTS),
        "MODEL_SELECTOR": model,
        "MODEL_SOURCE_PATH": f"{MODEL_ROOT}/{model}/model",
        "MODEL_SOURCE_REF": source_sha,
        "MODEL_SOURCE_REPO": MODEL_REPO,
        "PROFILE_CENTER": PROFILE_CENTER,
        "PROFILE_EXECUTION_MODE": "continuation",
        "PROFILE_INCLUDE_BASE_ANCHOR": "false",
        "PROFILE_PARALLEL_MODE": "chains",
        "PROFILE_VALUES": PROFILE_VALUES,
        "PROFILE_VALUE_MODE": "percent",
    }


def diagnostic_payload_base(
    *,
    env: dict[str, str],
    tags: dict[str, Any],
    metadata: dict[str, Any],
    input_jobs: list[str],
) -> dict[str, Any]:
    return {
        **common_job_payload(repo=CHECK_REPO, branch=CHECK_BRANCH),
        "env": env,
        "job_config": env,
        "tags": {"campaign": CAMPAIGN, **tags},
        "metadata": {
            "campaign": CAMPAIGN,
            "check_source_ref": CHECK_SOURCE_REF,
            **metadata,
        },
        "input_jobs": input_jobs,
    }


def hessian_unit_payload(
    *,
    model: str,
    part: int,
    fit_ref: str,
    source_sha: str,
    flow_group: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, Any]:
    title = f"hessian part {part}/{HESSIAN_PARTS}: {model}"
    description = f"Run hessian part {part}/{HESSIAN_PARTS} check for {model}."
    env = {
        **diagnostic_common_env(
            model=model,
            source_sha=source_sha,
            flow_group=flow_group,
            mfclkit_ref=mfclkit_ref,
            mfclshiny_ref=mfclshiny_ref,
        ),
        "CHECK_TYPE": "hessian",
        "HESSIAN_PART": str(part),
        "HESSIAN_PARTS": str(part),
        "KFLOW_JOB_DESCRIPTION": description,
        "KFLOW_JOB_TITLE": title,
    }
    return diagnostic_payload_base(
        env=env,
        tags={
            "check_type": "hessian",
            "check_unit": str(part),
            "flow": flow_group,
            "model": model,
            "source_sha": source_sha[:12],
            "stage": "checks",
        },
        metadata={
            "check_type": "hessian",
            "check_unit": str(part),
            "check_unit_type": "hessian_part",
            "flow_group": flow_group,
            "hessian_nsplit": str(HESSIAN_PARTS),
            "input_jobs": [fit_ref],
            "job_description": description,
            "job_title": title,
            "model_selector": model,
            "parallel_units": True,
            "source_sha": source_sha[:12],
            "submission_key": sha256_text(
                f"{CAMPAIGN}:{source_sha}:{model}:hessian:{part}"
            ),
        },
        input_jobs=[fit_ref],
    )


def profile_env() -> dict[str, str]:
    return {
        "PROFILE_AF172": "0",
        "PROFILE_AF173": "0",
        "PROFILE_AF174": "0",
        "PROFILE_CHAIN": "true",
        "PROFILE_CONTINUATION_REPS": "1000",
        "PROFILE_CONVERGENCE_EXPONENT": "-3",
        "PROFILE_DISTANCE_BREAKS": "20 35",
        "PROFILE_DOITALL_CONVERGENCE": "-3",
        "PROFILE_DOITALL_PENALTY": "10000000",
        "PROFILE_DOITALL_SCRIPT": "doitall.sh",
        "PROFILE_EXPECTED_VALUES": PROFILE_VALUES,
        "PROFILE_EXTRA_FAR_REFINE": "true",
        "PROFILE_HBASE_BASE_REL_TOLERANCE": "1e-5",
        "PROFILE_HBASE_CONDITION_CAP": "10000000",
        "PROFILE_HBASE_EIGEN_FLOOR_RELATIVE": "1e-10",
        "PROFILE_HBASE_ENABLED": "false",
        "PROFILE_HBASE_MAX_COORDINATE_STEP": "0.35",
        "PROFILE_HBASE_MAX_QUADRATIC_STEP": "25",
        "PROFILE_HBASE_NEGATIVE_TOLERANCE": "1e-8",
        "PROFILE_HBASE_REPAIR_CPUS": "4",
        "PROFILE_HBASE_REPAIR_MEMORY_GB": "32",
        "PROFILE_HBASE_REPAIR_MEMORY_PER_WORKER_GB": "8",
        "PROFILE_HBASE_REPAIR_PASSES": "2",
        "PROFILE_HBASE_RESTART_BASE": "920000",
        "PROFILE_INCLUDE_FLAG55": "true",
        "PROFILE_INVALID_RETRY_PASSES": "3",
        "PROFILE_JAGGED_REPAIR_PASSES": "2",
        "PROFILE_JAGGED_TOLERANCE": "0.1",
        "PROFILE_LABEL": "total_average_biomass",
        "PROFILE_MAX_JAGGED_REPAIRS": "6",
        "PROFILE_NAME": "total_average_biomass",
        "PROFILE_PENALTIES": "100000 1000000 10000000",
        "PROFILE_PENALTY_SCALES": "1 2 4",
        "PROFILE_PRESET": "three_stage",
        "PROFILE_QUANTITY": "avg_bio",
        "PROFILE_QUANTITY_TYPE": "2",
        "PROFILE_RAMP_REPS": "50 50 2000",
        "PROFILE_REPS_SCALES": "1 1.25 1.5",
        "PROFILE_RETRY_INVALID": "true",
        "PROFILE_RETRY_JAGGED": "true",
        "PROFILE_SPEC_VERSION": "mfclkit.quantity-profile.v2",
        "PROFILE_STYLE": "three_stage",
        "PROFILE_TARGET_REL_TOLERANCE": "0.001",
        "PROFILE_TYPE": "quantity",
    }


def profile_unit_payload(
    *,
    model: str,
    side: str,
    fit_ref: str,
    source_sha: str,
    flow_group: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, Any]:
    values = PROFILE_DOWNSTREAM if side == "downstream" else PROFILE_UPSTREAM
    title = f"profile {side} chain: {model}"
    description = f"Run profile {side} chain check for {model}."
    env = {
        **diagnostic_common_env(
            model=model,
            source_sha=source_sha,
            flow_group=flow_group,
            mfclkit_ref=mfclkit_ref,
            mfclshiny_ref=mfclshiny_ref,
        ),
        **profile_env(),
        "CHECK_TYPE": "profile",
        "KFLOW_JOB_DESCRIPTION": description,
        "KFLOW_JOB_TITLE": title,
        "PROFILE_CHAIN_SIDE": side,
        "PROFILE_VALUES": values,
    }
    return diagnostic_payload_base(
        env=env,
        tags={
            "check_type": "profile",
            "check_unit": side,
            "flow": flow_group,
            "model": model,
            "source_sha": source_sha[:12],
            "stage": "checks",
        },
        metadata={
            "check_type": "profile",
            "check_unit": side,
            "check_unit_type": "profile_chain",
            "flow_group": flow_group,
            "input_jobs": [fit_ref],
            "job_description": description,
            "job_title": title,
            "model_selector": model,
            "parallel_units": True,
            "profile_center": PROFILE_CENTER,
            "profile_chain_values": values,
            "profile_doitall_penalty": "10000000",
            "profile_doitall_script": "doitall.sh",
            "profile_execution_mode": "continuation",
            "profile_expected_values": PROFILE_VALUES,
            "profile_name": "total_average_biomass",
            "profile_preset": "three_stage",
            "source_sha": source_sha[:12],
            "submission_key": sha256_text(
                f"{CAMPAIGN}:{source_sha}:{model}:profile:{side}"
            ),
        },
        input_jobs=[fit_ref],
    )


def merge_payload(
    *,
    model: str,
    check_type: str,
    fit_ref: str,
    unit_refs: list[str],
    source_sha: str,
    flow_group: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, Any]:
    title = f"{check_type}-merge: {model}"
    description = f"Merge split {check_type} check outputs for {model}."
    attached_group = f"{flow_group}:{model}:diagnostics"
    common = diagnostic_common_env(
        model=model,
        source_sha=source_sha,
        flow_group=flow_group,
        mfclkit_ref=mfclkit_ref,
        mfclshiny_ref=mfclshiny_ref,
    )
    env = {
        **common,
        **(profile_env() if check_type == "profile" else {}),
        "ATTACH_CHECK_TYPES": check_type,
        "ATTACH_OUTPUT_MODE": "delta",
        "ATTACH_UPDATED_CHECK_TYPES": check_type,
        "BASE_MODEL_JOB": fit_ref,
        "CHECK_INPUT_JOBS": " ".join(unit_refs),
        "CHECK_MERGE_TYPE": check_type,
        "CHECK_TYPE": f"{check_type}-merge" if check_type == "profile" else "hessian_merge",
        "KFLOW_JOB_DESCRIPTION": description,
        "KFLOW_JOB_TITLE": title,
        "MODEL_BASE_INPUT_JOB": fit_ref,
        "MODEL_ORIGINAL_BASE_INPUT_JOB": fit_ref,
    }
    if check_type == "profile":
        env["PROFILE_VALUES"] = PROFILE_VALUES
    metadata: dict[str, Any] = {
        "allow_failed_input_jobs": True,
        "attach_base_input_job": fit_ref,
        "attach_check_types": [check_type],
        "attach_output_mode": "delta",
        "attached_check_types": [check_type],
        "attached_output_overlay": True,
        "attached_output_overlay_mode": "diagnostics_with_payload",
        "attached_output_overlay_preserve_payload": True,
        "attached_output_overlay_replace_names": [check_type],
        "attached_output_overlay_replace_payload": True,
        "attached_updated_check_types": [check_type],
        "attached_work_group": attached_group,
        "attached_work_headline": "Diagnostics",
        "attached_work_label": f"{model} {check_type} diagnostics",
        "attached_work_latest": True,
        "attached_work_parent_job": fit_ref,
        "attached_work_role": "updated output",
        "attached_work_slot": f"diagnostics:{model}:{check_type}",
        "attached_work_summary": (
            f"Merged {check_type} diagnostic delta attached directly to the base model output."
        ),
        "auto_merge": True,
        "base_job": fit_ref,
        "check_input_jobs": unit_refs,
        "check_type": f"{check_type}-merge",
        "direct_merge_attach": True,
        "flow_group": flow_group,
        "independent_diagnostic_merge": True,
        "input_history": [],
        "input_jobs": [fit_ref, *unit_refs],
        "job_description": description,
        "job_title": title,
        "merged_check_type": check_type,
        "model_selector": model,
        "nested_work_group": check_type,
        "original_base_job": fit_ref,
        "overlay_base_input_job": fit_ref,
        "parallel_units": True,
        "previous_attached_output_job": "",
        "previous_check_merge_jobs": [],
        "same_slot_predecessor_job": "",
        "source_sha": source_sha[:12],
        "submission_key": sha256_text(
            f"{CAMPAIGN}:{source_sha}:{model}:{check_type}:merge"
        ),
    }
    if check_type == "profile":
        metadata.update(
            {
                "profile_doitall_penalty": "10000000",
                "profile_doitall_script": "doitall.sh",
                "profile_execution_mode": "continuation",
                "profile_expected_values": PROFILE_VALUES,
                "profile_name": "total_average_biomass",
                "profile_parallel_mode": "chains",
                "profile_preset": "three_stage",
                "profile_spec_version": "mfclkit.quantity-profile.v2",
            }
        )
    return diagnostic_payload_base(
        env=env,
        tags={
            "attached_output_overlay": "true",
            "base_job": fit_ref,
            "check_type": f"{check_type}-merge",
            "flow": flow_group,
            "merge_for": check_type,
            "model": model,
            "source_sha": source_sha[:12],
            "stage": "checks",
        },
        metadata=metadata,
        input_jobs=[fit_ref, *unit_refs],
    )


def task_payload(
    *,
    source_sha: str,
    mfclkit_ref: str,
    mfclshiny_ref: str,
) -> dict[str, Any]:
    return {
        "name": TASK_NAME,
        "description": (
            "Thirty-nine independent BET 2026 OPR recruitment sensitivities from the "
            "TC1/NOCUT/DW1 input, fitted in parallel on Suva. Each fit has five Hessian "
            "partitions and two profile chains as automatic dependency diagnostics."
        ),
        "owner_login": "kyuhank",
        "repo_full_name": MODEL_REPO,
        "branch": MODEL_BRANCH,
        "command": "bash run.sh",
        "remote_user": REMOTE_USER,
        "remote_host": REMOTE_HOST,
        "remote_base_dir": REMOTE_BASE_DIR,
        "docker_image": DOCKER_IMAGE,
        "cpus": 2,
        "memory": "8GB",
        "disk": "10GB",
        "slot_requirements": SUVA_REQUIREMENTS,
        "checkout": {"mode": "full", "paths": []},
        "env": runtime_env(mfclkit_ref, mfclshiny_ref),
        "tags": {
            "campaign": CAMPAIGN,
            "site": "suva",
            "source_sha": source_sha[:12],
        },
        "metadata": {
            "campaign": CAMPAIGN,
            "check_source_ref": CHECK_SOURCE_REF,
            "diagnostics": {"hessian_partitions": HESSIAN_PARTS, "profile_chains": 2},
            "model_count": EXPECTED_MODELS,
            "model_root": MODEL_ROOT,
            "model_source_commit": source_sha,
            "runtime_refs": {
                "mfclkit": mfclkit_ref,
                "mfclshiny": mfclshiny_ref,
            },
            "task_role": "sensitivity-campaign",
        },
        "output_patterns": ["outputs/**"],
    }


def create_or_reuse(
    *,
    api: KflowAPI,
    task_code: str,
    existing_jobs: list[dict[str, Any]],
    model: str,
    source_short: str,
    payload: dict[str, Any],
    check_type: str = "",
    check_unit: str = "",
    stage: str = "",
) -> tuple[dict[str, Any], bool]:
    existing = tagged_job(
        existing_jobs,
        model=model,
        check_type=check_type,
        check_unit=check_unit,
        stage=stage,
        source_short=source_short,
    )
    if existing is not None:
        return existing, False
    job = api.create_job(task_code, payload)
    existing_jobs.append(job)
    return job, True


def submit_campaign(args: argparse.Namespace, models: list[str], source_sha: str) -> dict[str, Any]:
    api = KflowAPI(args.api_url, args.api_token, args.github_token)
    flow_group = f"{args.task_code}-{source_sha[:12]}"
    source_short = source_sha[:12]
    task = api.register_task(
        args.task_code,
        task_payload(
            source_sha=source_sha,
            mfclkit_ref=args.mfclkit_ref,
            mfclshiny_ref=args.mfclshiny_ref,
        ),
    )

    task_codes = {
        "fit": args.task_code,
        "hessian": f"{args.task_code}-check-hessian",
        "profile": f"{args.task_code}-check-profile",
        "hessian_merge": f"{args.task_code}-check-hessian-merge",
        "profile_merge": f"{args.task_code}-check-profile-merge",
    }
    jobs_by_task: dict[str, list[dict[str, Any]]] = {}
    for key, code in task_codes.items():
        try:
            jobs_by_task[key] = api.list_jobs(code)
        except RuntimeError as exc:
            if "Task not found" in str(exc):
                jobs_by_task[key] = []
            else:
                raise

    created_counts = {key: 0 for key in task_codes}
    model_records: list[dict[str, Any]] = []

    for index, model in enumerate(models, start=1):
        fit, created = create_or_reuse(
            api=api,
            task_code=task_codes["fit"],
            existing_jobs=jobs_by_task["fit"],
            model=model,
            source_short=source_short,
            payload=fit_payload(
                model=model,
                source_sha=source_sha,
                flow_group=flow_group,
                mfclkit_ref=args.mfclkit_ref,
                mfclshiny_ref=args.mfclshiny_ref,
            ),
            stage="fit",
        )
        created_counts["fit"] += int(created)
        fit_ref = job_number(fit)

        hessian_refs: list[str] = []
        for part in range(1, HESSIAN_PARTS + 1):
            unit, unit_created = create_or_reuse(
                api=api,
                task_code=task_codes["hessian"],
                existing_jobs=jobs_by_task["hessian"],
                model=model,
                source_short=source_short,
                payload=hessian_unit_payload(
                    model=model,
                    part=part,
                    fit_ref=fit_ref,
                    source_sha=source_sha,
                    flow_group=flow_group,
                    mfclkit_ref=args.mfclkit_ref,
                    mfclshiny_ref=args.mfclshiny_ref,
                ),
                check_type="hessian",
                check_unit=str(part),
            )
            created_counts["hessian"] += int(unit_created)
            hessian_refs.append(job_number(unit))

        profile_refs: list[str] = []
        for side in ("downstream", "upstream"):
            unit, unit_created = create_or_reuse(
                api=api,
                task_code=task_codes["profile"],
                existing_jobs=jobs_by_task["profile"],
                model=model,
                source_short=source_short,
                payload=profile_unit_payload(
                    model=model,
                    side=side,
                    fit_ref=fit_ref,
                    source_sha=source_sha,
                    flow_group=flow_group,
                    mfclkit_ref=args.mfclkit_ref,
                    mfclshiny_ref=args.mfclshiny_ref,
                ),
                check_type="profile",
                check_unit=side,
            )
            created_counts["profile"] += int(unit_created)
            profile_refs.append(job_number(unit))

        hessian_merge, merge_created = create_or_reuse(
            api=api,
            task_code=task_codes["hessian_merge"],
            existing_jobs=jobs_by_task["hessian_merge"],
            model=model,
            source_short=source_short,
            payload=merge_payload(
                model=model,
                check_type="hessian",
                fit_ref=fit_ref,
                unit_refs=hessian_refs,
                source_sha=source_sha,
                flow_group=flow_group,
                mfclkit_ref=args.mfclkit_ref,
                mfclshiny_ref=args.mfclshiny_ref,
            ),
            check_type="hessian-merge",
        )
        created_counts["hessian_merge"] += int(merge_created)

        profile_merge, merge_created = create_or_reuse(
            api=api,
            task_code=task_codes["profile_merge"],
            existing_jobs=jobs_by_task["profile_merge"],
            model=model,
            source_short=source_short,
            payload=merge_payload(
                model=model,
                check_type="profile",
                fit_ref=fit_ref,
                unit_refs=profile_refs,
                source_sha=source_sha,
                flow_group=flow_group,
                mfclkit_ref=args.mfclkit_ref,
                mfclshiny_ref=args.mfclshiny_ref,
            ),
            check_type="profile-merge",
        )
        created_counts["profile_merge"] += int(merge_created)

        model_records.append(
            {
                "model": model,
                "fit": fit_ref,
                "hessian_units": hessian_refs,
                "hessian_merge": job_number(hessian_merge),
                "profile_units": profile_refs,
                "profile_merge": job_number(profile_merge),
            }
        )
        print(
            f"[{index:02d}/{len(models)}] {model}: fit {fit_ref}; "
            f"Hessian {','.join(hessian_refs)} -> {job_number(hessian_merge)}; "
            f"Profile {','.join(profile_refs)} -> {job_number(profile_merge)}",
            flush=True,
        )

    return {
        "task": {
            "code": args.task_code,
            "name": task.get("name") or TASK_NAME,
        },
        "campaign": CAMPAIGN,
        "source_sha": source_sha,
        "flow_group": flow_group,
        "site": "Suva",
        "container": DOCKER_IMAGE,
        "runtime_refs": {
            "mfclkit": args.mfclkit_ref,
            "mfclshiny": args.mfclshiny_ref,
            "checks": args.check_source_ref,
        },
        "created": created_counts,
        "counts": {
            "models": len(models),
            "fit": len(models),
            "hessian_units": len(models) * HESSIAN_PARTS,
            "hessian_merges": len(models),
            "profile_units": len(models) * 2,
            "profile_merges": len(models),
            "diagnostics": len(models) * (HESSIAN_PARTS + 1 + 2 + 1),
            "all_jobs": len(models) * (1 + HESSIAN_PARTS + 1 + 2 + 1),
        },
        "models": model_records,
    }


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    models = model_names(repo_root, args.expected_models)
    source_sha = git_head(repo_root)
    plan = {
        "task": args.task_code,
        "source_sha": source_sha,
        "site": "Suva",
        "models": len(models),
        "fit_jobs": len(models),
        "hessian_units": len(models) * HESSIAN_PARTS,
        "hessian_merges": len(models),
        "profile_units": len(models) * 2,
        "profile_merges": len(models),
        "all_jobs": len(models) * 10,
        "mfclkit_ref": args.mfclkit_ref,
        "mfclshiny_ref": args.mfclshiny_ref,
        "check_source_ref": args.check_source_ref,
    }
    if not args.submit:
        print(json.dumps(plan, indent=2))
        return 0
    result = submit_campaign(args, models, source_sha)
    print("KFLOW_SUBMISSION_RESULT=" + json.dumps(result, separators=(",", ":")), flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
