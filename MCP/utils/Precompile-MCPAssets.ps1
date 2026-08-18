<#
.SYNOPSIS
    Compiles all Python scripts in the MCP runtime directory and subdirectories to bytecode (.pyc).
.DESCRIPTION
    Scans the target directory recursively, runs the native compileall module via the virtual
    environment Python interpreter to compile all assets (including nested libs package),
    and verifies the final exit status. Returns false if any compilation error occurs.
.EXAMPLE
    Precompile-MCPAssets -venvPython "C:\.ai\venv\mcp\Scripts\python.exe" -mcpRuntimeDir "C:\.ai\venv\mcp"
#>

function Precompile-MCPAssets {
  param(
    [Parameter(Mandatory=$true)]
    [string]$venvPython,

    [Parameter(Mandatory=$true)]
    [string]$mcpRuntimeDir
  )

  try {
    Write-Host "[PHASE 6.1.5] Compiling Python assets recursively to bytecode..." -ForegroundColor Yellow

    if (-not (Test-Path $mcpRuntimeDir)) {
      Write-Host "  |-- [FAIL] Target runtime directory not found: $mcpRuntimeDir" -ForegroundColor Red
      return $false
    }

    # Execute standard python module 'compileall' for recursive compilation [1]
    # -q: quiet mode (only errors)
    # -f: force compilation even if timestamps are up to-date
    $compileResult = & $venvPython -m compileall -q -f "$mcpRuntimeDir" 2>&1

    if ($LASTEXITCODE -ne 0) {
      Write-Host "  |-- [FAIL] Bytecode precompilation crashed: $($compileResult | Out-String)" -ForegroundColor Red
      return $false
    }

    Write-Host "  |-- Bytecode compilation successfully verified for all packages." -ForegroundColor Green
    return $true

  } catch {
    $ErrorMessage = $_.Exception.Message
    Write-Error "[ERROR] Critical error during pyc asset compilation: $ErrorMessage"
    return $false
  }
}
