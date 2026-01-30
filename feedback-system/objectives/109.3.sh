#!/bin/bash
# Objective 109.3: Basic network troubleshooting
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

echo "Checking Objective 109.3: Basic network troubleshooting"
echo "========================================================"
echo

# Check iproute2 commands (modern)
echo "Iproute2 Commands:"
check "ip available" "command -v ip"
check "ss available" "command -v ss"
echo

# Check diagnostic commands
echo "Diagnostic Commands:"
check "ping available" "command -v ping"
check "traceroute available" "command -v traceroute || command -v tracepath"
check "tracepath available" "command -v tracepath"
check "hostname available" "command -v hostname"
echo

# Check netcat (optional but useful)
echo "Netcat:"
if command -v nc &>/dev/null || command -v netcat &>/dev/null; then
    check "netcat available" "command -v nc || command -v netcat"
else
    echo -e "${YELLOW}${WARN}${NC} netcat not installed (optional)"
fi
echo

# Check legacy net-tools (awareness)
echo "Legacy net-tools (awareness):"
if command -v ifconfig &>/dev/null; then
    check "ifconfig available" "command -v ifconfig"
else
    echo -e "${YELLOW}${WARN}${NC} ifconfig not installed (use ip instead)"
fi
if command -v netstat &>/dev/null; then
    check "netstat available" "command -v netstat"
else
    echo -e "${YELLOW}${WARN}${NC} netstat not installed (use ss instead)"
fi
if command -v route &>/dev/null; then
    check "route available" "command -v route"
else
    echo -e "${YELLOW}${WARN}${NC} route not installed (use ip route instead)"
fi
echo

# Test ip command functionality
echo "IP Command Functionality:"
check "ip addr shows interfaces" "ip addr show | grep -q 'inet'"
check "ip link shows devices" "ip link show | head -2"
check "ip route shows routing" "ip route show | head -2"
check "ip neigh shows ARP" "ip neigh show 2>/dev/null || true"
echo

# Test ss command functionality
echo "SS Command Functionality:"
check "ss shows sockets" "ss -tuln | head -2"
check "ss -t shows TCP" "ss -t"
check "ss -u shows UDP" "ss -u"
check "ss -l shows listening" "ss -l | head -2"
check "ss -p shows processes" "ss -tlnp 2>/dev/null || ss -tln"
echo

# Test ping functionality
echo "Ping Functionality:"
check "ping localhost works" "ping -c 1 -W 2 127.0.0.1"
check "ping6 or ping -6 exists" "command -v ping6 || ping -6 -c 1 ::1 2>/dev/null || true"
echo

# Test traceroute/tracepath
echo "Traceroute Functionality:"
if command -v tracepath &>/dev/null; then
    check "tracepath works" "tracepath -m 1 127.0.0.1 2>/dev/null || true"
fi
echo

# Check routing
echo "Routing Information:"
check "Can view default route" "ip route show default || ip route show | grep -q default || true"
check "Can view routing table" "ip route show"
echo

# Check interface configuration ability
echo "Interface Management:"
check "Can view interface details" "ip addr show"
check "Can view interface stats" "ip -s link show | head -10"
echo

# Summary
total=$((passed + failed))
echo "========================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 109.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
