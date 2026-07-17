$ErrorActionPreference = 'Stop'

# 1. Host Runtime Workspace Architecture Scaffolding (~/.ai/)
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath('UserProfile')

# Enforcing standardized runtime hidden allocations layout inside user profile
$aiRoot = Join-Path $homeDir '.ai'
$litellmRuntimeDir = Join-Path $aiRoot '.litellm'
$qdrantRuntimeDir = Join-Path $aiRoot '.qdrant'
$venvDir = Join-Path $qdrantRuntimeDir '.venv'

Write-Host '>>> Starting PyParts Provisioning Pipeline...' -ForegroundColor Yellow
Write-Host "    |-- Host Environment: Windows ($winUser)" -ForegroundColor Cyan
Write-Host "    |-- Master Target Root: $aiRoot" -ForegroundColor Cyan

# 2. Dynamic Python Engine Discovery (Bypassing Hardcoded AppData Traps)
$pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # Fallback check inside AppData if missing from global PATH entries
  $fallbackDir = "$homeDir\AppData\Local\Programs\Python"
  if (Test-Path $fallbackDir) {
    $latestPython = Get-ChildItem -Path $fallbackDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($latestPython) {
      $pythonExe = Join-Path $fallbackDir $latestPython.Name 'python.exe'
    }
  }
} else {
  $pythonExe = $pythonCmd.Source
}

if (-not $pythonExe -or -not (Test-Path $pythonExe)) {
  throw '[FATAL] Python engine core not found. Ensure Python is installed and accessible within host environment.'
}

Write-Host "    |-- Resolved active Python executable target: $pythonExe" -ForegroundColor Green

# 3. Provision Core Directory Hierarchy Securely
$requiredDirs = @($aiRoot, $litellmRuntimeDir, $qdrantRuntimeDir)
foreach ($dir in $requiredDirs) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
}

# 4. Sync Global Core Package Tooling and LiteLLM Engine Proxies via Safe Space
Write-Host '>>> Synchronizing Base Package Managers and Global Extensions...' -ForegroundColor Yellow
& $pythonExe -m pip install --upgrade pip --user --quiet
& $pythonExe -m pip install 'litellm[proxy]==1.34.0' --user --quiet
Write-Host '    |-- Global host litellm proxy system mapping verified.' -ForegroundColor Green

# 5. Build Isolated Environment Sandbox inside Mapped Runtime Allocation
Write-Host '>>> Deploying Virtual Isolation Layer for Vector Watcher...' -ForegroundColor Yellow
if (-not (Test-Path $venvDir)) {
  Write-Host '    |-- Constructing clean runtime .venv under user storage layout...' -ForegroundColor Cyan
  & $pythonExe -m venv $venvDir
}

# Resolve virtual runtime binary pointers explicitly
$venvPip = Join-Path $venvDir 'Scripts\pip.exe'
$venvPython = Join-Path $venvDir 'Scripts\python.exe'

if (-not (Test-Path $venvPip)) {
  throw '[FATAL] Virtual environment provisioning failure: pip binary tracking lost.'
}

# 6. Resolve Domain-Specific Packages Inside Local Subsystem Sandbox
Write-Host '>>> Aligning targeted RAG package dependencies within isolated sandbox...' -ForegroundColor Yellow

# FIXED: Replaced legacy blocking modules with async counterparts and locked precise enterprise versions
$requiredPackages = @(
  'watchfiles==0.24.0',
  'qdrant-client==1.9.0',
  'langchain-text-splitters==0.2.0',
  'httpx==0.27.0',
  'mcp==1.2.1'
)

foreach ($package in $requiredPackages) {
  Write-Host "    |-- Binding runtime library module: $package" -ForegroundColor Cyan
  & $venvPip install $package --quiet
}

# 7. Deliver Pristine Assets From Master Distribution Repository
# FIXED: Added synchronization for both unified async core python assets using snake_case layout
$assetsToSync = @(
  @{ Source = 'Qdrant\qdrant_watcher.py'; Dest = Join-Path $qdrantRuntimeDir 'qdrant_watcher.py' },
  @{ Source = 'Qdrant\libs.py';           Dest = Join-Path $qdrantRuntimeDir 'libs.py' }
)

foreach ($asset in $assetsToSync) {
  $localScriptPath = Join-Path $PSScriptRoot $asset.Source
  if (Test-Path $localScriptPath) {
    Copy-Item -Path $localScriptPath -Destination $asset.Dest -Force
    Write-Host "    |-- Successfully synchronized asset: $($asset.Source)" -ForegroundColor Green
  } else {
    throw "[FATAL] Missing distribution file reference dependency: $($asset.Source)"
  }
}

Write-Host "`n[SUCCESS] PyParts execution tracking alignment complete. Host environment structured." -ForegroundColor Green
