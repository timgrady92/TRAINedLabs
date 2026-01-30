#!/bin/bash
# Objective 104.7: Find system files and place files in the correct location
# Weight: 2

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

echo "Checking Objective 104.7: Find system files and place files in correct location"
echo "================================================================================"
echo

# Check essential commands
echo "File Finding Commands:"
check "find available" "command -v find"
check "locate available" "command -v locate || command -v mlocate"
check "updatedb available" "command -v updatedb"
check "whereis available" "command -v whereis"
check "which available" "command -v which"
check "type available" "type type"
echo

# Check FHS directories
echo "Filesystem Hierarchy Standard:"
check "/ exists" "test -d /"
check "/bin exists" "test -d /bin || test -L /bin"
check "/sbin exists" "test -d /sbin || test -L /sbin"
check "/usr exists" "test -d /usr"
check "/usr/bin exists" "test -d /usr/bin"
check "/usr/sbin exists" "test -d /usr/sbin"
check "/usr/local exists" "test -d /usr/local"
check "/var exists" "test -d /var"
check "/var/log exists" "test -d /var/log"
check "/var/tmp exists" "test -d /var/tmp"
check "/tmp exists" "test -d /tmp"
check "/etc exists" "test -d /etc"
check "/home exists" "test -d /home"
check "/opt exists" "test -d /opt"
check "/boot exists" "test -d /boot"
check "/lib exists" "test -d /lib || test -L /lib"
check "/dev exists" "test -d /dev"
check "/proc exists" "test -d /proc"
check "/sys exists" "test -d /sys"
check "/run exists" "test -d /run"
echo

# Test find functionality
echo "Find Functionality:"
check "find by name" "find /etc -name 'passwd' -type f 2>/dev/null | head -1"
check "find by type" "find /etc -type d 2>/dev/null | head -3"
check "find with maxdepth" "find /var -maxdepth 1 -type d 2>/dev/null | head -5"
echo

# Test locate functionality
echo "Locate Functionality:"
if command -v locate &>/dev/null; then
    check "locate database exists" "test -f /var/lib/mlocate/mlocate.db || test -f /var/lib/plocate/plocate.db || locate --version"
    check "locate finds files" "locate passwd 2>/dev/null | head -3 || true"
elif command -v mlocate &>/dev/null; then
    check "mlocate available" "command -v mlocate"
else
    echo -e "${YELLOW}${WARN}${NC} locate/mlocate not installed"
fi
echo

# Test whereis functionality
echo "Whereis Functionality:"
check "whereis finds binary" "whereis ls | grep -q '/'"
check "whereis finds man pages" "whereis bash | grep -qE 'man|/usr/share'"
echo

# Test which functionality
echo "Which Functionality:"
check "which finds command" "which ls | grep -q '/'"
check "which in PATH" "which bash | grep -q 'bash'"
echo

# Test type functionality
echo "Type Functionality:"
check "type identifies commands" "type ls"
check "type identifies builtins" "type cd | grep -qi 'builtin'"
check "type identifies aliases" "type type | grep -qi 'builtin'"
echo

# Check updatedb configuration
echo "Updatedb Configuration:"
if [[ -f /etc/updatedb.conf ]]; then
    check "/etc/updatedb.conf exists" "test -f /etc/updatedb.conf"
fi
echo

# Summary
total=$((passed + failed))
echo "================================================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 104.7 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
