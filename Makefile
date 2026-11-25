# Run `make` or `make help` to list targets.

.DEFAULT_GOAL := help

VIDEOS_DIR      := videos
MEDIAMTX_CONFIG := infrastructure/mediamtx/mediamtx.yml
RTSP_BASE       := rtsp://localhost:8554

.PHONY: help check-tools

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s %s\n", $$1, $$2}'

check-tools: ## Check required tools are installed and print versions
	@scripts/check-tools.sh

.PHONY: sample-videos
sample-videos: ## Generate small H.264 test clips into videos/
	@scripts/make-sample-videos.sh $(VIDEOS_DIR)

.PHONY: mediamtx
mediamtx: ## Run MediaMTX in the foreground with the repo config
	mediamtx $(MEDIAMTX_CONFIG)

.PHONY: smoke
smoke: ## Publish two clips to MediaMTX, verify both, clean up
	@scripts/smoke-publish.sh $(VIDEOS_DIR) $(RTSP_BASE)
