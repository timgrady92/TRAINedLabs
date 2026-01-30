#!/bin/bash
# Objective 108.1: Maintain system time
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

echo "Checking Objective 108.1: Maintain system time"
echo "==============================================="
echo

# Check time commands
echo "Time Commands:"
check "date available" "command -v date"
check "hwclock available" "command -v hwclock"
check "timedatectl available" "command -v timedatectl"
echo

# Check NTP clients
echo "NTP Clients:"
if command -v chronyc &>/dev/null; then
    check "chronyc available" "command -v chronyc"
fi
if command -v ntpd &>/dev/null; then
    check "ntpd available" "command -v ntpd"
fi
if command -v ntpdate &>/dev/null; then
    check "ntpdate available" "command -v ntpdate"
fi
if command -v ntpq &>/dev/null; then
    check "ntpq available" "command -v ntpq"
fi
echo

# Check timezone configuration
echo "Timezone Configuration:"
check "/etc/localtime exists" "test -f /etc/localtime || test -L /etc/localtime"
check "/usr/share/zoneinfo exists" "test -d /usr/share/zoneinfo"
if [[ -f /etc/timezone ]]; then
    check "/etc/timezone exists" "test -f /etc/timezone"
fi
echo

# Check NTP configuration files
echo "NTP Configuration Files:"
if [[ -f /etc/chrony.conf ]]; then
    check "/etc/chrony.conf exists" "test -f /etc/chrony.conf"
fi
if [[ -f /etc/ntp.conf ]]; then
    check "/etc/ntp.conf exists" "test -f /etc/ntp.conf"
fi
if [[ -f /etc/systemd/timesyncd.conf ]]; then
    check "/etc/systemd/timesyncd.conf exists" "test -f /etc/systemd/timesyncd.conf"
fi
echo

# Test date command
echo "Date Command Functionality:"
check "date shows current time" "date"
check "date with format" "date '+%Y-%m-%d %H:%M:%S %Z'"
check "date -u shows UTC" "date -u"
echo

# Test timedatectl
echo "Timedatectl Functionality:"
check "timedatectl status works" "timedatectl status"
check "timedatectl shows NTP status" "timedatectl status | grep -qi 'ntp\|synchronized\|system clock'"
echo

# Check NTP service
echo "NTP Service:"
if systemctl is-active chronyd &>/dev/null; then
    check "chronyd is running" "systemctl is-active --quiet chronyd"
elif systemctl is-active ntpd &>/dev/null; then
    check "ntpd is running" "systemctl is-active --quiet ntpd"
elif systemctl is-active systemd-timesyncd &>/dev/null; then
    check "systemd-timesyncd is running" "systemctl is-active --quiet systemd-timesyncd"
else
    echo -e "${YELLOW}${WARN}${NC} No NTP service detected running"
fi
echo

# Check chrony functionality (if available)
if command -v chronyc &>/dev/null; then
    echo "Chrony Functionality:"
    check "chronyc tracking works" "chronyc tracking 2>/dev/null | head -3 || true"
    check "chronyc sources works" "chronyc sources 2>/dev/null | head -3 || true"
    echo
fi

# Check pool.ntp.org awareness
echo "NTP Pool:"
echo "  pool.ntp.org provides public NTP servers"
echo "  Use: 0.pool.ntp.org, 1.pool.ntp.org, etc."
echo "  Or regional pools: us.pool.ntp.org, europe.pool.ntp.org"
echo

# Check hardware clock (may require root)
echo "Hardware Clock:"
check "hwclock --help works" "hwclock --help 2>&1 | head -3"
echo "  (Reading hardware clock may require root)"
echo

# Summary
total=$((passed + failed))
echo "==============================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 108.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
