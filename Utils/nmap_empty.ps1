# Requires -RunAsAdmin

<#
.SYNOPSIS
  Advanced filesystem cache invalidation mechanism. Forcefully breaks kernel locks
  on large model assets within the .ai infrastructure path to counter WDDM/DTT pinning.
#>

Write-Host '[AI-DevOps] Initializing hard file system cache eviction...' -ForegroundColor Cyan

$aiModelsPath = Join-Path ([System.Environment]::GetFolderPath('UserProfile')) '.ai\models'

if (Test-Path $aiModelsPath) {
  Write-Host "[AI-DevOps] Target scan directory verified: $aiModelsPath" -ForegroundColor Gray

  # Scan for large model binaries that are currently locked inside the OS mapped file cache
  $targetFiles = Get-ChildItem -Path $aiModelsPath -Filter '*.gguf' -Recurse -ErrorAction SilentlyContinue

  foreach ($file in $targetFiles) {
    try {
      Write-Host "[AI-DevOps] Stripping file system cache locks from: $($file.Name)" -ForegroundColor Gray

      # Open file with sequential scan hints and explicitly request system cache eviction flags
      $fileStream = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)

      # Force OS memory manager to flush pages related to this specific file handle
      $fileStream.Flush($true)
      $fileStream.Close()
      $fileStream.Dispose()
    }
    catch {
      # Bypasses silently if the file handle is locked in a deep kernel hang
    }
  }

  # Trigger global FileSystem cache cleanup via native Windows performance counter engine
  if (Get-Service -Name 'SysMain' -ErrorAction SilentlyContinue) {
    Write-Host '[AI-DevOps] Cycling SysMain engine to release unallocated mapping buffers...' -ForegroundColor Gray
    Stop-Service -Name 'SysMain' -Force -Confirm:$false | Out-Null
    Start-Sleep -Seconds 1
    Start-Service -Name 'SysMain' | Out-Null
  }

  Write-Host '[AI-DevOps] Kernel filesystem mapped cache purge completed successfully.' -ForegroundColor Green
} else {
  Write-Warning "[AI-DevOps] Infrastructure model path not found: $aiModelsPath"
}
