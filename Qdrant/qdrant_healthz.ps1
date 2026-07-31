# .\Qdrant\qdrant_healthz.ps1 - Vector Infrastructure Diagnostics Runtime Engine
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control
# Single Source of Truth Alignment: Extracts settings directly from central config slot

$ErrorActionPreference = 'Stop'

# --- Phase 1: Configuration Discovery & Resolution ---
$homeDir = [System.Environment]::GetFolderPath('UserProfile')
$mcpConfigPath = Join-Path $homeDir '.ai\conf\mcp.conf.yml'

if (-not (Test-Path $mcpConfigPath)) {
  throw "[FATAL] Centralized RAG configuration missing at slot: $mcpConfigPath"
}

$configContent = Get-Content -Path $mcpConfigPath -Raw

$qdrantPort = 8093
if ($configContent -match 'qdrant_rest_port:\s*(\d+)') {
  $qdrantPort = [int]$Matches[1]
}

$qdrantApiKey = 'dev-srv-key-default'
if ($configContent -match 'qdrant-srv:[\s\S]*?api_key:\s*[''"]?([^\''"\s\n]*)[''"]?') {
  $qdrantApiKey = $Matches[1].Trim()
}

$collectionUrl = "http://127.0.0.1:$qdrantPort/collections/db-dev"
$headers = @{ 'api-key' = $qdrantApiKey }

# --- Phase 2: Fetch Active Collections List ---
Write-Host '>>> Requesting vector collections manifest from node...' -ForegroundColor Cyan
$rootUrl = "http://127.0.0.1:$qdrantPort/collections"

try {
  $collectionsResponse = Invoke-RestMethod -Uri $rootUrl -Method Get -ContentType 'application/json' -Headers $headers
  $globalCollections = $collectionsResponse.result.collections | ForEach-Object { $_.name }
} catch {
  Write-Host "  |-- [ERROR] Target endpoint unreachable at port $qdrantPort. Node offline." -ForegroundColor Red
  $globalCollections = @()
}

Write-Host '=== AVAILABLE COLLECTIONS ===' -ForegroundColor Green
if ($globalCollections.Count -gt 0) {
  foreach ($col in $globalCollections) {
    Write-Host "  |-- Found Cluster Partition: $col" -ForegroundColor Yellow
  }
} else {
  Write-Host '  |-- No active collections identified inside vector engine map.' -ForegroundColor Red
}
Write-Host '============================='

# --- Phase 3: Fetch Target Collection Status & Inspect Payload ---
$targetCollection = 'db-dev'

if ($globalCollections -contains $targetCollection) {
  Write-Host "`n>>> Targeted analysis for collection: $targetCollection..." -ForegroundColor Cyan
  $status = Invoke-RestMethod -Uri $collectionUrl -Method Get -ContentType 'application/json' -Headers $headers

  Write-Host '=== COLLECTION METRICS ===' -ForegroundColor Green
  Write-Host "Node Status: $($status.result.status)"
  Write-Host "Total Vectors: $($status.result.vectors_count)"
  Write-Host "Total Points: $($status.result.points_count)"
  Write-Host '==========================='

  if ($status.result.points_count -gt 0) {
    Write-Host "`n>>> Sampling context chunk distribution matrix..." -ForegroundColor Cyan
    $body = @{ limit = 3; with_payload = $true } | ConvertTo-Json
    $points = Invoke-RestMethod -Uri "$collectionUrl/points/scroll" -Method Post -Body $body -ContentType 'application/json' -Headers $headers

    foreach ($point in $points.result.points) {
      $text = $point.payload.text
      if ($text.Length -gt 150) { $text = $text.Substring(0, 150) + '...' }
      Write-Host "Point ID: $($point.id)" -ForegroundColor Yellow
      Write-Host "Source File: $($point.payload.file_path)"
      Write-Host "Chunk Index: $($point.payload.chunk_index)"
      Write-Host "Payload Text: $text"
      Write-Host '------------------------'
    }
  } else {
    Write-Warning "[WARN] Target collection '$targetCollection' is empty. Indexing payload has not started."
  }
} else {
  Write-Warning "[WARN] Expected collection '$targetCollection' is missing from current cluster node mapping."
}
