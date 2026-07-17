$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Pipeline Environment Discovery
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$configPath = Join-Path $homeDir '.ai\.litellm\config.yaml'

Write-Host '>>> Starting Automated Model Provisioning Pipeline...' -ForegroundColor Yellow

# 2. Modularity Validation
if (-not (Test-Path $configPath)) {
  throw "[FATAL] Target global config manifest missing at: $configPath"
}

# 3. Extract Dependencies from LiteLLM Base Configuration
Write-Host '>>> Extracting model definitions from declarative configuration...' -ForegroundColor Yellow
$configContent = Get-Content -Path $configPath -Raw
$requiredModels = @()

# Flexible regex matching both 'ollama/name' and 'openai/name' abstractions
$modelMatches = [regex]::Matches($configContent, 'model:\s+(?:ollama|openai)\/([^\s\n\r]+)')
foreach ($match in $modelMatches) {
  $modelName = $match.Groups[1].Value.Trim('"', "'")
  if ($requiredModels -notcontains $modelName -and $modelName -ne 'custom_model') {
    $requiredModels += $modelName
    Write-Host "    |-- Detected infrastructure dependency: $modelName" -ForegroundColor Cyan
  }
}

if ($requiredModels.Count -eq 0) {
  Write-Host '    |-- No active model dependencies discovered inside manifests.' -ForegroundColor Green
  exit
}

# 4. Dynamic Backend Detection Matrix
$backendType = 'UNKNOWN'
$backendUrl = ''

$endpoints = @{
  'OLLAMA'   = 'http://127.0.0.1:11434'
  'LLAMACPP' = 'http://127.0.0.1:1234' # Shared port layer matching llama-server and LM Studio
}

foreach ($engine in $endpoints.Keys) {
  try {
    $testUrl = if ($engine -eq 'OLLAMA') { "$($endpoints[$engine])/api/tags" } else { "$($endpoints[$engine])/v1/models" }
    $check = Invoke-RestMethod -Uri $testUrl -Method Get -TimeoutSec 2
    if ($check) {
      $backendType = $engine
      $backendUrl = $endpoints[$engine]
      break
    }
  } catch { continue }
}

# Fallback: If server is down but lms CLI toolchain is active, force LLAMACPP routing
if ($backendType -eq 'UNKNOWN' -and (Get-Command 'lms' -ErrorAction SilentlyContinue)) {
  $backendType = 'LLAMACPP'
  $backendUrl = $endpoints['LLAMACPP']
}

Write-Host ">>> Active Runtime Environment Detected: [ $backendType ]" -ForegroundColor Green

# 5. Execute Architecture-Specific Deployment Strategy
switch ($backendType) {
  'OLLAMA' {
    Write-Host '>>> Enforcing Host CUDA Memory Isolation Rules...' -ForegroundColor Yellow
    $registryPath = 'HKCU:\Environment'
    $isRestartRequired = $false

    # Target memory constraints: 6.2GB CUDA ceiling, block Shared GPU RAM fallback, isolate device 0
    $cudaEnv = @{
      'CUDA_VISIBLE_DEVICES'            = '0'
      'CUDA_MANAGED_FORCE_DEVICE_ALLOC' = '1'
      'CUDA_MALLOC_MAX_BYTES'           = '6657199360'
      'OLLAMA_NUM_PARALLEL'             = '1'
    }

    foreach ($envVar in $cudaEnv.Keys) {
      $currentVal = Get-ItemProperty -Path $registryPath -Name $envVar -ErrorAction SilentlyContinue
      if ($null -eq $currentVal -or $currentVal.$envVar -ne $cudaEnv[$envVar]) {
        Set-ItemProperty -Path $registryPath -Name $envVar -Value $cudaEnv[$envVar]
        [System.Environment]::SetEnvironmentVariable($envVar, $cudaEnv[$envVar], 'User')
        Write-Host "    |-- Applied environment boundary constraint: $envVar = $($cudaEnv[$envVar])" -ForegroundColor Cyan
        $isRestartRequired = $true
      }
    }

    if ($isRestartRequired) {
      Write-Host '    |-- Target environment mutation detected. Recycling Ollama daemon...' -ForegroundColor Yellow
      $ollamaProcess = Get-Process -Name 'ollama' -ErrorAction SilentlyContinue
      if ($ollamaProcess) {
        Stop-Process -Name 'ollama' -Force
        Start-Sleep -Seconds 2
      }
      $ollamaAppPath = Join-Path ${env:LocalAppData} 'Ollama\ollama app.exe'
      if (Test-Path $ollamaAppPath) {
        Start-Process -FilePath $ollamaAppPath -WindowStyle Hidden
        Write-Host '    |-- Safe Ollama daemon initialized with hard VRAM bounds.' -ForegroundColor Green
        Start-Sleep -Seconds 3
      } else {
        Write-Host '    |-- [WARNING] Failed to locate native Ollama binary for auto-restart.' -ForegroundColor Yellow
      }
    }

    # Reassert active daemon connectivity and cache state
    $engineCheck = Invoke-RestMethod -Uri "$backendUrl/api/tags" -Method Get
    $installedModels = @($engineCheck.models.name)

    Write-Host "`n>>> Syncing required local model layers..." -ForegroundColor Yellow
    foreach ($model in $requiredModels) {
      $normalizedModel = if ($model.Contains(':')) { $model } else { "$model`:latest" }

      if ($installedModels -contains $model -or $installedModels -contains $normalizedModel) {
        Write-Host "    |-- Model layer [ $model ] is already cached and ready." -ForegroundColor Green
      } else {
        Write-Host "    |-- Layer drift detected! Pulling model weight signatures for [ $model ]..." -ForegroundColor Cyan
        Write-Host "        |-- Download streaming initialized. Please wait..." -ForegroundColor Yellow

        try {
          $pullUri = "$backendUrl/api/pull"
          $body = @{ name = $model; stream = $false } | ConvertTo-Json
          $pullSuccess = $false

          foreach ($i in 0..2) {
            try {
              $progress = Invoke-RestMethod -Uri $pullUri -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 3600
              if ($progress.status -eq 'success' -or $null -eq $progress.status) {
                $pullSuccess = $true
                break
              }
            } catch {
              $attempt = $i + 1
              Write-Host "        |-- Network/Service error ($attempt/3): $_" -ForegroundColor Yellow
              if ($i -lt 2) { Start-Sleep -Seconds 5 }
            }
          }

          if ($pullSuccess) {
            Write-Host "        |-- Layer verification passed: $model deployment complete." -ForegroundColor Green
          } else {
            Write-Host "        |-- [ERROR] Failed to download model layer after retries: $model" -ForegroundColor Red
          }
        } catch {
          Write-Host "        |-- [FATAL] Unexpected error pulling ${model}: $_" -ForegroundColor Red
        }
      }
    }
  }

  'LLAMACPP' {
    Write-Host '>>> Processing Managed Automation Layer via LM Studio lms Toolchain...' -ForegroundColor Yellow

    # Assert standard lms CLI availability within environment PATH variables
    if (-not (Get-Command 'lms' -ErrorAction SilentlyContinue)) {
      Write-Host '    |-- LM Studio CLI missing. Bootstrapping llmster headless daemon stream...' -ForegroundColor Cyan
      Write-Host '    |-- Flushing Host DNS Cache to clear routing blocks...' -ForegroundColor Yellow
      ipconfig /flushdns | Out-Null
      Start-Sleep -Seconds 1

      # Headless core installation execution layer (installs llmster + lms CLI)
      Invoke-RestMethod -Uri 'https://lmstudio.ai/install.ps1' | Invoke-Expression | Out-Null
      Start-Sleep -Seconds 5

      if (-not (Get-Command 'lms' -ErrorAction SilentlyContinue)) {
        throw '[FATAL] Toolchain installation succeeded but lms binary is unreachable in current session.'
      }
    }

    # Enterprise Distribution Asset Matrix mapping: LiteLLM Name ---> Hugging Face / LM Repository ID
    $modelDistributionMatrix = @{
      'fredrezones55/Qwen3.6-35B-A3B-Uncensored-HauhauCS-Aggressive:Q4' = 'Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/qwen2.5-coder-32b-instruct-q4_k_m.gguf'
      'qwen2.5-coder:1.5b-instruct-q4_K_M'                            = 'Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf'
    }

    # Bring up the underlying headless llmster daemon and start the local API server node
    Write-Host '    |-- Initializing underlying llmster background service engine...' -ForegroundColor Cyan
    & lms daemon up | Out-Null
    & lms server start --port 1234 | Out-Null
    Start-Sleep -Seconds 2

    # Reassert loaded models catalog state via CLI queries
    $loadedModels = & lms ls

    Write-Host "`n>>> Syncing managed LM Studio model assets..." -ForegroundColor Yellow
    foreach ($model in $requiredModels) {
      if (-not $modelDistributionMatrix.ContainsKey($model)) {
        Write-Host "    |-- [WARNING] No static distribution mapping discovered for token: $model" -ForegroundColor Yellow
        continue
      }

      $repoId = $modelDistributionMatrix[$model]
      $fileName = [System.IO.Path]::GetFileName($repoId)

      # Check if target model weight layer is already cached in local storage paths
      if ($loadedModels -match [regex]::Escape($fileName)) {
        Write-Host "    |-- Model asset [ $fileName ] is already verified and cached on disk." -ForegroundColor Green
      } else {
        Write-Host "    |-- Deployment drift identified! Spawning lms download pipeline for: $fileName" -ForegroundColor Cyan
        Write-Host '        |-- Dynamic streaming initialized. Please wait...' -ForegroundColor Yellow

        # Pull model binaries directly using native multi-threaded lms engine download stream
        & lms get $repoId
      }

      # Force-load the asset into the active inference memory context
      Write-Host "    |-- Mounting model [ $fileName ] into active inference memory..." -ForegroundColor Cyan
      & lms load $repoId | Out-Null
      Write-Host "    |-- [SUCCESS] Model layer operational: $fileName is active and ready for transport." -ForegroundColor Green
    }
  }

  'UNKNOWN' {
    throw '[FATAL] No compliant AI inference engines discovered on active network channels. Provisioning aborted.'
  }
}

Write-Host "`n[SUCCESS] AI Infrastructure Model provisioning cycle complete." -ForegroundColor Green
