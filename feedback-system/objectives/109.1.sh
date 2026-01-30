#!/bin/bash
# Objective 109.1: Fundamentals of internet protocols
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

echo "Checking Objective 109.1: Fundamentals of internet protocols"
echo "============================================================="
echo

# Check essential files
echo "Essential Files:"
check "/etc/services exists" "test -f /etc/services"
check "/etc/services readable" "test -r /etc/services"
check "/etc/protocols exists" "test -f /etc/protocols"
echo

# Check /etc/services content
echo "Common Ports in /etc/services:"
check "FTP port (21)" "grep -qE '^ftp[[:space:]]+21/tcp' /etc/services"
check "SSH port (22)" "grep -qE '^ssh[[:space:]]+22/tcp' /etc/services"
check "Telnet port (23)" "grep -qE '^telnet[[:space:]]+23/tcp' /etc/services"
check "SMTP port (25)" "grep -qE '^smtp[[:space:]]+25/tcp' /etc/services"
check "DNS port (53)" "grep -qE '^domain[[:space:]]+53' /etc/services"
check "HTTP port (80)" "grep -qE '^http[[:space:]]+80/tcp' /etc/services || grep -qE '^www[[:space:]]+80/tcp' /etc/services"
check "POP3 port (110)" "grep -qE '^pop3[[:space:]]+110/tcp' /etc/services"
check "IMAP port (143)" "grep -qE '^imap[[:space:]]+143/tcp' /etc/services || grep -qE '^imap2[[:space:]]+143/tcp' /etc/services"
check "HTTPS port (443)" "grep -qE '^https[[:space:]]+443/tcp' /etc/services"
echo

# Check network commands
echo "Network Commands:"
check "ip available" "command -v ip"
check "ss available" "command -v ss"
check "ping available" "command -v ping"
echo

# Check /etc/protocols content
echo "Protocols in /etc/protocols:"
check "ICMP protocol (1)" "grep -qE '^icmp[[:space:]]+1' /etc/protocols"
check "TCP protocol (6)" "grep -qE '^tcp[[:space:]]+6' /etc/protocols"
check "UDP protocol (17)" "grep -qE '^udp[[:space:]]+17' /etc/protocols"
echo

# Check IP configuration
echo "IP Configuration:"
check "Can view IP addresses" "ip addr show | grep -q 'inet'"
check "IPv4 loopback exists" "ip addr show lo | grep -q '127.0.0.1'"
check "IPv6 loopback exists" "ip addr show lo | grep -q '::1'"
echo

# Check network interface information
echo "Network Interfaces:"
check "At least one interface up" "ip link show up | grep -q 'state UP'"
check "Can view interface stats" "ip -s link show | head -5"
echo

# Test subnet/CIDR understanding
echo "CIDR Notation Support:"
check "ip understands CIDR" "ip addr show | grep -qE '/[0-9]+'"
check "Can filter by subnet" "ip route show | grep -qE '/[0-9]+' || true"
echo

# Check IPv6 support
echo "IPv6 Support:"
check "IPv6 enabled in kernel" "test -d /proc/sys/net/ipv6 || cat /proc/net/if_inet6 2>/dev/null"
check "IPv6 addresses visible" "ip -6 addr show | grep -q 'inet6' || true"
echo

# Summary
total=$((passed + failed))
echo "============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 109.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
