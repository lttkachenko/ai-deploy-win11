<#
.SYNOPSIS
  Validates the operational state of all installed MCP services.
.DESCRIPTION
  Iterates through provided service objects, checks their Windows Service Control Manager status via Get-CimInstance, and probes their respective HTTP /healthz endpoints using Test-HealthEndpoint. Returns true only if all services are running and healthy.
.PARAMETER serviceCfg
  PSCustomObject containing "name", "host", and "port" properties.
.EXAMPLE
  Test-MCPServiceHealth $srvConfig "server"
#>

function Test-MCPServiceHealth {
  param(
    [PSCustomObject]$serviceCfg,
    [string]$serviceType
  )

  try {
    # Check Windows Service Control Manager state first
    Write-Host "[PHASE 6.3.2] Validating service health for $($serviceCfg.Name) ($($serviceType))..." -ForegroundColor Yellow
    $svcState = (Get-CimInstance -ClassName Win32_Service -Filter "Name = '$($serviceCfg.Name)'").State
    if ($svcState -ne 'Running') { throw "[FAIL] Windows service is not running. State: '$svcState'" }

    if ($serviceType -eq "server") {
      # Check HTTP /healthz endpoint second (for MCP Servers only!!!)
      $httpStatus = Test-HealthEndpoint $serviceCfg
      if (-not $httpStatus) { throw "HTTP health check failed." }
      Write-Host "  |-- MCP Server $($serviceCfg.Name) is fully operational." -ForegroundColor Green
    }
  } catch {
    Write-Error "[ERROR] Validation failure for service '$($serviceCfg.Name)': $_"
    return $false
  }

  return $true
}
