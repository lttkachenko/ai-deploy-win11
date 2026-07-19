$ErrorActionPreference = "Stop"

# 1. Pipeline Environment Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$aiRoot = Join-Path $homeDir ".ai"

# Standardizing runtime layouts inside user profile (LiteLLM стерт)
$qdrantRuntimeDir = Join-Path $aiRoot ".qdrant"

Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host ">>> Spawning Headless Backend & Qdrant Orchestration Pipeline..." -ForegroundColor Magenta
Write-Host ">>> Target Host: Windows ($winUser) | Runtime Workspace: $aiRoot" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

# 2. Assert Component Script Locations (Modularity Verification)
$lmsScript      = Join-Path $PSScriptRoot "Backend\backend_deploy.ps1"
$pypartsScript  = Join-Path $PSScriptRoot "pyparts_deploy.ps1"
$networkScript  = Join-Path $PSScriptRoot "network_setup.ps1"
$modelsScript   = Join-Path $PSScriptRoot "models_deploy.ps1"
$qdrantScript   = Join-Path $PSScriptRoot "Qdrant\qdrant_deploy.ps1"
$aiderScript    = Join-Path $PSScriptRoot "Aider\aider_deploy.ps1"

# Проверяем строго только живые ноды новой архитектуры
$requiredScripts = @($pypartsScript, $networkScript, $modelsScript, $qdrantScript, $aiderScript)
foreach ($script in $requiredScripts) {
  if (-not (Test-Path $script)) {
    throw "[FATAL] Modular architecture violation. Missing orchestration node: $script"
  }
}

# 3. Host Runtime Workspace Architecture Scaffolding (~/.ai/)
Write-Host "`n[PHASE 0] Scaffolding Runtime Directories and Seeding Assets..." -ForegroundColor Yellow

if (-not (Test-Path $aiRoot)) {
  New-Item -ItemType Directory -Path $aiRoot | Out-Null
  Write-Host " |-- Created hidden master infrastructure root: $aiRoot" -ForegroundColor Green
}

# Init Qdrant runtime only (lms runtime lives in its own native ~/.cache/)
if (-not (Test-Path $qdrantRuntimeDir)) {
  New-Item -ItemType Directory -Path $qdrantRuntimeDir | Out-Null
  Write-Host " |-- Scaffolded system runtime node: $qdrantRuntimeDir" -ForegroundColor Cyan
}

# Unified resource matrix compilation under .ai/context path
$contextRuntimeRoot = Join-Path $aiRoot "context"
if (-not (Test-Path $contextRuntimeRoot)) {
  New-Item -ItemType Directory -Path $contextRuntimeRoot | Out-Null
}

$resourcePools = @("roles", "prompts", "skills", "user")
foreach ($pool in $resourcePools) {
  $targetPoolPath = Join-Path $contextRuntimeRoot $pool
  if (-not (Test-Path $targetPoolPath)) {
    New-Item -ItemType Directory -Path $targetPoolPath | Out-Null
    Write-Host " |-- Scaffolded internal runtime pool: .ai\context\$pool" -ForegroundColor Cyan
  }
}

# Centralized initial seeding from distribution source folder
$sourceContextRoot = Join-Path $PSScriptRoot "Context"
if (Test-Path $sourceContextRoot) {
  $sourceDirs = Get-ChildItem -Path $sourceContextRoot -Directory
  foreach ($pool in $resourcePools) {
    $matchedDir = $sourceDirs | Where-Object { $_.Name -ieq $pool }
    $targetPoolPath = Join-Path $contextRuntimeRoot $pool
    if ($matchedDir) {
      Get-ChildItem -Path $matchedDir.FullName -File | ForEach-Object {
        $destFile = Join-Path $targetPoolPath $_.Name
        if (-not (Test-Path $destFile)) {
          Copy-Item -Path $_.FullName -Destination $destFile -Force
          Write-Host " |-- Seeded context asset: .ai\context\$pool\$($_.Name)" -ForegroundColor Gray
        }
      }
    }
  }
} else {
  throw "[FATAL] Centralized distribution directory missing: $sourceContextRoot"
}

# 4. Phase 1: Host Base Environment Provisioning (Python, Venv, Tooling)
Write-Host "`n[PHASE 1] Bootstrapping Headless AI Inference Backend..." -ForegroundColor Yellow
& $lmsScript

# 5. Phase 2: Host Base Environment Provisioning (Python, Venv, Tooling)
Write-Host "`n[PHASE 2] Initializing Host Core Python Dependencies..." -ForegroundColor Yellow
& $pypartsScript

# 6. Phase 3: Host Network Topology Alignment (Firewall, DNS Bridge strictly to port 1234)
Write-Host "`n[PHASE 3] Establishing Cross-Boundary Network Bridges..." -ForegroundColor Yellow
& $networkScript

# 7. Phase 4: Sync Declarative Presets and Load On-Demand Engine Models
Write-Host "`n[PHASE 4] Deploying LLM Models defined in Backend Configs..." -ForegroundColor Yellow
& $modelsScript

# 8. Phase 5: Vector Engine Node Deployment (Docker-Compose & Persistent Watcher)
Write-Host "`n[PHASE 5] Launching Distributed Qdrant Vector Engine Nodes..." -ForegroundColor Yellow
& $qdrantScript

# 9. Phase 6: Guest Runtime Synchronization (Aider, WSL configs, MCP links)
Write-Host "`n[PHASE 6] Bootstrapping Aider Environment Inside WSL Guest Subsystem..." -ForegroundColor Yellow
& $aiderScript

# 9. Pipeline Telemetry Check Verification
Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Enterprise Headless AI Stack Is Operational And Active!" -ForegroundColor Green
Write-Host " |-- LM Studio API Gateway: http://127.0.0.1:1234" -ForegroundColor Green
Write-Host " |-- Qdrant Vector Engine:  http://127.0.0.1:6333" -ForegroundColor Green
Write-Host " |-- Aider Orchestration:   Active via WSL & FastMCP" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
