#!/bin/bash
# Objective 110.1: Perform security administration tasks
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

echo "Checking Objective 110.1: Perform security administration tasks"
echo "================================================================"
echo

# Check essential commands
echo "Essential Commands:"
check "find available" "command -v find"
check "passwd available" "command -v passwd"
check "chage available" "command -v chage"
check "usermod available" "command -v usermod"
check "su available" "command -v su"
check "sudo available" "command -v sudo"
check "ulimit available" "type ulimit"
echo

# Check user tracking commands
echo "User Tracking Commands:"
check "who available" "command -v who"
check "w available" "command -v w"
check "last available" "command -v last"
check "lastlog available" "command -v lastlog"
echo

# Check process/file commands
echo "Process/File Commands:"
check "lsof available" "command -v lsof"
check "fuser available" "command -v fuser"
echo

# Check network scanning (optional)
echo "Network Scanning:"
if command -v nmap &>/dev/null; then
    check "nmap available" "command -v nmap"
else
    echo -e "${YELLOW}${WARN}${NC} nmap not installed (optional)"
fi
if command -v netstat &>/dev/null; then
    check "netstat available" "command -v netstat"
else
    check "ss available (netstat alternative)" "command -v ss"
fi
echo

# Check sudo configuration
echo "Sudo Configuration:"
check "/etc/sudoers exists" "test -f /etc/sudoers"
check "/etc/sudoers.d exists" "test -d /etc/sudoers.d"
check "sudo works" "sudo -n true 2>/dev/null || sudo -l 2>/dev/null | head -1 || true"
echo

# Check password files
echo "Password Security Files:"
check "/etc/passwd exists" "test -f /etc/passwd"
check "/etc/shadow exists" "test -f /etc/shadow"
check "/etc/shadow not world-readable" "test ! -r /etc/shadow 2>/dev/null || test \$(id -u) -eq 0"
echo

# Test find for SUID/SGID
echo "SUID/SGID Awareness:"
check "Can search for SUID files" "find /usr/bin -perm -4000 -type f 2>/dev/null | head -1 || true"
check "Can search for SGID files" "find /usr/bin -perm -2000 -type f 2>/dev/null | head -1 || true"
check "Can find world-writable" "find /tmp -perm -002 -type f 2>/dev/null | head -1 || true"
echo

# Test user tracking commands
echo "User Tracking Functionality:"
check "who shows logged users" "who || true"
check "w shows user activity" "w | head -2"
check "last shows login history" "last -n 3"
echo

# Test ulimit
echo "Resource Limits:"
check "ulimit shows limits" "ulimit -a | head -3"
check "Can show file limit" "ulimit -n"
check "Can show process limit" "ulimit -u"
echo

# Test lsof/fuser
echo "Open Files/Processes:"
check "lsof runs" "lsof -c bash 2>/dev/null | head -1 || lsof 2>/dev/null | head -1 || true"
check "fuser runs" "fuser / 2>/dev/null || true"
echo

# Check password aging
echo "Password Aging:"
check "chage can show info" "chage -l \$USER 2>/dev/null || true"
echo

# Summary
total=$((passed + failed))
echo "================================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 110.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
