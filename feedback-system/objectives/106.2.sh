#!/bin/bash
# Objective 106.2: Graphical Desktops
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

echo "Checking Objective 106.2: Graphical Desktops"
echo "============================================="
echo

# This is an awareness objective - checking knowledge of desktop environments
echo "Desktop Environment Detection:"
if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    echo "  Current desktop: $XDG_CURRENT_DESKTOP"
    check "Desktop environment detected" "test -n \"\$XDG_CURRENT_DESKTOP\""
else
    echo -e "${YELLOW}${WARN}${NC} No desktop environment detected (headless/server)"
fi
echo

# Check for common desktop environments
echo "Desktop Environments (awareness):"

# GNOME
if command -v gnome-shell &>/dev/null || command -v gnome-session &>/dev/null; then
    check "GNOME available" "command -v gnome-shell || command -v gnome-session"
else
    echo "  GNOME: not installed"
fi

# KDE
if command -v plasmashell &>/dev/null || command -v startkde &>/dev/null; then
    check "KDE Plasma available" "command -v plasmashell || command -v startkde"
else
    echo "  KDE: not installed"
fi

# Xfce
if command -v xfce4-session &>/dev/null; then
    check "Xfce available" "command -v xfce4-session"
else
    echo "  Xfce: not installed"
fi
echo

# Check remote desktop protocols (awareness)
echo "Remote Desktop Protocols:"

# VNC
if command -v vncserver &>/dev/null || command -v tigervncserver &>/dev/null; then
    check "VNC server available" "command -v vncserver || command -v tigervncserver"
else
    echo "  VNC: not installed"
fi

if command -v vncviewer &>/dev/null; then
    check "VNC viewer available" "command -v vncviewer"
else
    echo "  VNC viewer: not installed"
fi

# RDP (xrdp)
if command -v xrdp &>/dev/null || systemctl list-unit-files 2>/dev/null | grep -q xrdp; then
    check "RDP (xrdp) available" "command -v xrdp || systemctl list-unit-files | grep -q xrdp"
else
    echo "  RDP: not installed"
fi

# SPICE
if command -v spice-vdagent &>/dev/null; then
    check "SPICE agent available" "command -v spice-vdagent"
else
    echo "  SPICE: not installed"
fi
echo

# Check XDMCP awareness
echo "XDMCP (awareness):"
echo "  XDMCP allows remote X display management"
echo "  Usually configured via display manager settings"
echo

# Check X11 forwarding capability
echo "X11 Forwarding:"
check "SSH available for X11 forwarding" "command -v ssh"
if [[ -f /etc/ssh/sshd_config ]]; then
    if grep -q "^X11Forwarding yes" /etc/ssh/sshd_config 2>/dev/null; then
        check "X11Forwarding enabled in sshd" "grep -q '^X11Forwarding yes' /etc/ssh/sshd_config"
    else
        echo -e "${YELLOW}${WARN}${NC} X11Forwarding not explicitly enabled"
    fi
fi
echo

# Summary
total=$((passed + failed))
echo "============================================="
echo "Results: $passed/$total checks passed"
echo
echo "Note: This is an awareness objective about desktop environments"
echo "and remote access protocols (VNC, XDMCP, RDP, SPICE)."

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 106.2 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
