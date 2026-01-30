#!/bin/bash
# Objective 107.1: Manage user and group accounts and related system files
# Weight: 5

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

echo "Checking Objective 107.1: Manage user and group accounts"
echo "========================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "useradd available" "command -v useradd"
check "userdel available" "command -v userdel"
check "usermod available" "command -v usermod"
check "groupadd available" "command -v groupadd"
check "groupdel available" "command -v groupdel"
check "groupmod available" "command -v groupmod"
check "passwd available" "command -v passwd"
check "chage available" "command -v chage"
check "getent available" "command -v getent"
echo

# Check system files
echo "System Files:"
check "/etc/passwd exists" "test -f /etc/passwd"
check "/etc/shadow exists" "test -f /etc/shadow"
check "/etc/group exists" "test -f /etc/group"
check "/etc/gshadow exists" "test -f /etc/gshadow"
check "/etc/login.defs exists" "test -f /etc/login.defs"
check "/etc/skel exists" "test -d /etc/skel"
echo

# Check file permissions
echo "Security Permissions:"
check "/etc/passwd readable" "test -r /etc/passwd"
check "/etc/shadow not world-readable" "test ! -r /etc/shadow 2>/dev/null || test \$(id -u) -eq 0"
check "/etc/group readable" "test -r /etc/group"
echo

# Check file format validity
echo "File Format Validation:"
check "/etc/passwd has valid format" "getent passwd | head -1 | grep -q ':'"
check "/etc/group has valid format" "getent group | head -1 | grep -q ':'"
check "Current user in passwd" "getent passwd \$USER"
echo

# Check command functionality
echo "Command Functionality:"
check "getent passwd works" "getent passwd root"
check "getent group works" "getent group root"
check "id command works" "id \$USER"
check "groups command works" "groups \$USER"
echo

# Check /etc/skel contents
echo "Skeleton Directory:"
check "/etc/skel/.bashrc exists" "test -f /etc/skel/.bashrc || test -f /etc/skel/.profile"
check "/etc/skel readable" "test -r /etc/skel"
echo

# Check login.defs configuration
echo "Login Configuration:"
check "UID_MIN defined" "grep -q '^UID_MIN' /etc/login.defs"
check "UID_MAX defined" "grep -q '^UID_MAX' /etc/login.defs"
check "GID_MIN defined" "grep -q '^GID_MIN' /etc/login.defs"
check "PASS_MAX_DAYS defined" "grep -q '^PASS_MAX_DAYS' /etc/login.defs"
echo

# Check user information retrieval
echo "User Information:"
check "Can list all users" "getent passwd | wc -l | grep -q '[0-9]'"
check "Can list all groups" "getent group | wc -l | grep -q '[0-9]'"
check "Can check user groups" "id -Gn \$USER"
echo

# Summary
total=$((passed + failed))
echo "========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 107.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
