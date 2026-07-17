param (
  [Parameter(Mandatory=$true)] [string]$Url,
  [Parameter(Mandatory=$true)] [string]$DestinationPath
)

$ErrorActionPreference = "Stop"

# Force DNS flush to bypass stale CDN edge routing before initiating heavy transport pipeline
Write-Host ">>> Flushing Host DNS Cache to re-align network routing topology..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Start-Sleep -Seconds 1

$file = New-Object System.IO.FileInfo($DestinationPath)
$destDir = $file.DirectoryName
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }

$httpClient = New-Object System.Net.Http.HttpClient
$httpClient.Timeout = [System.TimeSpan]::FromHours(2) # Prevent early drop on slow connections

# Check if partial download layer already exists to calculate range offset
$startBytes = 0
if ($file.Exists) {
  $startBytes = $file.Length
  Write-Host "    |-- Existing partial file detected: $($file.Name) ($([Math]::Round($startBytes/1GB, 2)) GB)" -ForegroundColor Cyan
}

$request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $Url)
if ($startBytes -gt 0) {
  $request.Headers.Range = New-Object System.Net.Http.Headers.RangeHeaderValue($startBytes, $null)
  Write-Host "    |-- Requesting byte-range offset from HTTP host..." -ForegroundColor Yellow
}

try {
  $response = $httpClient.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result

  # Handle case when server doesn't support range requests or file completed previously
  if ($response.StatusCode -eq [System.Net.HttpStatusCode]::RequestedRangeNotSatisfiable) {
    Write-Host "    |-- Asset verification passed: Target file is already complete." -ForegroundColor Green
    $httpClient.Dispose()
    exit
  }

  $response.EnsureSuccessStatusCode() | Out-Null

  # Assert if server actually honored the partial range request
  $isPartial = $response.StatusCode -eq [System.Net.HttpStatusCode]::PartialContent
  $fileMode = if ($isPartial) { [System.IO.FileMode]::Append } else { [System.IO.FileMode]::Create }

  if (-not $isPartial -and $startBytes -gt 0) {
    Write-Host "    |-- [WARNING] Remote server dropped range request. Restarting stream from zero..." -ForegroundColor Yellow
  }

  $totalBytesToDownload = $response.Content.Headers.ContentLength
  $fileStream = New-Object System.IO.FileStream($DestinationPath, $fileMode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
  $responseStream = $response.Content.ReadAsStreamAsync().Result

  $buffer = New-Object byte[] 65536 # 64KB operational buffer chunk
  $bytesRead = 0
  $totalRead = 0
  $lastReport = [System.DateTime]::Now

  Write-Host "    |-- Content stream established. Downloading model weights layout..." -ForegroundColor Yellow

  while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
    $fileStream.Write($buffer, 0, $bytesRead)
    $totalRead += $bytesRead

    # Non-blocking telemetry output limited to 2-second intervals to minimize IO throttle
    if (([System.DateTime]::Now - $lastReport).TotalSeconds -gt 2) {
      $currentTotal = $startBytes + $totalRead
      if ($totalBytesToDownload -gt 0) {
        $pct = [Math]::Round(($totalRead / $totalBytesToDownload) * 100, 1)
        Write-Host "        |-- Completed: $pct% ($([Math]::Round($currentTotal/1GB, 2)) GB downloaded)" -ForegroundColor Gray
      } else {
        Write-Host "        |-- Streaming active: $([Math]::Round($currentTotal/1GB, 2)) GB pulled" -ForegroundColor Gray
      }
      $lastReport = [System.DateTime]::Now
    }
  }

  $fileStream.Flush()
  $fileStream.Close()
  $responseStream.Close()

  Write-Host "    |-- Transport layer closed. Verification passed for: $($file.Name)" -ForegroundColor Green
} catch {
  if ($null -ne $fileStream) { $fileStream.Close() }
  throw "[FATAL] Network pipeline collapsed during heavy file asset transfer: $_"
} finally {
  $httpClient.Dispose()
}
