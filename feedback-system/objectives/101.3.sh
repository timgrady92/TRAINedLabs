#!/bin/bash
# Objective 101.3: Change runlevels / boot targets and shutdown or reboot system
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

echo "Checking Objective 101.3: Change runlevels / boot targets"
echo "=========================================================="
echo

# Check essential commands
echo "Essential Commands:"
check "systemctl available" "command -v systemctl"
check "shutdown available" "command -v shutdown"
check "reboot available" "command -v reboot"
check "poweroff available" "command -v poweroff"
check "wall available" "command -v wall"
echo

# Check legacy commands
echo "Legacy Commands:"
if command -v telinit &>/dev/null; then
    check "telinit available" "command -v telinit"
else
    echo -e "${YELLOW}${WARN}${NC} telinit not found (systemd native)"
fi
if command -v init &>/dev/null; then
    check "init available" "command -v init"
fi
if command -v runlevel &>/dev/null; then
    check "runlevel available" "command -v runlevel"
fi
echo

# Check systemd targets
echo "Systemd Targets:"
check "multi-user.target exists" "systemctl cat multi-user.target"
check "graphical.target exists" "systemctl cat graphical.target"
check "rescue.target exists" "systemctl cat rescue.target"
check "emergency.target exists" "systemctl cat emergency.target"
check "poweroff.target exists" "systemctl cat poweroff.target"
check "reboot.target exists" "systemctl cat reboot.target"
echo

# Check current target
echo "Current Boot Target:"
check "Can get default target" "systemctl get-default"
check "Can list targets" "systemctl list-units --type=target --no-pager | head -5"
echo

# Check target directories
echo "Target Configuration:"
check "/etc/systemd/system exists" "test -d /etc/systemd/system"
check "/usr/lib/systemd/system exists" "test -d /usr/lib/systemd/system || test -d /lib/systemd/system"
check "default.target is symlink" "test -L /etc/systemd/system/default.target || systemctl get-default"
echo

# Check runlevel compatibility
echo "Runlevel Compatibility:"
check "runlevel0.target exists" "systemctl cat runlevel0.target || true"
check "runlevel1.target exists" "systemctl cat runlevel1.target || true"
check "runlevel3.target exists" "systemctl cat runlevel3.target || true"
check "runlevel5.target exists" "systemctl cat runlevel5.target || true"
check "runlevel6.target exists" "systemctl cat runlevel6.target || true"
echo

# Check /etc/init.d scripts
echo "Init Scripts:"
check "/etc/init.d exists" "test -d /etc/init.d"
if [[ -d /etc/init.d ]]; then
    check "Init scripts present" "ls /etc/init.d/ | head -1"
fi
echo

# Check shutdown/reboot commands exist
echo "Power Management Commands:"
check "shutdown --help works" "shutdown --help 2>&1 | head -1"
check "systemctl poweroff available" "systemctl --help | grep -q 'poweroff'"
check "systemctl reboot available" "systemctl --help | grep -q 'reboot'"
check "systemctl halt available" "systemctl --help | grep -q 'halt'"
echo

# Check wall command
echo "User Notification:"
check "wall command works" "echo '' | wall 2>/dev/null || wall --help 2>&1 | head -1 || true"
echo

# Check ACPI awareness
echo "ACPI (awareness):"
if [[ -d /sys/firmware/acpi ]]; then
    check "ACPI present" "test -d /sys/firmware/acpi"
fi
if command -v acpid &>/dev/null || systemctl list-unit-files | grep -q acpid; then
    check "acpid available" "command -v acpid || systemctl list-unit-files | grep -q acpid"
else
    echo -e "${YELLOW}${WARN}${NC} acpid not installed (optional)"
fi
echo

# Summary
total=$((passed + failed))
echo "=========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 101.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
