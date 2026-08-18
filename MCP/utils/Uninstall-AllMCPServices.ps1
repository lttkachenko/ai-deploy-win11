<#
.SYNOPSIS
    Uninstalls all existing MCP Watcher and Server Windows services via NSSM.
.DESCRIPTION
    Iterates through provided service lists, stops them gracefully using NSSM,
    removes the service stubs from the Service Control Manager, purges the entire
    runtime assets directory, and wipes out service-specific log files while
    preserving third-party logs like llama-swap.
.EXAMPLE
    Uninstall-AllMCPServices -serviceNames @("mcp-server", "mcp-watcher") -mcpRuntimeDir "C:\.ai\venv\mcp" -logStorage "C:\.ai\log"
#>

function Uninstall-AllMCPServices {
  param(
    [Parameter(Mandatory=$true)]
    [string[]]$serviceNames,

    [Parameter(Mandatory=$true)]
    [string]$mcpRuntimeDir,

    [Parameter(Mandatory=$true)]
    [string]$logStorage
  )

  try {
    foreach ($svc in $serviceNames) {
      # Check if the service actually exists in the Windows Service Control Manager
      $existingService = Get-Service -Name $svc -ErrorAction SilentlyContinue
      if (-not $existingService) {
        Write-Host "  |-- Service '$($svc)' not found. Skipping removal." -ForegroundColor DarkGray
        continue
      }
      Write-Host "  |-- Stopping & removing service: $($svc)" -ForegroundColor Gray
      nssm.exe stop $svc 2>$null
      Start-Sleep -Seconds 1
      nssm.exe remove $svc confirm 2>$null
    }

    # Purge entire runtime tree AFTER all services are fully stopped and uninstalled
    Write-Host "`n[PHASE 6.0] Purging runtime assets directory..." -ForegroundColor Yellow
    if (Test-Path $mcpRuntimeDir) {
      # Remove files and subdirectories recurse-force to clean the slate
      Get-ChildItem -Path $mcpRuntimeDir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
      Write-Host "  |-- Runtime folder contents purged successfully." -ForegroundColor Gray
    } else {
      Write-Host "  |-- Runtime directory not found. Nothing to purge." -ForegroundColor DarkGray
    }

    # Wipe service-specific log files safely without touching llama-swap or other logs
    Write-Host "`n[PHASE 6.0] Purging service-specific log files..." -ForegroundColor Yellow
    if (Test-Path $logStorage) {
      foreach ($svc in $serviceNames) {
        if (-not [string]::IsNullOrWhiteSpace($svc)) {
          # Select and destroy files starting with the specific service name (e.g., ai-dev-rag-wtr*)
          Get-ChildItem -Path $logStorage -Filter "$svc*" -File | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
        }
      }
      Write-Host "  |-- Target service logs purged successfully." -ForegroundColor Gray
    } else {
      Write-Host "  |-- Log storage directory not found. Skipping log purge." -ForegroundColor DarkGray
    }

    return $true
  } catch {
    $ErrorMessage = $_.Exception.Message
    $FailedLine   = $_.InvocationInfo.ScriptLineNumber
    $FailedScript = $_.InvocationInfo.ScriptName

    Write-Error "[ERROR] Critical failure during deinstallation on line $FailedLine in $FailedScript"
    Write-Error "[DETAILS] Reason: $ErrorMessage"
  }

  return $false
}
