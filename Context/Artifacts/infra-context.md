# SYSTEM ARCHITECTURE CONTEXT: LOCAL AI DEVOPS & C++ INFRASTRUCTURE (REVISED)

## 1. ROLES & Actors
### User ([[User-EN]], [[User-RU]])
- Senior JS/TS Full Stack Software Engineer / Enterprise Architecture Team Lead. Single Source of Truth for task generation.

### AI Assistant ([[AI-Devops-EN]], [[AI-Devops-RU]])
- Zhorvis: Battle-tested Senior/Lead DevOps Infrastructure Architect consultant. Direct, cynical, peer-level Slack tone. No fluff.

### Guest AI ([[AI-AQA-EN]], [[AI-AQA-RU]])
- Aider: Autonomous AI-AQA engineering agent executing direct code modifications inside WSL guest workspace via native OpenAI-compatible protocol.

---

## 2. REPOSITORY & RUNTIME WORKSPACE TOPOLOGY
Distribution Package Root: Any folder into which it is unpacked by the User.
Distribution Package Root is set to `~d\` in this document for explanatory purposes only.

### Source Directory Layout (GitHub Compliant ASCII)
```text
📂 ~d\
|-- 📂 Aider\
|   |-- 📄 aider_deploy.ps1      # Mounts guest shell script, maps parent root path for qdrant_mcp.py extraction
|   |-- 📄 aider_deploy.sh       # Guest shell installer: locks version to aider-chat==0.74.0 via pipx
|   |-- 📄 aider_run.sh          # Guest CLI execution wrapper: injects ultra-lightweight [MARKER HYDRATE] triggers
|   `-- 📄 config.yml            # Guest configuration blueprint featuring declarative SSE HTTP network MCP bindings
|-- 📂 Backend\                  # Encapsulated C++ inference gateway matrix (Former LiteLLM directory)
|   |-- 📄 backend_deploy.ps1    # Provisions native llama binaries, registers app path, spawns NSSM host service
|   |-- 📄 config.yml            # Master swap configuration manifest driving multi-user environment-agnostic profiles
|   `-- 📄 system_prompt.txt     # Pure system prompt template asset layer embedding the IDENTITY HYDRATION policy
|-- 📂 Conf\
|   `-- 📄 .wslconfig            # Idempotent host limits template (16GB RAM ceiling / 8 Cores / pageReporting=false)
|-- 📂 Context\                  # Single Source of Truth for static operational assets (PascalCase folder)
|   |-- 📂 Artifacts\            # DevOps architectural, logging, and scripting sessions summary documents
|   |-- 📂 Insights\             # Immutable baseline usable insights documents for prompt mixins
|   |-- 📂 Prompts\              # Immutable baseline prompt templates and task scenario documents
|   |-- 📂 Roles\                # Hardened engineering system personas (AQA, DevOps, and Backend Lead profiles)
|   |-- 📂 Skills\               # Flat technology reference architectures, coding specs, and logic rules
|   `-- 📂 User\                 # Core developer bio profiles defining background and execution limits
|-- 📂 Qdrant\
|   |-- 📄 docker-compose.yml    # Native Docker Compose manifest hosting pristine official Qdrant node capped to 2GB
|   |-- 📄 libs.py               # Shared async library offloading heavy CPU tensor generation off the event loop
|   |-- 📄 qdrant_deploy.ps1     # Synces Python assets, validates healthz, mounts watcher tasks and NSSM MCP service
|   |-- 📄 qdrant_mcp.py         # Async host FastMCP tool exposing non-blocking SSE HTTP streams on port 8000
|   `-- 📄 qdrant_watcher.py     # High-performance async file-system auditor leveraging Rust-backed watchfiles loop
|-- 📂 Utils\
|   |-- 📄 qdrant_mcp.py         # Async host FastMCP tool exposing non-blocking SSE HTTP streams on port 8000
|   `-- 📄 qdrant_watcher.py     # High-performance async file-system auditor leveraging Rust-backed watchfiles loop
|-- 📄 infra_deploy.ps1          # Unified master orchestration engine routing all deployment lifecycle phases
|-- 📄 models_deploy.ps1         # Safe declarative downloader pipeline pulling GGUF weights directly from Hugging Face
`-- 📄 network_setup.ps1         # Rebuilds firewall rules (LocalSubnet) and Netsh PortProxy vEthernet tunnels
```

Production User Profile Runtime Root: `~/.ai/` (`C:\Users\<User>\.ai\`)

### Destination Directory Layout
```text
📂 ~/.ai/
|-- 📂 .venv/             # Python virtual environment persistent location
|    `-- 📂 mcp/          # Python MCP Server and MCP Watcher / Chunker / Embedder repository and working directory
|-- 📂 bin/               # Centralized repository for native binaries (llama-swap.exe, llama-server.exe, nssm.exe)
|-- 📂 conf/              # Centralized repository for service configs (llama-swap.conf.yml, etc.)
|-- 📂 log/               # Consolidated enterprise telemetry room tracking llama-swap.log and qdrant-mcp.log
|-- 📂 models/            # Pure data asset layer hosting downloaded Q4_K_M and IQ4_NL GGUF weight matrices
`-- 📂 context/           # Mapped active bootstrap resource pool deployment root
    |-- 📂 artifacts/     # AI Artifacts - Project / Architecture definition markdown files for AI
    |-- 📂 insights/      # AI Insights - Insights collected by AI in the Project development process (markdown files for AI)    
    |-- 📂 prompts/       # Immediate session task instruction execution files
    |-- 📂 roles/         # AI Persona definition markdown files
    |-- 📂 skills/        # AI Skills definition markdown files
    |-- 📂 tools/         # AI Tools / Toolchains definition markdown files        
    `-- 📂 user/          # Core personalized profile constraints (User-RU.md, User-EN.md)

```

## 3. CORE INFRASTRUCTURE CONFIGURATIONS (REVISED)

### Llama-Swap `llama-swap.conf.yml`
Exposes the single source of truth for local model virtualization and routing. Driven by a fast Go-backed proxy gateway on the Windows Host listening strictly on the loopback interface (`127.0.0.1:1234`) to completely bypass Hyper-V zero-address binding bugs. Managed as a persistent, headless background Windows service via the `NSSM` daemon running under the active user session context. It enforces strict sequential execution (`concurrency: 1`) to lock maximum VRAM utilization to a hard **6GB boundary** (out of 8GB physical host VRAM) and automatically evicts dead server processes from memory via an aggressive time-to-live (`ttl: 300s`) configuration layer.

### Native C++ `llama-server` Primitives
Launched on-demand by the swap router proxy on isolated loopback ports (`8080`, `8081`, `8082`). It completely bypasses heavy Python/JS runtime overheads, loading quantum files (`IQ4_NL` / `Q4_K_M`) directly into the GPU CUDA grid via the `--n-gpu-layers -1` command parameter. It natively replicates old LiteLLM YAML anchors by reading the corporate specification instructions from a static file via the `--system-prompt-file` flag. The system prompt contains explicit `[MARKER L99]`, `[MARKER ULTRATHINK]`, and `[MARKER HYDRATE]` token layers, enforcing the absolute `[CRITICAL POLICY: IDENTITY HYDRATION]` guardrails.

### Aider `llama-swap.conf.yml` (Inside WSL: `~/.config/aider/config.yml`)
Completely stripped of Ollama/LiteLLM pre-parsing prefix configurations. Routes execution streams directly to the host loopback port-proxy bridge via the standardized protocol format `model: openai/claude-sonnet-4-6` targeting the `http://win-host:1234/v1` gateway. Integrates the host-level FastMCP server node dynamically using the advanced `url: http://win-host:8000/sse` network transport block.

---

## 4. MODULAR POWERSHELL DEPLOYMENT SCRIPTS

### 1. `infra_deploy.ps1` (Master Orchestrator / Root Point)
* **PHASE 0**: Idempotently provisions the `~/.ai/` user-isolated profile master layout structure.
* **PHASE 0.5**: Legacy Infrastructure Liquidation. Gracefully terminates and completely deletes the old Windows `litellm` service via `sc.exe`, purges legacy config folders, executes global `pip uninstall litellm -y`, and recursively wipes the distribution `LiteLLM` source directory from the host machine.
* **PHASE 1-6**: Sequential execution control pipeline: `LMStudio\lms_deploy.ps1` (Backend service) -> `pyparts_deploy.ps1` -> `network_setup.ps1` -> `models_deploy.ps1` -> `Qdrant\qdrant_deploy.ps1` -> `Aider\aider_deploy.ps1`.

### 2. `pyparts_deploy.ps1` (Python & Venv Handler / Root Point)
* Validates host system Python compliance (minimum version 3.10 required).
* Provisions an isolated `.venv` sandbox within `~/.ai/.qdrant/` packed with frozen, production-ready asynchronous dependencies (`watchfiles==0.21.0`, `qdrant-client==1.9.0`, `fastmcp==0.4.1`, `sentence-transformers==3.0.1`, `langchain-text-splitters==0.2.0`, `pydantic==2.7.1`, `pyyaml==6.0.1`).

### 3. `network_setup.ps1` (Security & Routing Bridge / Root Point)
* Establishes a highly restrictive firewall perimeter via `New-NetFirewallRule` for ports `1234`, `8000`, and `6333` locked to `-RemoteAddress LocalSubnet` to completely prevent external LAN intrusions while maintaining guest access.
* Dynamically extracts the volatile WSL vEthernet gateway IP interface on log-on, automatically injects it as `win-host` inside the guest `/etc/hosts` registry, and sets up explicit `netsh interface portproxy` mapping tunnels from the gateway IP straight into the host loopback `127.0.0.1` sockets.

### 4. `models_deploy.ps1` (Asset Delivery Factory / Root Point)
* Pure data asset ingestion pipeline. It uses lightweight, inline Python scripts to safely parse the centralized `Backend\config.yml` Single Source of Truth profiles list.
* Evaluates active weight files inside `~/.ai/models/` and silently downloads missing GGUF models directly from Hugging Face repositories using chunked web requests forced to the secure TLS 1.2 network protocol.

### 5. `Qdrant\qdrant_deploy.ps1` (Vector Engine Node / Qdrant Folder)
* Instantiates a pristine, official Qdrant database node container via Docker Compose (port `6333`). To preserve system safety under strict multi-user loads, the container is locked to a 2GB RAM ceiling with hardware caps (`cpus: 2`), forcing a complete memory-mapped vector translation threshold (`QDRANT__VECTORS__MEMMAP_THRESHOLD=0`) to load layers directly from fast NVMe storage.
* Asserts an active HTTP `200 OK` health-check verification loop targeting the valid `http://127.0.0` URI.
* Registers the background `qdrant_watcher.py` file-tracker via Windows Task Scheduler (`AI-RAG-Dev`), and registers the host-level `qdrant_mcp.py` SSE web server as a persistent service via `NSSM` running under the current user's profile account.

### 6. `Aider\aider_deploy.ps1` (Guest Environment Sync / Aider Folder)
* Mounts and runs `aider_deploy.sh` inside the WSL2 guest shell environment. Pins the client environment to a locked version (`aider-chat==0.74.0`) via `pipx` to eliminate upstream runtime configuration drifts.
* Dynamically resolves modular cross-folder path tokens using the `.Parent` descriptor to safely extract and copy the `qdrant_mcp.py` bridge directly into the user workspace inside WSL.

---

## 5. REAL-TIME KNOWLEDGE INDEXING PIPELINE (RAG)

### Windows Watcher (`qdrant_watcher.py` inside `~/.ai/.qdrant/`)
* Relies on the **`watchfiles`** high-performance library core utilizing non-blocking Rust file system auditing loops.
* **Self-Stabilizing Core:** Contains a non-blocking asynchronous `libs.wait_for_qdrant` hook on startup. If Docker Desktop or the Qdrant container is offline, it loops gracefully checking the health socket every 5 seconds using native lightweight `urllib.request` polling blocks, avoiding high CPU spikes and crash loops.
* **Asynchronous I/O Consistency:** All heavy synchronous file system operations (`with open()`, `read()`, and recursive note transclusions `![[Note]]`) are completely offloaded from the main event loop thread via an isolated internal function executed inside an explicit `asyncio.to_thread()` worker boundary.
* **Deterministic Identity Mapping:** Generates point IDs by hashing strictly the combination of the absolute file path and the chunk index (`hash(f'{file_path}_{i}')`). This completely eliminates the legacy `time.time()` token leakage, preventing double-indexing collisions and database bloat.
* **CPU-Backed Embedding Layer:** Extracts vectors by calling the local `SentenceTransformer` engine (`nomic-ai/nomic-embed-text-v1.5`) running strictly on the host CPU boundary (`device="cpu"`) to save VRAM. It injects mandatory Nomic v1.5 API prefixes (`search_document: `) to align the calculated cosine distance matrix.
* **Multi-Zone Data Isolation Matrix:**
  * Coding and enterprise software architectural vectors reside in the `db-dev` collection and process documents from the isolated engineering Obsidian vault (`E:\Vaults\v-dev`).
  * Hobby assistance vectors reside in the separate `db-hobby` collection and process documents from the isolated personal Obsidian vault (`E:\Vaults\v-hobby`).

### Windows FastMCP Server Service (`qdrant_mcp.py` inside `~/.ai/.qdrant/`)
* Implements a highly scalable, asynchronous **`FastMCP`** server exposed as an independent network node using the `SSE HTTP` transport protocol listening on `127.0.0.1:8000`.
* **Lazy-Loading Synchronization:** Blocks the initialization thread upon service start via `loop.run_until_complete()` until the underlying Qdrant container passes health handshakes. If the database drops, the service stays alive in a non-blocking wait lock, logging clean data streams to `~/.ai/log/qdrant-mcp.log`.
* **Shared Library Integration:** Completely stripped of redundant text-splitters and mathematical modeling layers. It imports the unified `libs.py` single source of truth module to calculate query embeddings on the host CPU using the correct `search_query: ` API prefix notation.
* **Explicit Identity Hydration Layer:**
  * Exposes the `search_knowledge_base` tool to extract markdown context layers matching the project language. It analyzes Cyrillic presence via `libs.detect_language()` to dynamically filter metadata using file naming conventions (`-RU` or `-EN`).
  * Listens to the single lightweight prompt token trigger `[MARKER HYDRATE] $ROLE` passed by `aider_run.sh`. The model captures this indicator at the opening line of a conversation, immediately intercepts execution, and forces the FastMCP tool to pull explicit markdown playbooks directly from the vector storage. This performs an on-demand runtime **Context Hydration** injection to mutate the model's persona without blowing out context limits.

### Obsidian Ecosystem Constraints
* **Model Inference Gateway:** Driven by local chatbot plugins. The engineering vault targets the local llama-swap host proxy gateway loopback (`http://127.0.0`) using model mapping to call virtual Claude endpoints. The hobby vault targets the local Qdrant REST API container node directly (`http://127.0.0.1:6333`) to run semantic vector queries.
* **Code Environment Sync:** Enforces strict layout rendering and document sanitization via `Editor Syntax Highlight` (token coloring match for JS/TS/PowerShell/INI), `Advanced URI` (system-wide execution paths bridging IDE links), and `Linter` (strict markdown syntax verification on save).
