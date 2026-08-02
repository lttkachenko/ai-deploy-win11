# .\Qdrant\mcp_deploy.ps1 - FastMCP & Daemon Orchestration Pipeline
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control
$ErrorActionPreference = 'Stop'

# --- Phase 1: Environment Discovery & Sync ---
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$aiRoot = Join-Path $homeDir '.ai'
$binStorage = Join-Path $aiRoot 'bin'
$logStorage = Join-Path $aiRoot 'log'
$mcpRuntimeDir = Join-Path $aiRoot 'venv\mcp'
$mcpConfigPath = Join-Path $aiRoot 'conf\mcp.conf.yml'

Write-Host '>>> Synchronizing shared data libraries and execution modules...' -ForegroundColor Cyan

$localLibs    = Join-Path $PSScriptRoot 'libs.py'
$localMcp     = Join-Path $PSScriptRoot 'qdrant_mcp.py'
$localWatcher = Join-Path $PSScriptRoot 'qdrant_watcher.py'
$localApi     = Join-Path $PSScriptRoot 'mcp_api.py'

if (-not (Test-Path $localLibs))    { throw '[FATAL] Missing baseline dependency asset: Qdrant\libs.py' }
if (-not (Test-Path $localMcp))     { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_mcp.py' }
if (-not (Test-Path $localWatcher)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_watcher.py' }
if (-not (Test-Path $localApi))     { throw '[FATAL] Missing baseline dependency asset: Qdrant\mcp_api.py' }

if (-not (Test-Path $mcpRuntimeDir)) { New-Item -ItemType Directory -Path $mcpRuntimeDir | Out-Null }
if (-not (Test-Path $logStorage))    { New-Item -ItemType Directory -Path $logStorage | Out-Null }

$runtimeLibs    = Join-Path $mcpRuntimeDir 'libs.py'
$runtimeMcp     = Join-Path $mcpRuntimeDir 'qdrant_mcp.py'
$runtimeWatcher = Join-Path $mcpRuntimeDir 'qdrant_watcher.py'
$runtimeApi     = Join-Path $mcpRuntimeDir 'mcp_api.py'

Copy-Item -Path $localLibs    -Destination $runtimeLibs    -Force
Copy-Item -Path $localMcp     -Destination $runtimeMcp     -Force
Copy-Item -Path $localWatcher -Destination $runtimeWatcher -Force
Copy-Item -Path $localApi     -Destination $runtimeApi     -Force
Write-Host ' |-- Synced pipeline components to user profile: .ai\venv\mcp\' -ForegroundColor Gray

# --- Phase 2: Runtime Environment Discovery ---
$configContent = Get-Content -Path $mcpConfigPath -Raw
$VenvPython = Join-Path $aiRoot 'venv\mcp\Scripts\python.exe'
if (-not (Test-Path $VenvPython)) {
  $VenvPython = Join-Path $aiRoot 'venv\Scripts\python.exe'
}
if (-not (Test-Path $VenvPython)) {
  throw "[FATAL] Isolated virtual environment runtime python interpreter not detected at: $VenvPython"
}

$nssmExe = Join-Path $binStorage 'nssm.exe'
if (-not (Test-Path $nssmExe)) { throw "[FATAL] NSSM binary asset missing: $nssmExe" }

# Robust stream parsing for declarative mcp.conf.yml metadata to bypass regex drift
$configMap = @{}
$configContent -split "`n" | ForEach-Object {
  $cleanLine = $_.Trim()
  if ($cleanLine -and -not $cleanLine.StartsWith('#') -and $cleanLine.Contains(':')) {
    $pair = $cleanLine.Split(':', 2)
    $key = $pair[0].Trim()
    $val = $pair[1].Trim().Trim("'").Trim('"')
    if (-not $configMap.ContainsKey($key)) { $configMap[$key] = $val }
  }
}

# --- Phase 2.5: Total Legacy Garbage Eviction (DOS-11 Hardening) ---
Write-Host '>>> Purging legacy runtime debris and orphan process trees...' -ForegroundColor Yellow

# 1. Terminate running Python processes to lift lock descriptors on runtime assets
Stop-Process -Name 'python' -Force -ErrorAction SilentlyContinue

# 2. Evict old scheduled tasks to stop background window pops
Unregister-ScheduledTask -TaskName 'AI-RAG-Dev' -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName 'ai-rag-wtr' -Confirm:$false -ErrorAction SilentlyContinue

# 3. Clean up active old services if any exist under dirty states
$dirtyServices = @('qdrant-mcp-service', 'ai-rag-wtr', 'ai-rag-srv')
foreach ($srv in $dirtyServices) {
  $srvCheck = Get-Service -Name $srv -ErrorAction SilentlyContinue
  if ($srvCheck) {
    Write-Host " |-- Eradicating legacy unit: $srv" -ForegroundColor DarkYellow
    Stop-Service -Name $srv -Force -ErrorAction SilentlyContinue
    & $nssmExe remove $srv confirm | Out-Null
  }
}
Start-Sleep -Seconds 2

# --- Phase 3: Watcher Windows Service Orchestration via NSSM ---
Write-Host '>>> Demonizing Filesystem RAG Watcher Service via NSSM Wrapper...' -ForegroundColor Cyan

$watcherServiceName = 'ai-rag-wtr'
if ($configMap.ContainsKey('name') -and $configContent -match 'watchers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $watcherServiceName = $Matches[1].Trim().ToLower().Replace(' ', '-')
}

$watcherVault = 'D:\Obsidian\Vaults\v-dev'
if ($configMap.ContainsKey('vault')) { $watcherVault = $configMap['vault'] }

if (Test-Path $watcherVault) {
  $watcherLogFile = Join-Path $logStorage "$watcherServiceName.log"
  Write-Host " |-- Compiling declarative service parameters for $watcherServiceName..." -ForegroundColor Green

  & $nssmExe install $watcherServiceName $VenvPython "`"$runtimeWatcher`"" | Out-Null
  & $nssmExe set $watcherServiceName AppDirectory $mcpRuntimeDir | Out-Null
  & $nssmExe set $watcherServiceName AppStdout $watcherLogFile | Out-Null
  & $nssmExe set $watcherServiceName AppStderr $watcherLogFile | Out-Null
  & $nssmExe set $watcherServiceName AppEnvironmentExtra "AI_CONFIG_PATH=$mcpConfigPath" "USERPROFILE=$homeDir" "PATH=$env:Path" | Out-Null
  & $nssmExe set $watcherServiceName AppExit Default Restart | Out-Null
  & $nssmExe set $watcherServiceName AppThrottle 5000 | Out-Null

  Start-Service -Name $watcherServiceName
  Write-Host "[SUCCESS] Registered active self-stabilizing daemon service: $watcherServiceName" -ForegroundColor Green
} else {
  Write-Host "[WARNING] Target Vault directory missing, skipping watcher service configuration: $watcherVault" -ForegroundColor Yellow
}

# --- Phase 4: FastMCP Windows Service Orchestration via NSSM ---
Write-Host '>>> Demonizing FastMCP Context Server Layer via NSSM Wrapper...' -ForegroundColor Cyan

$serviceName = 'ai-rag-srv'
if ($configMap.ContainsKey('name') -and $configContent -match 'servers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $serviceName = $Matches[1].Trim().ToLower().Replace(' ', '-')
}
$runtimeLogFile = Join-Path $logStorage "$serviceName.log"

Write-Host " |-- Compiling declarative service parameters for $serviceName..." -ForegroundColor Green

& $nssmExe install $serviceName $VenvPython "`"$runtimeMcp`"" | Out-Null
& $nssmExe set $serviceName AppDirectory $mcpRuntimeDir | Out-Null
& $nssmExe set $serviceName AppStdout $runtimeLogFile | Out-Null
& $nssmExe set $serviceName AppStderr $runtimeLogFile | Out-Null
& $nssmExe set $serviceName AppEnvironmentExtra "AI_CONFIG_PATH=$mcpConfigPath" "USERPROFILE=$homeDir" "PATH=$env:Path" | Out-Null
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName AppThrottle 5000 | Out-Null

$mcpPort = 8095
if ($configMap.ContainsKey('port')) { $mcpPort = [int]$configMap['port'] }

Start-Service -Name $serviceName

# --- Phase 5: Verification and Validation Loops ---
Write-Host '>>> Initiating runtime telemetry validations on active context layers...' -ForegroundColor Yellow

# Validation 1: Verify Python Filesystem Watcher service status
if (Test-Path $watcherVault) {
  $wtrCheck = Get-Service -Name $watcherServiceName -ErrorAction SilentlyContinue
  if ($wtrCheck.Status -ne 'Running') {
    throw "[FATAL] Watcher Service ($watcherServiceName) failed to boot. Check logs at: $watcherLogFile"
  }
  Write-Host " |-- Telemetry: Watcher Daemon Service ($watcherServiceName) confirmed in active state cluster." -ForegroundColor Gray
}

# Validation 2: Verify FastMCP Service status
$srvCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($srvCheck.Status -ne 'Running') {
  throw "[FATAL] FastMCP Windows Service ($serviceName) failed to boot. Check logs at: $runtimeLogFile"
}

# Validation 3: Verify FastMCP active socket allocation boundary via cyclic pre-flight barrier (DOS-7)
$McpConnected = $false
$McpMaxAttempts = 12
$McpAttempt = 1
Write-Host " |-- Awaiting responsive socket hook on FastMCP port $mcpPort (Cold-booting CPU Transformer)..." -ForegroundColor Yellow

while (-not $McpConnected -and $McpAttempt -le $McpMaxAttempts) {
  $socketCheck = Get-NetTCPConnection -LocalPort $mcpPort -State Listen -ErrorAction SilentlyContinue
  if ($socketCheck) {
    $McpConnected = $true
  } else {
    Write-Host " |-- [Attempt $McpAttempt/$McpMaxAttempts] FastMCP socket initializing. Retrying in 5s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    $McpAttempt++
  }
}

if (-not $McpConnected) {
  throw "[FATAL] FastMCP service process is online but failed to bind responsive socket hook on port $mcpPort within allocation bounds."
}

Write-Host "[SUCCESS] FastMCP network service container verified at 127.0.0.1:$mcpPort" -ForegroundColor Green
Write-Host '>>> Phase Complete: MCP stack deployment matches Gheimher quality standards.' -ForegroundColor Green
