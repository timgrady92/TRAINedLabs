#!/bin/bash
# Objective 108.4: Manage printers and printing
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

echo "Checking Objective 108.4: Manage printers and printing"
echo "======================================================="
echo

# Check CUPS commands
echo "CUPS Commands:"
if command -v lpstat &>/dev/null; then
    check "lpstat available" "command -v lpstat"
else
    echo -e "${YELLOW}${WARN}${NC} lpstat not installed"
fi
if command -v lp &>/dev/null; then
    check "lp available" "command -v lp"
fi
if command -v cancel &>/dev/null; then
    check "cancel available" "command -v cancel"
fi
if command -v cupsctl &>/dev/null; then
    check "cupsctl available" "command -v cupsctl"
fi
if command -v lpadmin &>/dev/null; then
    check "lpadmin available" "command -v lpadmin"
fi
echo

# Check legacy LPD commands
echo "Legacy LPD Commands:"
if command -v lpr &>/dev/null; then
    check "lpr available" "command -v lpr"
fi
if command -v lpq &>/dev/null; then
    check "lpq available" "command -v lpq"
fi
if command -v lprm &>/dev/null; then
    check "lprm available" "command -v lprm"
fi
echo

# Check CUPS configuration
echo "CUPS Configuration:"
check "/etc/cups exists" "test -d /etc/cups"
if [[ -d /etc/cups ]]; then
    check "cupsd.conf exists" "test -f /etc/cups/cupsd.conf"
    check "printers.conf exists" "test -f /etc/cups/printers.conf || true"
fi
echo

# Check CUPS service
echo "CUPS Service:"
if systemctl list-unit-files 2>/dev/null | grep -q cups; then
    check "CUPS service available" "systemctl list-unit-files | grep -q cups"
    if systemctl is-active cups &>/dev/null; then
        check "CUPS service running" "systemctl is-active --quiet cups"
    else
        echo -e "${YELLOW}${WARN}${NC} CUPS service not running"
    fi
else
    echo -e "${YELLOW}${WARN}${NC} CUPS not installed"
fi
echo

# Check printer status
echo "Printer Status:"
if command -v lpstat &>/dev/null; then
    check "lpstat -p lists printers" "lpstat -p 2>/dev/null || true"
    check "lpstat -d shows default" "lpstat -d 2>/dev/null || true"
    check "lpstat -a shows accepting" "lpstat -a 2>/dev/null || true"
fi
echo

# Check CUPS web interface
echo "CUPS Web Interface:"
echo "  Default URL: http://localhost:631"
echo "  Admin URL: http://localhost:631/admin"
if [[ -f /etc/cups/cupsd.conf ]]; then
    check "cupsd.conf readable" "test -r /etc/cups/cupsd.conf"
fi
echo

# Check print spool
echo "Print Spool:"
check "/var/spool/cups exists" "test -d /var/spool/cups"
echo

# CUPS awareness
echo "CUPS Awareness:"
echo "  Key commands:"
echo "  - lpstat: Query printer/job status"
echo "  - lp/lpr: Submit print jobs"
echo "  - cancel/lprm: Cancel print jobs"
echo "  - lpadmin: Configure printers (root)"
echo "  - cupsctl: Configure CUPS server"
echo

# Summary
total=$((passed + failed))
echo "======================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 108.4 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
