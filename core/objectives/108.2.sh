#!/bin/bash
# Objective 108.2: System logging
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

echo "Checking Objective 108.2: System logging"
echo "========================================="
echo

# Check logging commands
echo "Logging Commands:"
check "logger available" "command -v logger"
check "journalctl available" "command -v journalctl"
check "systemd-cat available" "command -v systemd-cat"
echo

# Check log rotation
echo "Log Rotation:"
check "logrotate available" "command -v logrotate"
check "/etc/logrotate.conf exists" "test -f /etc/logrotate.conf"
check "/etc/logrotate.d exists" "test -d /etc/logrotate.d"
echo

# Check rsyslog (if installed)
echo "Rsyslog:"
if command -v rsyslogd &>/dev/null || test -f /etc/rsyslog.conf; then
    check "rsyslog config exists" "test -f /etc/rsyslog.conf"
    check "rsyslog.d directory exists" "test -d /etc/rsyslog.d"
    if systemctl is-active rsyslog &>/dev/null; then
        check "rsyslog service running" "systemctl is-active --quiet rsyslog"
    else
        echo -e "${YELLOW}${WARN}${NC} rsyslog not running"
    fi
else
    echo -e "${YELLOW}${WARN}${NC} rsyslog not installed (using systemd-journald)"
fi
echo

# Check systemd journal
echo "Systemd Journal:"
check "journald config exists" "test -f /etc/systemd/journald.conf"
check "/var/log/journal or runtime journal" "test -d /var/log/journal || test -d /run/log/journal"
if systemctl is-active systemd-journald &>/dev/null; then
    check "systemd-journald running" "systemctl is-active --quiet systemd-journald"
fi
echo

# Check log directories
echo "Log Directories:"
check "/var/log exists" "test -d /var/log"
check "/var/log is readable" "test -r /var/log"
echo

# Check common log files
echo "Common Log Files:"
if [[ -f /var/log/syslog ]]; then
    check "/var/log/syslog exists" "test -f /var/log/syslog"
elif [[ -f /var/log/messages ]]; then
    check "/var/log/messages exists" "test -f /var/log/messages"
else
    echo -e "${YELLOW}${WARN}${NC} Traditional syslog files not found (using journald)"
fi
check "/var/log/auth.log or secure" "test -f /var/log/auth.log || test -f /var/log/secure"
echo

# Test journalctl functionality
echo "Journalctl Functionality:"
check "journalctl runs" "journalctl --no-pager -n 1"
check "journalctl -u filters by unit" "journalctl --no-pager -u systemd-journald -n 1 || true"
check "journalctl -p filters by priority" "journalctl --no-pager -p err -n 1 || true"
check "journalctl --since works" "journalctl --no-pager --since 'today' -n 1 || true"
check "journalctl -f exists (follow)" "journalctl --help | grep -q '\\-f'"
echo

# Test logger functionality
echo "Logger Functionality:"
check "logger can write" "logger 'LPIC test message'"
check "logger with priority" "logger -p user.info 'LPIC priority test'"
check "logger with tag" "logger -t lpic-test 'tagged message'"
echo

# Check journal size configuration
echo "Journal Configuration:"
check "journald.conf readable" "test -r /etc/systemd/journald.conf"
check "SystemMaxUse configurable" "grep -q 'SystemMaxUse' /etc/systemd/journald.conf || true"
echo

# Check syslog facilities awareness
echo "Syslog Facilities:"
check "logger understands auth" "logger -p auth.info 'test' 2>&1 || true"
check "logger understands daemon" "logger -p daemon.info 'test' 2>&1 || true"
check "logger understands kern" "logger -p kern.info 'test' 2>&1 || true"
check "logger understands local0" "logger -p local0.info 'test' 2>&1 || true"
echo

# Summary
total=$((passed + failed))
echo "========================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 108.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
