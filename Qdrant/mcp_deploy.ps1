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

$localLibs = Join-Path $PSScriptRoot 'libs.py'
$localMcp = Join-Path $PSScriptRoot 'qdrant_mcp.py'
$localWatcher = Join-Path $PSScriptRoot 'qdrant_watcher.py'

if (-not (Test-Path $localLibs)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\libs.py' }
if (-not (Test-Path $localMcp)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_mcp.py' }
if (-not (Test-Path $localWatcher)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_watcher.py' }

Copy-Item -Path $localLibs -Destination $mcpRuntimeDir -Force
Copy-Item -Path $localMcp -Destination $mcpRuntimeDir -Force
Copy-Item -Path $localWatcher -Destination $mcpRuntimeDir -Force
Write-Host '  |-- Synced pipeline components to user profile: .ai\venv\mcp\' -ForegroundColor Gray

# --- Phase 2: Runtime Environment Discovery ---
$configContent = Get-Content -Path $mcpConfigPath -Raw

$VenvPython = Join-Path $aiRoot 'venv\mcp\Scripts\python.exe'
if (-not (Test-Path $VenvPython)) {
  $VenvPython = Join-Path $aiRoot 'venv\Scripts\python.exe'
}
if (-not (Test-Path $VenvPython)) {
  throw "[FATAL] Isolated virtual environment runtime python interpreter not detected at: $VenvPython"
}

# --- Phase 3: Watcher Scheduled Task Orchestration ---
Write-Host '>>> Configuring persistent background filesystem tracking daemons...' -ForegroundColor Cyan

$watcherName = 'AI-RAG-Dev'
if ($configContent -match 'watchers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $watcherName = $Matches[1].Trim()
}

$watcherVault = 'D:\Obsidian\Vaults\v-dev'
if ($configContent -match 'vault_path:\s*[''"]?([^\''"\r\n]+)[''"]?') {
  $watcherVault = $Matches[1].Trim()
}

if (Test-Path $watcherVault) {
  # Evict legacy task registration locks to prevent thread fragmentation collisions
  Unregister-ScheduledTask -TaskName $watcherName -Confirm:$false -ErrorAction SilentlyContinue

  $Action = New-ScheduledTaskAction -Execute $VenvPython -Argument "`"$localWatcher`"" -WorkingDirectory $mcpRuntimeDir
  $Trigger = New-ScheduledTaskTrigger -AtLogOn
  $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
  $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

  Register-ScheduledTask -TaskName $watcherName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
  Start-ScheduledTask -TaskName $watcherName
  Write-Host "[SUCCESS] Registered active self-stabilizing daemon task: $watcherName" -ForegroundColor Green
} else {
  Write-Host "[WARNING] Target Vault directory missing, skipping task configuration: $watcherVault" -ForegroundColor Yellow
}

# --- Phase 4: FastMCP Windows Service Orchestration via NSSM ---
Write-Host '>>> Demonizing FastMCP Context Server Layer via NSSM Wrapper...' -ForegroundColor Cyan

$serviceName = 'qdrant-mcp-service'
if ($configContent -match 'servers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $serviceName = $Matches[1].Trim().ToLower().Replace(' ', '-')
}

$nssmExe = Join-Path $binStorage 'nssm.exe'
$runtimeLogFile = Join-Path $logStorage "$serviceName.log"

if (-not (Test-Path $nssmExe)) { throw "[FATAL] NSSM binary asset missing: $nssmExe" }

$serviceCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
  Write-Host "  |-- Active context service ($serviceName) found. Executing graceful cleanup sequence..." -ForegroundColor Yellow
  Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
  & $nssmExe remove $serviceName confirm | Out-Null
  Start-Sleep -Seconds 1
}

Write-Host "  |-- Compiling declarative service parameters for $serviceName..." -ForegroundColor Green

& $nssmExe install $serviceName $VenvPython $localMcp | Out-Null
& $nssmExe set $serviceName AppDirectory $mcpRuntimeDir | Out-Null
& $nssmExe set $serviceName AppStdout $runtimeLogFile | Out-Null
& $nssmExe set $serviceName AppStderr $runtimeLogFile | Out-Null

# --- DOS-9 Hardening: Inject absolute configuration path mapping matrix into LocalSystem space ---
& $nssmExe set $serviceName AppEnvironmentExtra "AI_CONFIG_PATH=$mcpConfigPath" "USERPROFILE=$homeDir" "PATH=$env:Path" | Out-Null
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName AppThrottle 5000 | Out-Null

$mcpPort = 8095
if ($configContent -match 'fastmcp_sse_port:\s*(\d+)') {
  $mcpPort = [int]$Matches
}

Start-Service -Name $serviceName

# --- Phase 5: Verification and Validation Loops ---
Write-Host '>>> Initiating runtime telemetry validations on active context layers...' -ForegroundColor Yellow

# Validation 1: Verify Python Filesystem Watcher task status (DOS-9 Soft Validation)
if (Test-Path $watcherVault) {
  $taskCheck = Get-ScheduledTask -TaskName $watcherName -ErrorAction SilentlyContinue
  if ($taskCheck.State -ne 'Running' -and $taskCheck.State -ne 'Ready') {
    throw "[FATAL] Watcher Scheduled Task state is unhealthy. Current state: $($taskCheck.State)"
  }
  Write-Host "  |-- Telemetry: Watcher Daemon Task ($watcherName) confirmed in active state cluster." -ForegroundColor Gray
} else {
  Write-Host "  |-- Telemetry: Watcher Task verification bypassed safely (physical directory skipped)." -ForegroundColor Yellow
}

# Validation 2: Verify FastMCP Service status
$srvCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($srvCheck.Status -ne 'Running') {
  throw "[FATAL] FastMCP Windows Service failed to boot. Check logs at: $runtimeLogFile"
}

# Validation 3: Verify FastMCP active socket allocation boundary via cyclic pre-flight barrier (DOS-7)
$McpConnected = $false
$McpMaxAttempts = 12
$McpAttempt = 1

Write-Host "  |-- Awaiting responsive socket hook on FastMCP port $mcpPort (Cold-booting CPU Transformer)..." -ForegroundColor Yellow

while (-not $McpConnected -and $McpAttempt -le $McpMaxAttempts) {
  $socketCheck = Get-NetTCPConnection -LocalPort $mcpPort -State Listen -ErrorAction SilentlyContinue
  if ($socketCheck) {
    $McpConnected = $true
  } else {
    Write-Host "  |-- [Attempt $McpAttempt/$McpMaxAttempts] FastMCP socket initializing. Retrying in 5s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    $McpAttempt++
  }
}

if (-not $McpConnected) {
  throw "[FATAL] FastMCP service process is online but failed to bind responsive socket hook on port $mcpPort within allocation bounds."
}

Write-Host "[SUCCESS] FastMCP network service container verified at 127.0.0.1:$mcpPort" -ForegroundColor Green
Write-Host '>>> Phase Complete: MCP stack deployment matches Gheimher quality standards.' -ForegroundColor Green
