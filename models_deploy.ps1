$ErrorActionPreference = "Stop"

Write-Host ">>> Executing Target Model Weight Ingestion Pipeline..." -ForegroundColor Yellow

# 1. Environment Discovery (Targeting active user's home directory)
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$modelStorage = Join-Path $homeDir ".ai\models"
$backendFolder = Join-Path $PSScriptRoot "Backend"

if (-not (Test-Path $modelStorage)) {
  New-Item -ItemType Directory -Path $modelStorage | Out-Null
  Write-Host " |-- Scaffolded user home model directory: $modelStorage" -ForegroundColor Cyan
}

# 2. Assert Master Configuration Node
$masterConfig = Join-Path $backendFolder "config.yml"
if (-not (Test-Path $masterConfig)) {
  throw "[FATAL] Master config.yml missing from Backend directory: $masterConfig"
}

Write-Host " |-- Parsing Backend\config.yml for download targets..." -ForegroundColor Cyan

# Safe inline python script to pull unique HF paths strictly from the profile list
$pythonCmd = "import yaml; data = yaml.safe_load(open('$($masterConfig.Replace('\','/'))')); print(';'.join(list(set([p['litellm_params']['model'] for p in data['profiles'] if 'litellm_params' in p]))))"
$extractedModelsRaw = & python -c $pythonCmd
$targetModels = $extractedModelsRaw.Split(';')

# 3. Secure Asset Download Loop
foreach ($modelPath in $targetModels) {
  if ([string]::IsNullOrEmpty($modelPath)) { continue }

  # Extract filename from HuggingFace string notation (e.g., Repo/Name/file.gguf -> file.gguf)
  $modelFile = $modelPath.Split('/')[-1]
  $targetFile = Join-Path $modelStorage $modelFile
  $downloadUrl = "https://huggingface.co"

  if (-not (Test-Path $targetFile)) {
    Write-Host "   |-- Downloading asset to user home: $modelFile" -ForegroundColor Yellow
    Write-Host "   |-- Source: $downloadUrl" -ForegroundColor Gray

    # Enforcing modern secure TLS connection for heavy file streams
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $downloadUrl -OutFile $targetFile -UserAgent "Mozilla/5.0"
    Write-Host "   |-- [SUCCESS] Successfully ingested weight node: $modelFile" -ForegroundColor Green
  } else {
    Write-Host "   |-- Asset verified in local user storage: $modelFile" -ForegroundColor Gray
  }
}

Write-Host "[SUCCESS] All master target model weights are fully synced and ready." -ForegroundColor Green
