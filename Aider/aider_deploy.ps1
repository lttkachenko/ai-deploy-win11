$ErrorActionPreference = "Stop"

# 1. Environment and Subsystem Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$wslUser = (wsl exec whoami).Trim()

if (-not $wslUser) {
  throw "[FATAL] WSL Linux subsystem is unreachable or completely halted."
}

# Modernized host runtime root mapping inside the hidden master folder
$aiRoot = Join-Path $homeDir ".ai"
$contextRuntimeRoot = Join-Path $aiRoot "context"

Write-Host ">>> Starting Refactored Aider Subsystem Synchronization..." -ForegroundColor Yellow
Write-Host "    |-- WSL Subsystem Target User: $wslUser" -ForegroundColor Cyan
Write-Host "    |-- Vector RAG Mode Active: Skipping flat /skills and /insights transport." -ForegroundColor Green

# 2. Assert and Scaffold Internal Directory Tree Inside WSL Target Environment
Write-Host ">>> Scaffolding directory structures inside WSL guest..." -ForegroundColor Yellow
$wslHome = (wsl exec sh -c "echo `$HOME").Trim()

# Flattened runtime architecture: everything sits inside a single unified .aider root
wsl exec mkdir -p "$wslHome/.aider" "$wslHome/.aider/roles" "$wslHome/.aider/prompts" "$wslHome/.aider/user"

# 3. Execute Guest Package Installation Bootstrap
$localDeployScript = Join-Path $PSScriptRoot "aider_deploy.sh"
if (Test-Path $localDeployScript) {
  Write-Host ">>> Bootstrapping Linux environment and Aider packages..." -ForegroundColor Yellow
  $wslDeployPath = wslpath "`$localDeployScript"
  & wsl cp "$wslDeployPath" "$wslHome/aider_deploy.sh"
  & wsl chmod +x "$wslHome/aider_deploy.sh"
  & wsl "$wslHome/aider_deploy.sh"
  & wsl rm "$wslHome/aider_deploy.sh"
} else {
  throw "[FATAL] Guest bootstrap script 'aider_deploy.sh' missing from source directory."
}

# 4. Deliver Modular Configurations via Pure Transport Protocol
Write-Host ">>> Aligning global configuration parameters..." -ForegroundColor Yellow
$localConfigFile = Join-Path $PSScriptRoot "config.yml"
if (Test-Path $localConfigFile) {
  $wslConfigPath = wslpath "`$localConfigFile"
  & wsl cp "$wslConfigPath" "$wslHome/.aider/config.yml"
} else {
  throw "[FATAL] Declarative configuration template config.yml missing from source directory."
}

# 5. Synchronize Execution Runner and MCP Bridge Assets (FIXED AGNOSTIC PATHS)
Write-Host ">>> Synchronizing execution runners and FastMCP bridge..." -ForegroundColor Yellow
$localRunScript = Join-Path $PSScriptRoot "aider_run.sh"

# Resolving cross-modular path safely using .Parent descriptor to eliminate fragile '..' literals
$distRoot = (Get-Item $PSScriptRoot).Parent.FullName
$localMcpScript = Join-Path $distRoot "Qdrant\qdrant_mcp.py"

if (-not (Test-Path $localRunScript)) { throw "[FATAL] Core script 'aider_run.sh' missing from source directory." }
if (-not (Test-Path $localMcpScript)) { throw "[FATAL] MCP bridge asset 'qdrant_mcp.py' missing from resolved Qdrant root: $localMcpScript" }

$wslRunPath = wslpath "`$localRunScript"
$wslMcpPath = wslpath "`$localMcpScript"

& wsl cp "$wslRunPath" "$wslHome/.aider/aider_run.sh"
& wsl chmod +x "$wslHome/.aider/aider_run.sh"

& wsl cp "$wslMcpPath" "$wslHome/.aider/qdrant_mcp.py"
& wsl chmod +x "$wslHome/.aider/qdrant_mcp.py"

# 6. Synchronize Runtime Structural Session Context From Host User Workspace (~/.ai/context/)
Write-Host ">>> Syncing core session infrastructure pools into guest environment..." -ForegroundColor Yellow

# RAG takes care of skills and insights, we only transfer bootstrap context layers
$sessionContextPools = @("roles", "prompts", "user")

foreach ($subDir in $sessionContextPools) {
  $runtimeSubDirPath = Join-Path $contextRuntimeRoot $subDir
  if (Test-Path $runtimeSubDirPath) {
    Write-Host "    |-- Synchronizing bootstrap context pool: .ai\context\$subDir" -ForegroundColor Cyan
    Get-ChildItem -Path $runtimeSubDirPath -File | ForEach-Object {
      # Direct flat mapping execution inside WSL target folders safely escaped from spaces
      $wslTargetFile = "$wslHome/.aider/$subDir/$($_.Name)"
      $wslItemPath = wslpath "`$($_.FullName)"
      & wsl cp "$wslItemPath" $wslTargetFile
    }
  } else {
    Write-Host "    |-- [WARNING] Source runtime folder '$runtimeSubDirPath' not found. Skipping sync." -ForegroundColor Yellow
  }
}

Write-Host "`n[SUCCESS] Aider environment completely mapped with native Qdrant RAG protocol." -ForegroundColor Green
