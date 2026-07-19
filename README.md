# Local AI Infrastructure & RAG Distribution

This project provides a hardened local AI orchestration environment, automated multi-zone deployment workflows,
and context-isolated Async Real-Time Knowledge Indexing Pipelines (RAG) deployment. It is engineered as a Single Source of Truth (SSoT)
to seamlessly route traffic between host windows tools, inference engines, and the WSL2 guest kernel.

## Setup

### Prerequisites
Before executing the initialization pipeline, verify your system meets the following engineering baselines.
These components must be installed manually prior to running the deployment suite:

1.  **Terminal & Execution Policy:**
*   Modern cross-platform **PowerShell 7+ Core** (`pwsh.exe`) installed.
*   Script execution policy unlocked. Run as Administrator:
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
    ```
2.  **Local Inference Engine:**
*   **Ollama for Windows** (listening on default host loopback port `11434`) OR **LM Studio/Llama.cpp Server** toolchain installed.
*   If utilizing LM Studio, ensure the headless `llmster` background daemon and `lms` CLI toolchain are accessible.
3.  **Container Sandbox:**
*   **Docker Desktop for Windows** installed and running.
*   WSL2 integration enabled (`Settings -> Resources -> WSL integration`).
4.  **Guest Subsystem:**
*   **WSL2** instance configured with a modern Linux distribution (Ubuntu 22.04 LTS or 24.04 LTS recommended).
*   Ensure `systemd` is enabled inside the guest (`/etc/wsl.conf` containing `[boot]\nsystemd=true`).

---

### External IDE Integration
The local infrastructure is explicitly optimized for JetBrains PhpStorm / WebStorm.
To inject local LLMs into your IDE via `Continue` or `Claude` plugins:
1. Direct your IDE plugin API base URL endpoint to: `http://127.0.0.1:8000`
2. Utilize the master authentication token: `sk-sithedition-2026`
3. Map the target model alias token to mimic `claude-sonnet-4-6` or `claude-opus-4-8`.
   The LiteLLM proxy automatically translates and hot-swaps payloads to the high-throughput local Qwen MoE Coder models.

## Available Scripts

In the project root directory, you can execute the following lifecycle deployment automation scripts:

### `.\infra_deploy.ps1`

Runs the master orchestration engine in sequential phases.
It validates target path permissions, scaffolds lowercase persistent runtimes inside `~/.ai/`, and critically enforces strict global virtualization memory bounds (`16GB` RAM / 8 Cores allocation) by injecting an idempotent `.wslconfig` layout prior to bootstrapping any network routing or Docker daemons.

### `.\pyparts_deploy.ps1`

Upgrades global python package managers on the host. Installs the localized `litellm[proxy]` routing platform and instantiates an isolated hidden virtual environment (`.venv`) nested inside `~/.ai/.qdrant/` packed with locked enterprise async dependencies (`watchfiles==0.24.0`, `httpx==0.27.0`, `mcp==1.2.1`). It copies both `qdrant_watcher.py` and `libs.py` into the user operational workspace area.

### `.\network_setup.ps1`

Rebuilds secure Windows Inbound Firewall rule policies. Re-maps volatile WSL guest interface network points using explicit `netsh interface portproxy` parameters targeting ports `8000` (LiteLLM) and `6333` (Qdrant), and dynamically injects the `win-host` loopback alias into the guest `/etc/hosts` registry for inverse boundary traversal.

### `.\models_deploy.ps1`

Automated polymorphic model provisioning pipeline. It scans active network ports to dynamically detect whether Ollama or LM Studio (`lms`) is active. For Ollama, it applies environment registry isolation constraints to block Shared System Memory allocations. For LM Studio, it automatically initializes the headless `llmster` background daemon, streams required `.gguf` model weights using the native multithreaded engine, and force-loads the selected assets into memory.

### `.\Qdrant\qdrant_deploy.ps1`

Deploys a persistent Qdrant Vector Engine container node. To preserve memory safety under the strict 16GB WSL limit, the container is locked to a 3GB ceiling with hardware limitations (`cpus: 2`), forcing a complete memory-mapped vector translation threshold (`QDRANT__VECTORS__MEMMAP_THRESHOLD=0`) to load layers directly from the fast NVMe disk. Blocks execution until a successful `200 OK` `/healthz` handshake is achieved, then registers the background file-system trackers via Windows Task Scheduler.

### `.\Aider\aider_deploy.ps1`

Mounts and fires the `aider_deploy.sh` script inside the WSL2 guest shell environment. It resolves path tokens, installs core packages using `pipx`, and flattens and copies configuration assets from the active host environment into `~/.aider/`.

## RAG & Vector Space Topology

The Real-Time Knowledge Indexing Pipeline operates with strict data isolation on a fully non-blocking asynchronous architecture (`asyncio` + `AsyncQdrantClient`). It prevents context leakage between enterprise engineering architectures and personal hobby workflows by using two distinct Obsidian vaults and two isolated Qdrant vector collections.
To secure your host's strict 6GB VRAM allocation threshold, both pipelines bypass external inference dependencies (purging Ollama/LiteLLM HTTP blocks) and leverage the unified `get_embedding` factory engine inside `libs.py` executing **strictly on the host CPU boundary** utilizing the lightweight `nomic-embed-text-v1.5` model (dimension `768`) over `MarkdownHeaderTextSplitter` structures. All file parsing, Markdown splitting, and tensor extractions are entirely offloaded from the main event loop thread via `asyncio.to_thread()` allocations to guarantee fail-soft execution boundaries.
The pipeline complies with native Nomic specifications by forcing `search_document: ` prefixes for filesystem ingestion loops and `search_query: ` prefixes for FastMCP query tools.

### Development & Engineering Stream (db-dev)
* **Host Obsidian Vault Path:** `~\Vaults\v-dev`
* **Target Qdrant Collection ID:** `db-dev`
* **File Watcher Loop Engine:** Asynchronous, Rust-backed `watchfiles` worker monitoring real-time filesystem mutations, recursive Wiki-note transclusions `![[Note]]`, and metadata frontmatter stripping.
* **Context Delivery Protocol:** Persistent host-level `qdrant_mcp.py` network service managed via `NSSM`, exposing an `SSE HTTP` transport stream on port 8000 for Aider (WSL), Cline (VS Code), and JetBrains IDE agents.
* **Content Scope:** System devops contexts, personalized user profiles, coding standards, corporate architecture blueprints, language-specific API maps, and enterprise rules.

### Personal Hobby Stream (db-hobby)
* **Host Obsidian Vault Path:** `~\Vaults\v-hobby`
* **Target Qdrant Collection ID:** `db-hobby`
* **File Watcher Loop Engine:** Independent async `watchfiles` worker instance tracking mutations concurrently inside the hobby directory boundary.
* **Context Delivery Protocol:** Localized `Gemma-4 12B` and `Qwen` instances querying the `127.0.0.1:6333` Qdrant REST API node directly via internal Obsidian chatbot plugins or local client extensions.
* **Content Scope:** Military history datasets, aviation records, engineering schematics, and scale modeling databases.

