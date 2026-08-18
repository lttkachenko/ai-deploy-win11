<#
.SYNOPSIS
    Idempotent Qdrant Vector Store deployment pipeline.
.DESCRIPTION
    Validates Docker engine status, checks container existence/state (absent/stopped/running), provisions via compose if needed, and runs health diagnostics.
.EXAMPLE
    .\qdrant_deploy.ps1
.NOTES
    Requires: Docker Desktop running, mcp.conf.yml present in workspace or ~/.ai/conf/.
#>

$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\utils\Check-QdrantHealth.ps1" -Force | Out-Null

Write-Host '>>> Scaffolding workspace layouts and configs...' -ForegroundColor Cyan

$aiRoot = Join-Path ([System.Environment]::GetFolderPath('UserProfile')) '.ai'
$confFolder = Join-Path $aiRoot 'conf'
$binFolder = Join-Path $aiRoot 'bin'

# Define Qdrant API port (aligned with DOS-10 routing matrix)
$qdrantPort = 8093
$HealthEndpoint = "http://127.0.0.1:$qdrantPort/readyz"

# Sync configuration matrix (auth/api-key layer for Store Engine)
$mcpConfigPath = Join-Path $confFolder 'mcp.conf.yml'
$sourceConfig = Join-Path $PSScriptRoot 'mcp.conf.yml'
if (-not (Test-Path $sourceConfig)) { $sourceConfig = Join-Path $PSScriptRoot '..\conf\mcp.conf.yml' }

if (Test-Path $sourceConfig) {
  if (-not (Test-Path $confFolder)) { New-Item -ItemType Directory -Path $confFolder | Out-Null }
  Copy-Item -Path $sourceConfig -Destination $mcpConfigPath -Force
  Write-Host "  |-- Synchronized active matrix profile to slot: $mcpConfigPath" -ForegroundColor Gray
} else {
  if (-not (Test-Path $mcpConfigPath)) { throw '[FATAL] Centralized RAG configuration manifest missing from both workspace and template store.' }
}

# --- Phase 1: Docker Engine Validation ---
Write-Host '>>> Validating Docker engine status...' -ForegroundColor Yellow
try {
  docker info > $null 2>&1
  if ($LASTEXITCODE -ne 0) { throw '[FATAL] Docker engine is not running.' }
} catch {
  throw '[FATAL] Docker engine is not running.'
}

# --- Phase 2: Container State Check & Provisioning ---
Write-Host '>>> Checking Qdrant container state...' -ForegroundColor Yellow
$containerStatus = docker ps -a --filter name=qdrant --format '{{.Status}}' 2>$null

if (-not $containerStatus) {
  Write-Host '  |-- Container absent. Provisioning via Docker Compose...' -ForegroundColor Gray
  docker compose -f "$PSScriptRoot\docker-compose.yml" up -d --remove-orphans | Out-Null
  Write-Host "  |-- Vector Store container launched on port $qdrantPort" -ForegroundColor Green
} elseif ($containerStatus -match 'Exited') {
  Write-Host '  |-- Container present but stopped. Starting...' -ForegroundColor Gray
  docker start qdrant
  if ($LASTEXITCODE -ne 0) { throw '[FATAL] Qdrant container failed to start.' }
  Write-Host "  |-- Vector Store container resumed on port $qdrantPort" -ForegroundColor Green
} else {
  Write-Host '  |-- Container is up and running. Skipping compose provisioning.' -ForegroundColor Gray
}

# --- Phase 3: Health Verification Utility ---
Write-Host '>>> Running pre-flight health verification...' -ForegroundColor Yellow
if (Check-QdrantHealth) {
  Write-Host '>>> [SUCCESS] Qdrant Store installation verified successfully.' -ForegroundColor Green
} else {
  throw '[FATAL] Qdrant Store installation failed health check.'
}

Write-Host '>>> Vector Store Engine deployment complete. Passing execution...' -ForegroundColor Gray
