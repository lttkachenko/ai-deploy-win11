$ErrorActionPreference = 'Stop'

Write-Host '>>> Bootstrapping Native Llama Server & Llama-Swap Matrix...' -ForegroundColor Yellow

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

$serverSpec = $backendDeps | Where-Object { $_.alias -eq 'llama-server' }
$swapSpec   = $backendDeps | Where-Object { $_.alias -eq 'llama-swap' }
$nssmSpec   = $backendDeps | Where-Object { $_.alias -eq 'nssm_wrapper' }

# 2. Sequential Component Ingestion
Write-Host ' |-- Delivering infrastructure components sequentially...' -ForegroundColor Cyan

# Step 2.1: Deliver Native Llama-Server Binary
$serverString = ConvertTo-Json -InputObject $serverSpec -Compress
& $downloaderScript -DependencyJson $serverString -DestinationDir $binStorage

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

  # Strict non-negotiable extraction from yml matrix layout
  if ($patchedConfig -match 'SW_HOST:\s*([\d\.]+)') {
    $detectedHost = $Matches[1].Trim()
  } else {
    throw '[FATAL] Critical configuration token missing: SW_HOST must be explicitly defined in llama-swap.conf.yml'
  }

  if ($patchedConfig -match 'SW_PORT:\s*(\d+)') {
    $detectedPort = [int]$Matches[1]
  } else {
    throw '[FATAL] Critical configuration token missing: SW_PORT must be explicitly defined in llama-swap.conf.yml'
  }
} else {
  throw "[FATAL] Distribution asset broken. Missing source Backend\llama-swap.conf.yml"
}

if (Test-Path $sourcePrompt) {
  Copy-Item -Path $sourcePrompt -Destination $targetPromptPath -Force
}

# 4. Refresh Host Environment PATH Context for User and Machine Registry
Write-Host ' |-- Refreshing host environment PATH context...' -ForegroundColor Cyan
$userRegPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')

if ($userRegPath -notlike "*$binStorage*") {
  Write-Host '   |-- Registering AI bin directory into persistent User PATH registry...' -ForegroundColor Gray
  $updatedUserPath = $userRegPath.TrimEnd(';') + ';' + $binStorage
  [System.Environment]::SetEnvironmentVariable('Path', $updatedUserPath, 'User')
  $userRegPath = $updatedUserPath
}

$machineRegPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$env:Path = $userRegPath + ';' + $machineRegPath

# 5. Persistent Windows Service Orchestration via NSSM Wrapper
Write-Host ' |-- Orchestrating persistent background daemon via NSSM Wrapper...' -ForegroundColor Cyan

$serviceName    = 'llama-swap-service'
$nssmExe        = Join-Path $binStorage $nssmSpec.target_file
$runtimeLogFile = Join-Path $logStorage 'llama-swap.log'
$swapExePath    = Join-Path $binStorage $swapSpec.binary

Get-ChildItem -Path $binStorage -Filter "*.exe" | Unblock-File

Write-Host '   |-- Purging orphan backend and proxy execution tasks...' -ForegroundColor Yellow
Stop-Process -Name 'llama-swap' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'llama-server' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$serviceCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
  Write-Host '   |-- Active service container found. Triggering teardown sequence...' -ForegroundColor Yellow
  Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
  if (Test-Path $nssmExe) { & $nssmExe remove $serviceName confirm | Out-Null } else { & sc.exe delete $serviceName | Out-Null }
  Start-Sleep -Seconds 2
}

Write-Host '   |-- Registering headless proxy service instance via NSSM...' -ForegroundColor Green

$userAppData         = Join-Path $homeDir 'AppData\Roaming'
$userLocalAppData    = Join-Path $homeDir 'AppData\Local'
$serviceIsolatedPath = "$binStorage;$env:Path"

& $nssmExe install $serviceName "$swapExePath" --config "$targetConfigPath" --listen "${detectedHost}:${detectedPort}" | Out-Null
& $nssmExe set $serviceName AppDirectory "$binStorage" | Out-Null
& $nssmExe set $serviceName AppStdout "$runtimeLogFile" | Null
& $nssmExe set $serviceName AppStderr "$runtimeLogFile" | Out-Null

& $nssmExe set $serviceName ObjectName "LocalSystem" | Out-Null
& $nssmExe set $serviceName AppEnvironmentExtra "USERPROFILE=$homeDir" "APPDATA=$userAppData" "LOCALAPPDATA=$userLocalAppData" "PATH=$serviceIsolatedPath" | Out-Null
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName AppThrottle 5000 | Out-Null

Start-Sleep -Seconds 3
Write-Host ">>> Backend deployment pipeline completed successfully for user: $winUser" -ForegroundColor Green
