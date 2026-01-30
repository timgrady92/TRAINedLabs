#!/bin/bash
# LPIC-1 Build Scenario: Web Server Setup
# Guides through setting up Apache or Nginx
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
PRACTICE_DIR="/var/www/lpic1-practice"
HINTS_USED=0

# Detect distro
detect_distro() {
    if [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
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
    print_header "Web Server Setup Challenge"

    echo "Your mission: Set up a functioning web server"
    echo
    echo "Requirements:"
    echo "  1. Install Apache (httpd) or Nginx"
    echo "  2. Configure it to serve files from ${PRACTICE_DIR}"
    echo "  3. Create a custom index.html page"
    echo "  4. Ensure the service starts automatically on boot"
    echo "  5. Configure the firewall to allow HTTP traffic"
    echo
    echo "Detected distribution: $DISTRO"
    echo

    # Create practice directory
    mkdir -p "$PRACTICE_DIR"
    chmod 755 "$PRACTICE_DIR"

    print_info "Challenge started!"
    print_info "Run: $0 --check  to verify your setup"
    print_info "Run: $0 --hint   to get a hint (costs points!)"
}

# Provide hints
give_hint() {
    local hint_num="${1:-1}"
    ((HINTS_USED++)) || true

    print_header "Hint #$hint_num"

    case "$hint_num" in
        1)
            echo "Installing the web server:"
            case "$DISTRO" in
                fedora|rhel)
                    echo "  Apache: dnf install httpd"
                    echo "  Nginx:  dnf install nginx"
                    ;;
                debian)
                    echo "  Apache: apt install apache2"
                    echo "  Nginx:  apt install nginx"
                    ;;
            esac
            ;;
        2)
            echo "Managing the service:"
            echo "  Start:   systemctl start httpd  (or nginx)"
            echo "  Enable:  systemctl enable httpd (or nginx)"
            echo "  Status:  systemctl status httpd (or nginx)"
            ;;
        3)
            echo "Configuring document root:"
            echo
            echo "For Apache, edit the config file:"
            case "$DISTRO" in
                fedora|rhel)
                    echo "  /etc/httpd/conf/httpd.conf"
                    echo "  Or create: /etc/httpd/conf.d/lpic1-practice.conf"
                    ;;
                debian)
                    echo "  /etc/apache2/sites-available/000-default.conf"
                    echo "  Or create a new site configuration"
                    ;;
            esac
            echo
            echo "For Nginx, edit:"
            case "$DISTRO" in
                fedora|rhel)
                    echo "  /etc/nginx/nginx.conf"
                    echo "  Or create: /etc/nginx/conf.d/lpic1-practice.conf"
                    ;;
                debian)
                    echo "  /etc/nginx/sites-available/default"
                    ;;
            esac
            ;;
        4)
            echo "Firewall configuration:"
            case "$DISTRO" in
                fedora|rhel)
                    echo "  firewall-cmd --permanent --add-service=http"
                    echo "  firewall-cmd --reload"
                    ;;
                debian)
                    echo "  ufw allow http"
                    echo "  # Or: ufw allow 80/tcp"
                    ;;
            esac
            ;;
        5)
            echo "Creating the index page:"
            echo
            echo "cat > ${PRACTICE_DIR}/index.html << 'EOF'"
            echo "<!DOCTYPE html>"
            echo "<html>"
            echo "<head><title>LPIC-1 Practice</title></head>"
            echo "<body>"
            echo "<h1>Hello from LPIC-1 Training!</h1>"
            echo "</body>"
            echo "</html>"
            echo "EOF"
            ;;
        *)
            print_warn "No more hints available"
            ;;
    esac

    echo
    print_warn "Hints used: $HINTS_USED (affects score)"
}

# Check the challenge
check_challenge() {
    print_header "Checking Web Server Setup"

    local passed=0
    local total=0
    local web_server=""

    # Detect which web server is installed
    if systemctl is-active --quiet httpd 2>/dev/null; then
        web_server="httpd"
    elif systemctl is-active --quiet apache2 2>/dev/null; then
        web_server="apache2"
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        web_server="nginx"
    fi

    # Check 1: Web server installed and running
    ((total++)) || true
    if [[ -n "$web_server" ]]; then
        print_pass "Web server running: $web_server"
        ((passed++)) || true
    else
        print_fail "No web server running (httpd/apache2/nginx)"
        print_info "Try: systemctl status httpd (or nginx)"
    fi

    # Check 2: Service enabled
    ((total++)) || true
    if [[ -n "$web_server" ]] && systemctl is-enabled --quiet "$web_server" 2>/dev/null; then
        print_pass "Service enabled for automatic start"
        ((passed++)) || true
    else
        print_fail "Service not enabled for automatic start"
        print_info "Try: systemctl enable $web_server"
    fi

    # Check 3: Practice directory exists
    ((total++)) || true
    if [[ -d "$PRACTICE_DIR" ]]; then
        print_pass "Practice directory exists: $PRACTICE_DIR"
        ((passed++)) || true
    else
        print_fail "Practice directory missing: $PRACTICE_DIR"
    fi

    # Check 4: Index file exists
    ((total++)) || true
    if [[ -f "$PRACTICE_DIR/index.html" ]]; then
        print_pass "Index file exists: $PRACTICE_DIR/index.html"
        ((passed++)) || true
    else
        print_fail "Index file missing: $PRACTICE_DIR/index.html"
    fi

    # Check 5: Port 80 is listening
    ((total++)) || true
    if ss -tlnp | grep -q ':80 '; then
        print_pass "Port 80 is listening"
        ((passed++)) || true
    else
        print_fail "Port 80 is not listening"
        print_info "Check if web server is running and configured correctly"
    fi

    # Check 6: Firewall allows HTTP
    ((total++)) || true
    local firewall_ok=false
    if command -v firewall-cmd &>/dev/null; then
        if firewall-cmd --query-service=http &>/dev/null; then
            firewall_ok=true
        fi
    elif command -v ufw &>/dev/null; then
        if ufw status | grep -q "80.*ALLOW"; then
            firewall_ok=true
        fi
    else
        # No firewall detected, assume OK
        firewall_ok=true
    fi

    if [[ "$firewall_ok" == "true" ]]; then
        print_pass "Firewall allows HTTP traffic"
        ((passed++)) || true
    else
        print_fail "Firewall may be blocking HTTP"
        print_info "Allow HTTP in firewall settings"
    fi

    # Check 7: Can fetch the page
    ((total++)) || true
    if command -v curl &>/dev/null; then
        if curl -s http://localhost/ | grep -q -i "html"; then
            print_pass "Web server responds to requests"
            ((passed++)) || true
        else
            print_warn "Web server responds but content may not be correct"
        fi
    elif command -v wget &>/dev/null; then
        if wget -q -O- http://localhost/ | grep -q -i "html"; then
            print_pass "Web server responds to requests"
            ((passed++)) || true
        else
            print_warn "Web server responds but content may not be correct"
        fi
    else
        print_warn "Cannot test (curl/wget not available)"
    fi

    # Calculate score
    echo
    print_header "Results"

    local base_score=$((passed * 100 / total))
    local hint_penalty=$((HINTS_USED * 5))
    local final_score=$((base_score - hint_penalty))
    [[ $final_score -lt 0 ]] && final_score=0

    echo "Checks passed: $passed/$total"
    echo "Hints used: $HINTS_USED (penalty: -$hint_penalty)"
    echo "Final score: $final_score%"
    echo

    if [[ $passed -eq $total ]]; then
        print_pass "CHALLENGE COMPLETE!"
        echo
        echo "Excellent work! You've successfully configured a web server."
        echo
        echo "Additional learning:"
        echo "  - Try adding SSL/TLS with Let's Encrypt"
        echo "  - Configure virtual hosts"
        echo "  - Set up log rotation"
    elif [[ $passed -ge $((total / 2)) ]]; then
        print_warn "Good progress! Keep going."
        echo
        echo "Check the failed items and try again."
        echo "Use --hint for help if stuck."
    else
        print_fail "More work needed."
        echo
        echo "Start with the basics: install and start the web server."
        echo "Use --hint for step-by-step guidance."
    fi
}

# Cleanup
cleanup() {
    print_header "Cleanup"

    print_info "Stopping web servers..."
    systemctl stop httpd 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true

    print_info "Disabling auto-start..."
    systemctl disable httpd 2>/dev/null || true
    systemctl disable apache2 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true

    print_info "Removing practice directory..."
    rm -rf "$PRACTICE_DIR"

    print_pass "Cleanup complete"
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Build Scenario: Web Server Setup

Usage: setup-web-server.sh <action>

Actions:
  --start      Begin the challenge
  --check      Verify your setup
  --hint [N]   Get hint #N (default: next hint)
  --cleanup    Remove all challenge resources

Objectives:
  1. Install Apache or Nginx web server
  2. Configure document root to /var/www/lpic1-practice
  3. Create a custom index.html
  4. Enable service for automatic startup
  5. Configure firewall for HTTP access
  6. Verify web server responds to requests

Scoring:
  Each objective is worth points
  Using hints reduces your final score
  Complete all objectives for 100%

Examples:
  sudo ./setup-web-server.sh --start
  sudo ./setup-web-server.sh --hint
  sudo ./setup-web-server.sh --check
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
