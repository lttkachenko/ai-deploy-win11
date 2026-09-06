function Find-NodeJSBinary {
    # Check direct installation first (via PATH)
    $DirectNode = Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($DirectNode) { return $DirectNode }

    # Check NVM installation
    $NvmPath = $env:NVM_HOME
    if (-not $NvmPath -and (Test-Path "$env:APPDATA\nvm")) { $NvmPath = "$env:APPDATA\nvm" }

    if ($NvmPath) {
        # Try NVM_SYMLINK first (usually points to the active version folder or node.exe directly depending on setup)
        if ($env:NVM_SYMLINK -and (Test-Path "$env:NVM_SYMLINK\node.exe")) {
            return "$env:NVM_SYMLINK\node.exe"
        }

        # Fallback: Read symlink file to find active version folder, then node.exe inside it
        $SymlinkFile = Join-Path $NvmPath "symlink"
        if (Test-Path $SymlinkFile) {
            $ActiveVersion = Get-Content $SymlinkFile -ErrorAction SilentlyContinue
            if ($ActiveVersion) {
                return Join-Path $NvmPath "$ActiveVersion\node.exe"
            }
        }
    }

    return $null
}
