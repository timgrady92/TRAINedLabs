#!/bin/bash
# LPIC-1 Build Scenario: Print Server Setup
# Guides through CUPS configuration
# MUST be run as root

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"
INFO="ℹ"

print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
print_info() { echo -e "${CYAN}${INFO}${NC} $1"; }
print_header() { echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}\n"; }

# Configuration
HINTS_USED=0
VIRTUAL_PRINTER="LPIC1-Virtual-Printer"

# Detect distro
detect_distro() {
    if [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_fail "This script must be run as root"
        echo "Use: sudo $0 $*"
        exit 1
    fi
}

# Start the challenge
start_challenge() {
    print_header "Print Server (CUPS) Setup Challenge"

    echo "Your mission: Set up a working print system using CUPS"
    echo
    echo "LPIC-1 Objective 108.4: Manage printers and printing"
    echo
    echo "Requirements:"
    echo "  1. Install CUPS printing system"
    echo "  2. Start and enable the CUPS service"
    echo "  3. Create a virtual PDF printer for testing"
    echo "  4. Understand CUPS web interface access"
    echo "  5. Print a test page using command line tools"
    echo
    echo "Detected distribution: $DISTRO"
    echo

    print_info "Challenge started!"
    print_info "Run: $0 --check  to verify your setup"
    print_info "Run: $0 --hint   to get a hint"
}

# Provide hints
give_hint() {
    local hint_num="${1:-1}"
    ((HINTS_USED++)) || true

    print_header "Hint #$hint_num"

    case "$hint_num" in
        1)
            echo "Installing CUPS:"
            case "$DISTRO" in
                fedora)
                    echo "  dnf install cups cups-pdf"
                    ;;
                debian)
                    echo "  apt install cups cups-pdf"
                    ;;
            esac
            ;;
        2)
            echo "Starting and enabling CUPS:"
            echo "  systemctl start cups"
            echo "  systemctl enable cups"
            echo "  systemctl status cups"
            ;;
        3)
            echo "CUPS configuration files:"
            echo "  Main config: /etc/cups/cupsd.conf"
            echo "  Printers:    /etc/cups/printers.conf"
            echo "  PPD files:   /etc/cups/ppd/"
            echo
            echo "CUPS web interface:"
            echo "  URL: http://localhost:631"
            echo "  Admin: http://localhost:631/admin"
            ;;
        4)
            echo "Command-line printer management:"
            echo
            echo "  lpstat -p         # List printers"
            echo "  lpstat -d         # Show default printer"
            echo "  lpadmin           # Add/modify printers"
            echo "  lpinfo -v         # List available devices"
            echo "  lpinfo -m         # List available drivers"
            ;;
        5)
            echo "Creating a virtual PDF printer:"
            echo
            echo "  # If cups-pdf is installed, a PDF printer may auto-appear"
            echo "  lpstat -p"
            echo
            echo "  # Or create one manually:"
            echo "  lpadmin -p ${VIRTUAL_PRINTER} \\"
            echo "    -E \\"
            echo "    -v file:///dev/null \\"
            echo "    -m drv:///sample.drv/generic.ppd"
            ;;
        6)
            echo "Printing from command line:"
            echo
            echo "  # Print a file"
            echo "  lp -d printer-name /path/to/file"
            echo
            echo "  # Print with options"
            echo "  lp -d printer-name -n 2 file.pdf  # 2 copies"
            echo
            echo "  # Print test page"
            echo "  lp -d printer-name /usr/share/cups/data/testprint"
            echo
            echo "  # Check print queue"
            echo "  lpq"
            echo "  lpstat -o"
            ;;
        *)
            print_warn "No more hints available"
            ;;
    esac

    echo
    print_warn "Hints used: $HINTS_USED"
}

# Check the challenge
check_challenge() {
    print_header "Checking Print Server Setup"

    local passed=0
    local total=0

    # Check 1: CUPS installed
    ((total++)) || true
    if command -v cupsd &>/dev/null; then
        print_pass "CUPS is installed"
        ((passed++)) || true
    else
        print_fail "CUPS is not installed"
        print_info "Install with: dnf install cups (or apt install cups)"
    fi

    # Check 2: CUPS running
    ((total++)) || true
    if systemctl is-active --quiet cups 2>/dev/null; then
        print_pass "CUPS is running"
        ((passed++)) || true
    else
        print_fail "CUPS is not running"
        print_info "Start with: systemctl start cups"
    fi

    # Check 3: CUPS enabled
    ((total++)) || true
    if systemctl is-enabled --quiet cups 2>/dev/null; then
        print_pass "CUPS is enabled for automatic start"
        ((passed++)) || true
    else
        print_fail "CUPS is not enabled"
        print_info "Enable with: systemctl enable cups"
    fi

    # Check 4: CUPS listening on 631
    ((total++)) || true
    if ss -tlnp | grep -q ':631 '; then
        print_pass "CUPS listening on port 631"
        ((passed++)) || true
    else
        print_fail "CUPS not listening on port 631"
    fi

    # Check 5: At least one printer configured
    ((total++)) || true
    local printer_count
    printer_count=$(lpstat -p 2>/dev/null | wc -l)
    if [[ "$printer_count" -gt 0 ]]; then
        print_pass "Printer(s) configured: $printer_count"
        ((passed++)) || true
        echo "  Printers:"
        lpstat -p 2>/dev/null | sed 's/^/    /'
    else
        print_fail "No printers configured"
        print_info "Add a virtual printer with lpadmin"
    fi

    # Check 6: lp command available
    ((total++)) || true
    if command -v lp &>/dev/null; then
        print_pass "lp command available"
        ((passed++)) || true
    else
        print_fail "lp command not found"
    fi

    # Check 7: lpstat command works
    ((total++)) || true
    if lpstat -r 2>/dev/null | grep -q "running"; then
        print_pass "CUPS scheduler is running"
        ((passed++)) || true
    else
        print_warn "Cannot confirm CUPS scheduler status"
    fi

    # Calculate score
    echo
    print_header "Results"

    local base_score=$((passed * 100 / total))
    local hint_penalty=$((HINTS_USED * 5))
    local final_score=$((base_score - hint_penalty))
    [[ $final_score -lt 0 ]] && final_score=0

    echo "Checks passed: $passed/$total"
    echo "Hints used: $HINTS_USED"
    echo "Final score: $final_score%"
    echo

    if [[ $passed -eq $total ]]; then
        print_pass "CHALLENGE COMPLETE!"
        echo
        echo "You've successfully configured a print server."
        echo
        echo "Key files for LPIC-1:"
        echo "  /etc/cups/cupsd.conf    - CUPS daemon config"
        echo "  /etc/cups/printers.conf - Printer definitions"
        echo "  /var/spool/cups/        - Print job spool"
        echo "  /var/log/cups/          - CUPS logs"
        echo
        echo "Key commands:"
        echo "  lp, lpr      - Print files"
        echo "  lpq, lpstat  - Check print queue"
        echo "  lprm         - Remove print jobs"
        echo "  lpadmin      - Administer printers"
        echo "  cupsctl      - Configure CUPS"
    else
        print_warn "Keep working on it!"
    fi
}

# Cleanup
cleanup() {
    print_header "Cleanup"

    # Remove virtual printer if exists
    if lpstat -p "$VIRTUAL_PRINTER" &>/dev/null; then
        print_info "Removing virtual printer..."
        lpadmin -x "$VIRTUAL_PRINTER" 2>/dev/null || true
    fi

    print_info "Stopping CUPS..."
    systemctl stop cups 2>/dev/null || true

    print_info "Disabling CUPS..."
    systemctl disable cups 2>/dev/null || true

    print_pass "Cleanup complete"
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Build Scenario: Print Server Setup

Usage: setup-print-server.sh <action>

Actions:
  --start      Begin the challenge
  --check      Verify your setup
  --hint [N]   Get hint #N
  --cleanup    Remove virtual printer and stop CUPS

LPIC-1 Objective 108.4 Coverage:
  - Install and configure CUPS
  - Manage printers with lpadmin
  - Print with lp and lpr
  - Check queues with lpq and lpstat
  - Remove jobs with lprm
  - Access CUPS web interface

Examples:
  sudo ./setup-print-server.sh --start
  sudo ./setup-print-server.sh --hint 1
  sudo ./setup-print-server.sh --check
EOF
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 0
    fi

    local action="$1"
    shift 2>/dev/null || true

    case "$action" in
        --start|-s)
            check_root "$@"
            start_challenge
            ;;
        --check|-c)
            check_root "$@"
            check_challenge
            ;;
        --hint|-h)
            give_hint "${1:-$((HINTS_USED + 1))}"
            ;;
        --cleanup)
            check_root "$@"
            cleanup
            ;;
        --help)
            usage
            ;;
        *)
            print_fail "Unknown action: $action"
            usage
            exit 1
            ;;
    esac
}

main "$@"
