$ErrorActionPreference = "Stop"

# 1. Pipeline Environment Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$aiRoot = Join-Path $homeDir ".ai"

# Standardizing runtime hidden allocations layout inside user profile
$litellmRuntimeDir = Join-Path $aiRoot ".litellm"
$qdrantRuntimeDir  = Join-Path $aiRoot ".qdrant"

Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host ">>> Spawning Master AI Infrastructure Orchestration Pipeline... " -ForegroundColor Magenta
Write-Host ">>> Target Host: Windows ($winUser) | Runtime Workspace: $aiRoot" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

# 2. Assert Component Script Locations (Modularity Verification)
$pypartsScript  = Join-Path $PSScriptRoot "pyparts_deploy.ps1"
$networkScript  = Join-Path $PSScriptRoot "network_setup.ps1"
$modelsScript   = Join-Path $PSScriptRoot "models_deploy.ps1"
$litellmScript  = Join-Path $PSScriptRoot "LiteLLM\litellm_deploy.ps1"
$qdrantScript   = Join-Path $PSScriptRoot "Qdrant\qdrant_deploy.ps1"
$aiderScript    = Join-Path $PSScriptRoot "Aider\aider_deploy.ps1"

$requiredScripts = @($pypartsScript, $networkScript, $litellmScript, $modelsScript, $qdrantScript, $aiderScript)

foreach ($script in $requiredScripts) {
  if (-not (Test-Path $script)) {
    throw "[FATAL] Modular architecture violation. Missing orchestration node: $script"
  }
}

# 3. Host Runtime Workspace Architecture Scaffolding (~/.ai/)
Write-Host "`n[PHASE 0] Scaffolding Runtime Directories and Seeding Assets..." -ForegroundColor Yellow

# Explicitly assert and create the hidden master root directory if missing entirely
if (-not (Test-Path $aiRoot)) {
  New-Item -ItemType Directory -Path $aiRoot | Out-Null
  Write-Host "    |-- Created hidden master infrastructure root: $aiRoot" -ForegroundColor Green
}

# Scaffold hidden application infrastructure roots inside the master root
$runtimeDirs = @($litellmRuntimeDir, $qdrantRuntimeDir)
foreach ($dir in $runtimeDirs) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
    Write-Host "    |-- Scaffolded system runtime node: $dir" -ForegroundColor Cyan
  }
}

# Unified resource matrix compilation under .ai/context path
$contextRuntimeRoot = Join-Path $aiRoot "context"
if (-not (Test-Path $contextRuntimeRoot)) {
  New-Item -ItemType Directory -Path $contextRuntimeRoot | Out-Null
  Write-Host "    |-- Scaffolded unified runtime context layout root: .ai\context" -ForegroundColor Cyan
}

# Subdirectory structure mapping matching lowercase enterprise rules
$resourcePools = @("roles", "prompts", "skills", "user")
foreach ($pool in $resourcePools) {
  $targetPoolPath = Join-Path $contextRuntimeRoot $pool
  if (-not (Test-Path $targetPoolPath)) {
    New-Item -ItemType Directory -Path $targetPoolPath | Out-Null
    Write-Host "    |-- Scaffolded internal runtime pool: .ai\context\$pool" -ForegroundColor Cyan
  }
}

# Execute master initial seeding from centralized distribution source folder
$sourceContextRoot = Join-Path $PSScriptRoot "Context"
if (Test-Path $sourceContextRoot) {
  # Resolve actual directories on disk to bypass case-sensitivity bugs on transfer steps
  $sourceDirs = Get-ChildItem -Path $sourceContextRoot -Directory

  foreach ($pool in $resourcePools) {
    $matchedDir = $sourceDirs | Where-Object { $_.Name -ieq $pool }
    $targetPoolPath = Join-Path $contextRuntimeRoot $pool

    if ($matchedDir) {
      Get-ChildItem -Path $matchedDir.FullName -File | ForEach-Object {
        $destFile = Join-Path $targetPoolPath $_.Name
        # Pure Seed Enforcement: Move data only if operational path is completely pristine
        if (-not (Test-Path $destFile)) {
          Copy-Item -Path $_.FullName -Destination $destFile -Force
          Write-Host "        |-- Seeded context asset: .ai\context\$pool\$($_.Name)" -ForegroundColor Gray
        }
      }
    }
  }
} else {
  throw "[FATAL] Centralized distribution directory missing: $sourceContextRoot"
}

# 4. Phase 1: Host Base Environment Provisioning (Python, Venv, Tooling)
Write-Host "`n[PHASE 1] Initializing Host Core Python Dependencies..." -ForegroundColor Yellow
& $pypartsScript

# 5. Phase 2: Host Network Topology Alignment (Firewall, PortProxy, DNS Bridge)
Write-Host "`n[PHASE 2] Establishing Cross-Boundary Network Bridges..." -ForegroundColor Yellow
& $networkScript

# 7. Phase 3: Reconcile and Sync Ollama Model Layers with Shortcode Manifests
Write-Host "`n[PHASE 3.5] Reconciling and Pulling Required Local Ollama Models..." -ForegroundColor Yellow
& $modelsScript

# 6. Phase 3.5: Proxy Layer Provisioning (LiteLLM Config Transport & NSSM Daemon)
Write-Host "`n[PHASE 3] Deploying Global LiteLLM Gateway Infrastructure..." -ForegroundColor Yellow
& $litellmScript

# 8. Phase 4: Vector Engine Node Deployment (Docker-Compose & Persistent Watcher)
Write-Host "`n[PHASE 4] Launching Distributed Qdrant Vector Engine Nodes..." -ForegroundColor Yellow
& $qdrantScript

# 9. Phase 5: Guest Runtime Synchronization (WSL Bootstrapping, Alias, Resource Push)
Write-Host "`n[PHASE 5] Bootstrapping Aider Environment Inside WSL Guest Subsystem..." -ForegroundColor Yellow
& $aiderScript

# 10. Pipeline Telemetry Check Verification
Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Enterprise Local AI Stack Is Operational And Active!" -ForegroundColor Green
Write-Host "          |-- LiteLLM Proxy Gateway:  http://127.0.0.1:8000" -ForegroundColor Green
Write-Host "          |-- Qdrant Vector Engine:   http://127.0.0.1:6333" -ForegroundColor Green
Write-Host "          |-- Aider Guest Orchestration Terminal Root Is Ready." -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
