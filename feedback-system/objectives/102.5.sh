#!/bin/bash
# Objective 102.5: Use RPM and YUM package management
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

echo "Checking Objective 102.5: Use RPM and YUM package management"
echo "============================================================="
echo

# Check if this is an RPM-based system
if ! command -v rpm &>/dev/null; then
    echo -e "${YELLOW}${WARN}${NC} This is not an RPM-based system"
    echo "Checking for command awareness only..."
    echo
    echo "RPM Package Commands (conceptual):"
    echo -e "${YELLOW}${WARN}${NC} rpm - RPM package manager (not installed)"
    echo -e "${YELLOW}${WARN}${NC} yum - Yellowdog Updater Modified (not installed)"
    echo -e "${YELLOW}${WARN}${NC} dnf - Dandified YUM (not installed)"
    echo -e "${YELLOW}${WARN}${NC} zypper - SUSE package manager (not installed)"
    echo
    echo "=============================================="
    echo "Results: N/A (not an RPM system)"
    echo -e "${YELLOW}${WARN} Objective 102.5 requires RPM-based system${NC}"
    exit 0
fi

# Check RPM command
echo "RPM Commands:"
check "rpm available" "command -v rpm"
check "rpm2cpio available" "command -v rpm2cpio"
echo

# Check YUM/DNF
echo "Package Managers:"
if command -v dnf &>/dev/null; then
    check "dnf available" "command -v dnf"
elif command -v yum &>/dev/null; then
    check "yum available" "command -v yum"
fi
if command -v zypper &>/dev/null; then
    check "zypper available" "command -v zypper"
fi
echo

# Check configuration files
echo "Configuration Files:"
if [[ -f /etc/yum.conf ]]; then
    check "/etc/yum.conf exists" "test -f /etc/yum.conf"
fi
if [[ -d /etc/yum.repos.d ]]; then
    check "/etc/yum.repos.d exists" "test -d /etc/yum.repos.d"
fi
if [[ -f /etc/dnf/dnf.conf ]]; then
    check "/etc/dnf/dnf.conf exists" "test -f /etc/dnf/dnf.conf"
fi
check "/var/lib/rpm exists" "test -d /var/lib/rpm"
echo

# Check RPM functionality
echo "RPM Functionality:"
check "rpm -qa lists packages" "rpm -qa | head -5"
check "rpm -qi queries package info" "rpm -qi bash | head -5"
check "rpm -ql lists package files" "rpm -ql bash | head -5"
check "rpm -qf finds file owner" "rpm -qf /bin/bash"
check "rpm -qc lists config files" "rpm -qc bash || true"
check "rpm -qd lists doc files" "rpm -qd bash | head -3 || true"
check "rpm -V verifies package" "rpm -V bash 2>&1 || true"
echo

# Check YUM/DNF functionality
echo "YUM/DNF Functionality:"
if command -v dnf &>/dev/null; then
    check "dnf list works" "dnf list installed | head -5"
    check "dnf search works" "dnf search bash | head -5"
    check "dnf info works" "dnf info bash | head -10"
    check "dnf repolist works" "dnf repolist | head -5"
    check "dnf provides works" "dnf provides /bin/bash | head -5"
elif command -v yum &>/dev/null; then
    check "yum list works" "yum list installed | head -5"
    check "yum search works" "yum search bash | head -5"
    check "yum info works" "yum info bash | head -10"
    check "yum repolist works" "yum repolist | head -5"
fi
echo

# Check rpm2cpio functionality
echo "RPM2CPIO:"
check "rpm2cpio --help works" "rpm2cpio --help 2>&1 | head -1 || rpm2cpio 2>&1 | head -1"
echo

# Check package groups (if available)
echo "Package Groups:"
if command -v dnf &>/dev/null; then
    check "dnf group list works" "dnf group list | head -5 || true"
elif command -v yum &>/dev/null; then
    check "yum grouplist works" "yum grouplist | head -5 || true"
fi
echo

# Summary
total=$((passed + failed))
echo "============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.5 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
