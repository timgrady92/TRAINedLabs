#!/bin/bash
# Objective 106.1: Install and configure X11
# Weight: 2

# shellcheck disable=SC2088  # Tildes in description strings are intentional display text
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

echo "Checking Objective 106.1: Install and configure X11"
echo "===================================================="
echo

# Check X11 commands
echo "X11 Commands:"
if command -v xhost &>/dev/null; then
    check "xhost available" "command -v xhost"
else
    echo -e "${YELLOW}${WARN}${NC} xhost not installed"
fi
if command -v xauth &>/dev/null; then
    check "xauth available" "command -v xauth"
else
    echo -e "${YELLOW}${WARN}${NC} xauth not installed"
fi
echo

# Check X11 configuration directories
echo "X11 Configuration:"
check "/etc/X11 exists" "test -d /etc/X11"
if [[ -f /etc/X11/xorg.conf ]]; then
    check "/etc/X11/xorg.conf exists" "test -f /etc/X11/xorg.conf"
else
    echo -e "${YELLOW}${WARN}${NC} /etc/X11/xorg.conf not present (auto-configured)"
fi
if [[ -d /etc/X11/xorg.conf.d ]]; then
    check "/etc/X11/xorg.conf.d exists" "test -d /etc/X11/xorg.conf.d"
fi
echo

# Check DISPLAY variable
echo "Display Environment:"
if [[ -n "${DISPLAY:-}" ]]; then
    check "DISPLAY variable set" "test -n \"\$DISPLAY\""
    echo "  DISPLAY=$DISPLAY"
else
    echo -e "${YELLOW}${WARN}${NC} DISPLAY not set (not in X session)"
fi
echo

# Check X session errors
echo "Session Logs:"
if [[ -f "$HOME/.xsession-errors" ]]; then
    check "~/.xsession-errors exists" "test -f \$HOME/.xsession-errors"
else
    echo -e "${YELLOW}${WARN}${NC} ~/.xsession-errors not found"
fi
echo

# Check X server
echo "X Server:"
if command -v X &>/dev/null; then
    check "X server available" "command -v X"
elif command -v Xorg &>/dev/null; then
    check "Xorg server available" "command -v Xorg"
else
    echo -e "${YELLOW}${WARN}${NC} X server not found"
fi
echo

# Check Wayland (awareness)
echo "Wayland (awareness):"
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    echo "  Running on Wayland"
fi
if command -v wayland-info &>/dev/null; then
    check "Wayland tools available" "command -v wayland-info"
else
    echo -e "${YELLOW}${WARN}${NC} Wayland tools not installed (optional)"
fi
echo

# Check display managers
echo "Display Managers:"
for dm in gdm gdm3 sddm lightdm kdm xdm; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^${dm}"; then
        check "$dm available" "systemctl list-unit-files | grep -q '^${dm}'"
    fi
done
echo

# Check window managers (awareness)
echo "Desktop Components:"
if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    echo "  Current desktop: $XDG_CURRENT_DESKTOP"
fi
if [[ -n "${GDMSESSION:-}" ]]; then
    echo "  Session: $GDMSESSION"
fi
echo

# Summary
total=$((passed + failed))
echo "===================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 106.1 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
