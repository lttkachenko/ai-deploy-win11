$ErrorActionPreference = "Stop"

# 1. Network Boundary Environment Discovery
$winUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
$wslUser = (wsl exec whoami).Trim()

if (-not $wslUser) {
  throw "[FATAL] WSL subsystem unreachable. Cannot establish network topology."
}

Write-Host ">>> Initializing Host boundary Network Routing Architecture..." -ForegroundColor Yellow
Write-Host "    |-- Context Windows User: $winUser" -ForegroundColor Cyan
Write-Host "    |-- Target WSL Guest User: $wslUser" -ForegroundColor Cyan

# 2. Inbound Windows Firewall Rule Enforcement
Write-Host ">>> Aligning Advanced Inbound Firewall Policies..." -ForegroundColor Yellow
$ruleName = "WSL-LiteLLM-Proxy"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existingRule) {
  Write-Host "    |-- Legacy firewall configuration rule detected. Refreshing state..." -ForegroundColor Cyan
  Remove-NetFirewallRule -DisplayName $ruleName | Out-Null
}

New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000 -Profile Any | Out-Null
Write-Host "    |-- Dedicated TCP Port 8000 inbound rule applied successfully." -ForegroundColor Green

# 3. Dynamic IP Extraction and PortProxy Verification
Write-Host ">>> Rebuilding Virtual Port Forwarding Table Topology..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# Extract using robust regex pattern mapping
$wslRoute = wsl exec ip route show default
if ($wslRoute -match 'via\s+([0-9\.]+)') {
  $wslIp = $Matches[1].Trim()
} else {
  throw "[FATAL] Failed to extract volatile guest subsystem runtime network IP layout via regex parsing."
}

Write-Host "    |-- Active Guest Dynamic Target Interface IP: $wslIp" -ForegroundColor Cyan

# Secure overwrite strategy: delete only specific port conflict rules instead of total proxy reset
# LiteLLM Bridge:
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=$wslIp 2>$null
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=$wslIp connectport=8000 connectaddress=127.0.0.1 | Out-Null
Write-Host "    |-- Mapped Port Proxy link boundary: $wslIp`:8000 ---> 127.0.0.1`:8000" -ForegroundColor Green
# Qdrant Bridge:
netsh interface portproxy delete v4tov4 listenport=6333 listenaddress=$wslIp 2>$null
netsh interface portproxy add v4tov4 listenport=6333 listenaddress=$wslIp connectport=6333 connectaddress=127.0.0.1 | Out-Null
Write-Host "    |-- Mapped Port Proxy link boundary: $wslIp`:6333 ---> 127.0.0.1`:6333" -ForegroundColor Green

# 4. Guest Subsystem DNS Inversion (win-host generation inside /etc/hosts)
Write-Host ">>> Enforcing Dynamic DNS Inversion inside WSL Container..." -ForegroundColor Yellow

$bashDnsScript = @"
#!/bin/bash
NEW_IP=\$(ip route show default | awk '{print \$3}')
if [ -n "\$NEW_IP" ]; then
  sudo sed -i '/win-host/d' /etc/hosts
  sudo sh -c "echo '\$NEW_IP win-host' >> /etc/hosts"
fi
"@

# Inject persistent script engine to update gateway links dynamically on user bash login
wsl exec sh -c "echo '$bashDnsScript' > /home/$wslUser/update_win_host.sh && chmod +x /home/$wslUser/update_win_host.sh"
wsl exec sudo sh -c "echo '$wslUser ALL=(ALL) NOPASSWD: /home/$wslUser/update_win_host.sh' > /etc/sudoers.d/wsl-network"
wsl exec sh -c "grep -q 'update_win_host.sh' /home/$wslUser/.bashrc || echo 'sudo /home/$wslUser/update_win_host.sh' >> /home/$wslUser/.bashrc"

# Fire script instantly to map active runtime networking states
wsl exec sudo /home/$wslUser/update_win_host.sh
Write-Host "    |-- Mapped resolution entry 'win-host' successfully synced inside WSL /etc/hosts." -ForegroundColor Green

Write-Host "`n[SUCCESS] Host-to-Guest secure transport pipeline fully established." -ForegroundColor Green
