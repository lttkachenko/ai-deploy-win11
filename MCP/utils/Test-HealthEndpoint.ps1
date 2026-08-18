<#
.SYNOPSIS
  Probes the live HTTP /healthz endpoint of an MCP service.
.DESCRIPTION
  Extracts service name, host and port from the provided item object, constructs the health check URI,
  and polls it with a retry loop (default 8 attempts). Returns true if 'healthy' status is received;
  returns $false on failure after 12-th attempt.
.PARAMETER serviceCfg
  PSCustomObject containing "name", "host", and "port" properties.
.EXAMPLE
  Test-MCPServiceHealth $srvConfig "server"
#>

function Test-HealthEndpoint {
  param([PSCustomObject]$serviceCfg)

  [string]$cleanHost = ($serviceCfg.host ?? "http://127.0.0.1").TrimEnd('/') -replace 'http://|https://', ''
  $endpoint = "$($cleanHost):$($serviceCfg.port)/healthz"

  Write-Host "      |-- Probing live endpoint at $endpoint..." -ForegroundColor Yellow
  $maxAttempts = 8; $attempt = 1
  while ($attempt -le $maxAttempts) {
    try {
      $resp = Invoke-RestMethod -Uri $endpoint -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
      if ($resp.status -eq 'healthy') {
        Write-Host "      [SUCCESS] Server $($serviceCfg.Name) health endpoint verified." -ForegroundColor Green
        return $true
      }
    } catch {
      Write-Host "      [Attempt $attempt/$maxAttempts] Waiting for server initialization..." -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 5; $attempt++
  }

  Write-Host "      [FAIL] Server $($serviceCfg.Name) health endpoint failed after retries." -ForegroundColor Red
  return $false
}
