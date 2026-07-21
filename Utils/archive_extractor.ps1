param (
  [Parameter(Mandatory = $true)]
  [string]$ZipPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

# 1. Active extraction engine discovery
$sevenZipExe = "C:\Program Files\7-Zip\7z.exe"
$has7Zip = Test-Path $sevenZipExe
$archiveName = Split-Path -Path $ZipPath -Leaf

if (-not (Test-Path $OutputPath)) {
  New-Item -ItemType Directory -Path $OutputPath | Out-Null
}

# 2. Execution routing with integrated progress tracking
if ($has7Zip) {
  Write-Host "   |-- Spawning high-performance 7-Zip process for $archiveName..." -ForegroundColor Gray

  # Trigger 7z extraction with raw percent rendering redirection
  & $sevenZipExe x "$ZipPath" "-o$OutputPath" -y -bsp1 | ForEach-Object {
    if ($_ -match '(\d+)%') {
      $percent = [int]$Matches[1]
      Write-Progress -Activity "Extracting $archiveName via 7-Zip" `
                     -Status "Processing nodes... $percent%" `
                     -PercentComplete $percent
    }
  }
  Write-Progress -Activity "Extracting $archiveName via 7-Zip" -Completed
} else {
  Write-Host "   |-- Spawning native tar process for $archiveName..." -ForegroundColor Gray

  # Visual dynamic loader for native fallback execution
  $scriptBlock = {
    param($src, $dst)
    & tar.exe -xf $src -C $dst
  }

  $process = Start-Job -ScriptBlock $scriptBlock -ArgumentList $ZipPath, $OutputPath
  $spinner = @('|', '/', '-', '\')
  $counter = 0

  while ($process.State -eq 'Running') {
    $char = $spinner[$counter % $spinner.Length]
    Write-Progress -Activity "Extracting $archiveName via Tar Fallback" `
                   -Status "Decompressing data assets... $char"
    Start-Sleep -Milliseconds 200
    $counter++
  }

  Write-Progress -Activity "Extracting $archiveName via Tar Fallback" -Completed
  Receive-Job -Job $process | Out-Null
  Remove-Job -Job $process
}
