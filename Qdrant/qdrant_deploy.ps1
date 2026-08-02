# .\Qdrant\qdrant_deploy.ps1 - Container Lifecycle Architecture Pipeline
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

# --- Phase 1: Environment Discovery & Scaffolding ---
Write-Host '>>> Scaffolding host workspace and persistence cache layouts...' -ForegroundColor Cyan

$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$aiRoot = Join-Path $homeDir '.ai'
$mcpRuntimeDir = Join-Path $aiRoot 'venv\mcp'
$confFolder = Join-Path $aiRoot 'conf'
$mcpConfigPath = Join-Path $confFolder 'mcp.conf.yml'
$binFolder = Join-Path $aiRoot 'bin'

# Dynamic fallback discovery: check if matrix template is inside local distribution workspace (DOS-9)
$sourceConfig = Join-Path $PSScriptRoot 'mcp.conf.yml'
if (-not (Test-Path $sourceConfig)) {
  $sourceConfig = Join-Path $PSScriptRoot '..\conf\mcp.conf.yml'
}

# Auto-delivery injection loop if runtime slot configuration is missing
if (-not (Test-Path $mcpConfigPath)) {
  if (Test-Path $sourceConfig) {
    if (-not (Test-Path $confFolder)) { New-Item -ItemType Directory -Path $confFolder | Out-Null }
    Copy-Item -Path $sourceConfig -Destination $mcpConfigPath -Force
    Write-Host "  |-- [AUTO-FIX] Transported missing matrix specification to configuration slot: $mcpConfigPath" -ForegroundColor Yellow
  } else {
    throw "[FATAL] Centralized RAG infrastructure configuration spec missing at production slot: $mcpConfigPath"
  }
}

# --- Phase 2: Launch Containerized Qdrant Engine ---
Write-Host '>>> Instantiating Containerized Qdrant Vector Architecture...' -ForegroundColor Cyan

$dockerCheck = docker compose version 2>$null
if (-not $dockerCheck) {
  throw '[FATAL] Docker Compose CLI interface not identified within current system environment.'
}

Push-Location -Path $PSScriptRoot
try {
  docker compose up -d
}
finally {
  Pop-Location
}

# --- Phase 3: HTTP Health Interface Verification Loop ---
$configContent = Get-Content -Path $mcpConfigPath -Raw

$qdrantPort = 8093
if ($configContent -match 'qdrant_rest_port:\s*(\d+)') {
  if ($null -ne $Matches -and $Matches.Count -ge 2) {
    $qdrantPort = [int]$Matches[1]
  }
}

$qdrantApiKey = 'dev-srv-key-default'
if ($configContent -match 'qdrant-srv:[\s\S]*?api_key:\s*[''"]?([^\''"\s\n]*)[''"]?') {
  if ($null -ne $Matches -and $Matches.Count -ge 2) {
    $qdrantApiKey = $Matches[1].Trim()
  }
}

$HealthEndpoint = "http://127.0.0.1:$qdrantPort/readyz"
$MaxAttempts = 12
$Attempt = 1
$Connected = $false
$Headers = @{ 'api-key' = $qdrantApiKey }

Write-Host ">>> Initiating verification handshakes targeting vector engine interface at port $qdrantPort..." -ForegroundColor Yellow

while (-not $Connected -and $Attempt -le $MaxAttempts) {
  try {
    $Response = Invoke-WebRequest -Uri $HealthEndpoint -Method Get -Headers $Headers -TimeoutSec 2 -UseBasicParsing
    if ($Response.StatusCode -eq 200) {
      $Connected = $true
      Write-Host '[SUCCESS] Vector engine node is online. Health status verified.' -ForegroundColor Green
    }
  } catch {
    Write-Host "  |-- [Attempt $Attempt/$MaxAttempts] Cluster initializing. Retrying context hook in 5s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    $Attempt++
  }
}

if (-not $Connected) {
  throw "[FATAL] Handshake verification failed. Qdrant cluster unready at endpoint: $HealthEndpoint"
}

# --- Phase 4: Sub-Chain Execution Integration & Utility Migration ---
$sourceHealthz = Join-Path $PSScriptRoot 'qdrant_healthz.ps1'
$targetHealthz = Join-Path $binFolder 'qdrant_healthz.ps1'

if (Test-Path $sourceHealthz) {
  if (-not (Test-Path $binFolder)) { New-Item -ItemType Directory -Path $binFolder | Out-Null }
  Copy-Item -Path $sourceHealthz -Destination $targetHealthz -Force
  Write-Host '  |-- Migrated qdrant_healthz.ps1 utility engine to runtime production bin.' -ForegroundColor Green
} else {
  Write-Warning "[WARN] Diagnostic source utility 'qdrant_healthz.ps1' not identified inside current script path."
}

$mcpDeployScript = Join-Path $PSScriptRoot 'mcp_deploy.ps1'
if (-not (Test-Path $mcpDeployScript)) {
  throw "[FATAL] Decoupled downstream deployment script missing: $mcpDeployScript"
}

Write-Host '>>> Container lifecycle active. Transferring execution thread to Context Layer...' -ForegroundColor Cyan
& $mcpDeployScript
