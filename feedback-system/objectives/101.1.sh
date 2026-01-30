#!/bin/bash
# Objective 101.1: Determine and configure hardware settings
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

check_verbose() {
    local desc="$1"
    local cmd="$2"

    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "Testing: $desc"
        echo -e "Command: $cmd"
    fi
    check "$desc" "$cmd"
}

echo "Checking Objective 101.1: Hardware Settings"
echo "============================================"
echo

# Check essential commands exist
echo "Essential Commands:"
check "lspci command available" "command -v lspci"
check "lsusb command available" "command -v lsusb"
check "lsmod command available" "command -v lsmod"
check "modprobe command available" "command -v modprobe"
check "modinfo command available" "command -v modinfo"
check "lsblk command available" "command -v lsblk"
check "dmesg command available" "command -v dmesg"
echo

# Check /proc and /sys exist
echo "Virtual Filesystems:"
check "/proc filesystem exists" "test -d /proc"
check "/sys filesystem exists" "test -d /sys"
check "/proc/cpuinfo readable" "test -r /proc/cpuinfo"
check "/proc/meminfo readable" "test -r /proc/meminfo"
check "/proc/interrupts readable" "test -r /proc/interrupts"
check "/proc/ioports readable" "test -r /proc/ioports"
check "/proc/dma readable" "test -r /proc/dma"
echo

# Check key /sys directories
echo "Sysfs Structure:"
check "/sys/class exists" "test -d /sys/class"
check "/sys/bus exists" "test -d /sys/bus"
check "/sys/devices exists" "test -d /sys/devices"
check "/sys/module exists" "test -d /sys/module"
echo

# Check commands work (not just exist)
echo "Command Functionality:"
check "lspci runs successfully" "lspci -nn 2>/dev/null | head -1"
check "lsusb runs successfully" "lsusb 2>/dev/null | head -1"
check "lsmod runs successfully" "lsmod 2>/dev/null | head -1"
check "lsblk runs successfully" "lsblk 2>/dev/null | head -1"
echo

# Check module operations
echo "Kernel Module System:"
check "/lib/modules directory exists" "test -d /lib/modules"
check "Current kernel modules dir exists" "test -d /lib/modules/\$(uname -r)"
check "modules.dep exists" "test -f /lib/modules/\$(uname -r)/modules.dep"
echo

# Summary
total=$((passed + failed))
echo "============================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 101.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
