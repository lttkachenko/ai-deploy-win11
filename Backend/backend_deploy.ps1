$ErrorActionPreference = "Stop"

Write-Host ">>> Bootstrapping Agnostic Headless C++ Inference Backend Layer via NSSM..." -ForegroundColor Yellow

# 1. Environment and Workspace Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$aiRoot = Join-Path $homeDir ".ai"
$binStorage = Join-Path $aiRoot "bin"
$logStorage = Join-Path $aiRoot "log"

# Ensure target scaffolding is properly instantiated inside the user's home path
if (-not (Test-Path $binStorage)) {
  New-Item -ItemType Directory -Path $binStorage | Out-Null
  Write-Host " |-- Scaffolded production binary repository: $binStorage" -ForegroundColor Cyan
}

if (-not (Test-Path $logStorage)) {
  New-Item -ItemType Directory -Path $logStorage | Out-Null
  Write-Host " |-- Scaffolded production telemetry log room: $logStorage" -ForegroundColor Cyan
}

# 2. Automated Native Tooling Delivery (Assert C++ engine binaries & NSSM)
$localBinaries = @("llama-swap.exe", "llama-server.exe", "nssm.exe")

Write-Host " |-- Checking core C++ engine binaries and NSSM wrapper..." -ForegroundColor Cyan
foreach ($binName in $localBinaries) {
  $targetBinPath = Join-Path $binStorage $binName
  if (-not (Test-Path $targetBinPath)) {
    $localSourceBin = Join-Path $PSScriptRoot $binName
    if (Test-Path $localSourceBin) {
      Copy-Item -Path $localSourceBin -Destination $targetBinPath -Force
      Write-Host "   |-- [SUCCESS] Replicated binary asset: $binName" -ForegroundColor Green
    } else {
      throw "[FATAL] Missing required deployment binary in distribution folder: Backend\$binName"
    }
  } else {
    Write-Host "   |-- Binary baseline verified: $binName" -ForegroundColor Gray
  }
}

# 3. Synchronizing Declarative Configuration and System Prompt Assets
Write-Host " |-- Transporting operational configuration layers..." -ForegroundColor Cyan

$sourceConfig = Join-Path $PSScriptRoot "config.yml"
$sourcePrompt = Join-Path $PSScriptRoot "system_prompt.txt"

if (Test-Path $sourceConfig) {
  Copy-Item -Path $sourceConfig -Destination (Join-Path $binStorage "config.yml") -Force
  Write-Host "   |-- Synced runtime mapping matrix: config.yml" -ForegroundColor Gray
} else {
  throw "[FATAL] Distribution asset broken. Missing source Backend\config.yml"
}

if (Test-Path $sourcePrompt) {
  Copy-Item -Path $sourcePrompt -Destination (Join-Path $binStorage "system_prompt.txt") -Force
  Write-Host "   |-- Synced native identity anchor: system_prompt.txt" -ForegroundColor Gray
}

# 4. Inject Environment PATH Variable Blocks
Write-Host " |-- Asserting User Path environment scope alignment..." -ForegroundColor Cyan
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*\.ai\bin*") {
  $updatedPath = $currentPath + ";" + $binStorage
  [System.Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
  $env:Path = $updatedPath
  Write-Host "   |-- Integrated .ai/bin targets into User Path environment variable." -ForegroundColor Green
} else {
  Write-Host "   |-- Environment PATH context alignment already verified." -ForegroundColor Gray
}

# 5. Persistent Windows Service Orchestration via NSSM Wrapper
Write-Host " |-- Orchestrating persistent background daemon via NSSM Wrapper..." -ForegroundColor Cyan

$serviceName = "llama-swap-service"
$nssmExe = Join-Path $binStorage "nssm.exe"
$runtimeLogFile = Join-Path $logStorage "llama-swap.log"

# Stop and purge existing service instance if running to prevent file locks
$serviceCheck = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
  Write-Host "   |-- Active service container found. Terminating legacy node..." -ForegroundColor Yellow
  Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
  & $nssmExe remove $serviceName confirm | Out-Null
  Start-Sleep -Seconds 1
}

Write-Host "   |-- Registering headless C++ service instance via NSSM..." -ForegroundColor Green

# Declarative NSSM Service Provisioning
& $nssmExe install $serviceName "`"$binStorage\llama-swap.exe`"" "`"--config `"$binStorage\config.yml`"`"" | Out-Null
& $nssmExe set $serviceName AppDirectory "`"$binStorage`"" | Out-Null

# Redirect standard logs for transparent OODA-loop telemetry tracking inside centralized log folder
& $nssmExe set $serviceName AppStdout "`"$runtimeLogFile`"" | Out-Null
& $nssmExe set $serviceName AppStderr "`"$runtimeLogFile`"" | Out-Null

# Critical: Enforce service to execute under the context of the active logged-in user session
& $nssmExe set $serviceName ObjectName ".\$winUser" "" | Out-Null

# Set automated recovery actions on daemon failure (Restart process after 5 seconds)
& $nssmExe set $serviceName AppExit Default Restart | Out-Null
& $nssmExe set $serviceName Throttle 5000 | Out-Null

# Trigger immediate cold-start sequence
try {
  Start-Service -Name $serviceName
  Write-Host "   |-- [SUCCESS] NSSM Service container is online. Telemetry fully routed to .ai/log/llama-swap.log" -ForegroundColor Green
}
catch {
  throw "[FATAL] Failed to initiate NSSM Windows Service boot sequence. Check Windows Event Viewer. Reason: $_"
}
