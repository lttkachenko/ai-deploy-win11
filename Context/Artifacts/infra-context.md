# SYSTEM ARCHITECTURE CONTEXT: LOCAL AI DEVOPS & RAG INFRASTRUCTURE (REVISED)

## 1. ROLES & Actors
### User ([[User-EN]], [[User-RU]])
- Senior JS/TS Full Stack Software Engineer / Enterprise Architecture Team Lead.

### AI Assistant ([[AI-Devops-EN]], [[AI-Devops-RU]])
- Zhorvis: Battle-tested Senior/Lead DevOps Infrastructure Architect consultant. Direct, cynical, peer-level Slack tone.

### Guest AI ([[AI-AQA-EN]], [[AI-AQA-RU]])
- Aider: Autonomous AI-AQA / automated quality assurance engineering agent executing direct code modifications inside WSL guest workspace.

---

## 2. REPOSITORY & RUNTIME WORKSPACE TOPOLOGY
Distribution Package Root: Any folder into which it is unpacked by the User.
Distribution Package Root is set to `~d\` in this document for explanatory purposes only.

### Source Directory Layout (GitHub Compliant ASCII)
```text
📂 ~d\
|-- 📂 Aider\
|   |-- 📄 aider_deploy.ps1      # Mounts guest shell script, syncs host context parameters
|   |-- 📄 aider_deploy.sh       # Guest shell installer: provisions pipx, async packages, environment folders
|   |-- 📄 aider_run.sh          # Guest CLI execution wrapper: performs dynamic layered prompt stitching
|   `-- 📄 config.yml            # Guest configuration blueprint featuring declarative MCP server bindings
|-- 📂 Conf\
|   `-- 📄 .wslconfig            # Idempotent host limits template (16GB RAM ceiling / 8 Cores / pageReporting=false)
|-- 📂 Context\                  # Single Source of Truth for static operational assets (PascalCase folder)
|   |-- 📂 Artifacts\            # DevOps architectural, logging, and scripting sessions summary documents
|   |-- 📂 Insights\             # Immutable baseline usable insights documents for prompt mixins
|   |-- 📂 Prompts\              # Immutable baseline prompt templates and task scenario documents
|   |-- 📂 Roles\                # Hardened engineering system personas (AQA, DevOps, and Backend Lead profiles)
|   |-- 📂 Skills\               # Flat technology reference architectures, coding specs, and logic rules
|   `-- 📂 User\                 # Core developer bio profiles defining background and execution limits
|-- 📂 LiteLLM\
|   |-- 📄 config.yml            # Gateway configuration manifest with declarative shortcuts include clause
|   |-- 📄 litellm_deploy.ps1    # Deploys configs to ~/.ai/.litellm/ and provisions Windows service via NSSM
|   `-- 📄 shortcodes.yml        # Isolated system prompt definitions featuring [MARKER HYDRATE] tokens
|-- 📂 Qdrant\
|   |-- 📄 asset_download.ps1    # High-throughput .NET chunked downloader engine supporting HTTP Range requests
|   |-- 📄 docker-compose.yml    # Native Docker Compose manifest hosting persistent Qdrant nodes locked to 3GB RAM
|   |-- 📄 libs.py               # Shared async infrastructure library containing get_embedding factory routes
|   |-- 📄 qdrant_deploy.ps1     # Fires up container, validates HTTP healthz, locks watchers to Windows Tasks
|   |-- 📄 qdrant_mcp.py         # Async official mcp.server implementation with explicit Identity Hydration tools
|   `-- 📄 qdrant_watcher.py     # High-performance async file-system auditor leveraging Rust-backed watchfiles loop
|-- 📄 infra_deploy.ps1          # Unified master orchestration engine routing all deployment lifecycle phases
|-- 📄 models_deploy.ps1         # Polymorphic pipeline automatically detecting Ollama and headless llmster/lms CLI
|-- 📄 network_setup.ps1         # Rebuilds firewall rules, netsh portproxy bindings (8000/6333), and WSL DNS inversion
`-- 📄 pyparts_deploy.ps1        # Instantiates virtual sandbox with locked versions (watchfiles==0.24.0, httpx==0.27.0)
```

Production User Profile Runtime Root: `~/.ai/` (`C:\Users\<User>\.ai\`)

### Destination Directory Layout
```text
📂 ~/.ai/
|-- 📂 .litellm/          # Mapped configuration file layer, shortcodes, and daemon logging targets
|-- 📂 .qdrant/           # Persistent docker storage binds, isolated .venv sandbox, and live watcher python scripts
`-- 📂 context/           # Mapped active resource pool deployment root
    |-- 📂 roles/         # AI Persona definition markdown files (zhorvis.md, aider.md, max.md)
    |-- 📂 prompts/       # Immediate session task instruction execution files
    |-- 📂 skills/        # Reference engineering standards and specification notes
    `-- 📂 user/          # Core personalized profile constraints (User-RU.md, User-EN.md)
```

---

## 3. CORE INFRASTRUCTURE CONFIGURATIONS

### LiteLLM `shortcodes.yml`
Mapped to local `ollama/qwen2.5-coder` or OpenAI-compatible custom endpoint (`http://127.0.0`) driven by LM Studio. Context length forced to 32768 tokens. System prompt markers hardcoded (`[MARKER L99]`, `[MARKER ULTRATHINK]`). Contains mandatory `[CRITICAL POLICY: IDENTITY HYDRATION]` guardrails triggering explicit persona mutation tool calls via `[MARKER HYDRATE]` parsing logic.

### LiteLLM `config.yml`
Includes relative mapping to `shortcodes.yml`. Master key: `sk-sithedition-2026`. Service runs on Windows Host via NSSM daemon on `127.0.0.1:8000`. Log streams routed inside hidden runtime path `~/.ai/.litellm/`.

### Aider `config.yml` (Inside WSL: `~/.config/aider/config.yml`)
Routes execution streams directly to host loopback bridge `http://win-host:8000/v1`. Integrates python-driven MCP server module dynamically mapped to host windows workspace targets using standard `stdio` transport.

---

## 4. MODULAR POWERSHELL DEPLOYMENT SCRIPTS

### 1. `infra_deploy.ps1` (Master Orchestrator / Root Point)
- **PHASE 0**: Idempotently provisions `~/.ai/` master layout structure.
- **PHASE 0.5**: Evaluates file integrity of `%USERPROFILE%\.wslconfig` via SHA256 hashing. Syncs changes from `Conf\.wslconfig` and executes immediate non-blocking `wsl --shutdown` recycle to isolate memory space **prior** to initializing networks.
- **PHASE 1-5**: Sequential execution control pipeline: `pyparts_deploy.ps1` -> `network_setup.ps1` -> `LiteLLM\litellm_deploy.ps1` -> `models_deploy.ps1` -> `Qdrant\qdrant_deploy.ps1` -> `Aider\aider_deploy.ps1`.

### 2. `pyparts_deploy.ps1` (Python & Venv Handler / Root Point)
- Upgrades foundational package managers, maps host-level `litellm[proxy]==1.34.0`.
- Provisions isolated `.venv` sandbox within `~/.ai/.qdrant/`. Installs explicit frozen dependency layers (`watchfiles==0.24.0`, `qdrant-client==1.9.0`, `langchain-text-splitters==0.2.0`, `httpx==0.27.0`, `mcp==1.2.1`). Syncs `qdrant_watcher.py` and `libs.py` into production paths.

### 3. `network_setup.ps1` (Security & Routing Bridge / Root Point)
- Sets Inbound Windows Firewall permit status for port 8000. Wipes and maps native routing parameters via `netsh interface portproxy` targeting volatile WSL guest interface IP.
- Enforces inverse DNS rules inside WSL guest subsystem config files, linking alias token `win-host` to current host gateway via shell bootstrap triggers.

### 4. `models_deploy.ps1` (Engine Warmup Factory / Root Point)
- Polymorphic backend detection module. Automatically tests ports `11434` (Ollama) and `1234` (LM Studio).
- **Ollama Mode**: Injects specific `CUDA_MALLOC_MAX_BYTES` (6.2GB) registry bounds and disables WDDM TDR shared memory fallback to prevent Windows GUI crashes under heavy context lengths.
- **LM Studio Mode**: Automatically triggers headless `lms daemon up` background service, utilizes multi-threaded `lms get` engine to pull weight signatures from Hugging Face hub, and performs explicit cache pre-loading via `lms load`.

### 5. `Qdrant\qdrant_deploy.ps1` (Vector Engine Node / Qdrant Folder)
- Instantiates Qdrant container architecture via standard `docker-compose.yml` (port 6333). Blocks execution thread until HTTP `/healthz` check returns `200 OK`.
- Parameters pass explicit endpoint bindings down to background tasks registered inside Windows Task Scheduler (`AI-RAG-Dev` and `AI-RAG-Hobby`), tracking folder changes instantly At LogOn.

### 6. `Aider\aider_deploy.ps1` (Guest Environment Sync / Aider Folder)
- Mounts and runs `aider_deploy.sh` inside WSL guest shell environment. Configures global `config.yml` dependencies, updating path structure variables dynamically.
- Flattens and synchronization resource payloads directly from active environment host paths `~/.ai/context/*` over to destination guest subsystem paths `~/.aider/*`.

---

## 5. REAL-TIME KNOWLEDGE INDEXING PIPELINE (RAG)

### Windows Watcher (`qdrant_watcher.py` inside `~/.ai/.qdrant/`)
- Relies on **`watchfiles`** high-performance library core utilizing non-blocking Rust file system auditing loops.
- Runtime Arguments: Parameterized via `argparse` to accept `--vault`, `--collection`, `--port`, and `--ai-url` flags dynamically, allowing infinite isolated background instances to run concurrently.
- Self-Stabilizing feature: Contains async wait loops checking `libs.wait_for_qdrant` on startup. Blocks execution until Docker Desktop/Qdrant container comes alive after system boot to prevent network spam.
- Chunking & Embedding: Strips YAML frontmatter, resolves recursive `![[transclusions]]` graph layers, flattens internal `[[wiki-links]]`, splits text structurally via `MarkdownHeaderTextSplitter` keeping header contexts, fetches vectors from universal `get_embedding` factory block, wipes obsolete file points from Qdrant, and bulk uploads new vectors into collection asynchronously.
- Core Data Isolation Matrix:
  - Coding and software architectural vectors reside in the separate Qdrant collection (`db-dev`) and ingest documents from the isolated engineering Obsidian vault (`v-dev`).
  - Hobby assistance vectors (war history, aviation, scale modeling) reside in the separate Qdrant collection (`db-hobby`) and ingest documents from the isolated personal Obsidian vault (`v-hobby`).

### WSL MCP Server Bridge (`qdrant_mcp.py` inside WSL `~/.aider/`)
- Implements low-level **`mcp.server`** primitives communicating with Aider runtime via native stdio transport pipelines. Fully asynchronous (`asyncio` + `httpx`).
- Multi-Collection Mapping: Parameterized via `--collection` flag execution parameters to dynamically attach the corresponding stdio instance to a targeted vector space workspace.
- Explicit Identity Hydration Layer:
  - Exposes two distinct tool definitions: `search_knowledge_base` (general RAG context search) and `hydrate_project_context` (targeted systemic workspace profile loading).
  - Triggers on direct name greetings/markers (`Жорвис`, `Айдэр`, `Макс`) or explicit `[MARKER HYDRATE]` token presence at the opening line of a conversation. The model (Qwen) fires an automated `<tool_call>` passing the name token into the `context_key` slot.
  - If no name or role token is successfully extracted, the model immediately halts code generation and prompts the user to select an explicit teammate identity to initialize.
  - The script pulls explicit markdown playbooks directly from the vector storage, performing a live runtime **Context Hydration** injection to mutate model weights into the targeted persona rules without blowing context limits.

### Obsidian Ecosystem Constraints
- Model Inference Gateway: Powered by `BMO Chatbot` or `Text Generator` plugins. The engineering vault (`v-dev`) targets the LiteLLM host proxy loopback (`http://127.0.0.1:8000`) using model mapping to mimic `claude-sonnet-4-6`. The hobby vault (`v-hobby`) targets the local Ollama daemon directly (`http://127.0.0.1:11434`) to drive `Gemma-4 12B` prompts.
- Code Environment Sync: Enforces strict layout rendering and document sanitization via `Editor Syntax Highlight` (token coloring match for JS/TS/PowerShell/INI), `Advanced URI` (system-wide execution paths bridging IDE links), and `Linter` (strict markdown syntax verification on save).

