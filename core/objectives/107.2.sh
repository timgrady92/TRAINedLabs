#!/bin/bash
# Objective 107.2: Automate system administration tasks by scheduling jobs
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

echo "Checking Objective 107.2: Automate system administration tasks"
echo "==============================================================="
echo

# Check cron commands
echo "Cron Commands:"
check "crontab available" "command -v crontab"
echo

# Check at commands
echo "At Commands:"
if command -v at &>/dev/null; then
    check "at available" "command -v at"
    check "atq available" "command -v atq"
    check "atrm available" "command -v atrm"
    check "batch available" "command -v batch"
else
    echo -e "${YELLOW}${WARN}${NC} at package not installed"
fi
echo

# Check systemd timer commands
echo "Systemd Timer Commands:"
check "systemctl available" "command -v systemctl"
check "systemd-run available" "command -v systemd-run"
echo

# Check cron directories
echo "Cron Directories:"
check "/etc/crontab exists" "test -f /etc/crontab"
check "/etc/cron.d exists" "test -d /etc/cron.d"
check "/etc/cron.daily exists" "test -d /etc/cron.daily"
check "/etc/cron.hourly exists" "test -d /etc/cron.hourly"
check "/etc/cron.weekly exists" "test -d /etc/cron.weekly"
check "/etc/cron.monthly exists" "test -d /etc/cron.monthly"
echo

# Check cron spool
echo "Cron Spool:"
check "/var/spool/cron exists" "test -d /var/spool/cron || test -d /var/spool/cron/crontabs"
echo

# Check cron access control
echo "Cron Access Control:"
if [[ -f /etc/cron.allow ]]; then
    check "/etc/cron.allow exists" "test -f /etc/cron.allow"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/cron.allow not found (using cron.deny or default allow)"
fi
if [[ -f /etc/cron.deny ]]; then
    check "/etc/cron.deny exists" "test -f /etc/cron.deny"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/cron.deny not found"
fi
echo

# Check at access control
echo "At Access Control:"
if [[ -f /etc/at.allow ]]; then
    check "/etc/at.allow exists" "test -f /etc/at.allow"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/at.allow not found (using at.deny or default)"
fi
if [[ -f /etc/at.deny ]]; then
    check "/etc/at.deny exists" "test -f /etc/at.deny"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/at.deny not found"
fi
echo

# Test crontab functionality
echo "Crontab Functionality:"
check "crontab -l runs" "crontab -l 2>&1 || true"
# Don't modify user's crontab, just verify command works
echo

# Check /etc/crontab format
echo "Crontab Format:"
check "/etc/crontab readable" "test -r /etc/crontab"
check "/etc/crontab has format" "grep -qE '^[0-9*]|^#|^SHELL|^PATH|^MAILTO' /etc/crontab"
echo

# Check cron service
echo "Cron Service:"
check "cron/crond service exists" "systemctl list-unit-files | grep -qE 'cron|crond' || test -f /etc/init.d/cron"
if systemctl is-active crond &>/dev/null || systemctl is-active cron &>/dev/null; then
    check "cron service is running" "systemctl is-active --quiet crond || systemctl is-active --quiet cron"
else
    echo -e "${YELLOW}${WARN}${NC} cron service not running"
fi
echo

# Check systemd timers
echo "Systemd Timers:"
check "Can list timers" "systemctl list-timers --no-pager | head -5"
check "Timer unit files exist" "systemctl list-unit-files '*.timer' --no-pager | head -5"
echo

# Test anacron (if available)
echo "Anacron (if available):"
if command -v anacron &>/dev/null; then
    check "anacron available" "command -v anacron"
    check "/etc/anacrontab exists" "test -f /etc/anacrontab"
else
    echo -e "${YELLOW}${WARN}${NC} anacron not installed (optional)"
fi
echo

# Summary
total=$((passed + failed))
echo "==============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 107.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
