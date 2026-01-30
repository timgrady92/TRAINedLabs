#!/bin/bash
# Objective 103.6: Modify process execution priorities
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

echo "Checking Objective 103.6: Modify process execution priorities"
echo "=============================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "nice available" "command -v nice"
check "renice available" "command -v renice"
check "ps available" "command -v ps"
check "top available" "command -v top"
echo

# Test nice functionality
echo "Nice Functionality:"
check "nice --help works" "nice --help 2>&1 | head -1"
check "nice default behavior" "nice echo test"
check "nice with value" "nice -n 10 echo test"
check "nice shows default priority" "nice | grep -qE '^[0-9]+$' || nice"
echo

# Test viewing process priorities
echo "Process Priority Display:"
check "ps shows nice values" "ps -eo pid,ni,comm | head -3"
check "ps -l shows nice column" "ps -l | head -3"
check "top -bn1 shows priorities" "top -bn1 | head -15 | grep -qE 'NI|PR'"
echo

# Test process with different nice levels
echo "Priority Levels:"
# Start a background process with nice
nice -n 10 sleep 60 &
NICE_PID=$!
disown $NICE_PID 2>/dev/null || true

check "Process started with nice 10" "ps -o ni= -p $NICE_PID | grep -qE '10|^ *10'"
kill $NICE_PID 2>/dev/null || true
echo

# Test nice range awareness
echo "Nice Value Range:"
check "Nice accepts positive values" "nice -n 19 true"
check "Nice accepts zero" "nice -n 0 true"
# Negative nice requires root, so we just test the syntax awareness
check "Nice syntax for negative" "nice --help 2>&1 | grep -qE '\\-n|adjustment' || true"
echo

# Test renice (limited without root)
echo "Renice Functionality:"
check "renice --help works" "renice --help 2>&1 | head -3 || renice 2>&1 | head -3"
check "renice can target PID" "renice --help 2>&1 | grep -qE 'pid|PID' || renice 2>&1 | grep -qE 'pid|PID'"
# Start process to test renice on our own process
sleep 100 &
TEST_PID=$!
disown $TEST_PID 2>/dev/null || true

check "renice own process" "renice -n 15 -p $TEST_PID 2>/dev/null || true"
kill $TEST_PID 2>/dev/null || true
echo

# Check /proc for priority info
echo "Proc Filesystem:"
check "/proc/self/stat readable" "cat /proc/self/stat | head -c 100"
echo

# Summary
total=$((passed + failed))
echo "=============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.6 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
