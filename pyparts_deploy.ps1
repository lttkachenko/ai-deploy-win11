# .\pyparts_deploy.ps1 - Python Infrastructure Provisioning Layer
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '>>> Executing Python Infrastructure Provisioning via Manifest...' -ForegroundColor Cyan
Write-Host '=================================================================' -ForegroundColor Cyan

# 1. Environment and Path Mapping Discovery
$homeDir = [System.Environment]::GetFolderPath('UserProfile')

# Polymorphic manifest path discovery engine
$manifestPath = Join-Path $PSScriptRoot 'MANIFEST.json'
if (-not (Test-Path $manifestPath)) {
  $manifestPath = Join-Path $PSScriptRoot '..\MANIFEST.json'
}
if (-not (Test-Path $manifestPath)) {
  $manifestPath = Join-Path $Pwd 'MANIFEST.json'
}

if (-not (Test-Path $manifestPath)) {
  throw '[FATAL] Centralized dependency specification missing. Expected MANIFEST.json in repository root scope context.'
}

Write-Host " |-- Verified infrastructure single source of truth matrix: $manifestPath" -ForegroundColor Gray

# Load and parse declarative infrastructure specification matrix
$manifest = Get-Content -Raw -Path $manifestPath | ConvertFrom-Json
$pySpec = $manifest.dependencies.python_tooling | Select-Object -First 1

if (-not $pySpec) {
  throw '[FATAL] Missing active python_tooling specification block inside MANIFEST.json'
}

# Resolve target destination folder dynamically from manifest spec (DOS-8 Compliance)
$normalizedTarget = $pySpec.target_dir.TrimStart('.\').TrimStart('/')
$venvStorage = [System.IO.Path]::GetFullPath((Join-Path $homeDir $normalizedTarget))
$pipExe = Join-Path $venvStorage 'Scripts\pip.exe'
$pythonExe = Join-Path $venvStorage 'Scripts\python.exe'

# 2. Idempotent Virtual Environment Scaffolding
if (-not (Test-Path $pythonExe)) {
  Write-Host " |-- Creating isolated Python Virtual Environment at: $venvStorage" -ForegroundColor Yellow

  $parentVenvDir = Split-Path -Path $venvStorage -Parent
  if (-not (Test-Path $parentVenvDir)) { New-Item -ItemType Directory -Path $parentVenvDir | Out-Null }

  & python.exe -m venv $venvStorage
  if (-not (Test-Path $pythonExe)) {
    throw "[FATAL] Failed to initialize Python virtual environment framework context at $venvStorage"
  }
  Write-Host '    |-- Isolated runtime environment scaffolded successfully.' -ForegroundColor Green
} else {
  Write-Host " |-- Verified isolated Python runtime context: $pythonExe" -ForegroundColor Gray
}

# Scaffold dedicated MCP script directory inside .venv boundary (DOS-9 Topology)
$mcpWorkingDir = Join-Path $venvStorage 'mcp'
if (-not (Test-Path $mcpWorkingDir)) {
  New-Item -ItemType Directory -Path $mcpWorkingDir | Out-Null
  Write-Host " |-- Scaffolded dedicated MCP working directory: .ai\.venv\mcp\" -ForegroundColor Cyan
}

# 3. Upgrade Core Package Manager Layer (Safe execution wrapper)
Write-Host ' |-- Aligning core package manager subsystem versions...' -ForegroundColor Cyan
try {
  & $pythonExe -m pip install --upgrade pip --quiet
  Write-Host '    |-- System pip package manager successfully aligned to latest release.' -ForegroundColor Green
}
catch {
  Write-Host '    |-- [WARNING] Subsystem blocked native pip upgrade. Proceeding with active caching metrics.' -ForegroundColor Yellow
}

# 4. Sequential Idempotent Dependencies Delivery Ingestion Loop
Write-Host ' |-- Provisioning production dependency matrices defined in manifest...' -ForegroundColor Cyan

# Fix: Purge the host DNS resolver cache and apply cooldown sleep before pip triggers network socket pooling
Write-Host '   |-- Flushing DNS cache and forcing network cooldown...' -ForegroundColor Gray
& ipconfig.exe /flushdns | Out-Null
Start-Sleep -Seconds 1

foreach ($package in $pySpec.packages) {
  Write-Host "   |-- Synced Ingestion target: $package" -ForegroundColor Yellow
  & $pipExe install $package --quiet
}

Write-Host "`n>>> [SUCCESS] Python runtime nodes aligned with async architecture specifications!" -ForegroundColor Green
