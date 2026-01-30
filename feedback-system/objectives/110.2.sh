#!/bin/bash
# Objective 110.2: Setup host security
# Weight: 3

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

echo "Checking Objective 110.2: Setup host security"
echo "=============================================="
echo

# Check shadow password files
echo "Shadow Passwords:"
check "/etc/passwd exists" "test -f /etc/passwd"
check "/etc/shadow exists" "test -f /etc/shadow"
check "/etc/passwd readable" "test -r /etc/passwd"
check "/etc/shadow not world-readable" "! test -r /etc/shadow 2>/dev/null || test \$(id -u) -eq 0"
echo

# Check /etc/nologin
echo "Login Control:"
if [[ -f /etc/nologin ]]; then
    check "/etc/nologin exists" "test -f /etc/nologin"
    echo "  WARNING: /etc/nologin prevents non-root logins"
else
    echo "  /etc/nologin not present (logins allowed)"
fi
echo

# Check init scripts
echo "Init Configuration:"
check "/etc/init.d exists" "test -d /etc/init.d"
if [[ -f /etc/inittab ]]; then
    check "/etc/inittab exists" "test -f /etc/inittab"
fi
echo

# Check xinetd/inetd (legacy)
echo "Super-server (legacy):"
if [[ -d /etc/xinetd.d ]]; then
    check "/etc/xinetd.d exists" "test -d /etc/xinetd.d"
    if [[ -f /etc/xinetd.conf ]]; then
        check "/etc/xinetd.conf exists" "test -f /etc/xinetd.conf"
    fi
else
    echo "  xinetd not installed (modern systems use systemd)"
fi
echo

# Check systemd socket activation
echo "Systemd Socket Units:"
check "Can list socket units" "systemctl list-units --type=socket --no-pager | head -5"
check "Socket units exist" "systemctl list-unit-files --type=socket --no-pager | head -5"
echo

# Check TCP wrappers
echo "TCP Wrappers:"
if [[ -f /etc/hosts.allow ]]; then
    check "/etc/hosts.allow exists" "test -f /etc/hosts.allow"
fi
if [[ -f /etc/hosts.deny ]]; then
    check "/etc/hosts.deny exists" "test -f /etc/hosts.deny"
fi
echo "  TCP wrappers control access to services"
echo "  Order: hosts.allow checked first, then hosts.deny"
echo

# Check for unnecessary services
echo "Service Management:"
check "systemctl available" "command -v systemctl"
check "Can list services" "systemctl list-units --type=service --state=running --no-pager | head -5"
echo

# Check listening ports
echo "Listening Services:"
check "ss available" "command -v ss"
check "Can list listening ports" "ss -tuln | head -5"
echo "  Review listening services with: ss -tulnp"
echo

# Security awareness
echo "Security Best Practices:"
echo "  - Disable unused services: systemctl disable <service>"
echo "  - Use TCP wrappers for legacy services"
echo "  - Keep /etc/shadow permissions restrictive"
echo "  - Use /etc/nologin for maintenance"
echo "  - Review listening ports regularly"
echo

# Summary
total=$((passed + failed))
echo "=============================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 110.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
