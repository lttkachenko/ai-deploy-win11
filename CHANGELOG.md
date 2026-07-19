# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com).

## [Unreleased] - DOS-7 (2026-07-19)

### Added
- (DOS-7) - Integrated `llama-swap` Go-backed proxy gateway on the host to manage the lazy execution loop lifecycle of native C++ `llama-server` instances.
- (DOS-7) - Implemented strict 6GB VRAM allocation caps and sequential request throttling (`concurrency: 1`) via a centralized `config.yml` layout.
- (DOS-7) - Replicated LiteLLM prompt template anchors by natively injecting the multi-layer spec prompt (`[MARKER HYDRATE]` and `IDENTITY HYDRATION` policy) into `llama-server` via the `--system-prompt-file` argument.
- (DOS-7) - Migrated the containerized FastMCP server (`qdrant_mcp.py`) directly to the host network boundary as a persistent background Windows service using the `NSSM` wrapper.
- (DOS-7) - Swapped out stdout transport protocols inside the FastMCP server for a unified network-accessible `SSE HTTP` web server structure listening on port 8000.

### Modified
- (DOS-7) - Deprecated and completely purged the entire `LiteLLM` proxy layer, `Ollama` daemon dependencies, and `NSSM` Windows services configuration scripts on the host.
- (DOS-7) - Refactored `models_deploy.ps1` into a strict data-delivery module, stripping out execution code to cleanly pull `IQ4_NL` / `Q4_K_M` GGUF weights directly from Hugging Face into `%USERPROFILE%/.ai/models`.
- (DOS-7) - Redefined `Aider\config.yml` parameters to execute direct native OpenAI-compatible calls on port 1234 using the `openai/claude-sonnet-4-6` identifier.
- (DOS-7) - Optimized `aider_run.sh` to pass a single isolated target token trigger `[MARKER HYDRATE] $ROLE` to offload the entire persona parsing stream down to the Qdrant RAG index.
- (DOS-7) - Re-engineered `network_setup.ps1` to handle severe Hyper-V zero-address binding bugs by mapping precise cross-boundary `netsh interface portproxy` tunnels from the WSL vEthernet gateway IP to `1234`, `8000`, and `6333` ports on loopback.

### Fixed
- (DOS-7) - Secured the `qdrant_watcher.py` file mapping logic by forcing index arrays to index `[0]` inside `os.path.splitext`, preventing runtime task drops on dot-nested file tags.
- (DOS-7) - Eliminated duplicate vector node allocations inside `libs.py` by removing the unstable `time.time()` string slice from the `point_id` hash algorithm.
- (DOS-7) - Resolved critical Python async consistency block errors by wrapping the heavy synchronous `.encode()` method inside `asyncio.to_thread()`, moving CPU tensor generation entirely off the main event loop thread.
- (DOS-7) - Fixed I/O blocking blocks inside `libs.py` by wrapping standard synchronous `open()` and recursive transclusion file reads inside an isolated `asyncio.to_thread()` pipeline.
- (DOS-7) - Corrected Sonar / Linter security hotspot flags inside `qdrant_deploy.ps1` by expanding the truncated health-check address to a valid production `http://127.0.0` URI.

## - DOS-6 (2026-07-17)

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
