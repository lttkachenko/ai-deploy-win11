<#
.SYNOPSIS
    Orchestrates MCP Stack deployment lifecycle (uninstall, sync, compile, service install, health validation).
.DESCRIPTION
    Loads configuration from mcp.conf.yml, provisions Python assets into ~/.ai/venv/mcp/, compiles bytecode, registers Watcher and Server services via NSSM, spawns companion Inspector daemons, and validates HTTP /healthz endpoints.
.EXAMPLE
    .\mcp_deploy.ps1
.NOTES
    Requires: powershell-yaml module, nodejs_finder.ps1, nssm.exe in ~/.ai/bin/, Python venv at ~/.ai/venv/.
#>

$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\utils\Uninstall-AllMCPServices.ps1" -Force | Out-Null
Import-Module "$PSScriptRoot\utils\Precompile-MCPAssets.ps1" -Force | Out-Null
Import-Module "$PSScriptRoot\utils\Test-HealthEndpoint.ps1" -Force | Out-Null
Import-Module "$PSScriptRoot\utils\Test-MCPServiceHealth.ps1" -Force | Out-Null
Import-Module "$PSScriptRoot\utils\Install-MCPInspector.ps1" -Force | Out-Null
Import-Module "$PSScriptRoot\utils\Install-MCPService.ps1" -Force | Out-Null

# --- Phase 0: Module & Path Initialization (DOS-13 Layout) ---
Import-Module powershell-yaml -Force | Out-Null
Import-Module "$PSScriptRoot\..\Utils\nodejs_finder.ps1" -Force | Out-Null

[string]$aiRoot = Join-Path ([System.Environment]::GetFolderPath('UserProfile')) '.ai'
[string]$binStorage = Join-Path $aiRoot 'bin'
[string]$logStorage = Join-Path $aiRoot 'log'
[string]$mcpRuntimeDir = Join-Path $aiRoot 'venv\mcp'
[string]$confDir = Join-Path $aiRoot 'conf'
[string]$VenvPython = Join-Path $aiRoot 'venv\Scripts\python.exe'
if (-not (Test-Path $VenvPython)) { $VenvPython = Join-Path $aiRoot 'venv\mcp\Scripts\python.exe' }
[string]$nssmExe = Join-Path $binStorage 'nssm.exe'

# --- Config Loading via Utility ---
$confPath = Join-Path $PSScriptRoot 'mcp.conf.yml'
if (-not (Test-Path $confPath)) { throw "[FATAL] Config path not found: $confPath" }

try {
  $config = & "$PSScriptRoot\..\Utils\config_parser.yml.ps1" -ConfigPath $confPath
} catch {
  throw $_
}

# --- Pre-Deployment Table ---
# Explicit property mapping to prevent table truncation/alignment bugs'
$inspectorConfig = if ($null -ne $config.inspector) { $config.inspector } else { @{} }

$srvList = if ($null -ne $config.servers) {
  @($config.servers.Values | ForEach-Object {
    [PSCustomObject]@{
      Name    = $_.name ?? 'default-srv'
      Host    = $_.host ?? 'http://127.0.0.1'
      Port    = $_.port ?? 8096
      LogDir  = $logStorage
    }
  })
} else { @() }

$wchList = if ($null -ne $config.watchers) {
  @($config.watchers.Values | ForEach-Object {
    [PSCustomObject]@{
      Name    = $_.name ?? 'default-wtr'
      Store   = $_.store ?? 'Not Found'
      Port    = $_.port ?? 8093
      LogDir  = $logStorage
    }
  })
} else { @() }

Write-Host "`n[PHASE 6] MCP Stack Deployment Matrix" -ForegroundColor Cyan
Write-Host '-----------------------------------------------------------' -ForegroundColor Gray
if ($srvList.Count -gt 0) {
  Write-Host 'SERVERS:' -ForegroundColor Green
  $srvList | Format-Table Name, Host, Port, LogDir -AutoSize -Wrap | Out-String | Write-Host
}
if ($wchList.Count -gt 0) {
  Write-Host 'WATCHERS:' -ForegroundColor Green
  $wchList | Format-Table Name, Store, Port, LogDir -AutoSize -Wrap | Out-String | Write-Host
}
Write-Host '-----------------------------------------------------------' -ForegroundColor Gray

# --- Phase 6.0: Global Deinstallation & Cache Purge (SEPARATED) ---
Write-Host "`n[PHASE 6.0] Uninstalling Existing Legacy Services..." -ForegroundColor Yellow
# Build unified service names array for uninstaller
$allServiceNames = @($inspectorConfig.name) +
  ($srvList.Name | Where-Object { $_ }) +
  ($wchList.Name | Where-Object { $_ }) |
  Select-Object -Unique

if (-not (Uninstall-AllMCPServices -serviceNames $allServiceNames -mcpRuntimeDir $mcpRuntimeDir -logStorage $logStorage)) {
  throw "[FATAL] Legacy services deinstallation failed!. Aborting deployment."
}

# --- Phase 6.1: Physical Asset Sync (Clean Architecture Layout) ---
Write-Host "`n[PHASE 6.1] Synchronizing Python Assets, Libraries & Configs..." -ForegroundColor Yellow
if (-not (Test-Path $mcpRuntimeDir)) { New-Item -ItemType Directory -Path $mcpRuntimeDir | Out-Null }
if (-not (Test-Path $confDir))     { New-Item -ItemType Directory -Path $confDir     | Out-Null }

# 1. Synchronize executable runners (removed deprecated mcp_api.py)
$syncFiles = @('mcp_server.py', 'mcp_watcher.py')
foreach ($file in $syncFiles) {
  $srcFile = Join-Path $PSScriptRoot $file
  if (Test-Path $srcFile) {
    Copy-Item -Path $srcFile -Destination (Join-Path $mcpRuntimeDir $file) -Force
    Write-Host "  |-- Synced: venv\mcp\$file" -ForegroundColor Gray
  } else { throw "[FATAL] Missing runtime asset: $srcFile" }
}

# 2. Synchronize the entire shared libraries package (libs/store and libs/mcp)
$srcLibsFolder = Join-Path $PSScriptRoot 'libs'
$dstLibsFolder = Join-Path $mcpRuntimeDir 'libs'

if (Test-Path $srcLibsFolder) {
  # -Recurse copies the folder tree, -Force overwrites modified files
  Copy-Item -Path $srcLibsFolder -Destination $mcpRuntimeDir -Recurse -Force
  Write-Host "  |-- Synced: venv\mcp\libs\ [Packages: store, mcp]" -ForegroundColor Gray
} else {
  throw "[FATAL] Critical package mirror missing: $srcLibsFolder"
}

# 3. Synchronize configuration file
Copy-Item -Path $confPath -Destination (Join-Path $confDir 'mcp.conf.yml') -Force
Write-Host "  |-- Synced: conf\mcp.conf.yml" -ForegroundColor Gray

# --- Phase 6.1.1: Precompile Assets to Bytecode ---
if (-not (Precompile-MCPAssets -venvPython $VenvPython -mcpRuntimeDir $mcpRuntimeDir)) {
  throw "[FATAL] Bytecode compilation failed. Aborting deployment."
}

# --- Phase 6.1.2: Global Env & NSSM Lifecycle ---
Write-Host "`n[PHASE 6.2] Injecting global PYTHONUNBUFFERED=1..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("PYTHONUNBUFFERED", "1", [System.EnvironmentVariableTarget]::User) > $null
Write-Host "  |-- OS-level env var injected." -ForegroundColor Gray

# --- Phase 6.2: MCP Inspector Installation ---
Write-Host "`n[PHASE 6.2] Installing MCP Inspector..." -ForegroundColor Yellow
if ($inspectorConfig.name) {
  Install-MCPInspector -target_name $inspectorConfig.name -target_host $inspectorConfig.host -target_port $inspectorConfig.port -target_transport "http" -nssmExe $nssmExe -logStorage $logStorage
} else {
  Write-Host "  |-- No inspector config found. Skipping." -ForegroundColor DarkGray
}

# --- Phase 6.3: NSSM Lifecycle Installer & Validation ---
foreach ($wch in $wchList) {
  if (Install-MCPService -service $wch -scriptName 'mcp_watcher.py' -nssmExe $nssmExe -venvPython $VenvPython -mcpRuntimeDir $mcpRuntimeDir -logStorage $logStorage) {
    Test-MCPServiceHealth $wch 'watcher'
  } else {
    throw "[FATAL] Deployment halted due to component failure."
  }
}
foreach ($srv in $srvList) {
  if (Install-MCPService -service $srv -scriptName 'mcp_server.py' -nssmExe $nssmExe -venvPython $VenvPython -mcpRuntimeDir $mcpRuntimeDir -logStorage $logStorage) {
    Test-MCPServiceHealth $srv 'server'
  } else {
    throw "[FATAL] Deployment halted due to component failure."
  }
}

Write-Host "`n[SUCCESS] MCP Stack deployment & validation complete." -ForegroundColor Green
