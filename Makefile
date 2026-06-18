SHELL := /usr/bin/env bash

CONFIG_R ?= stepwise-config.R
cfg = $(shell Rscript -e 'source("$(CONFIG_R)"); cat(stepwise_value("$(1)", "$(2)"))')
yml = $(shell Rscript -e 'y <- yaml::read_yaml("kflow.yaml"); v <- $(1); if (is.null(v) || length(v) == 0 || is.na(v[[1]])) v <- "$(2)"; if (is.logical(v)) v <- tolower(as.character(v)); cat(as.character(v[[1]]))')

STEP_SELECT ?= $(call cfg,default_step_select,01-base-11par)
MFCL_FEVALS ?= $(call cfg,mfcl_fevals,)
MFCL_LIVE_LOG ?= $(call yml,y$$env$$MFCL_LIVE_LOG,true)
OUTPUT_DIR ?= outputs
PROGRAM_PATH ?= $(call yml,y$$env$$PROGRAM_PATH,/home/mfcl/mfclo64)
DOCKER_IMAGE ?= $(call yml,y$$docker_image,ghcr.io/pacificcommunity/tuna-flow:v1.5)
HOST_UID ?= $(shell id -u 2>/dev/null || echo 1000)
HOST_GID ?= $(shell id -g 2>/dev/null || echo 1000)
DOCKER_HOME ?= /work/.docker-home

KFLOW_URL ?= http://127.0.0.1:8089
KFLOW_TASK ?= $(call yml,y$$name,ofp-sam-bet-2026-stepwise)
FLOW_GROUP ?= $(call cfg,flow_group,bet-2026-e2e)
TRIGGER_NEXT ?= $(call cfg,trigger_next,true)
JOB_TITLE ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_R)"); cat(stepwise_job_title(Sys.getenv("STEP_SELECT")))')

KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES,true)
KFLOW_RUNTIME_UPDATE ?= $(call yml,y$$env$$KFLOW_RUNTIME_UPDATE,auto)
KFLOW_RUNTIME_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_PACKAGES,mfclshiny=PacificCommunity/mfclshiny@main)
KFLOW_RUNTIME_GITHUB_AUTH ?= $(call yml,y$$env$$KFLOW_RUNTIME_GITHUB_AUTH,true)
KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME ?= $(call yml,y$$env$$KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME,true)

.PHONY: help list clean fix-permissions local docker kflow

help:
	@printf '%s\n' \
	  'BET 2026 stepwise shortcuts' \
	  '' \
	  'Models live in stepwise-config.R; Kflow/runtime defaults live in kflow.yaml.' \
	  '' \
	  'make list' \
	  '  Show configured model rows from stepwise-config.R.' \
	  '' \
	  'make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64' \
	  '  Run directly on this machine.' \
	  '' \
	  'make docker STEP_SELECT=01-base-11par' \
	  '  Run locally inside the configured tuna-flow Docker image.' \
	  '' \
	  'make fix-permissions' \
	  '  Repair root-owned files left by older local Docker runs.' \
	  '' \
	  'make kflow STEP_SELECT=01-base-11par KFLOW_API_TOKEN=...' \
	  '  Submit the selected model folder to Kflow.' \
	  '' \
	  'make kflow TRIGGER_NEXT=false' \
	  '  Submit only the selected model folder, without launching plot/report afterward.' \
	  '' \
	  'Note: MFCL_FEVALS is applied by the runner only for last_par/single; doitall.sh must read it explicitly.' \
	  '' \
	  'Common overrides: STEP_SELECT, MFCL_FEVALS, MFCL_LIVE_LOG, TRIGGER_NEXT, OUTPUT_DIR.'

list:
	@Rscript -e "source('$(CONFIG_R)'); print(stepwise_models, row.names = FALSE)"

clean:
	rm -rf '$(OUTPUT_DIR)' work .R-library .kflow-runtime-cache .docker-home

fix-permissions:
	docker run --rm \
	  -v "$$(pwd):/work" \
	  -w /work \
	  --user 0:0 \
	  '$(DOCKER_IMAGE)' \
	  bash -lc "chown -R $(HOST_UID):$(HOST_GID) outputs work .R-library .kflow-runtime-cache .docker-home 2>/dev/null || true"

local:
	STEP_SELECT='$(STEP_SELECT)' \
	MFCL_FEVALS='$(MFCL_FEVALS)' \
	MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	OUTPUT_DIR='$(OUTPUT_DIR)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	bash run.sh

docker:
	@token="$${GITHUB_PAT:-$${GH_TOKEN:-$${GIT_PAT:-}}}"; \
	if [[ -z "$$token" ]] && command -v gh >/dev/null 2>&1; then \
	  token="$$(gh auth token 2>/dev/null || true)"; \
	fi; \
	if [[ '$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' == 'true' && -z "$$token" ]]; then \
	  echo 'mfclshiny is private. Run `gh auth login` or pass GH_TOKEN=... / GITHUB_PAT=... to make docker.' >&2; \
	  exit 42; \
	fi; \
	mkdir -p .docker-home .R-library .kflow-runtime-cache; \
	docker run --rm \
	  --user '$(HOST_UID):$(HOST_GID)' \
	  -v "$$(pwd):/work" \
	  -w /work \
	  -e HOME='$(DOCKER_HOME)' \
	  -e XDG_CACHE_HOME='$(DOCKER_HOME)/.cache' \
	  -e R_LIBS_USER='/work/.R-library' \
	  -e KFLOW_RUNTIME_LIBRARY='/work/.R-library' \
	  -e STEP_SELECT='$(STEP_SELECT)' \
	  -e MFCL_FEVALS='$(MFCL_FEVALS)' \
	  -e MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	  -e OUTPUT_DIR='$(OUTPUT_DIR)' \
	  -e PROGRAM_PATH='$(PROGRAM_PATH)' \
	  -e KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	  -e KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	  -e KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	  -e KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	  -e KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	  -e GITHUB_PAT="$$token" \
	  -e GH_TOKEN="$$token" \
	  '$(DOCKER_IMAGE)' \
	  bash run.sh

kflow:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow.' >&2; exit 2; }
	@STEP_SELECT='$(STEP_SELECT)' MFCL_FEVALS='$(MFCL_FEVALS)' MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' FLOW_GROUP='$(FLOW_GROUP)' JOB_TITLE='$(JOB_TITLE)' TRIGGER_NEXT='$(TRIGGER_NEXT)' KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' python3 -c 'import json, os; env={k:os.environ[k] for k in ("STEP_SELECT","MFCL_FEVALS","MFCL_LIVE_LOG","FLOW_GROUP","JOB_TITLE","KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES","KFLOW_RUNTIME_UPDATE","KFLOW_RUNTIME_PACKAGES","KFLOW_RUNTIME_GITHUB_AUTH","KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME") if os.environ.get(k,"")}; payload={"env":env,"tags":{"stage":"stepwise","flow":os.environ["FLOW_GROUP"],"step":os.environ["STEP_SELECT"],"trigger_next":os.environ["TRIGGER_NEXT"]}}; flag=os.environ["TRIGGER_NEXT"].strip().lower(); payload.update({"triggers": {}} if flag in ("0","false","no","off","none","skip") else {}); print(json.dumps(payload))' | curl -sS -H "Authorization: Bearer $${KFLOW_API_TOKEN}" -H 'Content-Type: application/json' -X POST "$(KFLOW_URL)/api/job/$(KFLOW_TASK)" -d @-
	@printf '\n'
