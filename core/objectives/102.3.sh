#!/bin/bash
# Objective 102.3: Manage shared libraries
# Weight: 1

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

echo "Checking Objective 102.3: Manage shared libraries"
echo "=================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "ldd available" "command -v ldd"
check "ldconfig available" "command -v ldconfig"
echo

# Check library configuration
echo "Library Configuration:"
check "/etc/ld.so.conf exists" "test -f /etc/ld.so.conf"
check "/etc/ld.so.conf.d exists" "test -d /etc/ld.so.conf.d"
check "/etc/ld.so.cache exists" "test -f /etc/ld.so.cache"
echo

# Check standard library directories
echo "Standard Library Directories:"
check "/lib exists" "test -d /lib || test -L /lib"
check "/lib64 exists" "test -d /lib64 || test -L /lib64 || true"
check "/usr/lib exists" "test -d /usr/lib"
check "/usr/lib64 exists" "test -d /usr/lib64 || true"
check "/usr/local/lib exists" "test -d /usr/local/lib || true"
echo

# Check LD_LIBRARY_PATH awareness
echo "Environment Variables:"
check "LD_LIBRARY_PATH can be set" "LD_LIBRARY_PATH=/tmp true"
echo

# Test ldd functionality
echo "LDD Functionality:"
check "ldd shows dependencies" "ldd /bin/ls | head -3"
check "ldd on bash works" "ldd /bin/bash | grep -q 'libc'"
check "ldd identifies libc" "ldd /bin/ls | grep -qE 'libc\\.so'"
echo

# Check ldconfig
echo "Ldconfig Functionality:"
check "ldconfig -p lists libraries" "ldconfig -p | head -5"
check "ldconfig -p shows libc" "ldconfig -p | grep -q 'libc'"
check "ldconfig -v available" "ldconfig --help 2>&1 | grep -q 'verbose' || true"
echo

# Check library types
echo "Library Types:"
check "Shared libraries (.so) exist" "ls /lib/*.so* 2>/dev/null || ls /usr/lib/*.so* 2>/dev/null | head -1"
check "Can identify shared library" "file /lib/x86_64-linux-gnu/libc.so.* 2>/dev/null | grep -q 'shared object' || file /lib64/libc.so.* 2>/dev/null | grep -q 'shared object' || ls /lib*/libc.so.* 2>/dev/null | head -1"
echo

# Check common libraries
echo "Common Libraries:"
check "libc available" "ldconfig -p | grep -q 'libc\\.so'"
check "libm (math) available" "ldconfig -p | grep -q 'libm\\.so'"
check "libpthread available" "ldconfig -p | grep -q 'libpthread\\.so' || ldconfig -p | grep -q 'libc\\.so'"
check "libdl available" "ldconfig -p | grep -q 'libdl\\.so' || ldconfig -p | grep -q 'libc\\.so'"
echo

# Summary
total=$((passed + failed))
echo "=================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 102.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
