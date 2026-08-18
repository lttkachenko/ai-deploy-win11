<#
  .SYNOPSIS
    Automated pagefile optimization script for local AI distributions.
  .DESCRIPTION
    Calculates physical RAM, disables Windows automatic pagefile management,
    and sets a fixed-size pagefile (Initial = Maximum) equal to 0.5 x RAM on C:\.
#>

$ErrorActionPreference = "Stop"

# Check administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "[-] Error: This script must be executed as an Administrator!"
  exit 1
}

# Retrieve total physical RAM size in bytes using CIM (PS7 native)
$physicalRAMBytes = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
if (-not $physicalRAMBytes) {
  Write-Error "[-] Error: Failed to determine physical RAM size."
  exit 1
}

# Convert bytes to Gigabytes for logging and Megabytes for target sizing
$ramGB = [math]::Round($physicalRAMBytes / 1GB, 2)
$targetPagefileMB = [math]::Round(($physicalRAMBytes / 2) / 1MB)

Write-Host "[+] Detected physical RAM: $ramGB GB" -ForegroundColor Green
Write-Host "[+] Target pagefile size (0.5 x RAM): $targetPagefileMB MB" -ForegroundColor Green

# Pre-check existing pagefile configuration before any modification
$currentPagefile = Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -like "c:\pagefile.sys" }
if ($null -ne $currentPagefile) {
  if ($currentPagefile.InitialSize -ge $targetPagefileMB) {
    Write-Host "[+] Current pagefile size meets or exceeds requirements (>= 0.5 x RAM). Skipping configuration." -ForegroundColor Green
    exit 0
  }
}

# Disable automatic Windows pagefile management
Write-Host "[*] Disabling automatic pagefile management..." -ForegroundColor Yellow
$computerSystem = Get-CimInstance Win32_ComputerSystem
Set-CimInstance -CimInstance $computerSystem -Property @{AutomaticManagedPagefile = $false}

# Configure fixed-size pagefile on C:\
Write-Host "[*] Configuring fixed-size pagefile on C:..." -ForegroundColor Yellow
$pagefileProperties = @{
  Name        = "C:\pagefile.sys"
  InitialSize = $targetPagefileMB
  MaximumSize = $targetPagefileMB
}

if ($null -eq $currentPagefile) {
  New-CimInstance -ClassName Win32_PageFileSetting -Property $pagefileProperties | Out-Null
} else {
  Set-CimInstance -CimInstance $currentPagefile -Property @{InitialSize = $targetPagefileMB; MaximumSize = $targetPagefileMB}
}

# Force-sync settings directly via registry for persistent deployment across reboots
$registryPath = "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $registryPath -Name "PagingFiles" -Value "C:\pagefile.sys $targetPagefileMB $targetPagefileMB" -ErrorAction SilentlyContinue

Write-Host "`n[SUCCESS] Configuration completed successfully!" -ForegroundColor Green
Write-Host "[!] COMMAND ISSUED: Destroy current session and reboot to apply new Commit Limit!" -ForegroundColor Magenta -BackgroundColor Black
Write-Host "[*] Estimated total Commit Limit after reboot: " -NoNewline
Write-Host "$( [math]::Round($ramGB + ($targetPagefileMB / 1024), 2) ) GB" -ForegroundColor Cyan
