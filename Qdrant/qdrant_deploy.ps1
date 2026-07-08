# .\Qdrant\qdrant_deploy.ps1 - Architecture Bootstrap Pipeline
# Style Enforced: Spaces 2, LF, Double Quotes, Strict Quality Control

$ErrorActionPreference = "Stop"

# --- Phase 1: Launch Persistent Vector Node ---
Write-Host ">>> Instantiating Qdrant Container Architecture..." -ForegroundColor Cyan

if (-not (Get-Command "docker-compose" -ErrorAction SilentlyContinue)) {
  Write-Error "CRITICAL: Docker Compose binary not identified within current PATH environment parameters."
}

# Fire up infrastructure nodes via declarative manifest
docker-compose -f "$PSScriptRoot\docker_compose.yml" up -d

# --- Phase 2: HTTP Healthz Interface Verification Loop ---
$HealthEndpoint = "http://127.0.0"
$MaxAttempts = 10
$Attempt = 1
$Connected = $false

Write-Host ">>> Initiating connection handshakes targeting vector engine interface..." -ForegroundColor Intercept

while (-not $Connected -and $Attempt -le $MaxAttempts) {
  try {
    $Response = Invoke-WebRequest -Uri $HealthEndpoint -Method Get -TimeoutSec 2 -UseBasicParsing
    if ($Response.StatusCode -eq 200) {
      $Connected = $true
      Write-Host "[SUCCESS] Vector engine node online. Handshake verified." -ForegroundColor Green
    }
  } catch {
    Write-Host " |-- [Attempt $Attempt/$MaxAttempts] Engine initializing. Retrying connection context in 5s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    $Attempt++
  }
}

if (-not $Connected) {
  Write-Error "CRITICAL: Vector store node failed to pass active responsive HTTP state checks."
}

# --- Phase 3: Multi-Model RAG Daemon Registration Loop ---
Write-Host ">>> Configuring isolated background filesystem tracking daemons..." -ForegroundColor Cyan

$VenvPython = "$env:USERPROFILE\.ai\.qdrant\.venv\Scripts\python.exe"
$WatcherScript = "$env:USERPROFILE\.ai\.qdrant\qdrant_watcher.py"

if (-not (Test-Path $VenvPython)) {
  Write-Error "CRITICAL: Virtual environment python runtime not detected at: $VenvPython"
}

# Declarative Multi-Model matrix routing definitions
$RagTargets = @(
  @{ Name = "AI-RAG-Dev";   Vault = "E:\Vaults\v-dev";   Collection = "db-dev" },
  @{ Name = "AI-RAG-Hobby"; Vault = "E:\Vaults\v-hobby"; Collection = "db-hobby" }
)

foreach ($Target in $RagTargets) {
  if (Test-Path $Target.Vault) {
    # Rigid formatting arguments layout containing isolated namespace maps
    $TaskArgs = "`"$WatcherScript`" --vault `"$($Target.Vault)`" --collection `"$($Target.Collection)`""

    $Action = New-ScheduledTaskAction -Execute $VenvPython -Argument $TaskArgs
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    # Force rewrite target points to drop legacy lockouts
    Register-ScheduledTask -TaskName $Target.Name -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
    Write-Host "[SUCCESS] Registered background daemon task: $($Target.Name) targeting Qdrant collection: '$($Target.Collection)'" -ForegroundColor Green
  } else {
    Write-Host "[WARNING] Target Vault directory missing, skipping daemon configuration: $($Target.Vault)" -ForegroundColor Yellow
  }
}

Write-Host ">>> Phase Complete: Qdrant deployment matches Gheimher quality standards." -ForegroundColor Green
