SHELL := /usr/bin/env bash

CONFIG_R ?= job-config.R
CONFIG_HELPERS_R ?= R/stepwise_config_helpers.R
RUN_CONFIG_MD ?= docs/run-configuration.md
RUN_CONFIG_SOURCES := $(CONFIG_R) $(CONFIG_HELPERS_R) R/update_readme.R kflow.yaml
cfg = $(shell Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_value("$(1)", "$(2)"))')
yml = $(shell Rscript -e 'y <- yaml::read_yaml("kflow.yaml"); v <- $(1); if (is.null(v) || length(v) == 0 || is.na(v[[1]])) v <- "$(2)"; if (is.logical(v)) v <- tolower(as.character(v)); cat(as.character(v[[1]]))')

STEP_SELECT ?= $(call cfg,default_step_select,all)
MFCL_LIVE_LOG ?= $(call yml,y$$env$$MFCL_LIVE_LOG,true)
BET_PHASE10_11_CONVERGENCE ?= $(call yml,y$$env$$BET_PHASE10_11_CONVERGENCE,-3)
OUTPUT_DIR ?= outputs
PROGRAM_PATH ?= $(call yml,y$$env$$PROGRAM_PATH,/home/mfcl/mfclo64)
DOCKER_IMAGE ?= $(call yml,y$$docker_image,ghcr.io/pacificcommunity/tuna-flow:v1.8)
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
EFFECTIVE_BET_PHASE10_11_CONVERGENCE ?= $(BET_PHASE10_11_CONVERGENCE)
JOB_DESCRIPTION ?= Run $(MODEL_LABEL) with PHASE 10/11 convergence $(EFFECTIVE_BET_PHASE10_11_CONVERGENCE).
JOB_KEY ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_job_key(Sys.getenv("STEP_SELECT")))')
MAJOR_STEP ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "major_step"))')
SUBSTEP ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "substep"))')
CHANGE_AXIS ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "change_axis"))')
TAG_FLAGS_IT2 ?=
RUN_MODE ?= $(call yml,y$$env$$RUN_MODE,$(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "run_mode"))'))
MFCLRTMB_OPTIMIZER ?= $(call yml,y$$env$$MFCLRTMB_OPTIMIZER,fmm)
MFCLRTMB_START_PHASE ?= $(call yml,y$$env$$MFCLRTMB_START_PHASE,)
MFCLRTMB_MAX_PHASE ?= $(call yml,y$$env$$MFCLRTMB_MAX_PHASE,)
MFCLRTMB_MAXFN ?= $(call yml,y$$env$$MFCLRTMB_MAXFN,)
MFCLRTMB_OPENMP_THREADS ?= $(call yml,y$$env$$MFCLRTMB_OPENMP_THREADS,1)
MFCLRTMB_OPENMP_AUTOPAR ?= $(call yml,y$$env$$MFCLRTMB_OPENMP_AUTOPAR,false)
MFCLRTMB_RUN_OPTIMIZATION ?= $(call yml,y$$env$$MFCLRTMB_RUN_OPTIMIZATION,true)
MFCLRTMB_RUN_POST_SWITCHES ?= $(call yml,y$$env$$MFCLRTMB_RUN_POST_SWITCHES,true)
MFCLRTMB_EXACT_REPORT ?= $(call yml,y$$env$$MFCLRTMB_EXACT_REPORT,true)
MFCLRTMB_PROCESS_PER_CONTROL ?= $(call yml,y$$env$$MFCLRTMB_PROCESS_PER_CONTROL,)
MFCLRTMB_PROCESS_LOG ?= $(call yml,y$$env$$MFCLRTMB_PROCESS_LOG,)
MFCLRTMB_PROCESS_TIME ?= $(call yml,y$$env$$MFCLRTMB_PROCESS_TIME,)
MFCLRTMB_LOW_MEMORY ?= $(call yml,y$$env$$MFCLRTMB_LOW_MEMORY,)
MFCLRTMB_VERBOSE_MEMORY ?= $(call yml,y$$env$$MFCLRTMB_VERBOSE_MEMORY,)
MFCLRTMB_VERBOSE_EVAL ?= $(call yml,y$$env$$MFCLRTMB_VERBOSE_EVAL,false)
MFCLRTMB_DOITALL_EVAL_TIMING ?= $(call yml,y$$env$$MFCLRTMB_DOITALL_EVAL_TIMING,true)
MFCLRTMB_WRITE_MFCL_FILES ?= $(call yml,y$$env$$MFCLRTMB_WRITE_MFCL_FILES,true)
MFCLRTMB_TAG_FULL_ATOMIC_BUILD ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_ATOMIC_BUILD,)
MFCLRTMB_TAG_FULL_MANUAL_ADJOINT_OPENMP ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_MANUAL_ADJOINT_OPENMP,)
MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS,)
MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD,)
MFCLRTMB_TAG_FULL_PACKED_MORTALITY ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_PACKED_MORTALITY,)
MFCLRTMB_TAG_FULL_REVERSE_CACHE ?= $(call yml,y$$env$$MFCLRTMB_TAG_FULL_REVERSE_CACHE,)
MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK,)
MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_FACTOR ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_FACTOR,)
MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_MAX ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_MAX,)
MFCLRTMB_NLMINB_PLATEAU_STEP_MIN ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_PLATEAU_STEP_MIN,)
MFCLRTMB_NLMINB_PLATEAU_EVAL_CHUNK ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_PLATEAU_EVAL_CHUNK,)
MFCLRTMB_NLMINB_CONTINUE_EVAL_CHUNK ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_CONTINUE_EVAL_CHUNK,)
MFCLRTMB_NLMINB_STAGNATION_FMM_POLISH ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_STAGNATION_FMM_POLISH,)
MFCLRTMB_NLMINB_SAME_MGC_FMM_MAXFN ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_SAME_MGC_FMM_MAXFN,)
MFCLRTMB_NLMINB_SAME_MGC_FMM_MAX_ESCAPES ?= $(call yml,y$$env$$MFCLRTMB_NLMINB_SAME_MGC_FMM_MAX_ESCAPES,)
STEPWISE_BUILD_PAYLOAD ?= $(call yml,y$$env$$STEPWISE_BUILD_PAYLOAD,true)
INPUT_PAR ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "input_par"))')
FRQ ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "frq"))')
OUTPUT_PAR ?= $(shell STEP_SELECT='$(STEP_SELECT)' Rscript -e 'source("$(CONFIG_HELPERS_R)"); source_stepwise_config("$(CONFIG_R)"); cat(stepwise_row_value(Sys.getenv("STEP_SELECT"), "output_par"))')

KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES,true)
KFLOW_RUNTIME_UPDATE ?= $(call yml,y$$env$$KFLOW_RUNTIME_UPDATE,never)
TUNA_FLOW_RUNTIME_UPDATE ?= $(call yml,y$$env$$TUNA_FLOW_RUNTIME_UPDATE,never)
KFLOW_REPO_RUNTIME_UPDATE ?= $(call yml,y$$env$$KFLOW_REPO_RUNTIME_UPDATE,auto)
KFLOW_RUNTIME_PACKAGES ?= $(call yml,y$$env$$KFLOW_RUNTIME_PACKAGES,none)
KFLOW_REPO_RUNTIME_PACKAGES ?= $(call yml,y$$env$$KFLOW_REPO_RUNTIME_PACKAGES,mfclshiny=PacificCommunity/mfclshiny@main)
MFCLSHINY_GITHUB_REF ?= $(call yml,y$$env$$MFCLSHINY_GITHUB_REF,main)
KFLOW_RUNTIME_GITHUB_AUTH ?= $(call yml,y$$env$$KFLOW_RUNTIME_GITHUB_AUTH,true)
KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME ?= $(call yml,y$$env$$KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME,true)
STEPWISE_SAVE_FINAL_PAR ?= $(call yml,y$$env$$STEPWISE_SAVE_FINAL_PAR,false)
STEPWISE_COMMIT_FINAL_PARS ?= $(call yml,y$$env$$STEPWISE_COMMIT_FINAL_PARS,false)
STEPWISE_PUSH_FINAL_PARS ?= $(call yml,y$$env$$STEPWISE_PUSH_FINAL_PARS,false)
STEPWISE_PUBLISH_REQUIRED ?= $(call yml,y$$env$$STEPWISE_PUBLISH_REQUIRED,false)
PAR_SOURCE_JOB ?= $(call yml,y$$env$$PAR_SOURCE_JOB,)
STEPWISE_PAR_SOURCE_DIR ?= $(call yml,y$$env$$STEPWISE_PAR_SOURCE_DIR,)
KFLOW_INPUT_JOBS ?= $(call yml,y$$env$$KFLOW_INPUT_JOBS,)
STEPWISE_BASE_INPUT_JOB ?= $(call yml,y$$env$$STEPWISE_BASE_INPUT_JOB,)
STEPWISE_CHECK_INPUT_JOBS ?= $(call yml,y$$env$$STEPWISE_CHECK_INPUT_JOBS,)
ATTACH_CHECK_TYPES ?= $(call yml,y$$env$$ATTACH_CHECK_TYPES,)

.PHONY: help setup hooks readme list clean fix-permissions local docker kflow kflow-register kflow-register-chain

help:
	@printf '%s\n' \
	  'BET 2026 stepwise shortcuts' \
	  '' \
	  'Models live in job-config.R; Kflow/runtime defaults live in kflow.yaml.' \
	  '' \
	  'make list' \
	  '  Refresh docs/run-configuration.md, enable the commit hook, then show configured model rows from job-config.R.' \
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
	  'After a successful run, final .par files are archived under outputs/models/<step>/final.par.' \
	  'Use RUN_MODE=job_par with PAR_SOURCE_JOB and KFLOW_INPUT_JOBS set to the previous same-step job number.' \
	  '' \
	  'Common overrides: STEP_SELECT, RUN_MODE, INPUT_PAR, MFCL_LIVE_LOG, TRIGGER_NEXT, OUTPUT_DIR.' \
	  'Use RUN_MODE=mfclrtmb_doitall to test the same model folders with mfclrtmb.'

setup: hooks

hooks:
	@if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	  current="$$(git config --get core.hooksPath 2>/dev/null || true)"; \
	  if [[ "$$current" != ".githooks" ]]; then \
	    git config core.hooksPath .githooks; \
	  fi; \
	fi

$(RUN_CONFIG_MD): $(RUN_CONFIG_SOURCES)
	@CONFIG_R='$(CONFIG_R)' README_MD='$(RUN_CONFIG_MD)' Rscript R/update_readme.R

readme: hooks
	@CONFIG_R='$(CONFIG_R)' README_MD='$(RUN_CONFIG_MD)' Rscript R/update_readme.R

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
	RUN_MODE='$(RUN_MODE)' \
	INPUT_PAR='$(INPUT_PAR)' \
	FRQ='$(FRQ)' \
	OUTPUT_PAR='$(OUTPUT_PAR)' \
	MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' \
	OUTPUT_DIR='$(OUTPUT_DIR)' \
	PROGRAM_PATH='$(PROGRAM_PATH)' \
	KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	TUNA_FLOW_RUNTIME_UPDATE='$(TUNA_FLOW_RUNTIME_UPDATE)' \
	KFLOW_REPO_RUNTIME_UPDATE='$(KFLOW_REPO_RUNTIME_UPDATE)' \
	KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	KFLOW_REPO_RUNTIME_PACKAGES='$(KFLOW_REPO_RUNTIME_PACKAGES)' \
	MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' \
	KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	STEPWISE_SAVE_FINAL_PAR='$(STEPWISE_SAVE_FINAL_PAR)' \
	STEPWISE_COMMIT_FINAL_PARS='$(STEPWISE_COMMIT_FINAL_PARS)' \
	STEPWISE_PUSH_FINAL_PARS='$(STEPWISE_PUSH_FINAL_PARS)' \
	STEPWISE_PUBLISH_REQUIRED='$(STEPWISE_PUBLISH_REQUIRED)' \
	PAR_SOURCE_JOB='$(PAR_SOURCE_JOB)' \
	STEPWISE_PAR_SOURCE_DIR='$(STEPWISE_PAR_SOURCE_DIR)' \
	KFLOW_INPUT_JOBS='$(KFLOW_INPUT_JOBS)' \
	STEPWISE_BASE_INPUT_JOB='$(STEPWISE_BASE_INPUT_JOB)' \
	STEPWISE_CHECK_INPUT_JOBS='$(STEPWISE_CHECK_INPUT_JOBS)' \
	ATTACH_CHECK_TYPES='$(ATTACH_CHECK_TYPES)' \
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
	  -e RUN_MODE='$(RUN_MODE)' \
	  -e INPUT_PAR='$(INPUT_PAR)' \
	  -e FRQ='$(FRQ)' \
	  -e OUTPUT_PAR='$(OUTPUT_PAR)' \
	  -e MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' \
	  -e BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' \
	  -e OUTPUT_DIR='$(OUTPUT_DIR)' \
	  -e PROGRAM_PATH='$(PROGRAM_PATH)' \
	  -e KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' \
	  -e KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' \
	  -e TUNA_FLOW_RUNTIME_UPDATE='$(TUNA_FLOW_RUNTIME_UPDATE)' \
	  -e KFLOW_REPO_RUNTIME_UPDATE='$(KFLOW_REPO_RUNTIME_UPDATE)' \
	  -e KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' \
	  -e KFLOW_REPO_RUNTIME_PACKAGES='$(KFLOW_REPO_RUNTIME_PACKAGES)' \
	  -e MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' \
	  -e KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' \
	  -e KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' \
	  -e STEPWISE_SAVE_FINAL_PAR='$(STEPWISE_SAVE_FINAL_PAR)' \
	  -e STEPWISE_COMMIT_FINAL_PARS='$(STEPWISE_COMMIT_FINAL_PARS)' \
	  -e STEPWISE_PUSH_FINAL_PARS='$(STEPWISE_PUSH_FINAL_PARS)' \
	  -e STEPWISE_PUBLISH_REQUIRED='$(STEPWISE_PUBLISH_REQUIRED)' \
	  -e PAR_SOURCE_JOB='$(PAR_SOURCE_JOB)' \
	  -e STEPWISE_PAR_SOURCE_DIR='$(STEPWISE_PAR_SOURCE_DIR)' \
	  -e KFLOW_INPUT_JOBS='$(KFLOW_INPUT_JOBS)' \
	  -e STEPWISE_BASE_INPUT_JOB='$(STEPWISE_BASE_INPUT_JOB)' \
	  -e STEPWISE_CHECK_INPUT_JOBS='$(STEPWISE_CHECK_INPUT_JOBS)' \
	  -e ATTACH_CHECK_TYPES='$(ATTACH_CHECK_TYPES)' \
	  -e GITHUB_PAT="$$token" \
	  -e GH_TOKEN="$$token" \
	  '$(DOCKER_IMAGE)' \
	  bash run.sh

kflow: readme
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow.' >&2; exit 2; }
		@STEP_SELECT='$(STEP_SELECT)' MFCL_LIVE_LOG='$(MFCL_LIVE_LOG)' BET_PHASE10_11_CONVERGENCE='$(BET_PHASE10_11_CONVERGENCE)' BET_TAG_IT2_SWITCH_PHASE='$(BET_TAG_IT2_SWITCH_PHASE)' EFFECTIVE_BET_PHASE10_11_CONVERGENCE='$(EFFECTIVE_BET_PHASE10_11_CONVERGENCE)' FLOW_GROUP='$(FLOW_GROUP)' JOB_TITLE='$(JOB_TITLE)' JOB_DESCRIPTION='$(JOB_DESCRIPTION)' MODEL_LABEL='$(MODEL_LABEL)' JOB_KEY='$(JOB_KEY)' MAJOR_STEP='$(MAJOR_STEP)' SUBSTEP='$(SUBSTEP)' CHANGE_AXIS='$(CHANGE_AXIS)' TAG_FLAGS_IT2='$(TAG_FLAGS_IT2)' RUN_MODE='$(RUN_MODE)' MFCLRTMB_OPTIMIZER='$(MFCLRTMB_OPTIMIZER)' MFCLRTMB_START_PHASE='$(MFCLRTMB_START_PHASE)' MFCLRTMB_MAX_PHASE='$(MFCLRTMB_MAX_PHASE)' MFCLRTMB_MAXFN='$(MFCLRTMB_MAXFN)' MFCLRTMB_OPENMP_THREADS='$(MFCLRTMB_OPENMP_THREADS)' MFCLRTMB_OPENMP_AUTOPAR='$(MFCLRTMB_OPENMP_AUTOPAR)' MFCLRTMB_RUN_OPTIMIZATION='$(MFCLRTMB_RUN_OPTIMIZATION)' MFCLRTMB_RUN_POST_SWITCHES='$(MFCLRTMB_RUN_POST_SWITCHES)' MFCLRTMB_EXACT_REPORT='$(MFCLRTMB_EXACT_REPORT)' MFCLRTMB_PROCESS_PER_CONTROL='$(MFCLRTMB_PROCESS_PER_CONTROL)' MFCLRTMB_PROCESS_LOG='$(MFCLRTMB_PROCESS_LOG)' MFCLRTMB_PROCESS_TIME='$(MFCLRTMB_PROCESS_TIME)' MFCLRTMB_LOW_MEMORY='$(MFCLRTMB_LOW_MEMORY)' MFCLRTMB_VERBOSE_MEMORY='$(MFCLRTMB_VERBOSE_MEMORY)' MFCLRTMB_VERBOSE_EVAL='$(MFCLRTMB_VERBOSE_EVAL)' MFCLRTMB_DOITALL_EVAL_TIMING='$(MFCLRTMB_DOITALL_EVAL_TIMING)' MFCLRTMB_WRITE_MFCL_FILES='$(MFCLRTMB_WRITE_MFCL_FILES)' MFCLRTMB_TAG_FULL_ATOMIC_BUILD='$(MFCLRTMB_TAG_FULL_ATOMIC_BUILD)' MFCLRTMB_TAG_FULL_MANUAL_ADJOINT_OPENMP='$(MFCLRTMB_TAG_FULL_MANUAL_ADJOINT_OPENMP)' MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS='$(MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS)' MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD='$(MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD)' MFCLRTMB_TAG_FULL_PACKED_MORTALITY='$(MFCLRTMB_TAG_FULL_PACKED_MORTALITY)' MFCLRTMB_TAG_FULL_REVERSE_CACHE='$(MFCLRTMB_TAG_FULL_REVERSE_CACHE)' MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK='$(MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK)' MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_FACTOR='$(MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_FACTOR)' MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_MAX='$(MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_MAX)' MFCLRTMB_NLMINB_PLATEAU_STEP_MIN='$(MFCLRTMB_NLMINB_PLATEAU_STEP_MIN)' MFCLRTMB_NLMINB_PLATEAU_EVAL_CHUNK='$(MFCLRTMB_NLMINB_PLATEAU_EVAL_CHUNK)' MFCLRTMB_NLMINB_CONTINUE_EVAL_CHUNK='$(MFCLRTMB_NLMINB_CONTINUE_EVAL_CHUNK)' MFCLRTMB_NLMINB_STAGNATION_FMM_POLISH='$(MFCLRTMB_NLMINB_STAGNATION_FMM_POLISH)' MFCLRTMB_NLMINB_SAME_MGC_FMM_MAXFN='$(MFCLRTMB_NLMINB_SAME_MGC_FMM_MAXFN)' MFCLRTMB_NLMINB_SAME_MGC_FMM_MAX_ESCAPES='$(MFCLRTMB_NLMINB_SAME_MGC_FMM_MAX_ESCAPES)' STEPWISE_BUILD_PAYLOAD='$(STEPWISE_BUILD_PAYLOAD)' INPUT_PAR='$(INPUT_PAR)' PAR_SOURCE_JOB='$(PAR_SOURCE_JOB)' STEPWISE_PAR_SOURCE_DIR='$(STEPWISE_PAR_SOURCE_DIR)' KFLOW_INPUT_JOBS='$(KFLOW_INPUT_JOBS)' STEPWISE_BASE_INPUT_JOB='$(STEPWISE_BASE_INPUT_JOB)' STEPWISE_CHECK_INPUT_JOBS='$(STEPWISE_CHECK_INPUT_JOBS)' ATTACH_CHECK_TYPES='$(ATTACH_CHECK_TYPES)' FRQ='$(FRQ)' OUTPUT_PAR='$(OUTPUT_PAR)' TRIGGER_NEXT='$(TRIGGER_NEXT)' STEPWISE_SAVE_FINAL_PAR='$(STEPWISE_SAVE_FINAL_PAR)' STEPWISE_COMMIT_FINAL_PARS='$(STEPWISE_COMMIT_FINAL_PARS)' STEPWISE_PUSH_FINAL_PARS='$(STEPWISE_PUSH_FINAL_PARS)' STEPWISE_PUBLISH_REQUIRED='$(STEPWISE_PUBLISH_REQUIRED)' KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES='$(KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES)' KFLOW_RUNTIME_UPDATE='$(KFLOW_RUNTIME_UPDATE)' TUNA_FLOW_RUNTIME_UPDATE='$(TUNA_FLOW_RUNTIME_UPDATE)' KFLOW_REPO_RUNTIME_UPDATE='$(KFLOW_REPO_RUNTIME_UPDATE)' KFLOW_RUNTIME_PACKAGES='$(KFLOW_RUNTIME_PACKAGES)' KFLOW_REPO_RUNTIME_PACKAGES='$(KFLOW_REPO_RUNTIME_PACKAGES)' MFCLSHINY_GITHUB_REF='$(MFCLSHINY_GITHUB_REF)' KFLOW_RUNTIME_GITHUB_AUTH='$(KFLOW_RUNTIME_GITHUB_AUTH)' KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME='$(KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME)' python3 -c 'import json, os, re; keys=("STEP_SELECT","MFCL_LIVE_LOG","BET_PHASE10_11_CONVERGENCE","BET_TAG_IT2_SWITCH_PHASE","EFFECTIVE_BET_PHASE10_11_CONVERGENCE","FLOW_GROUP","JOB_TITLE","JOB_DESCRIPTION","MODEL_LABEL","JOB_KEY","MAJOR_STEP","SUBSTEP","CHANGE_AXIS","TAG_FLAGS_IT2","RUN_MODE","MFCLRTMB_OPTIMIZER","MFCLRTMB_START_PHASE","MFCLRTMB_MAX_PHASE","MFCLRTMB_MAXFN","MFCLRTMB_OPENMP_THREADS","MFCLRTMB_OPENMP_AUTOPAR","MFCLRTMB_RUN_OPTIMIZATION","MFCLRTMB_RUN_POST_SWITCHES","MFCLRTMB_EXACT_REPORT","MFCLRTMB_PROCESS_PER_CONTROL","MFCLRTMB_PROCESS_LOG","MFCLRTMB_PROCESS_TIME","MFCLRTMB_LOW_MEMORY","MFCLRTMB_VERBOSE_MEMORY","MFCLRTMB_VERBOSE_EVAL","MFCLRTMB_DOITALL_EVAL_TIMING","MFCLRTMB_WRITE_MFCL_FILES","MFCLRTMB_TAG_FULL_ATOMIC_BUILD","MFCLRTMB_TAG_FULL_MANUAL_ADJOINT_OPENMP","MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS","MFCLRTMB_TAG_FULL_MANUAL_SPLIT_CHUNKS_PER_THREAD","MFCLRTMB_TAG_FULL_PACKED_MORTALITY","MFCLRTMB_TAG_FULL_REVERSE_CACHE","MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK","MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_FACTOR","MFCLRTMB_NLMINB_PLATEAU_STEP_SHRINK_MAX","MFCLRTMB_NLMINB_PLATEAU_STEP_MIN","MFCLRTMB_NLMINB_PLATEAU_EVAL_CHUNK","MFCLRTMB_NLMINB_CONTINUE_EVAL_CHUNK","MFCLRTMB_NLMINB_STAGNATION_FMM_POLISH","MFCLRTMB_NLMINB_SAME_MGC_FMM_MAXFN","MFCLRTMB_NLMINB_SAME_MGC_FMM_MAX_ESCAPES","STEPWISE_BUILD_PAYLOAD","INPUT_PAR","PAR_SOURCE_JOB","STEPWISE_PAR_SOURCE_DIR","KFLOW_INPUT_JOBS","STEPWISE_BASE_INPUT_JOB","STEPWISE_CHECK_INPUT_JOBS","ATTACH_CHECK_TYPES","FRQ","OUTPUT_PAR","STEPWISE_SAVE_FINAL_PAR","STEPWISE_COMMIT_FINAL_PARS","STEPWISE_PUSH_FINAL_PARS","STEPWISE_PUBLISH_REQUIRED","KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES","KFLOW_RUNTIME_UPDATE","TUNA_FLOW_RUNTIME_UPDATE","KFLOW_REPO_RUNTIME_UPDATE","KFLOW_RUNTIME_PACKAGES","KFLOW_REPO_RUNTIME_PACKAGES","MFCLSHINY_GITHUB_REF","KFLOW_RUNTIME_GITHUB_AUTH","KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME"); env={k:os.environ[k] for k in keys if os.environ.get(k,"")}; requested=os.environ["BET_PHASE10_11_CONVERGENCE"]; effective=os.environ["EFFECTIVE_BET_PHASE10_11_CONVERGENCE"]; switch_phase=os.environ.get("BET_TAG_IT2_SWITCH_PHASE",""); payload={"env":env,"metadata":{"job_description":os.environ.get("JOB_DESCRIPTION",""),"major_step":os.environ.get("MAJOR_STEP",""),"substep":os.environ.get("SUBSTEP",""),"change_axis":os.environ.get("CHANGE_AXIS",""),"tag_flags_it2":os.environ.get("TAG_FLAGS_IT2",""),"tag_it2_switch_phase":switch_phase,"requested_phase10_11_convergence":requested,"phase10_11_convergence":effective},"tags":{"stage":"stepwise","flow":os.environ["FLOW_GROUP"],"step":os.environ["STEP_SELECT"],"major_step":os.environ.get("MAJOR_STEP",""),"substep":os.environ.get("SUBSTEP",""),"change_axis":os.environ.get("CHANGE_AXIS",""),"tag_flags_it2":os.environ.get("TAG_FLAGS_IT2",""),"tag_it2_switch_phase":switch_phase,"model_label":os.environ["MODEL_LABEL"],"job_key":os.environ["JOB_KEY"],"run_mode":os.environ["RUN_MODE"],"trigger_next":os.environ["TRIGGER_NEXT"],"requested_mgc":requested,"mgc":effective,"phase10_11_convergence":effective}}; payload["metadata"]={k:v for k,v in payload["metadata"].items() if v not in ("", None)}; payload["tags"]={k:v for k,v in payload["tags"].items() if v not in ("", None)}; raw=os.environ.get("KFLOW_INPUT_JOBS","").strip(); vals=[v.lstrip("#") for v in re.split(r"[\\s,]+", raw) if v.strip()] if raw.lower() not in ("","0","false","no","off","none","skip") else []; payload.update({"input_jobs":vals}) if vals else None; payload["metadata"].update({"input_jobs_override":True}) if vals else None; flag=os.environ["TRIGGER_NEXT"].strip().lower(); payload.update({"triggers": {}} if flag in ("0","false","no","off","none","skip") else {}); print(json.dumps(payload))' | curl -sS -H "Authorization: Bearer $${KFLOW_API_TOKEN}" -H 'Content-Type: application/json' -X POST "$(KFLOW_URL)/api/job/$(KFLOW_TASK)" -d @-
	@printf '\n'

kflow-register:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow-register.' >&2; exit 2; }
	python3 scripts/register_kflow_task.py --repo-root . --config kflow.yaml --kflow-url '$(KFLOW_URL)'

kflow-register-chain:
	@test -n "$${KFLOW_API_TOKEN:-}" || { echo 'Set KFLOW_API_TOKEN before running make kflow-register-chain.' >&2; exit 2; }
	@for repo in $(KFLOW_CHAIN_REPOS); do \
	  python3 scripts/register_kflow_task.py --repo-root "$$repo" --config "$$repo/kflow.yaml" --kflow-url '$(KFLOW_URL)'; \
	done
