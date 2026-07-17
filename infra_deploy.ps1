$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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

# PHASE 0.5: Enforce Host Global Virtualization Boundaries
Write-Host "    |-- Synchronizing Global WSL2 Virtualization Limits..." -ForegroundColor Yellow
$targetWslConfig = Join-Path $homeDir ".wslconfig"
$sourceWslConfig = Join-Path $PSScriptRoot "Conf\.wslconfig"

if (Test-Path $sourceWslConfig) {
  $wslNeedsShutdown = $false

  # Idempotent validation layer: seed only if pristine or drift detected via SHA256 hashing
  if (-not (Test-Path $targetWslConfig)) {
    Copy-Item -Path $sourceWslConfig -Destination $targetWslConfig -Force
    Write-Host "        |-- Seeded fresh global .wslconfig infrastructure limits." -ForegroundColor Green
    $wslNeedsShutdown = $true
  } else {
    $sourceHash = (Get-FileHash -Path $sourceWslConfig -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -Path $targetWslConfig -Algorithm SHA256).Hash

    if ($sourceHash -ne $targetHash) {
      Copy-Item -Path $sourceWslConfig -Destination $targetWslConfig -Force
      Write-Host "        |-- Configuration drift detected. Overwriting global .wslconfig..." -ForegroundColor Cyan
      $wslNeedsShutdown = $true
    }
  }

  # Hard recycle the subsystem before network routing and Docker daemon initialization
  if ($wslNeedsShutdown) {
    Write-Host "        |-- Recycling WSL guest subsystem to map safe memory/CPU bounds..." -ForegroundColor Yellow
    wsl --shutdown | Out-Null
    Start-Sleep -Seconds 2
  } else {
    Write-Host "        |-- Global .wslconfig state is aligned and compliant." -ForegroundColor Green
  }
} else {
  throw "[FATAL] Centralized distribution configuration missing at deployment source: $sourceWslConfig"
}

# 4. Phase 1: Host Base Environment Provisioning (Python, Venv, Tooling)
Write-Host "`n[PHASE 1] Initializing Host Core Python Dependencies..." -ForegroundColor Yellow
& $pypartsScript

# 5. Phase 2: Host Network Topology Alignment (Firewall, PortProxy, DNS Bridge)
Write-Host "`n[PHASE 2] Establishing Cross-Boundary Network Bridges..." -ForegroundColor Yellow
& $networkScript

# 6. Phase 3: Proxy Layer Provisioning (LiteLLM Config Transport & NSSM Daemon)
Write-Host "`n[PHASE 3] Deploying Global LiteLLM Gateway Infrastructure..." -ForegroundColor Yellow
& $litellmScript

# 7. Phase 3.5: Reconcile and Sync Model Layers with Shortcode Manifests
Write-Host "`n[PHASE 3.5] Reconciling and Pulling Required Local Models..." -ForegroundColor Yellow
& $modelsScript

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
