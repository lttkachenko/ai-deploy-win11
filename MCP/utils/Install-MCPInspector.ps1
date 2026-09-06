<#
.SYNOPSIS
  Installs the MCP Inspector UI daemon as a persistent Windows service via NSSM.
.DESCRIPTION
  Provisions a globally installed @mcp-use/inspector instance, configures Node.js runtime paths, and registers it as a background service bound to a custom host/port. Bypasses initial server attachments for runtime UI-driven target management.
.PARAMETER target_name
  Exact name of the target Windows service to be registered (e.g., 'ai-sys-mcp-inspector').
.PARAMETER target_host
  The network host address where the inspector UI will bind (e.g., 'http://127.0.0.1' or 'http://localhost').
.PARAMETER target_port
  Local port number where the inspector UI will listen (e.g., 8095).
.PARAMETER target_transport
  The preferred network protocol abstraction (e.g., 'http' for Streamable HTTP).
.PARAMETER nssmExe
  Absolute path to the NSSM executable binary.
.PARAMETER logStorage
  Directory path for service stdout/stderr log redirection.
#>

function Install-MCPInspector {
  param(
    [string]$target_name,
    [string]$target_host,
    [int]$target_port,
    [string]$target_transport,
    [string]$nssmExe,
    [string]$logStorage
  )

  Write-Host "      [INSPECTOR] Provisioning global fork daemon '$($target_name)' on port $($target_port)..." -ForegroundColor Yellow

  # 1. Cleanup old service instance via SCM/NSSM if exists
  if (Get-Service -Name $target_name -ErrorAction SilentlyContinue) {
    & $nssmExe stop $target_name > $null 2>&1
    & $nssmExe remove $target_name confirm > $null 2>&1
    Start-Sleep -Seconds 1
  }

  # 2. Validate that Node.js environment is active
  $NodeExe = Find-NodeJSBinary
  if (-not (Test-Path $NodeExe)) {
    Write-Error "      [INSPECTOR][ERROR] Node.js binary could not be resolved from NVM storage."
    return $false
  }

  try {
    # 3. Force global installation of the community fork via system context
    Write-Host "      [INSPECTOR] Ensuring @mcp-use/inspector is globally installed..." -ForegroundColor Cyan
    & npm install -g @mcp-use/inspector > $null 2>&1

    # 4. Provision Windows Service stub via NSSM using global npx from $PATH
    & $nssmExe install $target_name "cmd.exe" > $null
    & $nssmExe set $target_name AppDirectory "`"$mcpRuntimeDir`"" > $null

    # 5. Bind parameters to execute globally available npx
    $InspectorArgs = "/c npx @mcp-use/inspector --port $($target_port) --no-open"
    & $nssmExe set $target_name AppParameters $InspectorArgs > $null

    # 6. Inject target network bindings and Grafana/Pino production log configurations into Service Environment
    $ServiceEnv = "PORT=$target_port`nNODE_ENV=production`nMCP_TRANSPORT=$target_transport`nLOG_LEVEL=debug"
    & $nssmExe set $target_name AppEnvironmentExtra $ServiceEnv > $null

    # 7. Standard I/O redirection and throttling (Optimized for Grafana Promtail json scavenging)
    # Logging to JSON for Grafana
    & $nssmExe set $target_name AppStdout (Join-Path $logStorage "$($target_name).json.log") > $null
    & $nssmExe set $target_name AppStderr (Join-Path $logStorage "$($target_name).stderr.log") > $null
    & $nssmExe set $target_name AppRestartDelay 5000 > $null

    # 8. Fire up the engine and validate state using native Windows SCM (Get-Service)
    Write-Host "      [INSPECTOR] Attempting to start at: $($target_host):$($target_port)" -ForegroundColor Cyan
    Start-Service -Name $target_name -ErrorAction Stop
    Start-Sleep -Seconds 2

    # Validation strictly via standard OS mechanisms
    $ServiceState = (Get-Service -Name $target_name).Status
    if ($ServiceState -ne 'Running') {
      throw "Service failed to stabilize in Running state. Current native status: '$($ServiceState)'"
    }

    Write-Host "      [INSPECTOR][SUCCESS] Multi-Connection UI alternative is alive at: $($target_host):$($target_port)" -ForegroundColor Green
    return $true
  }
  catch {
    Write-Error "      [INSPECTOR][ERROR] Critical breakdown during fork daemon deployment: $($_.Exception.Message)"
  }

  return $false
}
