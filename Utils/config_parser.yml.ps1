param(
  [Parameter(Mandatory=$true)]
  [string]$ConfigPath
)

if (-not (Test-Path $ConfigPath)) { throw "[FATAL] Config file not found: $ConfigPath" }

# Install for AllUsers (admin context required by infra_deploy)
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
  Write-Host "[CONFIG_PARSER] Installing 'powershell-yaml' for AllUsers..." -ForegroundColor Yellow
  try { Install-Module -Name powershell-yaml -Scope AllUsers -Force -AllowClobber | Out-Null }
  catch { throw "[FATAL] Failed to install powershell-yaml: $_" }
}

try { Import-Module powershell-yaml -Force | Out-Null }
catch { throw "[FATAL] Module import failed: $_" }

# Parse using requested syntax
try { $parsed = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Yaml }
catch {
  $safePath = $ConfigPath -replace "'", "''"
  throw "[FATAL] YAML parse error in '$safePath'. $_"
}

if ($null -eq $parsed) {
  Write-Host "[CONFIG_PARSER] Parsed object is null. Config might be empty or invalid." -ForegroundColor Yellow
  return @{}
}

Write-Host "`n[CONFIG_PARSER] Parsed configuration structure:" -ForegroundColor Cyan
$parsed | ConvertTo-Yaml | Out-String | Write-Host

return $parsed
