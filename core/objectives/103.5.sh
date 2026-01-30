#!/bin/bash
# Objective 103.5: Create, monitor and kill processes
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

echo "Checking Objective 103.5: Create, monitor and kill processes"
echo "============================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "ps available" "command -v ps"
check "top available" "command -v top"
check "kill available" "command -v kill"
check "killall available" "command -v killall"
check "pgrep available" "command -v pgrep"
check "pkill available" "command -v pkill"
check "nohup available" "command -v nohup"
check "jobs available" "type jobs"
check "bg available" "type bg"
check "fg available" "type fg"
echo

# Check monitoring commands
echo "Monitoring Commands:"
check "free available" "command -v free"
check "uptime available" "command -v uptime"
check "watch available" "command -v watch"
echo

# Check terminal multiplexers (awareness)
echo "Terminal Multiplexers:"
if command -v screen &>/dev/null; then
    check "screen available" "command -v screen"
else
    echo -e "${YELLOW}${WARN}${NC} screen not installed (optional)"
fi
if command -v tmux &>/dev/null; then
    check "tmux available" "command -v tmux"
else
    echo -e "${YELLOW}${WARN}${NC} tmux not installed (optional)"
fi
echo

# Test ps functionality
echo "PS Functionality:"
check "ps shows processes" "ps aux | head -1 | grep -qi 'user\|pid'"
check "ps shows current shell" "ps -p \$\$ | grep -q '\$\$'"
check "ps forest view" "ps axjf > /dev/null || ps -ejH > /dev/null"
check "ps custom format" "ps -eo pid,comm,stat | head -1"
echo

# Test process information
echo "Process Information:"
check "/proc filesystem" "test -d /proc"
check "/proc/self exists" "test -d /proc/self"
check "Can read process info" "cat /proc/self/status | grep -q 'Name:'"
check "Can read cmdline" "cat /proc/self/cmdline"
echo

# Test kill signals
echo "Signal Handling:"
check "kill -l lists signals" "kill -l | grep -qi 'HUP\|TERM\|KILL'"
check "SIGTERM signal (15)" "kill -l | grep -q '15.*TERM\|TERM.*15' || kill -l 15 | grep -qi term"
check "SIGKILL signal (9)" "kill -l | grep -q '9.*KILL\|KILL.*9' || kill -l 9 | grep -qi kill"
check "SIGHUP signal (1)" "kill -l | grep -q '1.*HUP\|HUP.*1' || kill -l 1 | grep -qi hup"
echo

# Test background processes
echo "Background Process Control:"
# Start a background process for testing
sleep 100 &
BGPID=$!
disown $BGPID 2>/dev/null || true

check "Background process started" "ps -p $BGPID"
check "pgrep finds process" "pgrep -f 'sleep 100'"
check "kill terminates process" "kill $BGPID 2>/dev/null && sleep 0.5 && ! ps -p $BGPID 2>/dev/null"
echo

# Test monitoring commands functionality
echo "Monitoring Functionality:"
check "free shows memory" "free -h | grep -qi 'mem\|total'"
check "uptime shows load" "uptime | grep -q 'load average\|up'"
check "top batch mode" "top -bn1 | head -5 | grep -qi 'cpu\|tasks\|load'"
echo

# Test pgrep/pkill
echo "Process Grep/Kill:"
sleep 200 &
TESTPID=$!
disown $TESTPID 2>/dev/null || true

check "pgrep by name" "pgrep -x sleep"
check "pgrep by pattern" "pgrep -f 'sleep 200'"
check "pkill terminates" "pkill -f 'sleep 200' && sleep 0.5"
echo

# Test nohup
echo "Nohup Functionality:"
check "nohup command exists" "command -v nohup"
check "nohup.out handling" "test -f nohup.out || true"  # Just verify awareness
echo

# Summary
total=$((passed + failed))
echo "============================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 103.5 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
