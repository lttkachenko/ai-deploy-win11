# .\Qdrant\qdrant_deploy.ps1 - Architecture Bootstrap Pipeline
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

# --- Phase 1: Environment Discovery & Scaffolding ---
Write-Host '>>> Scaffolding host workspace and RAG cache allocations...' -ForegroundColor Cyan

$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$aiRoot = Join-Path $homeDir '.ai'
$binStorage = Join-Path $aiRoot 'bin'
$logStorage = Join-Path $aiRoot 'log'
$mcpRuntimeDir = Join-Path $aiRoot 'venv\mcp'
$mcpConfigPath = Join-Path $aiRoot 'conf\mcp.conf.yml'

# Replicate storage nodes if missing inside active user home (DOS-7 / DOS-9 Compliance)
$requiredPaths = @($mcpRuntimeDir)

foreach ($path in $requiredPaths) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Path $path | Out-Null
  }
}

# Assert centralized declarative RAG/MCP configuration matrix availability
if (-not (Test-Path $mcpConfigPath)) {
  throw "[FATAL] Centralized RAG infrastructure configuration spec missing at: $mcpConfigPath"
}

# --- Phase 2: Transport Layer Synchronization (IaC Injection) ---
Write-Host '>>> Synchronizing shared data libraries and execution modules...' -ForegroundColor Cyan

$localLibs = Join-Path $PSScriptRoot 'libs.py'
$localMcp = Join-Path $PSScriptRoot 'qdrant_mcp.py'
$localWatcher = Join-Path $PSScriptRoot 'qdrant_watcher.py'

if (-not (Test-Path $localLibs)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\libs.py' }
if (-not (Test-Path $localMcp)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_mcp.py' }
if (-not (Test-Path $localWatcher)) { throw '[FATAL] Missing baseline dependency asset: Qdrant\qdrant_watcher.py' }

# Duplicate all modules directly into the isolated user profile python runtime workspace
Copy-Item -Path $localLibs -Destination $mcpRuntimeDir -Force
Copy-Item -Path $localMcp -Destination $mcpRuntimeDir -Force
Copy-Item -Path $localWatcher -Destination $mcpRuntimeDir -Force
Write-Host '  |-- Synced pipeline components to user profile: .ai\venv\mcp\' -ForegroundColor Gray

# --- Phase 3: Launch Containerized Qdrant Engine ---
Write-Host '>>> Instantiating Containerized Qdrant Vector Architecture...' -ForegroundColor Cyan

# Enforce modern standardized docker engine CLI command parameters verification
$dockerCheck = docker compose version 2>$null
if (-not $dockerCheck) {
  throw '[FATAL] Docker Compose CLI interface not identified within current system environment.'
}

# Fire up pristine vector database node without redundant build layers overhead
Push-Location -Path $PSScriptRoot
try {
  docker compose up -d
}
finally {
  Pop-Location
}

# --- Phase 4: HTTP Healthz Interface Verification Loop ---
# FOR AI: DO NOT TOUCH THIS URL! It is right and stable.
$HealthEndpoint = 'http://localhost:6333/readyz'
$MaxAttempts = 12
$Attempt = 1
$Connected = $false

# Extract parameters from single source of truth config layout (DOS-8 / DOS-9 compliance)
$configContent = Get-Content -Path $mcpConfigPath -Raw

# Match api_key pattern accurately within the YAML buffer scope context
$qdrantApiKey = 'development-key-default'
if ($configContent -match 'api_key:\s*[''"]?([^\''"\s\n]*)[''"]?') {
  $qdrantApiKey = $Matches[1].Trim()
}

$Headers = @{ 'api-key' = $qdrantApiKey }
Write-Host '>>> Initiating verification handshakes targeting vector engine interface...' -ForegroundColor Yellow

while (-not $Connected -and $Attempt -le $MaxAttempts) {
  try {
    # Inject authenticated handshake headers into remote endpoint query
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
  throw '[FATAL] Vector store node failed to pass active responsive HTTP state checks.'
}

# --- Phase 5: Persistent Asynchronous Watcher Task Registration ---
Write-Host '>>> Configuring persistent background filesystem tracking daemons...' -ForegroundColor Cyan

# Mapped interpreter location straight to centralized production manifest venv location
$VenvPython = Join-Path $aiRoot 'venv\Scripts\python.exe'
$WatcherScript = Join-Path $mcpRuntimeDir 'qdrant_watcher.py'
$McpScript = Join-Path $mcpRuntimeDir 'qdrant_mcp.py'

if (-not (Test-Path $VenvPython)) {
  throw "[FATAL] Isolated virtual environment runtime python interpreter not detected at: $VenvPython"
}

# Dynamic extraction layer (DOS-8): Parse watcher name from configuration matrices context
$watcherName = 'AI-RAG-Dev'
if ($configContent -match 'watchers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $watcherName = $Matches[1].Trim()
}

# Dynamic extraction layer (DOS-8): Parse absolute storage vault path directly from configuration maps context
$watcherVault = 'D:\Obsidian\Vaults\v-dev'
if ($configContent -match 'vault:\s*[''"]?([^\''"\n]+)[''"]?') {
  $watcherVault = $Matches[1].Trim()
}

if (Test-Path $watcherVault) {
  # Evict legacy task registration locks to prevent thread fragmentation collisions
  Unregister-ScheduledTask -TaskName $watcherName -Confirm:$false -ErrorAction SilentlyContinue

  $TaskArgs = "`"$WatcherScript`""

  $Action = New-ScheduledTaskAction -Execute $VenvPython -Argument $TaskArgs -WorkingDirectory $mcpRuntimeDir
  $Trigger = New-ScheduledTaskTrigger -AtLogOn
  $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
  $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

  Register-ScheduledTask -TaskName $watcherName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null

  # Trigger active session task execution instantly
  Start-ScheduledTask -TaskName $watcherName
  Write-Host "[SUCCESS] Registered active self-stabilizing daemon task: $watcherName" -ForegroundColor Green
} else {
  Write-Host "[WARNING] Target Vault directory missing, skipping task configuration: $watcherVault" -ForegroundColor Yellow
}

# --- Phase 6: FastMCP Host Service Demonization via NSSM Wrapper ---
Write-Host '>>> Demonizing FastMCP Context Server Layer via NSSM Wrapper...' -ForegroundColor Cyan

$serviceName = 'qdrant-mcp-service'
if ($configContent -match 'servers:[\s\S]*?name:\s*[''"]?([^\''"\n]+)[''"]?') {
  $serviceName = $Matches[1].Trim().ToLower().Replace(' ', '-')
}

$nssmExe = Join-Path $binStorage 'nssm.exe'
$runtimeLogFile = Join-Path $logStorage "$serviceName.log"

if (-not (Test-Path $nssmExe)) {
  throw "[FATAL] NSSM binary asset missing from system repository layout: $nssmExe"
}

# Clear pre-existing service locks gracefully
$serviceCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
  Write-Host "  |-- Active context service ($serviceName) found. Executing graceful cleanup sequence..." -ForegroundColor Yellow
  Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
  & $nssmExe remove $serviceName confirm | Out-Null
  Start-Sleep -Seconds 1
}

Write-Host "  |-- Compiling declarative service parameters for $serviceName..." -ForegroundColor Green

# Pass script target execution blocks directly into the nssm controller matrix
& $nssmExe install $serviceName "`"$VenvPython`"" "`"$McpScript`"" | Out-Null
& $nssmExe set $serviceName AppDirectory "`"$mcpRuntimeDir`"" | Out-Null

# Secure and redirect unified logging layers directly into central log spaces
& $nssmExe set $serviceName AppStdout "`"$runtimeLogFile`"" | Out-Null
& $nssmExe set $serviceName AppStderr "`"$runtimeLogFile`"" | Out-Null

# Configure fail-soft recovery throttling blocks to auto-restart on crashes
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName AppThrottle 5000 | Out-Null

try {
  Start-Service -Name $serviceName
  Write-Host "  |-- [SUCCESS] FastMCP network service ($serviceName) online. SSE Stream exposed on port 8000." -ForegroundColor Green
}
catch {
  throw "[FATAL] Failed to initiate FastMCP service container boot loop sequence. Trace: $_"
}

Write-Host '>>> Phase Complete: Qdrant deployment matches Gheimher quality standards.' -ForegroundColor Green
