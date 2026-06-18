SHELL := /usr/bin/env bash

STEP_SELECT ?= 01-base-11par
MFCL_FEVALS ?= 1
MFCL_LIVE_LOG ?= true
OUTPUT_DIR ?= outputs
PROGRAM_PATH ?= /home/mfcl/mfclo64
DOCKER_IMAGE ?= ghcr.io/pacificcommunity/tuna-flow:v1.5

KFLOW_URL ?= http://127.0.0.1:8089
KFLOW_TASK ?= ofp-sam-bet-2026-stepwise
FLOW_GROUP ?= bet-2026-e2e
JOB_TITLE ?= BET stepwise $(STEP_SELECT)

.PHONY: help list clean local docker kflow

help:
	@printf '%s\n' \
	  'BET 2026 stepwise shortcuts' \
	  '' \
	  'make list' \
	  '  Show configured model rows from stepwise-config.R.' \
	  '' \
	  'make local STEP_SELECT=01-base-11par PROGRAM_PATH=/path/to/mfclo64' \
	  '  Run directly on this machine.' \
	  '' \
	  'make docker STEP_SELECT=01-base-11par' \
	  '  Run locally inside the tuna-flow Docker image.' \
	  '' \
	  'make kflow STEP_SELECT=01-base-11par KFLOW_API_TOKEN=...' \
	  '  Submit the selected model folder to Kflow.' \
	  '' \
	  'Common overrides: STEP_SELECT, MFCL_FEVALS, MFCL_LIVE_LOG, OUTPUT_DIR.'

list:
	@Rscript -e "source('stepwise-config.R'); print(stepwise_models, row.names = FALSE)"

clean:
	rm -rf outputs work .R-library .kflow-runtime-cache

local:
	STEP_SELECT='$(STEP_SELECT)' \
	MFCL_FEVALS='$(MFCL_FEVALS)' \
	MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	OUTPUT_DIR='$(OUTPUT_DIR)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	bash run.sh

docker:
	docker run --rm \
	  -v "$$(pwd):/work" \
	  -w /work \
	  -e STEP_SELECT='$(STEP_SELECT)' \
	  -e MFCL_FEVALS='$(MFCL_FEVALS)' \
	  -e MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	  -e OUTPUT_DIR='$(OUTPUT_DIR)' \
	  -e PROGRAM_PATH='$(PROGRAM_PATH)' \
	  -e KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='true' \
	  -e KFLOW_RUNTIME_UPDATE='auto' \
	  -e KFLOW_RUNTIME_PACKAGES='mfclshiny=PacificCommunity/mfclshiny@main' \
	  -e KFLOW_RUNTIME_GITHUB_AUTH='true' \
	  -e KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='true' \
	  -e GITHUB_PAT="$${GITHUB_PAT:-$${GH_TOKEN:-}}" \
	  -e GH_TOKEN="$${GH_TOKEN:-$${GITHUB_PAT:-}}" \
	  $(DOCKER_IMAGE) \
	  bash run.sh

kflow:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow.' >&2; exit 2; }
	@STEP_SELECT='$(STEP_SELECT)' MFCL_FEVALS='$(MFCL_FEVALS)' MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' FLOW_GROUP='$(FLOW_GROUP)' JOB_TITLE='$(JOB_TITLE)' python3 -c 'import json, os; print(json.dumps({"env":{"STEP_SELECT":os.environ["STEP_SELECT"],"MFCL_FEVALS":os.environ["MFCL_FEVALS"],"MFCL_LIVE_LOG":os.environ["MFCL_LIVE_LOG"],"FLOW_GROUP":os.environ["FLOW_GROUP"],"JOB_TITLE":os.environ["JOB_TITLE"],"KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES":"true","KFLOW_RUNTIME_UPDATE":"auto","KFLOW_RUNTIME_PACKAGES":"mfclshiny=PacificCommunity/mfclshiny@main","KFLOW_RUNTIME_GITHUB_AUTH":"true","KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME":"true"},"tags":{"stage":"stepwise","flow":os.environ["FLOW_GROUP"],"step":os.environ["STEP_SELECT"]}}))' | curl -sS -H "Authorization: Bearer $${KFLOW_API_TOKEN}" -H 'Content-Type: application/json' -X POST "$(KFLOW_URL)/api/job/$(KFLOW_TASK)" -d @-
	@printf '\n'
