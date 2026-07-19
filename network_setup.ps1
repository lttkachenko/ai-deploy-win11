# .\network_setup.ps1 - Fixed PortProxy Network Topology Binding
# Style Enforced: Spaces 2, LF, SingleQuotes, Strict Quality Control

$ErrorActionPreference = 'Stop'

# --- 1. Network Boundary Environment Discovery ---
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$wslUser = (wsl exec whoami).Trim()

if (-not $wslUser) {
  throw '[FATAL] WSL guest subsystem is unreachable. Cannot establish network topology.'
}

Write-Host '>>> Initializing Host Boundary Network Routing Architecture...' -ForegroundColor Yellow
Write-Host "    |-- Context Windows User: $winUser" -ForegroundColor Cyan
Write-Host "    |-- Target WSL Guest User: $wslUser" -ForegroundColor Cyan

# --- 2. Advanced Inbound Firewall Policies Alignment ---
Write-Host '>>> Aligning Advanced Inbound Firewall Policies...' -ForegroundColor Yellow

$targetPorts = @(1234, 8000, 6333) # 1234: Swap, 8000: FastMCP, 6333: Qdrant Docker Core
$legacyRule = 'WSL-LiteLLM-Proxy'
$newRuleName = 'Enterprise-Headless-AI-Stack'

if (Get-NetFirewallRule -DisplayName $legacyRule -ErrorAction SilentlyContinue) {
  Write-Host '    |-- Purging stale legacy LiteLLM firewall matrix configuration...' -ForegroundColor Red
  Remove-NetFirewallRule -DisplayName $legacyRule | Out-Null
}

if (Get-NetFirewallRule -DisplayName $newRuleName -ErrorAction SilentlyContinue) {
  Remove-NetFirewallRule -DisplayName $newRuleName | Out-Null
}

# Allow traffic strictly within the internal host-to-wsl boundary for secure isolation
New-NetFirewallRule -DisplayName $newRuleName `
                    -Direction Inbound `
                    -Action Allow `
                    -Protocol TCP `
                    -LocalPort $targetPorts `
                    -RemoteAddress LocalSubnet `
                    -Profile Any | Out-Null

Write-Host '    |-- Secured TCP ingress vectors applied for ports: 1234, 8000, 6333.' -ForegroundColor Green

# --- 3. Extracting Host Virtual Switch Gateway IP for Port Forwarding ---
Write-Host '>>> Extracting Volatile WSL vEthernet Gateway IP...' -ForegroundColor Yellow

# Parse the default route inside WSL to grab the exact Host IP seen by Linux
$wslRoute = wsl exec ip route show default
if ($wslRoute -match 'via\s+([0-9\.]+)') {
  $hostGatewayIp = $Matches[1].Trim()
} else {
  throw '[FATAL] Failed to parse default route inside WSL guest subsystem.'
}

Write-Host "    |-- Active Host vEthernet Gateway Interface IP: $hostGatewayIp" -ForegroundColor Cyan

# --- 4. Rebuilding Virtual Port Forwarding Table Table Topology (netsh) ---
Write-Host '>>> Mapping Netsh PortProxy Bridges (WSL Ingress to Localhost Loopback)...' -ForegroundColor Yellow

# We instruct Windows to listen on its own vEthernet IP ($hostGatewayIp) and route to 127.0.0.1
foreach ($port in $targetPorts) {
  # Clear existing stale bindings to prevent socket reallocation collisions
  & netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$hostGatewayIp 2>$null

  # Inject explicit tunnel matrix
  & netsh interface portproxy add v4tov4 listenport=$port listenaddress=$hostGatewayIp connectport=$port connectaddress=127.0.0.1 | Out-Null
  Write-Host "    |-- Port Proxy aligned: $hostGatewayIp`:$port ---> 127.0.0.1`:$port" -ForegroundColor Green
}

# --- 5. Guest Subsystem DNS Inversion (~/etc/hosts Synchronization) ---
Write-Host '>>> Enforcing Dynamic DNS Inversion inside WSL Container...' -ForegroundColor Yellow

$bashDnsScript = @"
#!/bin/bash
NEW_IP=\$(ip route show default | awk '{print \$3}')
if [ -n "\$NEW_IP" ]; then
  sudo sed -i '/win-host/d' /etc/hosts
  sudo sh -c "echo '\$NEW_IP win-host' >> /etc/hosts"
fi
"@

wsl exec sh -c "echo '$bashDnsScript' > /home/$wslUser/update_win_host.sh && chmod +x /home/$wslUser/update_win_host.sh"
wsl exec sudo sh -c "echo '$wslUser ALL=(ALL) NOPASSWD: /home/$wslUser/update_win_host.sh' > /etc/sudoers.d/wsl-network"
wsl exec sh -c "grep -q 'update_win_host.sh' /home/$wslUser/.bashrc || echo 'sudo /home/$wslUser/update_win_host.sh' >> /home/$wslUser/.bashrc"

wsl exec sudo /home/$wslUser/update_win_host.sh
Write-Host "    |-- Dynamic DNS entry 'win-host' successfully synced inside WSL /etc/hosts." -ForegroundColor Green

Write-Host "`n[SUCCESS] Fixed Netsh-backed secure transport pipeline fully established." -ForegroundColor Green
