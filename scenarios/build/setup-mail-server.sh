#!/bin/bash
# LPIC-1 Build Scenario: Mail Transfer Agent Setup
# Guides through basic Postfix configuration
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
    print_header "Mail Transfer Agent (MTA) Setup Challenge"

    echo "Your mission: Set up a local mail system using Postfix"
    echo
    echo "LPIC-1 Objective 108.3: MTA Basics"
    echo "This covers configuring a local MTA for system mail delivery."
    echo
    echo "Requirements:"
    echo "  1. Install Postfix MTA"
    echo "  2. Configure for local-only mail delivery"
    echo "  3. Set the system hostname in Postfix"
    echo "  4. Ensure the service starts automatically"
    echo "  5. Test sending local mail"
    echo
    echo "Detected distribution: $DISTRO"
    echo

    print_warn "This challenge configures Postfix for LOCAL mail only."
    print_warn "It will NOT send or receive internet email."
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
            echo "Installing Postfix:"
            case "$DISTRO" in
                fedora)
                    echo "  dnf install postfix mailx"
                    ;;
                debian)
                    echo "  apt install postfix bsd-mailx"
                    echo ""
                    echo "  During install, select 'Local only' configuration"
                    ;;
            esac
            ;;
        2)
            echo "Starting and enabling Postfix:"
            echo "  systemctl start postfix"
            echo "  systemctl enable postfix"
            echo "  systemctl status postfix"
            ;;
        3)
            echo "Postfix configuration files:"
            echo "  Main config: /etc/postfix/main.cf"
            echo
            echo "Key settings for local-only delivery:"
            echo "  inet_interfaces = loopback-only"
            echo "  mydestination = \$myhostname, localhost.\$mydomain, localhost"
            ;;
        4)
            echo "Testing local mail:"
            echo
            echo "  # Send a test email"
            echo "  echo 'Test message' | mail -s 'Test' root"
            echo
            echo "  # Check the mail queue"
            echo "  mailq"
            echo
            echo "  # Read mail (as root)"
            echo "  mail"
            ;;
        5)
            echo "Checking Postfix configuration:"
            echo "  postfix check      # Check for errors"
            echo "  postconf -n        # Show non-default settings"
            echo "  postconf mydomain  # Show specific setting"
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
    print_header "Checking MTA Setup"

    local passed=0
    local total=0

    # Check 1: Postfix installed
    ((total++)) || true
    if command -v postfix &>/dev/null; then
        print_pass "Postfix is installed"
        ((passed++)) || true
    else
        print_fail "Postfix is not installed"
        print_info "Install with: dnf install postfix (or apt install postfix)"
    fi

    # Check 2: Postfix running
    ((total++)) || true
    if systemctl is-active --quiet postfix 2>/dev/null; then
        print_pass "Postfix is running"
        ((passed++)) || true
    else
        print_fail "Postfix is not running"
        print_info "Start with: systemctl start postfix"
    fi

    # Check 3: Postfix enabled
    ((total++)) || true
    if systemctl is-enabled --quiet postfix 2>/dev/null; then
        print_pass "Postfix is enabled for automatic start"
        ((passed++)) || true
    else
        print_fail "Postfix is not enabled"
        print_info "Enable with: systemctl enable postfix"
    fi

    # Check 4: Port 25 listening on localhost
    ((total++)) || true
    if ss -tlnp | grep -q ':25 .*127'; then
        print_pass "SMTP listening on localhost:25"
        ((passed++)) || true
    elif ss -tlnp | grep -q ':25 '; then
        print_warn "SMTP listening but may be on all interfaces"
        print_info "For local-only, set: inet_interfaces = loopback-only"
    else
        print_fail "SMTP (port 25) is not listening"
    fi

    # Check 5: Mail command available
    ((total++)) || true
    if command -v mail &>/dev/null; then
        print_pass "mail command is available"
        ((passed++)) || true
    else
        print_fail "mail command not found"
        print_info "Install: mailx (Fedora) or bsd-mailx (Debian)"
    fi

    # Check 6: Configuration valid
    ((total++)) || true
    if postfix check 2>/dev/null; then
        print_pass "Postfix configuration is valid"
        ((passed++)) || true
    else
        print_fail "Postfix configuration has errors"
        print_info "Run: postfix check (to see errors)"
    fi

    # Check 7: Can send local mail
    ((total++)) || true
    if echo "LPIC-1 MTA test at $(date)" | mail -s "LPIC-1 Test" root 2>/dev/null; then
        # Check if it was queued or delivered
        sleep 1
        if [[ $(mailq 2>/dev/null | wc -l) -le 2 ]]; then
            print_pass "Can send local mail"
            ((passed++)) || true
        else
            print_warn "Mail sent but may be queued"
            print_info "Check: mailq"
        fi
    else
        print_fail "Failed to send local mail"
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
        echo "You've successfully configured a local MTA."
        echo
        echo "Key files to remember:"
        echo "  /etc/postfix/main.cf    - Main configuration"
        echo "  /var/spool/mail/        - User mailboxes"
        echo "  /var/log/maillog        - Mail logs (Fedora)"
        echo "  /var/log/mail.log       - Mail logs (Debian)"
        echo
        echo "Key commands:"
        echo "  mailq      - Show mail queue"
        echo "  postqueue  - Manage the queue"
        echo "  postconf   - View/set configuration"
    else
        print_warn "Keep working on it!"
    fi
}

# Cleanup
cleanup() {
    print_header "Cleanup"

    print_info "Stopping Postfix..."
    systemctl stop postfix 2>/dev/null || true

    print_info "Disabling Postfix..."
    systemctl disable postfix 2>/dev/null || true

    print_pass "Cleanup complete"
    print_info "Postfix remains installed but is stopped and disabled."
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Build Scenario: Mail Transfer Agent Setup

Usage: setup-mail-server.sh <action>

Actions:
  --start      Begin the challenge
  --check      Verify your setup
  --hint [N]   Get hint #N
  --cleanup    Stop and disable Postfix

LPIC-1 Objective 108.3 Coverage:
  - Install Postfix MTA
  - Configure for local mail delivery
  - Use mail command to send/read mail
  - Check mail queue with mailq
  - Understand /etc/postfix/main.cf

Note: This challenge configures LOCAL mail only.
      It does not enable internet email.

Examples:
  sudo ./setup-mail-server.sh --start
  sudo ./setup-mail-server.sh --hint 1
  sudo ./setup-mail-server.sh --check
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
