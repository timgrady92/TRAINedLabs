#!/bin/bash
# Objective 102.4: Use Debian package management
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

echo "Checking Objective 102.4: Use Debian package management"
echo "========================================================"
echo

# Check if this is a Debian-based system
if ! command -v dpkg &>/dev/null; then
    echo -e "${YELLOW}${WARN}${NC} This is not a Debian-based system"
    echo "Checking for command awareness only..."
    echo
    # Just check that we understand the commands exist conceptually
    echo "Debian Package Commands (conceptual):"
    echo -e "${YELLOW}${WARN}${NC} dpkg - Debian package manager (not installed)"
    echo -e "${YELLOW}${WARN}${NC} apt-get - APT package handling utility (not installed)"
    echo -e "${YELLOW}${WARN}${NC} apt-cache - APT package cache query (not installed)"
    echo -e "${YELLOW}${WARN}${NC} apt - High-level APT interface (not installed)"
    echo
    echo "=========================================="
    echo "Results: N/A (not a Debian system)"
    echo -e "${YELLOW}${WARN} Objective 102.4 requires Debian-based system${NC}"
    exit 0
fi

# Check essential commands
echo "Essential Commands:"
check "dpkg available" "command -v dpkg"
check "dpkg-reconfigure available" "command -v dpkg-reconfigure"
check "apt-get available" "command -v apt-get"
check "apt-cache available" "command -v apt-cache"
check "apt available" "command -v apt"
echo

# Check configuration files
echo "Configuration Files:"
check "/etc/apt/sources.list exists" "test -f /etc/apt/sources.list"
check "/etc/apt/sources.list.d exists" "test -d /etc/apt/sources.list.d"
check "/var/lib/dpkg exists" "test -d /var/lib/dpkg"
check "/var/lib/dpkg/status exists" "test -f /var/lib/dpkg/status"
echo

# Check dpkg functionality
echo "Dpkg Functionality:"
check "dpkg -l lists packages" "dpkg -l | head -5"
check "dpkg -L shows package files" "dpkg -L bash | head -3"
check "dpkg -S finds file owner" "dpkg -S /bin/bash"
check "dpkg --get-selections works" "dpkg --get-selections | head -3"
echo

# Check apt-cache functionality
echo "Apt-cache Functionality:"
check "apt-cache search works" "apt-cache search bash | head -3"
check "apt-cache show works" "apt-cache show bash | head -5"
check "apt-cache depends works" "apt-cache depends bash | head -5"
check "apt-cache policy works" "apt-cache policy bash | head -5"
echo

# Check apt-get functionality
echo "Apt-get Functionality:"
check "apt-get --help works" "apt-get --help | head -3"
check "apt-get update syntax" "apt-get --help | grep -q 'update'"
check "apt-get install syntax" "apt-get --help | grep -q 'install'"
check "apt-get remove syntax" "apt-get --help | grep -q 'remove'"
echo

# Check apt functionality (newer interface)
echo "Apt Functionality:"
check "apt list works" "apt list --installed 2>/dev/null | head -3"
check "apt search works" "apt search bash 2>/dev/null | head -3"
check "apt show works" "apt show bash 2>/dev/null | head -5"
echo

# Check package database
echo "Package Database:"
check "Can count installed packages" "dpkg -l | grep '^ii' | wc -l"
check "Can query package status" "dpkg -s bash | head -5"
echo

# Summary
total=$((passed + failed))
echo "========================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.4 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
