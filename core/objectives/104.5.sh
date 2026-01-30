#!/bin/bash
# Objective 104.5: Manage file permissions and ownership
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

echo "Checking Objective 104.5: File Permissions and Ownership"
echo "========================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "chmod available" "command -v chmod"
check "chown available" "command -v chown"
check "chgrp available" "command -v chgrp"
check "umask available" "type umask"
check "stat available" "command -v stat"
check "ls -l works" "ls -l / | head -1"
echo

# Check /etc/passwd and /etc/group
echo "User/Group Files:"
check "/etc/passwd exists" "test -f /etc/passwd"
check "/etc/group exists" "test -f /etc/group"
check "/etc/shadow exists" "test -f /etc/shadow"
check "Current user in passwd" "grep -q \"^\$USER:\" /etc/passwd"
echo

# Check permission understanding via stat
echo "Permission Verification:"
check "Can read permission mode" "stat -c %a /etc/passwd"
check "Can read owner" "stat -c %U /etc/passwd"
check "Can read group" "stat -c %G /etc/passwd"
echo

# Test file creation with umask
echo "Umask Functionality:"
TESTDIR=$(mktemp -d)
trap 'rm -rf "$TESTDIR"' EXIT

# Create test files
touch "$TESTDIR/testfile"
mkdir "$TESTDIR/testdir"

check "Default file permissions reasonable" "test \$(stat -c %a $TESTDIR/testfile) -le 666"
check "Default dir permissions reasonable" "test \$(stat -c %a $TESTDIR/testdir) -le 777"
echo

# Test chmod
echo "chmod Functionality:"
chmod 644 "$TESTDIR/testfile"
check "chmod numeric mode works (644)" "test \$(stat -c %a $TESTDIR/testfile) = '644'"

chmod 755 "$TESTDIR/testfile"
check "chmod numeric mode works (755)" "test \$(stat -c %a $TESTDIR/testfile) = '755'"

chmod u-x "$TESTDIR/testfile"
check "chmod symbolic mode works (u-x)" "test \$(stat -c %a $TESTDIR/testfile) = '655'"

chmod go-rx "$TESTDIR/testfile"
check "chmod symbolic mode works (go-rx)" "test \$(stat -c %a $TESTDIR/testfile) = '600'"
echo

# Test special permissions
echo "Special Permissions:"
chmod 4755 "$TESTDIR/testdir"
check "SUID can be set" "test \$(stat -c %a $TESTDIR/testdir) = '4755'"

chmod 2755 "$TESTDIR/testdir"
check "SGID can be set" "test \$(stat -c %a $TESTDIR/testdir) = '2755'"

chmod 1755 "$TESTDIR/testdir"
check "Sticky bit can be set" "test \$(stat -c %a $TESTDIR/testdir) = '1755'"
echo

# Check for ACL support
echo "ACL Support (if available):"
if command -v getfacl &>/dev/null; then
    check "getfacl available" "command -v getfacl"
    check "setfacl available" "command -v setfacl"
else
    echo -e "${YELLOW}${WARN}${NC} ACL tools not installed (optional for LPIC-1)"
fi
echo

# Summary
total=$((passed + failed))
echo "========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.5 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
