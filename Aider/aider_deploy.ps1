# .\Aider\aider_deploy.ps1 - WSL Guest Aider Orchestration Pipeline
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

# --- Phase 1: Environment and Subsystem Discovery ---
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$wslUser = (wsl exec whoami).Trim()

if (-not $wslUser) {
  throw '[FATAL] WSL Linux subsystem is unreachable or completely halted.'
}

# Resolve baseline distribution directory layout safely
$currentScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$distRoot = (Get-Item $currentScriptDir).Parent.FullName

# --- Phase 2: Assert and Scaffold Internal Directory Tree Inside WSL ---
Write-Host '>>> Scaffolding directory structures inside WSL guest...' -ForegroundColor Yellow
$wslHome = (wsl exec sh -c 'echo $HOME').Trim()

# Scaffold core execution spaces inside the single unified root folder
wsl exec mkdir -p "$wslHome/.aider"

# --- Phase 3: Execute Guest Package Installation Bootstrap ---
$localDeployScript = Join-Path $currentScriptDir 'aider_deploy.sh'
if (Test-Path $localDeployScript) {
  Write-Host '>>> Bootstrapping Linux environment and Aider packages...' -ForegroundColor Yellow
  $wslDeployPath = (wsl -e wslpath $localDeployScript).Trim()
  & wsl cp "$wslDeployPath" "$wslHome/aider_deploy.sh"
  & wsl chmod +x "$wslHome/aider_deploy.sh"
  & wsl "$wslHome/aider_deploy.sh"
  & wsl rm "$wslHome/aider_deploy.sh"
} else {
  throw '[FATAL] Guest bootstrap script ''aider_deploy.sh'' missing from source directory.'
}

# --- Phase 4: Deliver Centralized Configuration via Native Stream Injection ---
Write-Host '>>> Transporting global configuration parameters...' -ForegroundColor Yellow

$localConfigFile = Join-Path $currentScriptDir 'aider.conf.yml'
if (-not (Test-Path $localConfigFile)) {
  $localConfigFile = Join-Path $currentScriptDir 'aider_config.yml'
}

if (Test-Path $localConfigFile) {
  # Read host config text to pass it directly bypassing filesystem boundaries
  $configText = Get-Content -Path $localConfigFile -Raw

  # Inject via pure bash heredoc stream directly into the unified .aider root slot
  $wslCommand = "cat << 'EOF' > ~/.aider/aider.conf.yml`n$configText`nEOF"
  wsl exec bash -c $wslCommand

  Write-Host '  |-- Successfully injected distribution configuration to unified .aider container.' -ForegroundColor Gray
} else {
  throw "[FATAL] Declarative configuration template missing from resolved path: $localConfigFile"
}

# --- Phase 5: Synchronize Execution Runner ---
Write-Host '>>> Synchronizing execution runners...' -ForegroundColor Yellow
$localRunScript = Join-Path $currentScriptDir 'aider_run.sh'

if (-not (Test-Path $localRunScript)) {
  throw '[FATAL] Core script ''aider_run.sh'' missing from source directory.'
}

$wslRunPath = (wsl -e wslpath $localRunScript).Trim()
& wsl cp "$wslRunPath" "$wslHome/.aider/aider_run.sh"
& wsl chmod +x "$wslHome/.aider/aider_run.sh"

# --- Phase 6: Evict Legacy Context Debris & Enforce Vector Isolation ---
Write-Host '>>> Enforcing vector isolation and sanitizing guest environment...' -ForegroundColor Yellow

# Pure house-cleaning sequence: eradicate flat dumps, orphan bridges, and dirty configurations
wsl exec rm -rf "$wslHome/.aider/roles" "$wslHome/.aider/prompts" "$wslHome/.aider/user" "$wslHome/.aider/qdrant_mcp.py" "$wslHome/.aider.conf.yml" "$wslHome/.config/aider"
Write-Host '  |-- Telemetry: Legacy flat sub-directories and orphan scripts evicted.' -ForegroundColor Green

Write-Host "`n[SUCCESS] Aider environment completely mapped with native Qdrant RAG protocol." -ForegroundColor Green
