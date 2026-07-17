# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com).

## [Unreleased] - DOS-6 (2026-07-17)

### Added
- (DOS-6) - Overhauled the entire RAG pipeline python layer (`libs.py`, `qdrant_watcher.py`, `qdrant_mcp.py`) to fully asynchronous execution topology using `asyncio` and `httpx`.
- (DOS-6) - Swapped out legacy synchronous `watchdog` file system auditor for high-performance, Rust-backed `watchfiles` runtime loop inside `qdrant_watcher.py`.
- (DOS-6) - Unified the embedding generation engine by implementing a dynamic factory method (`get_embedding`) inside `libs.py`, abstracting format schemas for both Ollama (`/api/embed`) and OpenAI/LM-Studio (`/v1/embeddings`) endpoints.
- (DOS-6) - Hardcoded idempotent global resource constraint checks into `infra_deploy.ps1` utilizing SHA256 file hashing to safely deploy strict memory (`16GB`) and CPU boundaries via `.wslconfig` prior to launching Docker networks.
- (DOS-6) - Refactored `models_deploy.ps1` into an adaptive IaC factory module with headless bootstrap integration for the advanced `llmster` background daemon and native multi-threaded `lms` CLI toolchain down to local machines.

### Modified
- (DOS-6) - Migrated the low-level `qdrant_mcp.py` transport layer from high-level `FastMCP` decorators to official `mcp.server` primitives to natively handle concurrent client requests without clogging the loop.
- (DOS-6) - Standardized the entire distribution repository file structure to a strict object-oriented `subject_action` naming convention (e.g., `asset_download.ps1`, `qdrant_watcher.py`).
- (DOS-6) - Locked down all foundational pip packages inside `pyparts_deploy.ps1` to explicit enterprise version definitions (`watchfiles==0.24.0`, `httpx==0.27.0`, `mcp==1.2.1`) preventing runtime configuration drift across mid-level developer rigs.

### Fixed
- (DOS-6) - Eliminated host WDDM TDR / Windows graphics subsystem crashes under prolonged multi-hour contexts by forcing hardware isolation rules (`CUDA_MANAGED_FORCE_DEVICE_ALLOC=1`) and allocation caps via host registry injection layers.
- (DOS-6) - Mitigated major memory leaks inside WSL2 by forcing `QDRANT__VECTORS__MEMMAP_THRESHOLD=0` in `docker-compose.yml`, shifting vector storage execution boundaries out of RAM down to raw NVMe disk mapping.
- (DOS-6) - Resolved a silent async execution failure inside `libs.py` by applying proper `await` keywords to Qdrant client storage mutations (`delete`, `upsert`), correcting core memory-mapped collection pipeline drops.

## - 2026-07-08

### Added
- (DOS-2) - Implemented a multi-zone RAG data architecture featuring strict context isolation between engineering and hobby knowledge bases.
- (DOS-2) - Created dual-watcher background daemon loops using independent `qdrant_watcher.py` instances to index separate host folders concurrently.
- (DOS-2) - Formulated isolated shortcode naming parameters to prevent context leakage across general LLM instances and targeted coding models.

### Fixed
- (DOS-2) - Resolved a critical HTTP 404 crash inside `qdrant_watcher.py` by mapping the target Ollama payload explicitly to the updated `/api/embed` endpoint.
- (DOS-2) - Fixed vector parsing exceptions by re-engineering the response interpreter to extract structured arrays from the modern `embeddings` JSON key.

## - 2026-07-07

### Added
- (DOS-1) - Integrated FastMCP python framework bindings inside WSL (`qdrant_mcp.py`) to expose real-time context injections to the Aider runtime agent via stdio transport channels.
- (DOS-1) - Added automated background persistence triggers for file-watchers by nesting execution commands inside the Windows Task Scheduler, bypassing local service permission blocks.
- (DOS-1) - Introduced automated model dependency evaluations using direct regex parsing maps against local YAML shortcode matrix configurations.

### Modified
- (DOS-1) - Overhauled the entire local deployment suite (`.ps1` / `.sh`), resolving hidden race conditions and lockups during network adapter port forwarding.
- (DOS-1) - Swapped out obsolete foundational model layers in Ollama and LiteLLM configurations for modern high-context MoE and Coder model architectures.
- (DOS-1) - Hardcoded LiteLLM gateway routines on the host to operate exclusively as a stealth Claude Sonnet API mimic layer for JetBrains IDE integrations.
