# Local AI Infrastructure & RAG Distribution

This project provides a hardened local AI orchestration environment, automated multi-zone deployment workflows, 
and context-isolated Real-Time Knowledge Indexing Pipelines (RAG) deployment. It is engineered as a Single Source of Truth (SSoT) 
to seamlessly route traffic between host windows tools and the WSL2 guest kernel.

## Setup

### Prerequisites
Before executing the initialization pipeline, verify your system meets the following engineering baselines. 
These components must be installed and configured manually prior to running the deployment suite:

1.  **Terminal & Execution Policy:**
  *   Modern cross-platform **PowerShell 7+ Core** (`pwsh.exe`) installed.
  *   Script execution policy unlocked. Run as Administrator:
      ```powershell
      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
      ```
2.  **Local Inference Engine:**
  *   **Ollama for Windows** installed and active.
  *   Ensure the daemon is accessible on default host loopback port `11434`.
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
1. Direct your IDE plugin API base URL endpoint to: `http://127.0.0`
2. Utilize the master authentication token: `sk-sithedition-2026`
3. Map the target model alias token to mimic `claude-4-6-sonnet` or `claude-4-8-sonnet`. 
The proxy automatically translates and hot-swaps payloads to the high-throughput local Qwen MoE Coder model.

## Available Scripts

In the project root directory, you can execute the following lifecycle deployment automation scripts:

### `.\infra_deploy.ps1`

Runs the master orchestration engine in sequential phases.
It validates target path permissions, maps lowercase persistent runtimes inside `~/.ai/`, invokes underlying secure 
subsystem scripts, downloads required model layers, provisions Docker containers, and registers self-healing background daemons.

### `.\pyparts_deploy.ps1`

Upgrades global python package managers on the host. Installs the localized `litellm[proxy]` routing platform and 
instantiates an isolated hidden virtual environment (`.venv`) nested inside `~/.ai/.qdrant/` packed with text splitting 
and filesystem tracking dependencies.

### `.\network_setup.ps1`

Rebuilds secure Windows Inbound Firewall rule policies. Re-maps volatile WSL guest interface network points using 
explicit `netsh interface portproxy` parameters targeting port `8000`, and dynamically injects the `win-host` loopback alias 
into the guest `/etc/hosts` registry.

### `.\models_deploy.ps1`

Parses active shortcode maps inside `~/.ai/.litellm/shortcodes.yml`. It queries the local Ollama instance, calculates 
weight delta gaps, and automatically pulls missing foundation layers before unlocking runtime dependent processes.

### `.\Qdrant\qdrant_deploy.ps1`

Deploys a persistent Qdrant Vector Engine container node mapped to host port `6333`. It blocks current execution threads 
until the `/healthz` network interface status returns a valid `200 OK` handshake, then registers two isolated Obsidian 
indexing watchers via Windows Task Scheduler.

### `.\Aider\aider_deploy.ps1`

Mounts and fires the `aider_deploy.sh` script inside the WSL2 guest shell environment. It resolves path tokens, 
installs core packages using `pipx`, and flattens and copies configuration assets from the active host environment into `~/.aider/`.

## RAG & Vector Space Topology

The Real-Time Knowledge Indexing Pipeline operates with strict data isolation. It prevents context leakage between 
programming specifications and general hobby workflows by using two distinct Obsidian vaults and two isolated Qdrant 
vector collections. Both pipelines share the lightweight **`nomic-embed-text`** model (dimension `768`) for resource-efficient 
text chunking via the `MarkdownHeaderTextSplitter` architecture.

### Development & Engineering Stream (`db-dev`)
*   **Host Obsidian Vault:** `E:\Vaults\v-dev`
*   **Target Qdrant Collection:** `db-dev`
*   **Intended Consumers:** Local `Qwen` models routing context through FastMCP server pipelines (`qdrant_mcp.py` operating inside 
WSL via standard stdio transport).
*   **Content Scope:** System contexts, personalized user profiles, coding standards, language-specific API maps, and enterprise 
architecture patterns.

### Personal Hobby Stream (`db-hobby`)
*   **Host Obsidian Vault:** `E:\Vaults\v-hobby`
*   **Target Qdrant Collection:** `db-hobby`
*   **Intended Consumers:** Local `Gemma-4 12B` queried directly inside the Obsidian environment via local chatbot plugins.
*   **Content Scope:** Military history, aviation records, and scale modeling databases.
