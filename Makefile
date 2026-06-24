SHELL := /usr/bin/env bash

CONFIG_R ?= job-config.R
CONFIG_HELPERS_R ?= R/stepwise_config_helpers.R
README_SOURCES := $(CONFIG_R) $(CONFIG_HELPERS_R) R/update_readme.R kflow.yaml
cfg = $(shell Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_value("$(1)", "$(2)"))')
yml = $(shell Rscript -e 'y <- yaml::read_yaml("kflow.yaml"); v <- $(1); if (is.null(v) || length(v) == 0 || is.na(v[[1]])) v <- "$(2)"; if (is.logical(v)) v <- tolower(as.character(v)); cat(as.character(v[[1]]))')

STEP_SELECT ?= $(call cfg,default_step_select,all)
MFCL_FEVALS ?= $(call cfg,mfcl_fevals,)
MFCL_LIVE_LOG ?= $(call yml,y$$env$$MFCL_LIVE_LOG,true)
BET_PHASE10_11_CONVERGENCE ?= $(call yml,y$$env$$BET_PHASE10_11_CONVERGENCE,-3)
OUTPUT_DIR ?= outputs
PROGRAM_PATH ?= $(call yml,y$$env$$PROGRAM_PATH,/home/mfcl/mfclo64)
DOCKER_IMAGE ?= $(call yml,y$$docker_image,ghcr.io/pacificcommunity/tuna-flow:v1.5)
HOST_UID ?= $(shell id -u 2>/dev/null || echo 1000)
HOST_GID ?= $(shell id -g 2>/dev/null || echo 1000)
DOCKER_HOME ?= /work/.docker-home

KFLOW_URL ?= http://127.0.0.1:8089
KFLOW_TASK ?= $(call yml,y$$name,ofp-sam-bet-2026-stepwise)
KFLOW_CHAIN_REPOS ?= . ../ofp-sam-bet-2026-results ../ofp-sam-bet-2026-report
FLOW_GROUP ?= $(call cfg,flow_group,bet-2026-e2e)
TRIGGER_NEXT ?= $(call cfg,trigger_next,true)
JOB_TITLE ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_job_title(Sys.getenv("STEP_SELECT")))')
MODEL_LABEL ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_model_label(Sys.getenv("STEP_SELECT")))')
JOB_KEY ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_job_key(Sys.getenv("STEP_SELECT")))')
RUN_MODE ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "run_mode"))')
INPUT_PAR ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "input_par"))')
FRQ ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "frq"))')
OUTPUT_PAR ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "output_par"))')
FEVALS ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "fevals"))')

KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES,true)
KFLOW_RUNTIME_UPDATE ?= $(call yml,y$$env$$KFLOW_RUNTIME_UPDATE,auto)
KFLOW_RUNTIME_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_PACKAGES,mfclshiny=PacificCommunity/mfclshiny@e2ff718)
MFCLSHINY_GITHUB_REF ?= $(call yml,y$$env$$MFCLSHINY_GITHUB_REF,e2ff718)
KFLOW_RUNTIME_GITHUB_AUTH ?= $(call yml,y$$env$$KFLOW_RUNTIME_GITHUB_AUTH,true)
KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME ?= $(call yml,y$$env$$KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME,true)

.PHONY: help setup hooks readme list clean fix-permissions local docker kflow kflow-register kflow-register-chain

help:
	@printf '%s\n' \
	  'BET 2026 stepwise shortcuts' \
	  '' \
	  'Models live in job-config.R; Kflow/runtime defaults live in kflow.yaml.' \
	  '' \
	  'make list' \
	  '  Refresh README.md, enable the commit hook, then show configured model rows from job-config.R.' \
	  '' \
	  'make local STEP_SELECT=all PROGRAM_PATH=/path/to/mfclo64' \
	  '  Run directly on this machine.' \
	  '' \
	  'make docker STEP_SELECT=all' \
	  '  Run locally inside the configured tuna-flow Docker image.' \
	  '' \
	  'make fix-permissions' \
	  '  Repair root-owned files left by older local Docker runs.' \
	  '' \
	  'make kflow STEP_SELECT=all' \
	  '  Submit the selected model folder to Kflow with your shell credentials.' \
	  '' \
	  'make kflow-register-chain' \
	  '  Refresh Kflow task definitions for stepwise, results, and report from their kflow.yaml files.' \
	  '' \
	  'make kflow TRIGGER_NEXT=false' \
	  '  Submit only the selected model folder, without launching plot/report afterward.' \
	  '' \
	  'BET_PHASE10_11_CONVERGENCE=-3 is the quick default for PHASE 10/11. Set -5 for strict runs.' \
	  '' \
	  'Note: MFCL_FEVALS is applied by the runner only for last_par/single; doitall.sh must read it explicitly.' \
	  '' \
	  'Common overrides: STEP_SELECT, MFCL_FEVALS, MFCL_LIVE_LOG, TRIGGER_NEXT, OUTPUT_DIR.'

setup: hooks

hooks:
	@if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	  current="$$(git config --get core.hooksPath 2>/dev/null || true)"; \
	  if [[ "$$current" != ".githooks" ]]; then \
	    git config core.hooksPath .githooks; \
	  fi; \
	fi

README.md: $(README_SOURCES)
	@CONFIG_R='$(CONFIG_R)' README_MD='README.md' Rscript R/update_readme.R

readme: hooks
	@CONFIG_R='$(CONFIG_R)' README_MD='README.md' Rscript R/update_readme.R

list: readme
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

local: readme
	STEP_SELECT='$(STEP_SELECT)' \
	MFCL_FEVALS='$(MFCL_FEVALS)' \
	MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' \
	OUTPUT_DIR='$(OUTPUT_DIR)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' \
	KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	bash run.sh

docker: readme
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
	  -e BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' \
	  -e OUTPUT_DIR='$(OUTPUT_DIR)' \
	  -e PROGRAM_PATH='$(PROGRAM_PATH)' \
	  -e KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	  -e KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	  -e KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	  -e MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' \
	  -e KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	  -e KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	  -e GITHUB_PAT="$$token" \
	  -e GH_TOKEN="$$token" \
	  '$(DOCKER_IMAGE)' \
	  bash run.sh

kflow: readme
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow.' >&2; exit 2; }
	@STEP_SELECT='$(STEP_SELECT)' MFCL_FEVALS='$(MFCL_FEVALS)' MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' FLOW_GROUP='$(FLOW_GROUP)' JOB_TITLE='$(JOB_TITLE)' MODEL_LABEL='$(MODEL_LABEL)' JOB_KEY='$(JOB_KEY)' RUN_MODE='$(RUN_MODE)' INPUT_PAR='$(INPUT_PAR)' FRQ='$(FRQ)' OUTPUT_PAR='$(OUTPUT_PAR)' FEVALS='$(FEVALS)' TRIGGER_NEXT='$(TRIGGER_NEXT)' KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' python3 -c 'import json, os; env={k:os.environ[k] for k in ("STEP_SELECT","MFCL_FEVALS","MFCL_LIVE_LOG","BET_PHASE10_11_CONVERGENCE","FLOW_GROUP","JOB_TITLE","MODEL_LABEL","JOB_KEY","RUN_MODE","INPUT_PAR","FRQ","OUTPUT_PAR","FEVALS","KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES","KFLOW_RUNTIME_UPDATE","KFLOW_RUNTIME_PACKAGES","MFCLSHINY_GITHUB_REF","KFLOW_RUNTIME_GITHUB_AUTH","KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME") if os.environ.get(k,"")}; payload={"env":env,"tags":{"stage":"stepwise","flow":os.environ["FLOW_GROUP"],"step":os.environ["STEP_SELECT"],"model_label":os.environ["MODEL_LABEL"],"job_key":os.environ["JOB_KEY"],"run_mode":os.environ["RUN_MODE"],"trigger_next":os.environ["TRIGGER_NEXT"]}}; flag=os.environ["TRIGGER_NEXT"].strip().lower(); payload.update({"triggers": {}} if flag in ("0","false","no","off","none","skip") else {}); print(json.dumps(payload))' | curl -sS -H "Authorization: Bearer $${KFLOW_API_TOKEN}" -H 'Content-Type: application/json' -X POST "$(KFLOW_URL)/api/job/$(KFLOW_TASK)" -d @-
	@printf '\n'

kflow-register:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow-register.' >&2; exit 2; }
	python3 scripts/register_kflow_task.py --repo-root . --config kflow.yaml --kflow-url '$(KFLOW_URL)'

kflow-register-chain:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow-register-chain.' >&2; exit 2; }
	@for repo in $(KFLOW_CHAIN_REPOS); do \
	  python3 scripts/register_kflow_task.py --repo-root "$$repo" --config "$$repo/kflow.yaml" --kflow-url '$(KFLOW_URL)'; \
	done
