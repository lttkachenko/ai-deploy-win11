# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com).

## [Development Snapshot] - DOS-13 (2026-08-20)

### Added
- (DOS-13) - Designed a unified Object-Oriented paradigm for the vector indexer layer by splitting contracts into `IStoreServiceBase` and `IStoreService`, introducing abstract factories (`StoreFactoryBase`, `StoreFactory`) to cleanly segregate light server search pipelines from heavy file-system watchers.
- (DOS-13) - Engineered the `MCPServerGateway` managing class to completely encapsulate both FastAPI and FastMCP runtimes, migrating the entire server architecture to modern object state parameters (`self`) and completely eliminating antipattern global tracking states (`global`).
- (DOS-13) - Integrated the modern `HTTPStreamable` transport protocol via explicit FastAPI mounting (`app.mount("/mcp", mcp.asgi())`), successfully exposing a native high-performance streaming layer alongside standard HTTP configurations.
- (DOS-13) - Implemented a resilient, case-insensitive string normalization pipeline inside `libs/config_utils.py` driven by `.strip().lower()` and explicit quote purges (`.replace('"', "")`) to prevent silent config lookup failures caused by escaped Windows SCM and NSSM parameters.
- (DOS-13) - Developed a decoupled routing layer class `MCPRouter` inside `libs/mcp/MCPRouter.py`, separating raw transport parsing logic from the gateway shell and utilizing modern Python 3.10+ structural pattern matching (`match/case`) instead of deep `if/elif` chains.
- (DOS-13) - Implemented direct JSON-RPC interception for `tools/list` and `prompts/list` primitives inside the custom router, enabling the gateway to safely extract metadata from FastMCP decorator contexts when underlying core handlers are partially initialized.

### Modified
- (DOS-13) - Refactored the core transaction engine inside `MCPService.py` to recursively sort and compile vector shards strictly by their absolute `chunk_id` sequence, successfully recreating unbroken Markdown files from raw database points.
- (DOS-13) - Re-engineered the initialization pipelines in `StoreServiceQdrantBase` by moving configuration logic into a protected, polymorphic `_parse_config` method, allowing child classes to seamlessly inherit and extend database properties via clean `super()` chains.
- (DOS-13) - Modernized the asset synchronization routine inside `mcp_deploy.ps1` by switching to recursive, forced directory synchronization (`Copy-Item -Recurse -Force`) to perfectly replicate the new nested `libs/store` and `libs/mcp` structure into the target runtime.
- (DOS-13) - Upgraded the precompilation engine in `Precompile-MCPAssets.ps1` to invoke the native Python `compileall` module recursively, completely eliminating manual file loops and securing bytecode coverage for all inner packages.
- (DOS-13) - Standardized the runtime path routing engine inside `libs/config_utils.py` to extract configuration matrices relative to the isolated active working directory (`os.getcwd()`), cleanly preventing environment race conditions during multi-daemon parallel boots.
- (DOS-13) - Extended the `resources/templates/list` schema handler to expose a unified routing template (`obsidian://{folder}/{path}`), allowing advanced AI agents and inspectors to natively discover dynamic parameterized query rules.
- (DOS-13) - Overhauled the query criteria inside `_reconstruct_file_from_shards` and `_build_virtual_directory_manifest` by switching filters from non-deterministic `MatchText` to absolute `MatchValue` conditions, aligning search transactions with the watcher's exact string layout.

### Fixed
- (DOS-13) - Eliminated a persistent `ValueError` crash inside the NSSM runtime by fixing a multi-scope variable casing bug (`$venvPython` vs `$VenvPython`) and forcing an early `Set-Location` directive inside the isolated PowerShell session command block.
- (DOS-13) - Resolved an immediate runtime initialization drop inside `mcp_watcher.py` by restoring the standard top-level Python main execution block (`if __name__ == '__main__'`) and safeguarding it with explicit `asyncio.run()` error handling.
- (DOS-13) - Fixed a critical Python `TypeError` inside `libs/config_utils.py` caused by illegal list-to-hash indexing during debug fallbacks by standardizing dictionary key retrieval on precise index limits (`[0]`).
- (DOS-13) - Rectified a permanent connection timeout inside `_await_store` by integrating an automated URL parser (`urlparse`) to strip application scheme prefixes (`http://`) and isolate clean host coordinates prior to low-level socket binding.
- (DOS-13) - Eradicated code smells and SonarLint compilation warnings inside `_check_network_socket` by replacing empty context blocks and lazy `pass` operators with deterministic `.close()` socket release events.
- (DOS-13) - Resolved a critical Python `NameError` inside `IMCPService.py` by introducing clean type annotations (`Optional`, `List`) into the header of the interface file.
- (DOS-13) - Suppressed a critical `ValueError: too many values to unpack` crash inside Qdrant asynchronous search blocks by updating un-unpacked point tuples to capture offsets via trailing assignments (`scroll_result, _ = await ...`).
- (DOS-13) - Resolved a critical JSON-RPC collision where internal core crashes implicitly fell back to transport discovery objects, by decoupling `resources/list` routing definitions and returning isolated, compliant resource lists.
- (DOS-13) - Rectified a Liskov Substitution Principle (LSP) signature mismatch error and Sonar code analyzer blocker inside `MCPGateway.py` by restoring strict `(self, folder: str, path: str)` arguments to match the parent abstract interface layout.
- (DOS-13) - Fixed a critical vector mapping error where reading files returned empty folder matrices (`### Directory Map`) due to incorrect schema indexing, by mapping Qdrant searches to verified file properties (`metadata.parent_path` and `metadata.uri_path`).

### Deprecated / Removed
- (DOS-13) - **Deprecated**: The monolithic procedural script `libs.py` has been completely deprecated and broken down into isolated, single-responsibility OOP modules.
- (DOS-13) - **Removed**: Eradicated the deprecated procedural API gateway `mcp_api.py`, fully migrating its structural compilation logic and transaction flows into the `MCPService` class methods.
- (DOS-13) - **Removed**: Eliminated volatile OS-level user environment variables from the deployment lifecycle to completely protect concurrent daemon processes from cross-process memory leaks and race conditions.
- (DOS-13) - **Removed**: Stripped out loose, unbuffered global print statements across all files, substituting them with strict, atomic `flush=True` logs to guarantee instant disk output under Windows LocalSystem restrictions.

---

## [Development Snapshot] - DOS-12 (2026-08-10)

### Added


### Modified


### Fixed


### Deprecated / Removed


---

## [Development Snapshot] - DOS-11 (2026-07-31)

### Added
- (DOS-11) - Implemented a high-performance, asynchronous background workspace hydration scan loop inside `mcp_watcher.py` using native `os.walk` streams to completely index legacy Markdown assets on startup boundary before initiating the `watchfiles` event loop.
- (DOS-11) - Integrated an automated pre-flight environment discovery and directory scavenging block into `qdrant_deploy.ps1` to migrate `qdrant_healthz.ps1` into the centralized production runtime binaries directory (`~/.ai/bin/`).
- (DOS-11) - Introduced explicit, flexible path mapping capabilities inside `aider_run.sh` by provisioning the `-c` / `--config` CLI switch to natively intercept, override, and pass custom execution configuration slots.
- (DOS-11) - Scaffolded a dedicated, isolated runtime telemetry collection boundary at `~/.aider/log/` backed by a native bash `tee` output redirection sequence inside `aider_run.sh` to capture unified stdout and stderr logs.

### Modified
- (DOS-11) - Refactored the core configuration parsing logic inside `mcp_watcher.py` from fragile regex pattern filters to a low-complexity dictionary stream tokenizer (`Cognitive Complexity < 5`), ensuring stable token extraction for indented `db` and `vault` YAML mappings.
- (DOS-11) - Migrated the filesystem RAG tracking engine inside `mcp_deploy.ps1` from an interactive Windows Scheduled Task wrapper to a headless, non-interactive Windows Service driven entirely by NSSM (`ai-rag-wtr`), suppressing workspace window pops.
- (DOS-11) - Re-aligned the `Aider\aider_deploy.ps1` transport protocol to route the distribution deployment configuration template strictly into the unified internal profile runtime boundary location at `~/.aider/config.yml`.
- (DOS-11) - Standardized the guest invocation wrapper inside `aider_run.sh` to forward absolute configuration file declarations directly via the native `--config` argument string, enforcing precise middleware endpoint resolution.

### Fixed
- (DOS-11) - Resolved a crippling `TypeError: 'NoneType' object is not subscriptable` crash inside `mcp_watcher.py` by engineering a guaranteed dictionary fallback object return outside the configuration file stream iterator.
- (DOS-11) - Eradicated a severe SonarQube syntax code quality alert (`python:S5857`) inside character classes by replacing duplicated, over-escaped quotation literals with safe, compliant stream token processing.
- (DOS-11) - Corrected a fatal type-mismatch error inside `libs.py` (`Unsupported points selector type: <class 'dict'>`) by migrating raw dictionary query arrays into strictly-typed `FilterSelector`, `Filter`, `FieldCondition`, and `MatchValue` object models.
- (DOS-11) - Mitigated an immediate `CommandNotFoundException` failure during Step 6 of `aider_deploy.ps1` by cross-compiling windows paths through the native `wsl -e wslpath` wrapper utility boundary.
- (DOS-11) - Cleared a syntax error inside `aider_deploy.ps1` caused by unescaped nested single quotation marks enclosing the `throw` error boundaries, restoring strict PowerShell compilation metrics.
- (DOS-11) - Resolved an immediate runtime initialization block inside `aider_run.sh` by decoupling the initial prompt parsing pipeline from non-existent flat file directory constraints (`prompts/default.md`), enabling pure vector-backed interactive chat modes.
- (DOS-11) - Purged a silent deployment transport failure inside `aider_deploy.ps1` by deprecating unstable filesystem copy bridges in favor of a robust bash heredoc injection stream (`cat << 'EOF'`) to route configurations into the guest subsystem.

### Known Issues
- **Non-Interactive Environment Path Dropping**: Spawning the guest environment engine from abstract host terminal entries can occasionally skip parsing the user's `~/.bashrc` profile layer. Custom alias allocations like `aider-run` may drop out from remote execution threads, requiring operators to target the absolute script coordinate path (`~/.aider/aider_run.sh`) to maintain session persistence.

---

## [Development Snapshot] - DOS-10 (2026-07-27)

### Added
- (DOS-10) - Established a secure, dedicated port space routing matrix entirely shifted to non-standard high-range blocks (`8090`–`8095`), completely purging collision risks with future node and Webpack development pipelines.
- (DOS-10) - Integrated a high-performance, dynamic macro token discovery engine into `backend_deploy.ps1` utilizing explicit regex group filters to natively extract case-sensitive variables (`SW_HOST`, `SW_PORT`) from configuration matrices.
- (DOS-10) - Enforced a strict cryptographic identity validation mechanism inside `libs.py` by implementing a stable `hashlib.sha256` digest mapping protocol to yield deterministic, immutable uint64 `point_id` markers across daemon restarts.
- (DOS-10) - Introduced a strict security perimeter authorization layer inside `mcp_server.py` requiring explicit `client_key` query payload validation to pass incoming FastMCP tool invocation requests.
- (DOS-10) - Implemented a cyclic pre-flight validation barrier loop inside `mcp_deploy.ps1` targeting port `8095` to gracefully absorb cold-boot thread block latencies caused by heavy CPU matrix computations during `SentenceTransformer` initialization.

### Modified
- (DOS-10) - Refactored `backend_deploy.ps1` to cleanly pass precise, flattened infrastructure constraints (`--listen "${detectedHost}:${detectedPort}"`) down to the NSSM installation command boundary, eliminating nested quotation collapse failures in the Win32 registry.
- (DOS-10) - Shifted the underlying inference execution sequence from abstract multi-port mapping arrays to a unified sequential workflow on a single target port (`8090`), leveraging the native `mostlygeek/llama-swap` spec under strict `concurrency: 1` limits.
- (DOS-10) - Standardized the centralized variable injection topology across all core data-parsing layouts to strictly utilize standard dollar-brace tokens (`${macro}`), deprecating incompatible abstract bracket formats.
- (DOS-10) - Translated all code comment structures and logging signals inside `libs.py`, `mcp_server.py`, and `mcp_watcher.py` into a unified, enterprise-grade English vocabulary layout to comply with automated security code quality audits.

### Fixed
- (DOS-10) - Resolved a catastrophic, random vector replication loop inside `libs.py` by deprecating python's native, process-seeded `hash()` function, replacing it with case-immutable deterministic hash generation algorithms.
- (DOS-10) - Purged a crippling syntax error inside `mcp_server.py` caused by a misplaced PowerShell negation keyword (`if -not`) in the file validation sequence, restoring pure Python compliance standards.
- (DOS-10) - Corrected an invalid network routing loop inside `qdrant_deploy.ps1` by shifting the pre-flight check endpoint to the officially documented Qdrant path `/readyz`, preventing immediate `404 Not Found` deployment failures.
- (DOS-10) - Mitigated a severe runtime directory drifting bug inside `pyparts_deploy.ps1` by swapping single-character string trimmers with an absolute, non-destructive regex path normalization pattern that preserves Unix-style dot definitions (`.ai/`).
- (DOS-10) - Cleared an immediate `ModuleNotFoundError` inside host service containers by hard-coding explicit sys-path modifications (`sys.path.insert`) to force the `LocalSystem` engine to look up internal modules inside the exact execution directory.
- (DOS-10) - Eradicated a fatal `Null` execution command crash at step 5.3 of the backend deployment script by aligning raw output pipeline redirections with the native PowerShell `Out-Null` cmdlet signature.
- (DOS-10) - Resolved a severe file parsing drift inside `mcp_watcher.py` by completely expunging copy-paste function duplicates, routing all Markdown processing pipelines strictly through the verified `libs.index_file` coordinate.

### Known Issues
- **Hugging Face Rate Limiting Blocks**: Initializing cold boots of the shared CPU transformation pipeline from unauthenticated terminal instances triggers frequent `huggingface_hub` connection delay cycles. Production environments should explicitly provision an absolute `HF_TOKEN` macro value inside the NSSM wrapper extra environment space to ensure high-priority rate limits [DOS-7].
- **LocalSystem Configuration Routing Collisions**: Running context servers via headless background services can trigger environmental profile path resets inside standard libraries. If `AI_CONFIG_PATH` variables drop out from target NSSM blocks, the parsing routine will fall back onto default paths, ignoring the custom `mcp.conf.yml` socket mappings [DOS-9].

---

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
- (DOS-8) - Unified all network downloading processes by offloading heavy GGUF and mmproj weight ingestion routines directly to the centralized, multithreaded `Utils\asset_downloader.ps1` script core.
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
- (DOS-7) - Migrated the containerized FastMCP server (`mcp_server.py`) directly to the host network boundary as a persistent background Windows service using the `NSSM` wrapper.
- (DOS-7) - Swapped out stdout transport protocols inside the FastMCP server for a unified network-accessible `SSE HTTP` web server structure listening on port 8000.

### Modified
- (DOS-7) - Deprecated and completely purged the entire `LiteLLM` proxy layer, `Ollama` daemon dependencies, and `NSSM` Windows services configuration scripts on the host.
- (DOS-7) - Refactored `models_deploy.ps1` into a strict data-delivery module, stripping out execution code to cleanly pull `IQ4_NL` / `Q4_K_M` GGUF weights directly from Hugging Face into `%USERPROFILE%/.ai/models`.
- (DOS-7) - Redefined `Aider\config.yml` parameters to execute direct native OpenAI-compatible calls on port 1234 using the `openai/claude-sonnet-4-6` identifier.
- (DOS-7) - Optimized `aider_run.sh` to pass a single isolated target token trigger `[MARKER HYDRATE] $ROLE` to offload the entire persona parsing stream down to the Qdrant RAG index.
- (DOS-7) - Re-engineered `network_setup.ps1` to handle severe Hyper-V zero-address binding bugs by mapping precise cross-boundary `netsh interface portproxy` tunnels from the WSL vEthernet gateway IP to `1234`, `8000`, and `6333` ports on loopback.

### Fixed
- (DOS-7) - Secured the `mcp_watcher.py` file mapping logic by forcing index arrays to index `[0]` inside `os.path.splitext`, preventing runtime task drops on dot-nested file tags.
- (DOS-7) - Eliminated duplicate vector node allocations inside `libs.py` by removing the unstable `time.time()` string slice from the `point_id` hash algorithm.
- (DOS-7) - Resolved critical Python async consistency block errors by wrapping the heavy synchronous `.encode()` method inside `asyncio.to_thread()`, moving CPU tensor generation entirely off the main event loop thread.
- (DOS-7) - Fixed I/O blocks inside `libs.py` by wrapping standard synchronous `open()` and recursive transclusion file reads inside an isolated `asyncio.to_thread()` pipeline.
- (DOS-7) - Corrected Sonar / Linter security hotspot flags inside `qdrant_deploy.ps1` by expanding the truncated health check address to a valid production `http://127.0.0` URI.

---

## [Development Snapshot] - DOS-6 (2026-07-17)

### Added
- (DOS-6) - Overhauled the entire RAG pipeline python layer (`libs.py`, `mcp_watcher.py`, `mcp_server.py`) to fully asynchronous execution topology using `asyncio` and `httpx`.
- (DOS-6) - Swapped out legacy synchronous `watchdog` file system auditor for high-performance, Rust-backed `watchfiles` runtime loop inside `mcp_watcher.py`.
- (DOS-6) - Unified the embedding generation engine by implementing a dynamic factory method (`get_embedding`) inside `libs.py`, abstracting format schemas for both Ollama (`/api/embed`) and OpenAI/LM-Studio (`/v1/embeddings`) endpoints.
- (DOS-6) - Hardcoded idempotent global resource constraint checks into `infra_deploy.ps1` utilizing SHA256 file hashing to safely deploy strict memory (`16GB`) and CPU boundaries via `.wslconfig` prior to launching Docker networks.
- (DOS-6) - Refactored `models_deploy.ps1` into an adaptive IaC factory module with headless bootstrap integration for the advanced `llmster` background daemon and native multithreaded `lms` CLI toolchain down to local machines.

### Modified
- (DOS-6) - Migrated the low-level `mcp_server.py` transport layer from high-level `FastMCP` decorators to official `mcp.server` primitives to natively handle concurrent client requests without clogging the loop.
- (DOS-6) - Standardized the entire distribution repository file structure to a strict object-oriented `subject_action` naming convention (e.g., `asset_download.ps1`, `mcp_watcher.py`).
- (DOS-6) - Locked down all foundational pip packages inside `pyparts_deploy.ps1` to explicit enterprise version definitions (`watchfiles==0.24.0`, `httpx==0.27.0`, `mcp==1.2.1`) preventing runtime configuration drift across mid-level developer rigs.

### Fixed
- (DOS-6) - Eliminated host WDDM TDR / Windows graphics subsystem crashes under prolonged multi-hour contexts by forcing hardware isolation rules (`CUDA_MANAGED_FORCE_DEVICE_ALLOC=1`) and allocation caps via host registry injection layers.
- (DOS-6) - Mitigated major memory leaks inside WSL2 by forcing `QDRANT__VECTORS__MEMMAP_THRESHOLD=0` in `docker-compose.yml`, shifting vector storage execution boundaries out of RAM down to raw NVMe disk mapping.
- (DOS-6) - Resolved a silent async execution failure inside `libs.py` by applying proper `await` keywords to Qdrant client storage mutations (`delete`, `upsert`), correcting core memory-mapped collection pipeline drops.

---

## [Development Snapshot] - 2026-07-08

### Added
- (DOS-2) - Implemented a multi-zone RAG data architecture featuring strict context isolation between engineering and hobby knowledge bases.
- (DOS-2) - Created dual-watcher background daemon loops using independent `mcp_watcher.py` instances to index separate host folders concurrently.
- (DOS-2) - Formulated isolated shortcode naming parameters to prevent context leakage across general LLM instances and targeted coding models.

### Fixed
- (DOS-2) - Resolved a critical HTTP 404 crash inside `mcp_watcher.py` by mapping the target Ollama payload explicitly to the updated `/api/embed` endpoint.
- (DOS-2) - Fixed vector parsing exceptions by re-engineering the response interpreter to extract structured arrays from the modern `embeddings` JSON key.

---

## [Development Snapshot] - 2026-07-07

### Added
- (DOS-1) - Integrated FastMCP Python framework bindings inside WSL (`mcp_server.py`) to expose real-time context injections to the Aider runtime agent via stdio transport channels.
- (DOS-1) - Added automated background persistence triggers for file-watchers by nesting execution commands inside the Windows Task Scheduler, bypassing local service permission blocks.
- (DOS-1) - Introduced automated model dependency evaluations using direct regex parsing maps against local YAML shortcode matrix configurations.

### Modified
- (DOS-1) - Overhauled the entire local deployment suite (`.ps1` / `.sh`), resolving hidden race conditions and lockups during network adapter port forwarding.
- (DOS-1) - Swapped out obsolete foundational model layers in Ollama and LiteLLM configurations for modern high-context MoE and Coder model architectures.
- (DOS-1) - Hardcoded LiteLLM gateway routines on the host to operate exclusively as a stealth Claude Sonnet API mimic layer for JetBrains IDE integrations.
