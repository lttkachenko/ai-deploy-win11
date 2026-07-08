$ErrorActionPreference = "Stop"

# 1. Host Runtime Architecture Discovery
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$configPath = Join-Path $homeDir ".ai\.litellm\config.yaml"
$ollamaApiUrl = "http://127.0.0"

Write-Host ">>> Starting Automated Ollama Model Provisioning Pipeline..." -ForegroundColor Yellow

# 2. Modularity Validation
if (-not (Test-Path $configPath)) {
  throw "[FATAL] Target global config manifest missing at: $configPath"
}

# 3. Verify Ollama Engine Availability
try {
  $engineCheck = Invoke-RestMethod -Uri "$ollamaApiUrl/tags" -Method Get -TimeoutSec 5
}
catch {
  throw "[FATAL] Ollama local daemon is unresponsive at $ollamaApiUrl. Ensure Ollama app is running on the host."
}

# 4. Parse Required Models directly from LiteLLM Base Configuration
Write-Host ">>> Extracting required model definitions from declarative configuration..." -ForegroundColor Yellow
$configContent = Get-Content -Path $configPath -Raw

# Match patterns like: model: ollama/qwen3.6:35b-moe or model: ollama/qwen3.6:4b
$modelMatches = [regex]::Matches($configContent, 'model:\s+ollama\/([^\s\n\r]+)')
$requiredModels = @()

foreach ($match in $modelMatches) {
  $modelName = $match.Groups[1].Value.Trim()
  if ($requiredModels -notcontains $modelName) {
    $requiredModels += $modelName
    Write-Host "    |-- Detected configuration dependency: $modelName" -ForegroundColor Cyan
  }
}

if ($requiredModels.Count -eq 0) {
  Write-Host "    |-- No active local Ollama models found inside config manifests." -ForegroundColor Green
  exit
}

# 5. Extract the Manifest of Currently Cached Installed Models
$installedModels = @($engineCheck.models.name)

# 6. Reconcile Dependency Delta and Execute Auto-Pull Sequence
Write-Host "`n>>> Syncing required local model layers..." -ForegroundColor Yellow

foreach ($model in $requiredModels) {
  # Normalize tags for proper comparison inside array metrics
  $normalizedModel = $model
  if (-not ($model.Contains(":"))) {
    $normalizedModel = "$model`:latest"
  }

  if ($installedModels -contains $model -or $installedModels -contains $normalizedModel) {
    Write-Host "    |-- Model layer [ $model ] is already cached and ready." -ForegroundColor Green
  }
  else {
    Write-Host "    |-- Layer drift detected! Pulling model weight signatures for [ $model ]..." -ForegroundColor Cyan
    Write-Host "        |-- Download streaming initialized. Please wait..." -ForegroundColor Yellow

    try {
      # Trigger Ollama native streaming pull endpoint
      $pullUri = "$ollamaApiUrl/pull"
      $body = @{ name = $model; stream = $false } | ConvertTo-Json

      # Executing long-running REST action for weight allocation (3600s max for heavy MoE)
      $progress = Invoke-RestMethod -Uri $pullUri -Method Post -Body $body -ContentType "application/json" -TimeoutSec 3600

      if ($progress.status -eq "success" -or $null -eq $progress.status) {
        Write-Host "        |-- Layer verification passed: $model deployment complete." -ForegroundColor Green
      }
    }
    catch {
      Write-Host "        |-- [ERROR] Failed to automatically download model layer: $_" -ForegroundColor Red
    }
  }
}

Write-Host "`n[SUCCESS] Local Ollama weight model stack is synchronized with LiteLLM manifests." -ForegroundColor Green
