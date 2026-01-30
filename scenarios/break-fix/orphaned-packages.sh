#!/bin/bash
# LPIC-1 Break/Fix Scenario: Orphaned Packages
# Simulates package dependency issues for troubleshooting practice
# MUST be run as root

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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
print_header() { echo -e "\n${BOLD}═══ $1 ═══${NC}\n"; }

# Detect package manager
detect_pkg_manager() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v yum &>/dev/null; then
        echo "yum"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_fail "This script must be run as root"
        echo "Use: sudo $0 $*"
        exit 1
    fi
}

# Available scenarios (educational - these are demonstrations, not actual breakage)
declare -A SCENARIOS
SCENARIOS["show-orphans"]="Find and display orphaned packages"
SCENARIOS["show-deps"]="Demonstrate package dependency inspection"
SCENARIOS["broken-deps"]="Simulate checking for broken dependencies"
SCENARIOS["autoremove"]="Practice with autoremove functionality"
SCENARIOS["cache-issues"]="Demonstrate package cache problems"

# List scenarios
list_scenarios() {
    print_header "Package Management Scenarios"
    print_info "Detected package manager: $PKG_MANAGER"
    echo

    for id in "${!SCENARIOS[@]}"; do
        echo "  $id - ${SCENARIOS[$id]}"
    done

    echo
    print_warn "These are EDUCATIONAL scenarios - they demonstrate"
    print_warn "how to diagnose package issues without breaking your system."
}

# Start scenario
start_scenario() {
    local scenario="$1"

    if [[ -z "${SCENARIOS[$scenario]:-}" ]]; then
        print_fail "Unknown scenario: $scenario"
        list_scenarios
        exit 1
    fi

    print_header "Scenario: $scenario"
    echo "${SCENARIOS[$scenario]}"
    echo

    case "$scenario" in
        show-orphans)
            demo_orphans
            ;;
        show-deps)
            demo_dependencies
            ;;
        broken-deps)
            demo_broken_deps
            ;;
        autoremove)
            demo_autoremove
            ;;
        cache-issues)
            demo_cache_issues
            ;;
    esac
}

# Demonstration: Find orphaned packages
demo_orphans() {
    print_header "Finding Orphaned Packages"

    echo "Orphaned packages are packages that were installed as dependencies"
    echo "but are no longer required by any other installed package."
    echo

    case "$PKG_MANAGER" in
        dnf|yum)
            print_info "On Fedora/RHEL systems:"
            echo
            echo "# List packages that can be autoremoved"
            echo "dnf autoremove --assumeno"
            echo
            echo "# List leaf packages (not required by anything)"
            echo "dnf leaves"
            echo
            echo "Running actual check..."
            echo
            dnf autoremove --assumeno 2>/dev/null | head -30 || print_warn "No packages to autoremove"
            ;;

        apt)
            print_info "On Debian/Ubuntu systems:"
            echo
            echo "# Show packages that can be autoremoved"
            echo "apt autoremove --dry-run"
            echo
            echo "# Find orphaned packages with deborphan"
            echo "deborphan  # (if installed)"
            echo
            echo "Running actual check..."
            echo
            apt autoremove --dry-run 2>/dev/null | head -30 || print_warn "No packages to autoremove"
            ;;

        *)
            print_fail "Unsupported package manager"
            exit 1
            ;;
    esac

    echo
    print_header "Practice Tasks"
    echo "1. Identify which packages (if any) could be removed"
    echo "2. Understand why they are considered orphaned"
    echo "3. Research each package before removing to ensure it's not manually installed"
}

# Demonstration: Package dependencies
demo_dependencies() {
    print_header "Understanding Package Dependencies"

    local sample_pkg
    case "$PKG_MANAGER" in
        dnf|yum)
            sample_pkg="openssh-server"
            ;;
        apt)
            sample_pkg="openssh-server"
            ;;
        *)
            sample_pkg="bash"
            ;;
    esac

    echo "Let's examine dependencies using: $sample_pkg"
    echo

    case "$PKG_MANAGER" in
        dnf|yum)
            print_info "Commands for dependency inspection:"
            echo
            echo "# What does this package require?"
            echo "dnf repoquery --requires $sample_pkg"
            echo
            echo "# What requires this package?"
            echo "dnf repoquery --whatrequires $sample_pkg"
            echo
            echo "# Show dependency tree"
            echo "dnf repoquery --requires --resolve $sample_pkg"
            echo
            print_info "Actual dependencies for $sample_pkg:"
            echo
            dnf repoquery --requires "$sample_pkg" 2>/dev/null | head -15
            echo "..."
            ;;

        apt)
            print_info "Commands for dependency inspection:"
            echo
            echo "# What does this package require?"
            echo "apt-cache depends $sample_pkg"
            echo
            echo "# What requires this package?"
            echo "apt-cache rdepends $sample_pkg"
            echo
            echo "# Show package info including dependencies"
            echo "apt show $sample_pkg"
            echo
            print_info "Actual dependencies for $sample_pkg:"
            echo
            apt-cache depends "$sample_pkg" 2>/dev/null | head -15
            ;;

        *)
            print_fail "Unsupported package manager"
            exit 1
            ;;
    esac

    echo
    print_header "Practice Tasks"
    echo "1. Find dependencies for 3 different packages"
    echo "2. Identify shared dependencies between packages"
    echo "3. Find which packages depend on 'bash'"
}

# Demonstration: Check for broken dependencies
demo_broken_deps() {
    print_header "Checking for Broken Dependencies"

    echo "Broken dependencies occur when a package requires another package"
    echo "that is not installed or has been corrupted."
    echo

    case "$PKG_MANAGER" in
        dnf|yum)
            print_info "On Fedora/RHEL systems:"
            echo
            echo "# Check for problems"
            echo "dnf check"
            echo
            echo "# Verify installed packages"
            echo "rpm -Va  # (slow, checks all files)"
            echo
            echo "Running dnf check..."
            echo
            if dnf check 2>&1 | head -20; then
                print_pass "No broken dependencies found"
            else
                print_warn "Issues found (see output above)"
            fi
            ;;

        apt)
            print_info "On Debian/Ubuntu systems:"
            echo
            echo "# Check for broken packages"
            echo "apt --fix-broken install --dry-run"
            echo
            echo "# Check package integrity"
            echo "dpkg --audit"
            echo
            echo "# Configure pending packages"
            echo "dpkg --configure -a"
            echo
            echo "Running apt check..."
            echo
            if apt --fix-broken install --dry-run 2>&1 | grep -q "0 upgraded"; then
                print_pass "No broken packages found"
            else
                apt --fix-broken install --dry-run 2>&1 | head -20
            fi
            ;;

        *)
            print_fail "Unsupported package manager"
            exit 1
            ;;
    esac

    echo
    print_header "Common Causes of Broken Dependencies"
    echo "1. Interrupted package installation"
    echo "2. Manually deleting package files"
    echo "3. Adding incompatible repositories"
    echo "4. Forced package installation (--nodeps)"
    echo "5. Downgrading packages incorrectly"
}

# Demonstration: Autoremove functionality
demo_autoremove() {
    print_header "Package Autoremove Functionality"

    echo "Autoremove cleans up packages that were auto-installed as dependencies"
    echo "but are no longer needed."
    echo

    case "$PKG_MANAGER" in
        dnf|yum)
            print_info "On Fedora/RHEL systems:"
            echo
            echo "# Preview what would be removed"
            echo "dnf autoremove --assumeno"
            echo
            echo "# Actually remove orphaned packages"
            echo "dnf autoremove  # (requires confirmation)"
            echo
            echo "Current status:"
            echo
            dnf autoremove --assumeno 2>/dev/null || echo "(No packages to remove)"
            ;;

        apt)
            print_info "On Debian/Ubuntu systems:"
            echo
            echo "# Preview what would be removed"
            echo "apt autoremove --dry-run"
            echo
            echo "# Actually remove orphaned packages"
            echo "apt autoremove  # (requires confirmation)"
            echo
            echo "# Also clean package cache"
            echo "apt autoclean"
            echo
            echo "Current status:"
            echo
            apt autoremove --dry-run 2>/dev/null | head -20 || echo "(No packages to remove)"
            ;;

        *)
            print_fail "Unsupported package manager"
            exit 1
            ;;
    esac

    echo
    print_header "Practice Tasks"
    echo "1. Run the autoremove command in preview mode"
    echo "2. Research any packages that would be removed"
    echo "3. Understand why each package is considered orphaned"
}

# Demonstration: Cache issues
demo_cache_issues() {
    print_header "Package Cache Management"

    echo "Package manager caches can become outdated or corrupted."
    echo "This can cause installation failures or incorrect package information."
    echo

    case "$PKG_MANAGER" in
        dnf|yum)
            print_info "On Fedora/RHEL systems:"
            echo
            echo "# Clear all cached data"
            echo "dnf clean all"
            echo
            echo "# Rebuild cache"
            echo "dnf makecache"
            echo
            echo "# Check cache status"
            echo "dnf repolist -v"
            echo
            echo "Current cache info:"
            dnf repolist 2>/dev/null
            echo
            echo "Cache location: /var/cache/dnf/"
            du -sh /var/cache/dnf/ 2>/dev/null || true
            ;;

        apt)
            print_info "On Debian/Ubuntu systems:"
            echo
            echo "# Update package lists"
            echo "apt update"
            echo
            echo "# Clean downloaded package files"
            echo "apt clean"
            echo
            echo "# Remove old package versions"
            echo "apt autoclean"
            echo
            echo "Cache location: /var/cache/apt/archives/"
            du -sh /var/cache/apt/archives/ 2>/dev/null || true
            echo
            echo "# View cache age"
            # shellcheck disable=SC2012  # ls used for human-readable display, not parsing
            ls -la /var/lib/apt/lists/ | head -5
            ;;

        *)
            print_fail "Unsupported package manager"
            exit 1
            ;;
    esac

    echo
    print_header "When to Clear Cache"
    echo "1. After adding new repositories"
    echo "2. When getting 'package not found' errors"
    echo "3. When cache is using too much disk space"
    echo "4. After system recovery"
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Break/Fix Scenario: Package Management

Usage: orphaned-packages.sh <action> [scenario]

Actions:
  --list              List available scenarios
  --start <scenario>  Run an educational scenario

Scenarios:
  show-orphans     Find and display orphaned packages
  show-deps        Demonstrate dependency inspection
  broken-deps      Check for broken dependencies
  autoremove       Practice with autoremove functionality
  cache-issues     Demonstrate cache management

Examples:
  sudo ./orphaned-packages.sh --list
  sudo ./orphaned-packages.sh --start show-orphans
  sudo ./orphaned-packages.sh --start broken-deps

Note: These are EDUCATIONAL scenarios that demonstrate
      package management concepts without breaking your system.
EOF
}

# Main
main() {
    if [[ $# -lt 1 ]]; then
        usage
        exit 0
    fi

    local action="$1"
    local scenario="${2:-}"

    case "$action" in
        --list|-l)
            list_scenarios
            ;;
        --start|-s)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                list_scenarios
                exit 1
            fi
            start_scenario "$scenario"
            ;;
        --help|-h)
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
