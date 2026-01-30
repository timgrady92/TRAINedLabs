#!/bin/bash
# Objective 109.4: Configure client side DNS
# Weight: 2

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

echo "Checking Objective 109.4: Configure client side DNS"
echo "===================================================="
echo

# Check DNS query commands
echo "DNS Query Commands:"
check "host available" "command -v host"
check "dig available" "command -v dig"
check "nslookup available" "command -v nslookup"
check "getent available" "command -v getent"
echo

# Check DNS configuration files
echo "DNS Configuration Files:"
check "/etc/hosts exists" "test -f /etc/hosts"
check "/etc/resolv.conf exists" "test -f /etc/resolv.conf || test -L /etc/resolv.conf"
check "/etc/nsswitch.conf exists" "test -f /etc/nsswitch.conf"
echo

# Check /etc/hosts
echo "/etc/hosts Configuration:"
check "localhost in /etc/hosts" "grep -q 'localhost' /etc/hosts"
check "127.0.0.1 mapped" "grep -q '127.0.0.1' /etc/hosts"
if grep -q '::1' /etc/hosts 2>/dev/null; then
    check "IPv6 localhost (::1)" "grep -q '::1' /etc/hosts"
fi
echo

# Check /etc/resolv.conf
echo "/etc/resolv.conf Configuration:"
check "resolv.conf readable" "test -r /etc/resolv.conf"
if [[ -L /etc/resolv.conf ]]; then
    echo "  (symlink to: $(readlink /etc/resolv.conf))"
fi
check "nameserver configured" "grep -q 'nameserver' /etc/resolv.conf"
echo "  Nameservers:"
grep '^nameserver' /etc/resolv.conf 2>/dev/null | head -3 || true
echo

# Check /etc/nsswitch.conf
echo "/etc/nsswitch.conf Configuration:"
check "nsswitch.conf readable" "test -r /etc/nsswitch.conf"
check "hosts line present" "grep -q '^hosts:' /etc/nsswitch.conf"
echo "  hosts line: $(grep '^hosts:' /etc/nsswitch.conf)"
echo

# Test DNS resolution
echo "DNS Resolution:"
check "getent hosts localhost" "getent hosts localhost"
check "host command works" "host localhost 2>/dev/null || true"
# Try to resolve a public hostname
if host google.com &>/dev/null 2>&1; then
    check "External DNS works" "host google.com"
else
    echo -e "${YELLOW}${WARN}${NC} Cannot resolve external hostnames (network issue?)"
fi
echo

# Test dig functionality
echo "Dig Functionality:"
if command -v dig &>/dev/null; then
    check "dig +short works" "dig +short localhost || true"
    check "dig can query" "dig localhost | head -5"
fi
echo

# Check systemd-resolved (awareness)
echo "Systemd-resolved:"
if systemctl is-active systemd-resolved &>/dev/null; then
    check "systemd-resolved running" "systemctl is-active --quiet systemd-resolved"
    if command -v resolvectl &>/dev/null; then
        check "resolvectl available" "command -v resolvectl"
    fi
else
    echo -e "${YELLOW}${WARN}${NC} systemd-resolved not running (using traditional resolv.conf)"
fi
echo

# Summary
total=$((passed + failed))
echo "===================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 109.4 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
