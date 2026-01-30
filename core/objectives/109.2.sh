#!/bin/bash
# Objective 109.2: Persistent network configuration
# Weight: 4

set -euo pipefail

# shellcheck disable=SC2034  # VERBOSE available for debugging
VERBOSE="${1:-false}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"

passed=0
failed=0

check() {
    local desc="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}${PASS}${NC} $desc"
        ((passed++)) || true
        return 0
    else
        echo -e "${RED}${FAIL}${NC} $desc"
        ((failed++)) || true
        return 1
    fi
}

echo "Checking Objective 109.2: Persistent network configuration"
echo "==========================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "ip available" "command -v ip"
check "hostnamectl available" "command -v hostnamectl"
echo

# Check NetworkManager
echo "NetworkManager:"
if command -v nmcli &>/dev/null; then
    check "nmcli available" "command -v nmcli"
    check "NetworkManager running" "systemctl is-active --quiet NetworkManager || nmcli general status"
    check "nmcli can show connections" "nmcli connection show"
    check "nmcli can show devices" "nmcli device status"
else
    echo -e "${YELLOW}${WARN}${NC} NetworkManager not installed"
fi
echo

# Check legacy commands (awareness)
echo "Legacy Commands (awareness):"
if command -v ifup &>/dev/null; then
    check "ifup available" "command -v ifup"
    check "ifdown available" "command -v ifdown"
else
    echo -e "${YELLOW}${WARN}${NC} ifup/ifdown not installed (using NetworkManager)"
fi
echo

# Check hostname configuration
echo "Hostname Configuration:"
check "/etc/hostname exists" "test -f /etc/hostname"
check "hostname command works" "hostname"
check "hostnamectl works" "hostnamectl status"
echo

# Check hosts file
echo "Hosts Configuration:"
check "/etc/hosts exists" "test -f /etc/hosts"
check "/etc/hosts readable" "test -r /etc/hosts"
check "localhost in /etc/hosts" "grep -q 'localhost' /etc/hosts"
check "127.0.0.1 in /etc/hosts" "grep -q '127.0.0.1' /etc/hosts"
echo

# Check DNS resolution configuration
echo "DNS Configuration:"
check "/etc/resolv.conf exists" "test -f /etc/resolv.conf || test -L /etc/resolv.conf"
check "nameserver configured" "grep -q 'nameserver' /etc/resolv.conf || systemctl is-active --quiet systemd-resolved"
echo

# Check NSS configuration
echo "Name Service Switch:"
check "/etc/nsswitch.conf exists" "test -f /etc/nsswitch.conf"
check "hosts line in nsswitch.conf" "grep -q '^hosts:' /etc/nsswitch.conf"
echo

# Check systemd-networkd (awareness)
echo "Systemd-networkd (awareness):"
if systemctl list-unit-files | grep -q systemd-networkd; then
    check "systemd-networkd available" "systemctl list-unit-files | grep -q systemd-networkd"
    check "/etc/systemd/network directory" "test -d /etc/systemd/network || test -d /usr/lib/systemd/network"
else
    echo -e "${YELLOW}${WARN}${NC} systemd-networkd not available"
fi
echo

# Check network configuration files
echo "Configuration Locations:"
# Debian-style
if [[ -f /etc/network/interfaces ]]; then
    check "/etc/network/interfaces exists" "test -f /etc/network/interfaces"
fi
# RHEL-style
if [[ -d /etc/sysconfig/network-scripts ]]; then
    check "/etc/sysconfig/network-scripts exists" "test -d /etc/sysconfig/network-scripts"
fi
# NetworkManager
if [[ -d /etc/NetworkManager ]]; then
    check "/etc/NetworkManager exists" "test -d /etc/NetworkManager"
fi
echo

# Check network interfaces have IPs
echo "Interface Configuration:"
check "Network interfaces have IPs" "ip addr show | grep -q 'inet '"
check "Default route configured" "ip route show | grep -q 'default'"
echo

# Summary
total=$((passed + failed))
echo "==========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 109.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
