# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com).

## [Development Snapshot] - DOS-9 (2026-07-21)

### Added
- (DOS-9) - Established a pristine, decoupled host directory architecture under `~/.ai/`, completely isolating the core Python `.venv/` and its automation payload (`.venv/mcp/`) from containerized storage zones.
- (DOS-9) - Introduced automated, multi-layered parameter extraction inside `qdrant_deploy.ps1` to natively parse API keys, task names, and local storage coordinates directly from the unified `~/.ai/conf/mcp.conf.yml` manifest.
- (DOS-9) - Integrated a high-performance, idempotent caching layer in `Utils\asset_downloader.ps1` that completely bypasses heavy payload streaming routines with an instant exit warning (`Model asset already in place!`) if valid target GGUF layers are identified on disk.
- (DOS-9) - Enforced a strict LM Studio temporary transaction file allocation pattern (`download-<FILE_NAME>`) to protect the raw NVMe network stream array from target destination filesystem corruption upon sudden connection drops or socket timeouts.

### Modified
- (DOS-9) - Refactored `models_deploy.ps1` to migrate from complex string fragmentation methodologies (`.Split()`) to a centralized, declarative **Direct String Mapping** topology utilizing rigid YAML `model_url` and `mmproj_url` keys.
- (DOS-9) - Deprecated the memory-heavy, host-intrusive local bind mount structure (`type: bind`) for containerized vector engines, offloading all storage layouts exclusively to decoupled, native Docker Named Volumes (`volumes: qdrant_storage`).
- (DOS-9) - Shifted the `qdrant-mcp-service` Windows background daemon execution context from explicit user accounts to the unprivileged `LocalSystem` engine, completely eliminating the need for dynamic `ObjectName` binding and active Win32 `SeServiceLogonRight` security policy modifications.
- (DOS-9) - Segmented the persistent FastMCP logging telemetry rooms by forcing NSSM to route the host daemon execution lifecycle into distinct, isolated tracking streams (`<srv_name>.stdout.log` and `<srv_name>.stderr.log`).

### Fixed
- (DOS-9) - Eliminated a catastrophic directory shifting bug inside `pyparts_deploy.ps1` by forcing rigorous .NET path normalization (`[System.IO.Path]::GetFullPath`) to prevent relative syntax dots (`.\`) from leaking the active venv environment outside user profile bounds.
- (DOS-9) - Resolved a severe pipeline drop inside `network_setup.ps1` on Windows 11 environments by introducing a pre-flight WSL instance cold boot command (`wsl.exe -e true`) to forcefully bring up host vEthernet adapters before interface query operations take place.
- (DOS-9) - Purged an index displacement error in `models_deploy.ps1` caused by unstripped leading slashes on truncated URL strings, restoring symbol-for-symbol layout mapping functionality across case-immutable Hugging Face repositories.
- (DOS-9) - Cleared an implicit, recursive self-invocation infinite loop freeze in `models_deploy.ps1` caused by modular path resolution collisions mapping the universal downloader handle directly onto the calling script coordinate.
- (DOS-9) - Corrected an invalid command argument trap inside `qdrant_deploy.ps1` by aligning fallback retry variables with native, official NSSM service execution definitions (`AppThrottle` instead of `Throttle`).
- (DOS-9) - Eradicated a critical 401 Unauthorized cluster handshake collision by injecting mandatory `api-key` validation token header specs straight into the active PowerShell web request routine loops targeting `localhost:6333/readyz`.
- (DOS-9) - Mitigated a crippling local ISP routing filter crash by implementing absolute DNS cache flushing (`ipconfig /flushdns`) and a network cooldown period inside the raw GGUF streaming block prior to hitting remote CDN targets.

### Known Issues
- **Micro-Scalar YAML Block Conflicts**: Initializing unquoted literal variable definitions that utilize curly braces (`{...}`) directly inside the value block scope triggers immediate YAML mapping failures. The parser interprets the string as a nested JSON inline object declaration, requiring absolute string wrap enforcement via explicit double quotes (`"..."`) or conversion to standard Go/Llama-Swap macro definitions (`${...}`).
- **Address Space Network Socket Collisions**: Utilizing hyper-standard runtime connection sockets (such as binding `llama-server` to port `8080` or FastMCP to port `8000`) triggers address collision crashes (`Address already in use`) on dense developer setups with concurrent Webpack or FastAPI processes. All environment network configurations must be audited and relocated to isolated, non-standard high-range port spaces (e.g., `18080`, `18000`) before final pre-release optimization runs.

---

## [Development Snapshot] - DOS-8 (2026-07-20)

### Added
- (DOS-8) - Introduced a strict, recursive macro interpolation engine in `models_deploy.ps1` to expand nested environment tokens (e.g., `%USERPROFILE%`, `${models}`) into verified, absolute Win32 path targets.
- (DOS-8) - Standardized the model ingestion workflow to automatically map Hugging Face direct web streams into a structured nested layout matching LM Studio directory topology (`models/author/repo/file.gguf`).
- (DOS-8) - Implemented deep variable parsing to handle polymorphic `source`, `hf_name`, and `quant` keys anywhere inside the YAML configuration sub-scopes without relying on brittle indentation-based line processing.

### Modified
- (DOS-8) - Deprecated the unstable, interactive `lms get` CLI command sequence due to unbypassable TTY Win32 Console ReadKey locks and pseudo-graphic prompt blocks.
- (DOS-8) - Unified all network downloading processes by offloading heavy GGUF and mmproj weight ingestion routines directly to the centralized, multi-threaded `Utils\asset_downloader.ps1` script core.
- (DOS-8) - Forced the model download pipeline to retain strict, immutable case sensitivity across author names, repositories, and filenames to satisfy Hugging Face CDN routing rules.

### Fixed
- (DOS-8) - Purged the catastrophic `-or` logical evaluation bug from `Utils\asset_downloader.ps1` that routinely corrupted the internal PowerShell argument expression parser.
- (DOS-8) - Eliminated duplicate Win32 firewall rule generation collisions (`New-NetFirewallRule`) by dynamically sealing ingress rule identifiers to unique target socket port names.
- (DOS-8) - Resolved silent multi-gigabyte download corruption blocks by eliminating global string formatting (`.ToLower()`) on direct web stream endpoints.
- (DOS-8) - Mitigated a severe runtime block in `pyparts_deploy.ps1` by shifting `pip` upgrades to a safe module invocation layout (`python -m pip`), bypassing active execution binary file locks on Windows environments.

### Known Issues
- **SCM Service Context Redirection**: Spawning the `llama-swap-service` background daemon under the default `LocalSystem` account prunes active user profiles. The configuration engine must dynamically replace all `%USERPROFILE%` environment tokens with expanded absolute disk paths on the fly prior to saving `llama-swap.conf.yml` to prevent the Go parser from crashing inside `System32\config\systemprofile`.
- **WSL Deprecation Noise Leakage**: Legacy configuration keys inside host machines (e.g., `wsl2.pageReporting` in older `.wslconfig` setups) force `wsl.exe` to constantly flood the standard error (`Stderr`) stream. PowerShell cross-boundary wrappers must explicitly redirect error streams (`2>$null`) during cold instance checks to prevent system diagnostics noise from corrupting data delivery logs.
- **Node.js/Go Interactive TTY Hijacking**: CLI binaries that construct pseudo-graphic terminal dropdowns or raw keypress confirmation prompt blocks (like `lms get`) completely isolate standard input (`StandardInput.WriteLine`). They ignore automated text pipes (`echo y |`) and headless flags, requiring complete execution bypass or strict programmatic non-interactive mode isolation via native web transfer streams (`Invoke-WebRequest`).
- **Pydantic/FastMCP Dependency Hell**: The Anthropic `mcp` core transport package forces strict runtime constraints requiring `pydantic>=2.11.0`. Hardcoding older version definitions (`pydantic==2.7.1`) inside development manifests creates severe silent event loop collisions, requiring global baseline enforcement across all orchestrator rigs.

---

## [Development Snapshot] - DOS-7 (2026-07-19)

### Added
- (DOS-7) - Integrated `llama-swap` Go-backed proxy gateway on the host to manage the lazy execution loop lifecycle of native C++ `llama-server` instances.
- (DOS-7) - Implemented strict 6GB VRAM allocation caps and sequential request throttling (`concurrency: 1`) via a centralized `llama-swap.conf.yml` layout.
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
- (DOS-7) - Corrected Sonar / Linter security hotspot flags inside `qdrant_deploy.ps1` by expanding the truncated health check address to a valid production `http://127.0.0` URI.

---

## [Development Snapshot] - DOS-6 (2026-07-17)

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

---

## [Development Snapshot] - 2026-07-08

### Added
- (DOS-2) - Implemented a multi-zone RAG data architecture featuring strict context isolation between engineering and hobby knowledge bases.
- (DOS-2) - Created dual-watcher background daemon loops using independent `qdrant_watcher.py` instances to index separate host folders concurrently.
- (DOS-2) - Formulated isolated shortcode naming parameters to prevent context leakage across general LLM instances and targeted coding models.

### Fixed
- (DOS-2) - Resolved a critical HTTP 404 crash inside `qdrant_watcher.py` by mapping the target Ollama payload explicitly to the updated `/api/embed` endpoint.
- (DOS-2) - Fixed vector parsing exceptions by re-engineering the response interpreter to extract structured arrays from the modern `embeddings` JSON key.

---

## [Development Snapshot] - 2026-07-07

### Added
- (DOS-1) - Integrated FastMCP python framework bindings inside WSL (`qdrant_mcp.py`) to expose real-time context injections to the Aider runtime agent via stdio transport channels.
- (DOS-1) - Added automated background persistence triggers for file-watchers by nesting execution commands inside the Windows Task Scheduler, bypassing local service permission blocks.
- (DOS-1) - Introduced automated model dependency evaluations using direct regex parsing maps against local YAML shortcode matrix configurations.

### Modified
- (DOS-1) - Overhauled the entire local deployment suite (`.ps1` / `.sh`), resolving hidden race conditions and lockups during network adapter port forwarding.
- (DOS-1) - Swapped out obsolete foundational model layers in Ollama and LiteLLM configurations for modern high-context MoE and Coder model architectures.
- (DOS-1) - Hardcoded LiteLLM gateway routines on the host to operate exclusively as a stealth Claude Sonnet API mimic layer for JetBrains IDE integrations.
