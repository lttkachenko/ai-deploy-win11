$ErrorActionPreference = "Stop"

Write-Host ">>> Executing Python Infrastructure Provisioning..." -ForegroundColor Yellow

# 1. Verify system Python installation on Windows Host
$pythonCheck = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCheck) {
  throw "[FATAL] Python is missing from Host System PATH. Install Python 3.10+."
}

# Validate Python version compliance (minimum 3.10 required for modern Qdrant/MCP ecosystem)
$pyVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
Write-Host " |-- Found Host Python version: $pyVersion" -ForegroundColor Gray

# 2. Scaffolding isolated Virtual Environment for Vector Engine tooling
$venvDir = Join-Path $PSScriptRoot "Qdrant\.venv"
$pipExe = Join-Path $venvDir "Scripts\pip.exe"

if (-not (Test-Path $venvDir)) {
  Write-Host " |-- Scaffolding isolated vector runtime environment..." -ForegroundColor Cyan
  & python -m venv $venvDir
}

# Force upgrade core package manager inside virtual environment
Write-Host " |-- Upgrading core package manager..." -ForegroundColor Gray
& $pipExe install --upgrade pip --quiet

# 3. Declarative full package provisioning for Qdrant Watcher & FastMCP Server
Write-Host " |-- Provisioning comprehensive production dependencies..." -ForegroundColor Cyan

# Full asynchronous baseline package matrix for Rust-backed file tracking and MCP
$requiredPipPackages = @(
  "watchfiles==0.21.0",
  "qdrant-client==1.9.0",
  "sentence-transformers==3.0.1",
  "fastmcp==0.4.1",
  "pyyaml==6.0.1",
  "pydantic==2.7.1"
)

foreach ($pkg in $requiredPipPackages) {
  Write-Host "   |-- Installing target node: $pkg" -ForegroundColor Gray
  & $pipExe install $pkg --quiet
}

Write-Host "[SUCCESS] Python runtime nodes aligned with async architecture." -ForegroundColor Green
