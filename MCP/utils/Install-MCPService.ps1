<#
.SYNOPSIS
    Installs a Python-based MCP component (Watcher or Server) as a persistent Windows service via NSSM.
.DESCRIPTION
    Creates an NSSM service stub pointing to the virtual environment Python interpreter, passes the target script path and service name as arguments, configures I/O redirection to the log directory, sets restart delays, and launches the service.
.PARAMETER service
    PSCustomObject containing metadata (Name, Host, Ports).
.PARAMETER scriptName
    Filename of the Python script to execute (e.g., 'mcp_watcher.py' or 'mcp_server.py').
.EXAMPLE
    Install-MCPService -service $watcherObj -scriptName 'mcp_watcher.py'
.PARAMETER nssmExe
    Absolute path to the NSSM executable binary.
.PARAMETER venvPython
    Path to the Python interpreter inside the virtual environment.
.PARAMETER mcpRuntimeDir
    Working directory for the MCP Python scripts.
.PARAMETER logStorage
    Directory path for service stdout/stderr log redirection.
#>

function Install-MCPService {
  param(
    [PSCustomObject]$service,
    [string]$scriptName,
    [string]$nssmExe,
    [string]$venvPython,
    [string]$mcpRuntimeDir,
    [string]$logStorage
  )

  Write-Host "  |-- Processing $($service.name)..." -ForegroundColor Yellow

  $FullScriptPath = Join-Path $mcpRuntimeDir $scriptName

  # 1. Create service stub
  & $nssmExe install $service.name "powershell.exe" > $null
  # 2. Set runtime dir
  & $nssmExe set $service.name AppDirectory "`"$mcpRuntimeDir`"" > $null

  # 3. Pass service arguments
  $CleanArgs = "-NoProfile -Command `"$venvPython -u `"$FullScriptPath`" -n $($service.name)`""
  & $nssmExe set $service.name AppParameters $CleanArgs > $null

  # 4. Passing additional service params
  & $nssmExe set $service.name AppStdout (Join-Path $logStorage "$($service.name).stdout.log") > $null
  & $nssmExe set $service.name AppStderr (Join-Path $logStorage "$($service.name).stderr.log") > $null
  & $nssmExe set $service.name AppRestartDelay 5000 > $null
  & $nssmExe set $service.name AppStopMethodSkip 3 > $null

  try {
    # Start service AFTER config is applied
    Write-Host '      [STARTING] Launching service...' -ForegroundColor Green
    Start-Service -Name $service.name
    Start-Sleep -Seconds 1

    return $true
  } catch {
    Write-Error "[ERROR] Critical failure during installation of service '$($service.name)'. See '$($service.name).stderr.log for details'"
  }

  return $false
}
