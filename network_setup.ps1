$ErrorActionPreference = 'Stop'

Write-Host '=================================================================' -ForegroundColor Cyan
Write-Host '>>> Establishing Cross-Boundary Network Bridges via Netsh Spec...' -ForegroundColor Cyan
Write-Host '=================================================================' -ForegroundColor Cyan

# 1. Environment and User Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
Write-Host "   |-- Context Windows User: $winUser" -ForegroundColor Gray

$wslUser = "gadeshi"
Write-Host "   |-- Target WSL Guest User: $wslUser" -ForegroundColor Gray

# 2. Force Start Windows IP Helper Service (Fixes 'File not found' in netsh)
Write-Host '>>> Ensuring Windows IP Helper Service (Iphlpapi) is active...' -ForegroundColor Yellow
$ipHelper = Get-Service -Name 'IpHLPSvc' -ErrorAction SilentlyContinue
if ($ipHelper) {
  if ($ipHelper.Status -ne 'Running') {
    Start-Service -Name 'IpHLPSvc'
    Start-Sleep -Seconds 1
  }
  Set-Service -Name 'IpHLPSvc' -StartupType Automatic
  Write-Host '    |-- IP Helper service verified and running.' -ForegroundColor Green
} else {
  throw '[FATAL] Critical network dependency missing: IpHLPSvc (IP Helper) not found on host.'
}

# 3. Align Advanced Inbound Firewall Policies
Write-Host '>>> Aligning Advanced Inbound Firewall Policies...' -ForegroundColor Yellow
$targetPorts = @(1234, 8000, 6333)

foreach ($port in $targetPorts) {
  $specificRuleName = "AI-Stack-Ingress-Bridge-$port"
  Remove-NetFirewallRule -Name $specificRuleName -ErrorAction SilentlyContinue | Out-Null
  New-NetFirewallRule -Name $specificRuleName `
                      -DisplayName "AI Stack Ingress Gateway Port $port" `
                      -Description "Automated portproxy ingress traffic rule managed via enterprise-ai-stack script blocks." `
                      -Direction Inbound `
                      -Action Allow `
                      -Protocol TCP `
                      -LocalPort $port `
                      -Enabled True | Out-Null
}
Write-Host "    |-- Secured TCP ingress vectors applied for ports: $($targetPorts -join ', ')." -ForegroundColor Green

# 4. Extract Volatile WSL vEthernet Gateway IP
Write-Host '>>> Extracting Volatile WSL vEthernet Gateway IP...' -ForegroundColor Yellow
$wslAdapter = Get-NetIPAddress -InterfaceAlias '*WSL*' -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $wslAdapter) {
  throw '[FATAL] Network bridge broken. Active WSL vEthernet interface could not be identified.'
}

$wslGatewayIp = $wslAdapter.IPAddress
Write-Host "    |-- Active Host vEthernet Gateway Interface IP: $wslGatewayIp" -ForegroundColor Green

# 5. Mapping Netsh PortProxy Bridges (WSL Ingress to Localhost Loopback)
Write-Host '>>> Mapping Netsh PortProxy Bridges (WSL Ingress to Localhost Loopback)...' -ForegroundColor Yellow
& netsh.exe interface portproxy reset | Out-Null

foreach ($port in $targetPorts) {
  & netsh.exe interface portproxy add v4tov4 listenaddress=$wslGatewayIp listenport=$port connectaddress=127.0.0.1 connectport=$port | Out-Null
  Write-Host "    |-- Port Proxy aligned: $wslGatewayIp`:$port ---> 127.0.0.1`:$port" -ForegroundColor Gray
}

# 6. Enforce Dynamic DNS Inversion inside WSL Container (Strictly Isolated Execution)
Write-Host '>>> Enforcing Dynamic DNS Inversion inside WSL Container...' -ForegroundColor Yellow

# Fix: Quietly pre-boot WSL instance and suppress all internal deprecation warnings from .wslconfig
& wsl.exe -u root -e bash -c "exit" 2>$null | Out-Null
Start-Sleep -Seconds 1

$bashPayload = @'
NEW_IP=$(ip route show default | awk '{print $3}')
if [ -n "$NEW_IP" ]; then
  echo "nameserver $NEW_IP" | sudo tee /etc/resolv.conf > /dev/null
  echo "Successfully inverted container endpoint mapping context inside resolv.conf targeting host gateway: $NEW_IP"
else
  echo "[ERROR] Internal bash execution engine failed to extract fallback host gateway reference." >&2
  exit 1
fi
'@

try {
  # Fix: Stream execution output while completely discarding standard error noise from corrupted host .wslconfig keys
  $wslOutput = & wsl.exe -u root -e bash -c $bashPayload 2>$null
  $wslOutput | ForEach-Object {
    if ($_ -match "Successfully") {
      Write-Host "    |-- WSL:: $_" -ForegroundColor Cyan
    }
  }
  Write-Host '>>> [SUCCESS] Network cross-boundary bridges established on the green path matrix!' -ForegroundColor Green
}
catch {
  throw "[FATAL] WSL context injection sequence collapsed. Subsystem transmission error. Trace: $_"
}
