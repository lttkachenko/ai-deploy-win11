# .\Utils\asset_downloader.ps1 - Unified Asset Downloader Core Engine
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

param (
  [Parameter(Mandatory = $true)]
  [string]$DependencyJson,

  [Parameter(Mandatory = $true)]
  [string]$DestinationDir
)

$ErrorActionPreference = 'Stop'

# Hydrate compressed raw string text back into valid object layout safely
$DependencySpec = ConvertFrom-Json -Input $DependencyJson

# 1. Enforce production secure TLS 1.2 protocol for network transfer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not (Test-Path $DestinationDir)) {
  New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
}

$depName = $DependencySpec.name
$targetVersion = $DependencySpec.version

# Polyfill to check property names from manifest specification safely
$targetBinary = $null
if ($DependencySpec.PSObject.Properties['target_file']) {
  $targetBinary = $DependencySpec.target_file
}
if ($null -eq $targetBinary -and $DependencySpec.PSObject.Properties['binary']) {
  $targetBinary = $DependencySpec.binary
}

# Advanced multi-path discovery engine for windows environments
$checkPath = Join-Path $DestinationDir $targetBinary
$lmsProfileCheck = Join-Path $env:LOCALAPPDATA "Programs\lmstudio\$targetBinary"

# Split complex nested logical blocks into flat sequential execution checks
$isInstalled = $false
$isRawModel = $targetBinary.EndsWith('.gguf')

# Idempotency check for regular application binaries and daemons
if (-not $isRawModel) {
  if ($depName -eq 'lm-studio-headless-daemon') {
    if (Test-Path $lmsProfileCheck) { $isInstalled = $true }
    $globalCommandCheck = Get-Command $targetBinary -ErrorAction SilentlyContinue
    if ($globalCommandCheck) { $isInstalled = $true }
  } else {
    if (Test-Path $checkPath) { $isInstalled = $true }
  }

  if ($isInstalled) {
    Write-Host " |-- [SKIPPED] Dependency $depName is already verified on this host machine. Skipping download pipeline." -ForegroundColor Green
    return
  }
}

Write-Host ">>> Processing delivery container for: $depName..." -ForegroundColor Cyan

# RESOLUTION PATH A: Declarative Bootstrap Command Execution
if ($DependencySpec.PSObject.Properties['bootstrap_command']) {
  if ($depName -eq 'lm-studio-headless-daemon') {
    $cmd = $DependencySpec.bootstrap_command
    Write-Host "   |-- Ingesting component via bootstrap payload: $cmd" -ForegroundColor Yellow

    $spinner = @('|', '/', '-', '\')
    $counter = 0

    $psi = [System.Diagnostics.ProcessStartInfo]::new("powershell.exe", "-NoProfile -Command `"$cmd`"")
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($psi)

    while (-not $process.HasExited) {
      $char = $spinner[$counter % $spinner.Length]
      Write-Progress -Activity "Executing Bootstrap Routine for $depName" `
                     -Status "Processing operations inside isolated host process... $char"
      Start-Sleep -Milliseconds 250
      $counter++
    }

    Write-Progress -Activity "Executing Bootstrap Routine for $depName" -Completed

    if ($process.ExitCode -ne 0) {
      $errTrace = $process.StandardError.ReadToEnd()
      throw "[FATAL] Script payload execution collapsed with ExitCode $($process.ExitCode). Trace: $errTrace"
    }

    Write-Host "   |-- [SUCCESS] Bootstrap injection sequence completed for: $depName" -ForegroundColor Green
    return
  }
}

# RESOLUTION PATH B: Standard Remote Asset Download and Unpack Router
if ($DependencySpec.PSObject.Properties['url']) {
  $url = $DependencySpec.url

  if ($isRawModel) {
    $productionDst = Join-Path $DestinationDir $targetBinary

    # Idempotency check for neural weights: Skip instantly if valid file exists (DOS-8 Compliance)
    if (Test-Path $productionDst) {
      Write-Host "   |-- [SKIPPED] Model asset is already in place! Verified target slot: $productionDst" -ForegroundColor Green
      return
    }

    # LM Studio Style: Establish absolute temporary download destination mapping context
    $tempDownloadDst = Join-Path $DestinationDir "download-$targetBinary"

    Write-Host "   |-- [RAW STREAM] Detected neural weight matrix file. Streaming straight to target slot..." -ForegroundColor Cyan
    try {
      # Local ISP Routing Fix: Flush unstable local DNS resolver cache prior to web stream ingestion
      Write-Host '   |-- [CRITICAL DNS FIX] Flushing host DNS cache and forcing network cooldown...' -ForegroundColor Gray
      & ipconfig.exe /flushdns | Out-Null
      Start-Sleep -Seconds 1

      Write-Host "   |-- Delivery pipeline matched to remote endpoint: $url" -ForegroundColor Yellow

      $oldProgress = $ProgressPreference
      $ProgressPreference = 'Continue'

      # Stream web data payload directly into temporary prefix file
      Invoke-WebRequest -Uri $url -OutFile $tempDownloadDst -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -MaximumRedirection 5

      $ProgressPreference = $oldProgress

      # Atomic filesystem transaction: swap temporary layer onto production target slot
      Move-Item -Path $tempDownloadDst -Destination $productionDst -Force
      Write-Host "   |-- [SUCCESS] Ingested verified runtime model asset: $productionDst" -ForegroundColor Green
    } catch {
      if (Test-Path $tempDownloadDst) { Remove-Item -Path $tempDownloadDst -Force -ErrorAction SilentlyContinue }
      throw "[FATAL] Failed streaming raw weight file from remote CDN pipeline. Trace: $_"
    }
  } else {
    # Default routing lane for structural zip archives and tooling binaries
    $tempWorkspace = Join-Path $env:TEMP "ai_delivery_$(Get-Random)"
    $zipDst = Join-Path $tempWorkspace 'package_stream.zip'
    try {
      New-Item -ItemType Directory -Path $tempWorkspace -Force | Out-Null

      # Local ISP Routing Fix: Flush unstable local DNS resolver cache prior to web stream ingestion
      Write-Host '   |-- [CRITICAL DNS FIX] Flushing host DNS cache and forcing network cooldown...' -ForegroundColor Gray
      & ipconfig.exe /flushdns | Out-Null
      Start-Sleep -Seconds 1

      Write-Host "   |-- Delivery pipeline matched to remote endpoint: $url" -ForegroundColor Yellow

      $oldProgress = $ProgressPreference
      $ProgressPreference = 'Continue'

      Invoke-WebRequest -Uri $url -OutFile $zipDst -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -MaximumRedirection 5

      $ProgressPreference = $oldProgress

      $extractorScript = Join-Path $PSScriptRoot 'archive_extractor.ps1'
      if (-not (Test-Path $extractorScript)) {
        throw "[FATAL] Extraction subsystem missing. Expected node at: $extractorScript"
      }

      $extractPath = Join-Path $tempWorkspace 'extracted_payload'
      & $extractorScript -ZipPath $zipDst -OutputPath $extractPath

      $matchedFile = Get-ChildItem -Path $extractPath -Recurse -Filter $targetBinary | Select-Object -First 1
      if ($matchedFile) {
        $productionDst = Join-Path $DestinationDir $targetBinary
        Copy-Item -Path $matchedFile.FullName -Destination $productionDst -Force
        Write-Host "   |-- [SUCCESS] Ingested verified runtime binary asset into target slot: $productionDst" -ForegroundColor Green
      } else {
        throw "[FATAL] Integrity verification failed. Target element ($targetBinary) missing inside decompressed payload stream."
      }
    }
    finally {
      if (Test-Path $tempWorkspace) {
        Remove-Item -Path $tempWorkspace -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
  }
} else {
  throw '[FATAL] Invalid manifest element binding. Dependency spec must contain either url or bootstrap_command.'
}
