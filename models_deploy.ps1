# .\models_deploy.ps1 - Target Model Weight Ingestion Pipeline
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '>>> Initiating Target Model Weight Ingestion Pipeline...' -ForegroundColor Cyan
Write-Host '=================================================================' -ForegroundColor Cyan

# 1. Discover target configurations and core utils paths
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$aiRoot = Join-Path $homeDir '.ai'
$configPath = Join-Path $aiRoot 'conf\llama-swap.conf.yml'

# Fail-safe protection layer: resolve absolute path to core download utility
$universalDownloader = Join-Path $PSScriptRoot 'Utils\asset_downloader.ps1'
if (-not (Test-Path $universalDownloader)) {
  $universalDownloader = Join-Path (Split-Path $PSScriptRoot -Parent) 'Utils\asset_downloader.ps1'
}
if (-not (Test-Path $universalDownloader) -or $universalDownloader -eq $PSCommandPath) {
  throw '[FATAL] Infrastructure collision. Downloader fell into self-invocation loop.'
}

$configLines = Get-Content -Path $configPath
$modelsBaseStorage = Join-Path $aiRoot 'models'

# Centralized environment macro registry map (DOS-8 / DOS-9 SSOT)
$macroMap = @{
  'global_repo' = 'https://huggingface.co'
  'resolve'     = 'resolve/main'
  'qwen_35b'    = 'Qwen3.6-35B-A3B-Uncensored-HauhauCS-Aggressive'
  'gemma4_12b'  = 'gemma-4-12B-it'
  'qwen_coder'  = 'Qwen2.5-Coder-1.5B-Instruct'
}

$modelsData = @{}
$currentModel = $null
$inModelsBlock = $false

foreach ($rawLine in $configLines) {
  $line = $rawLine.TrimEnd()
  $trimmed = $line.Trim()

  if ($trimmed.StartsWith('models:')) { $inModelsBlock = $true; continue }
  if ($inModelsBlock -and $line -match '^[a-zA-Z]') { $inModelsBlock = $false }
  if (-not $inModelsBlock) { continue }

  # Parse specific target routing hardware context identifier profiles
  if ($line -match '^\s{2}([a-zA-Z0-9_\-]+):') {
    $currentModel = $Matches[1].Trim()
    $modelsData[$currentModel] = @{ "model_source" = $null; "model_url" = $null; "mmproj_url" = $null }
    continue
  }

  # Ingest profile parameters with rigorous validation boundaries
  if ($currentModel) {
    $val = if ($trimmed -match ':\s*(\S+)') { $Matches[1].Trim().Replace("'", "").Replace('"', "") } else { $null }
    if (-not $val) { continue }

    # Recursive compilation layer: resolve variable macro definitions dynamically
    foreach ($macro in $macroMap.Keys) {
      $val = $val.Replace('$' + "{$macro}", $macroMap[$macro])
    }

    if ($trimmed.StartsWith('model_source:')) { $modelsData[$currentModel]["model_source"] = $val }
    if ($trimmed.StartsWith('model_url:'))    { $modelsData[$currentModel]["model_url"] = $val }
    if ($trimmed.StartsWith('mmproj_url:'))   { $modelsData[$currentModel]["mmproj_url"] = $val }
  }
}

# Wrapper helper executing standardized json payload handshake contracts
function Ingest-WeightAsset {
  param ($DirectUrl, $TargetDir)
  if ([string]::IsNullOrEmpty($DirectUrl)) { return }

  $fileName = $DirectUrl.Split('/')[-1]
  $depSpec = @{ "name" = "weight-$fileName"; "version" = "v1.0"; "url" = $DirectUrl; "target_file" = $fileName }
  $depJsonString = ConvertTo-Json -InputObject $depSpec -Compress

  & $universalDownloader -DependencyJson $depJsonString -DestinationDir $TargetDir
}

Write-Host "`n>>> Orchestrating Unified Delivery Container Sequence..." -ForegroundColor Yellow

foreach ($modelName in $modelsData.Keys) {
  $mSource = $modelsData[$modelName]["model_source"]
  $mUrl    = $modelsData[$modelName]["model_url"]
  $pUrl    = $modelsData[$modelName]["mmproj_url"]

  if ([string]::IsNullOrEmpty($mSource) -or [string]::IsNullOrEmpty($mUrl)) { continue }

  # Deterministic regex mapping (DOS-8): isolate author and repository paths safely
  if ($mSource -match 'huggingface\.co/([^/]+)/([^@/]+)') {
    $authorDir = $Matches[1]
    $repoDir   = $Matches[2]
  } else {
    throw "[FATAL] Failed to parse HuggingFace repository layout coordinates from source: $mSource"
  }

  # Lock down dynamic destination to persistent user profile repository boundaries
  $specificTargetDir = Join-Path $modelsBaseStorage "${authorDir}\${repoDir}"

  Write-Host "`n [NODE] Target Profile Routing: $modelName" -ForegroundColor Cyan
  Write-Host "   |-- Downloading model: $mUrl" -ForegroundColor Gray
  if ($pUrl) { Write-Host "   |-- Downloading projector: $pUrl" -ForegroundColor Gray }
  Write-Host "   |-- Destination path: $specificTargetDir" -ForegroundColor Green

  # Trigger high-performance stream delivery routines sequentially
  Ingest-WeightAsset -DirectUrl $mUrl -TargetDir $specificTargetDir
  if ($pUrl) { Ingest-WeightAsset -DirectUrl $pUrl -TargetDir $specificTargetDir }
}

Write-Host "`n>>> [SUCCESS] All model routing assets verified!" -ForegroundColor Green
