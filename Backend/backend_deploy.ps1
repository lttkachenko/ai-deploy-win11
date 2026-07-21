$ErrorActionPreference = 'Stop'

Write-Host '>>> Bootstrapping Hybrid Headless AI Stack Configuration Layout...' -ForegroundColor Yellow

# 1. Environment and Workspace Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath('UserProfile')

$aiRoot      = Join-Path $homeDir '.ai'
$binStorage  = Join-Path $aiRoot 'bin'
$logStorage  = Join-Path $aiRoot 'log'
$confStorage = Join-Path $aiRoot 'conf'
$ctxStorage  = Join-Path $aiRoot 'context'

$downloaderScript = Join-Path $PSScriptRoot '..\Utils\asset_downloader.ps1'
$manifestPath     = Join-Path $PSScriptRoot '..\MANIFEST.json'

if (-not (Test-Path $downloaderScript)) { throw "[FATAL] Downloader missing: $downloaderScript" }
if (-not (Test-Path $manifestPath)) { throw "[FATAL] Manifest missing: $manifestPath" }

# Ensure production scaffolding paths are established inside host machine
if (-not (Test-Path $binStorage))  { New-Item -ItemType Directory -Path $binStorage | Out-Null }
if (-not (Test-Path $logStorage))  { New-Item -ItemType Directory -Path $logStorage | Out-Null }
if (-not (Test-Path $confStorage)) { New-Item -ItemType Directory -Path $confStorage | Out-Null }
if (-not (Test-Path $ctxStorage))  { New-Item -ItemType Directory -Path $ctxStorage | Out-Null }

# Load and parse declarative infrastructure specification matrix
$manifest = Get-Content -Raw -Path $manifestPath | ConvertFrom-Json
$backendDeps = $manifest.dependencies.backend

$lmsSpec = $backendDeps | Where-Object { $_.alias -eq 'llmster' }
$swapSpec = $backendDeps | Where-Object { $_.alias -eq 'llama-swap' }
$nssmSpec = $backendDeps | Where-Object { $_.alias -eq 'nssm_wrapper' }

# 2. Sequential Flat Component Ingestion (No loops, pure stability)
Write-Host ' |-- Delivering infrastructure binaries sequentially...' -ForegroundColor Cyan

# Step 2.1: Deliver LM Studio Headless Daemon
$lmsString = ConvertTo-Json -InputObject $lmsSpec -Compress
& $downloaderScript -DependencyJson $lmsString -DestinationDir $binStorage

# Step 2.2: Deliver Llama-Swap Proxy
$swapString = ConvertTo-Json -InputObject $swapSpec -Compress
& $downloaderScript -DependencyJson $swapString -DestinationDir $binStorage

# Step 2.3: Deliver NSSM Service Wrapper
$nssmString = ConvertTo-Json -InputObject $nssmSpec -Compress
& $downloaderScript -DependencyJson $nssmString -DestinationDir $binStorage

# 3. Synchronizing Operational Configuration & Identity Assets to Targeted Slots
Write-Host ' |-- Transporting operational configuration and prompt layers...' -ForegroundColor Cyan

$sourceConfig = Join-Path $PSScriptRoot 'llama-swap.conf.yml'
$sourcePrompt = Join-Path $PSScriptRoot 'system_prompt.txt'

$targetConfigPath = Join-Path $confStorage 'llama-swap.conf.yml'
$targetPromptPath = Join-Path $ctxStorage 'system_prompt.txt'

if (Test-Path $sourceConfig) {
  $rawConfig = Get-Content -Raw -Path $sourceConfig
  $absoluteHome = $homeDir -replace '\\', '/'
  $patchedConfig = $rawConfig -replace '%USERPROFILE%', $absoluteHome
  Set-Content -Path $targetConfigPath -Value $patchedConfig -Force
  Write-Host "   |-- Synced and absolute-patched routing matrix layout: $targetConfigPath" -ForegroundColor Gray
} else {
  throw "[FATAL] Distribution asset broken. Missing source Backend\llama-swap.conf.yml"
}

if (Test-Path $sourcePrompt) {
  Copy-Item -Path $sourcePrompt -Destination $targetPromptPath -Force
  Write-Host "   |-- Synced identity anchor node: $targetPromptPath" -ForegroundColor Gray
}

# 4. Refresh Host Environment PATH Context
Write-Host ' |-- Refreshing host environment PATH context...' -ForegroundColor Cyan
$userRegPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$machineRegPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$env:Path = $userRegPath + ';' + $machineRegPath

# 5. Persistent Windows Service Orchestration via NSSM Wrapper
Write-Host ' |-- Orchestrating persistent background daemon via NSSM Wrapper...' -ForegroundColor Cyan

$serviceName    = 'llama-swap-service'
$nssmExe        = Join-Path $binStorage $nssmSpec.target_file
$runtimeLogFile = Join-Path $logStorage 'llama-swap.log'
$swapExePath    = Join-Path $binStorage $swapSpec.binary

# Hard Force Check: Re-verify physical binary localization to avoid symlink locks
$globalSwap = Get-Command 'llama-swap.exe' -ErrorAction SilentlyContinue
if ($globalSwap -and (-not (Test-Path $swapExePath))) { Copy-Item -Path $globalSwap.Source -Destination $swapExePath -Force }

# Fix 5.1: Unblock delivery binaries to completely remove Windows zone identifier locks
Get-ChildItem -Path $binStorage -Filter "*.exe" | Unblock-File

# Fix 5.2: Force kill any orphan processes holding ports 1234, 8080, 8081, 8082 before service re-bind
Write-Host '   |-- Purging orphan backend and proxy execution tasks...' -ForegroundColor Yellow
Stop-Process -Name 'llama-swap' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'llama-server' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Explicitly boot the LM Studio headless daemon engine layer before spawning proxy
$lmsBinary = Join-Path $env:LOCALAPPDATA "Programs\lmstudio\$($lmsSpec.binary)"
if (-not (Test-Path $lmsBinary)) { $lmsBinary = "C:\Program Files\LM Studio\$($lmsSpec.binary)" }

if (Test-Path $lmsBinary) {
  Write-Host '   |-- Pre-booting LM Studio Core API Daemon process...' -ForegroundColor Gray
  Start-Process -FilePath $lmsBinary -ArgumentList "server start" -WindowStyle Hidden
  Start-Sleep -Seconds 4
}

# Smart teardown path. If service exists, choose teardown tool based on nssm.exe presence
$serviceCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
  Write-Host '   |-- Active service container found. Triggering teardown sequence...' -ForegroundColor Yellow
  Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
  if (Test-Path $nssmExe) { & $nssmExe remove $serviceName confirm | Out-Null } else { & sc.exe delete $serviceName | Out-Null }
  Start-Sleep -Seconds 2
}

Write-Host '   |-- Registering headless proxy service instance via NSSM...' -ForegroundColor Green

# Fix 5.3: Register using clean, flattened arguments to avoid sub-quoting parsing collapses in registry
& $nssmExe install $serviceName "$swapExePath" --config "$targetConfigPath" | Out-Null
& $nssmExe set $serviceName AppDirectory "$binStorage" | Out-Null
& $nssmExe set $serviceName AppStdout "$runtimeLogFile" | Out-Null
& $nssmExe set $serviceName AppStderr "$runtimeLogFile" | Out-Null

# Force execution parameters block isolation under LocalSystem context with native variables mapping
& $nssmExe set $serviceName ObjectName "LocalSystem" | Out-Null
& $nssmExe set $serviceName AppEnvironmentExtra "USERPROFILE=$homeDir" "LOCALAPPDATA=$env:LOCALAPPDATA" "PATH=$env:Path" | Out-Null
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName AppThrottle 5000 | Out-Null

# Allow Windows service database cache alignment
Start-Sleep -Seconds 3

try {
  Start-Service -Name $serviceName
  Write-Host '   |-- [SUCCESS] NSSM Service container is online. Telemetry fully routed to .ai/log/llama-swap.log' -ForegroundColor Green
}
catch {
  Write-Host '`n[CRITICAL] Service failed to boot. Dumping latest telemetry records:' -ForegroundColor Red
  if (Test-Path $runtimeLogFile) { Get-Content -Path $runtimeLogFile -Tail 5 | Write-Host -ForegroundColor Red }
  throw "[FATAL] Service boot sequence collapsed. Trace: $_"
}
