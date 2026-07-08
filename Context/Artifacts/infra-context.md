# SYSTEM ARCHITECTURE CONTEXT: LOCAL AI DEVOPS & RAG INFRASTRUCTURE (REVISED)

## 1. ROLES & PERSONAS
### User (Team Lead - JS/TS Full Stack SSE)
- 25+ years in production, 20+ years in Enterprise. Expert in JS/TS ecosystem (Node.js, NestJS, React, Next.js). Competent in DevOps.
- Goal: Integrating local LLM orchestration and automated RAG pipelines into daily dev workflow.
- Rules: Zero explanations of syntax/patterns, unless it is requested directly by the User. Dry, direct, professional peer-to-peer communication.
- **User Role and Profile** are defined here: [[User-EN]], [[User-RU]]
- **Coding Rules and Standards** are defined here: [[Coding-Rules]]

### AI Assistant (Senior DevOps Engineer - Infrastructure Architect)
- Chat nickname is Jorwis - given in honor of the real-life DevOps Team Lead from the Users production team which name is Georgy. Georgy said he is Jarvis (from Iron Man) in flesh.
- 15+ years in production DevOps, focused on local/hybrid AI infrastructure since 2021.
- Style: Cynical, highly pragmatic, zero corporate fluff, technically precise, Slack-chat tone.
- Constraints: Code/configs first. Sentences under 10 words. Punchy lists. Group clarifying questions at the very end.
- **AI Assistant Role** is defined here: [[AI-Devops-EN]], [[AI-Devops-RU]]

### Guest AI (Aider — Lead Automation QA Engineer)
- Chat nickname is Aider - a great Tatar name given in honor of real-life AQA Team Lead  from the Users production team.
- 15+ years in production QA and AQA.
- Runtime agent inside WSL2. Focuses on covering project code with automatic Unit and Integration tests including E2E. Uses JS/TS oriented test suites (Jest, Playwright). Uses Qwen3.6-coder directly via host port proxy.
- **Guest AI Role** is defined here: [[AI-AQA-EN]], [[AI-AQA-RU]]

---

## 2. REPOSITORY & RUNTIME WORKSPACE TOPOLOGY
Distribution Package Root: Any folder into which it is unpacked by the User.
Distribution Package Root is set to ~d\ in this document for explanatory purposes only.

### Source Directory Layout
📂 ~d\
├── 📂 Aider/
│   ├── 📄 aider_deploy.ps1      # Bootstraps WSL, fixes config path tokens, pushes context pools to guest
│   ├── 📄 aider_deploy.sh       # Guest shell installer: provisions pipx, packages, and environment folders
│   ├── 📄 aider_run.sh          # Guest CLI orchestrator wrapper: executes dynamic layered prompt stitching
│   └── 📄 config.yml            # Guest configuration blueprint featuring declarative MCP server bindings
├── 📂 Context/                  # Single Source of Truth for static operational assets (PascalCase folder)
│   ├── 📂 Artifacts/            # DevOps architectural and scripting sessions summary documents
│   ├── 📂 Insights/             # Immutable baseline usable insights documents for prompt mixins
│   ├── 📂 Prompts/              # Immutable baseline prompt templates and task scenario documents
│   ├── 📂 Roles/                # Hardened engineering system personas (AQA and DevOps profiles)
│   ├── 📂 Skills/               # Flat technology reference architectures, coding specs, and logic rules
│   └── 📂 User/                 # Core developer bio profiles defining background and execution limits
├── 📂 LiteLLM/
│   ├── 📄 config.yml            # Gateway configuration manifest with declarative shortcuts include clause
│   ├── 📄 litellm_deploy.ps1    # Deploys configs to ~/.ai/.litellm/ and provisions Windows service via NSSM
│   └── 📄 shortcodes.yml        # Isolated definitions of core system prompts (Anthropic military short codes)
├── 📂 Qdrant/
│   ├── 📄 docker_compose.yml    # Native Docker Compose manifest hosting persistent Qdrant engine nodes
│   ├── 📄 qdrant_deploy.ps1     # Fires up container, validates HTTP healthz, locks watcher to Task Scheduler
│   ├── 📄 qdrant_mcp.py         # Guest FastMCP server script translating stdio queries to vector search calls
│   └── 📄 qdrant-watcher.py     # Self-healing host watchdog agent indexing active Obsidian Vault changes
├── 📄 infra_deploy.ps1          # Unified master orchestration engine routing all deployment lifecycle phases
├── 📄 models_deploy.ps1         # Parser analyzing shortcodes dependencies to pull missing Ollama model layers
├── 📄 network_setup.ps1         # Rebuilds firewall rule policies, netsh portproxy maps, and WSL DNS inversion
└── 📄 pyparts_deploy.ps1        # Upgrades global pip, maps litellm proxy package, builds operational .venv layer


Production User Profile Runtime Root: `~/.ai/` (`C:\Users\<User>\.ai\`)

### Destination Directory Layout
📂 ~/.ai/
├── 📂 .litellm/          # Mapped configuration file layer, shortcodes, and daemon logging targets
├── 📂 .qdrant/           # Persistent docker volumes, isolated venv sandbox, and vault monitoring script
└── 📂 context/           # Mapped active resource pool deployment root
├── 📂 roles/         # AI Persona definition documents (AI-AQA-RU/EN, AI-Devops-RU/EN)
├── 📂 prompts/       # Immediate session task instruction execution files
├── 📂 skills/        # Reference engineering standards and specification notes
└── 📂 user/          # Core personalized profile constraints (User-RU.md, User-EN.md)

---

## 3. CORE INFRASTRUCTURE CONFIGURATIONS

### LiteLLM `shortcodes.yml`
Mapped to `ollama/qwen2.5-coder:7b` (as claude-3-5-sonnet) and `ollama/gemma4:12b` (as claude-instant-1). Context length forced to 32768 tokens. System prompt markers hardcoded (`[MARKER L99]`, `[MARKER ULTRATHINK]`).

### LiteLLM `config.yml`
Includes relative mapping to `shortcodes.yml`. Master key: `sk-sithedition-2026`. Service runs on Windows Host via NSSM daemon on `127.0.0.1:8000`. Log streams routed inside hidden runtime path `~/.ai/.litellm/`.

### Aider `config.yml` (Inside WSL: `~/.config/aider/config.yml`)
Routes execution streams directly to `http://win-host:8000/v1`. Integrates python-driven MCP server module dynamically mapped to host windows workspace targets.

---

## 4. MODULAR POWERSHELL DEPLOYMENT SCRIPTS

### 1. `infra_deploy.ps1` (Master Orchestrator / Root Point)
- PHASE 0: Securely builds `~/.ai/`, `~/.ai/.litellm/`, and `~/.ai/.qdrant/`. Spawns centralized `~/.ai/context/` directory shell, mappings lowercase subfolders (`roles`, `prompts`, etc.), and seeds asset blocks from source `Distr\Context\`.
- PHASE 1-5: Sequential routing control engine: `pyparts_deploy.ps1` -> `network_setup.ps1` -> `LiteLLM\litellm_deploy.ps1` -> `models_deploy.ps1` -> `Qdrant\qdrant_deploy.ps1` -> `Aider\aider_deploy.ps1`.

### 2. `pyparts_deploy.ps1` (Python & Venv Handler / Root Point)
- Enforces host package upgrades, installs global `litellm[proxy]`.
- Provisions hidden isolated `.venv` sandbox within `~/.ai/.qdrant/`. Installs functional dependency matrix (`watchdog`, `qdrant-client`, `langchain-text-splitters`, `requests`). Pulls indexing agent asset file from source.

### 3. `network_setup.ps1` (Security & Routing Bridge / Root Point)
- Sets Inbound Windows Firewall permit status for port 8000. Wipes and maps native routing parameters via `netsh interface portproxy` targeting volatile WSL guest interface IP.
- Enforces inverse DNS rules inside WSL guest subsystem config files, linking alias token `win-host` to current host gateway via shell bootstrap triggers.

### 4. `models_deploy.ps1` (Ollama Warmup Pipeline / Root Point)
- Evaluates active dependency metrics inside `~/.ai/.litellm/shortcodes.yml` using regex patterns.
- Interrogates host Ollama API, calculates version drift delta gaps, and locks execution flows to pull missing weights automatically before launching data tracking engines.

### 5. `Qdrant\qdrant_deploy.ps1` (Vector Engine Node / Qdrant Folder)
- Instantiates Qdrant container architecture via `docker-compose.yml` (port 6333). Blocks till HTTP `/healthz` check route verification passes.
- Provisions automated persistence layer by nesting background tracking tasks inside Windows Task Scheduler (`AI-Qdrant-Obsidian-Watcher`) triggered instantly At LogOn under current active user context, bypassing NSSM/permission conflicts.

### 6. `Aider\aider_deploy.ps1` (Guest Environment Sync / Aider Folder)
- Mounts and runs `aider_deploy.sh` inside WSL. Configures global `config.yml` dependencies, updating path structure variables dynamically by wiping `wsl_placeholder` tokens.
- Flattens and synchronization resource payloads directly from active environment host paths `~/.ai/context/*` over to destination guest subsystem paths `~/.aider/*`.

---

## 5. REAL-TIME KNOWLEDGE INDEXING PIPELINE (RAG)

### Windows Watcher (`qdrant_watcher.py` inside `~/.ai/.qdrant/`)
- Relies on `watchdog` library core. Tracks real-time folder modifications inside local Obsidian Vault workspace on host.
- Runtime Arguments: Parameterized via `argparse` to accept `--vault`, `--collection`, and `--port` flags dynamically, allowing infinite isolated background instances to run concurrently.
- Self-Stabilizing feature: Contains infinite loop checking `http://127.0.0` every 15 seconds on startup. Blocks execution until Docker Desktop/Qdrant container comes alive after system boot to prevent network spam.
- Chunking & Embedding: Strips YAML frontmatter, resolves recursive `![[transclusions]]` graph layers, flattens internal `[[wiki-links]]`, splits text structurally via `MarkdownHeaderTextSplitter` keeping header contexts, fetches vectors from local Ollama endpoint (`/api/embed` via `nomic-embed-text`), wipes obsolete file points from Qdrant, and bulk uploads new vectors into collection.
- Core Data Isolation Matrix:
  - Coding and software architectural vectors reside in the separate Qdrant collection (`db-dev`) and ingest documents from the isolated engineering Obsidian vault (`v-dev`).
  - Hobby assistance vectors (war history, aviation, scale modeling) reside in the separate Qdrant collection (`db-hobby`) and ingest documents from the isolated personal Obsidian vault (`v-hobby`).

### WSL MCP Server Bridge (`qdrant_mcp.py` inside WSL `~/.aider/`)
- Implements `FastMCP` framework communicating with Aider runtime via native stdio transport pipelines.
- Multi-Collection Mapping: Parameterized via `--collection` flag execution parameters to dynamically attach the corresponding stdio instance to a targeted vector space workspace.
- Operational Mechanics: Exposes `search_knowledge_base` tool to LLM (Qwen). Converts query to embedding vector via Ollama gateway, executes cosine similarity search in host Qdrant database via `http://win-host:6333`, formats output blocks with context source references, and feeds relevant chunks directly into prompt stitching layer.

### Obsidian Ecosystem Constraints
- Model Inference Gateway: Powered by `BMO Chatbot` or `Text Generator` plugins. The engineering vault (`v-dev`) targets the LiteLLM host proxy loopback (`http://127.0.0`) using model mapping to mimic `claude-3-5-sonnet`. The hobby vault (`v-hobby`) targets the local Ollama daemon directly (`http://127.0.0.1:11434`) to drive `Gemma-4 12B` prompts.
- Code Environment Sync: Enforces strict layout rendering and document sanitization via `Editor Syntax Highlight` (token coloring match for JS/TS/PowerShell), `Advanced URI` (system-wide execution paths bridging IDE links), and `Linter` (strict markdown syntax verification on save).

