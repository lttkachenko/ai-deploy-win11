$ErrorActionPreference = "Stop"

# 1. Host Runtime Architecture Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath("UserProfile")

# Standardized runtime paths mapping to the user hidden directory
$aiRoot = Join-Path $homeDir ".ai"
$litellmRuntimeDir = Join-Path $aiRoot ".litellm"
$targetConfigFile = Join-Path $litellmRuntimeDir "config.yml"
$targetShortcodesFile = Join-Path $litellmRuntimeDir "shortcodes.yml"

Write-Host ">>> Starting LiteLLM Service Provisioning Pipeline..." -ForegroundColor Yellow
Write-Host "    |-- Runtime Destination: $litellmRuntimeDir" -ForegroundColor Cyan

# 2. Dynamic Discovery of LiteLLM Executable (Aligning with PyParts Global User Mapping)
$litellmCmd = Get-Command litellm.exe -ErrorAction SilentlyContinue
if ($litellmCmd) {
  $litellmExe = $litellmCmd.Source
} else {
  # Fallback checking inside AppData user scripts directory if missing from global PATH
  $pythonDir = "$homeDir\AppData\Local\Programs\Python"
  if (Test-Path $pythonDir) {
    $latestPython = Get-ChildItem -Path $pythonDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($latestPython) {
      $litellmExe = Join-Path $pythonDir $latestPython.Name "Scripts\litellm.exe"
    }
  }
}

if (-not $litellmExe -or -not (Test-Path $litellmExe)) {
  throw "[FATAL] Verified execution entry point for litellm.exe not found. Ensure pyparts_deploy.ps1 executed successfully."
}

Write-Host "    |-- Resolved active LiteLLM target point: $litellmExe" -ForegroundColor Green

# 3. Intercept Legacy Daemon Duplications (Automated Overwrite Non-Interactive)
$existingService = Get-Service -Name "LiteLLM-Proxy" -ErrorAction SilentlyContinue
if ($existingService) {
  Write-Host "[WARNING] 'LiteLLM-Proxy' windows service is currently registered. Re-provisions automatically..." -ForegroundColor Yellow
  Stop-Service -Name "LiteLLM-Proxy" -ErrorAction SilentlyContinue
}

# 4. Modularity Validation: Verify local workspace asset components
$localConfigFile = Join-Path $PSScriptRoot "config.yml"
$localShortcodesFile = Join-Path $PSScriptRoot "shortcodes.yml"

if (-not (Test-Path $localConfigFile)) { throw "[FATAL] Target template data config.yml missing from source folder." }
if (-not (Test-Path $localShortcodesFile)) { throw "[FATAL] Target template data shortcodes.yml missing from source folder." }

# Secure runtime storage layout structure
if (-not (Test-Path $aiRoot)) { New-Item -ItemType Directory -Path $aiRoot | Out-Null }
if (-not (Test-Path $litellmRuntimeDir)) { New-Item -ItemType Directory -Path $litellmRuntimeDir | Out-Null }

# Pure Transport: Move configuration layouts to user hidden profile runtime area
Copy-Item -Path $localConfigFile -Destination $targetConfigFile -Force
Copy-Item -Path $localShortcodesFile -Destination $targetShortcodesFile -Force
Write-Host "    |-- Synced declarative config and shortcode matrix layout to user profile." -ForegroundColor Green

# 5. Background Daemon Provisioning via NSSM Wrapper Engine
Write-Host ">>> Configuring Host Background Process Infrastructure..." -ForegroundColor Yellow
& nssm remove "LiteLLM-Proxy" confirm -ErrorAction SilentlyContinue

# Establish clean NSSM system configurations
& nssm install "LiteLLM-Proxy" $litellmExe "--config $targetConfigFile --port 8000 --host 127.0.0.1"
& nssm set "LiteLLM-Proxy" AppDirectory $litellmRuntimeDir
& nssm set "LiteLLM-Proxy" AppStdout (Join-Path $litellmRuntimeDir "stdout.log")
& nssm set "LiteLLM-Proxy" AppStderr (Join-Path $litellmRuntimeDir "stderr.log")
& nssm set "LiteLLM-Proxy" Start SERVICE_AUTO_START

# Fire up active background daemon pipeline
Start-Service -Name "LiteLLM-Proxy"
Write-Host "`n[SUCCESS] LiteLLM core proxy background daemon is operational and active." -ForegroundColor Green
