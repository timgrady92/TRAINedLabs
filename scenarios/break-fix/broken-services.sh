#!/bin/bash
# LPIC-1 Break/Fix Scenario: Broken Services
# Creates systemd service problems for troubleshooting practice
# MUST be run as root

set -euo pipefail

# Cleanup trap for interrupted operations
cleanup_on_exit() {
    if [[ -n "${CREATING_SERVICE:-}" ]]; then
        echo
        echo "Interrupted! Cleaning up partial service files..."
        rm -f "${PRACTICE_UNIT_DIR:-/etc/systemd/system}/lpic1-practice-"*.service 2>/dev/null || true
        rm -f "${PRACTICE_SCRIPT_DIR:-/opt/lpic1-practice/scripts}/lpic1-"*.sh 2>/dev/null || true
        systemctl daemon-reload 2>/dev/null || true
    fi
}
trap cleanup_on_exit INT TERM

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

# Configuration
SNAPSHOT_DIR="/opt/LPIC-1/data/snapshots"
SCENARIO_NAME="broken-services"
PRACTICE_UNIT_DIR="/etc/systemd/system"
PRACTICE_SCRIPT_DIR="/opt/lpic1-practice/scripts"

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_fail "This script must be run as root"
        echo "Use: sudo $0 $*"
        exit 1
    fi
}

# Available scenarios
declare -A SCENARIOS
SCENARIOS["wrong-path"]="Service references non-existent executable"
SCENARIOS["missing-deps"]="Service has unmet dependency"
SCENARIOS["bad-user"]="Service configured to run as non-existent user"
SCENARIOS["type-mismatch"]="Service type doesn't match process behavior"
SCENARIOS["restart-loop"]="Service keeps restarting (exit code issue)"

# List scenarios
list_scenarios() {
    print_header "Available Service Scenarios"

    for id in "${!SCENARIOS[@]}"; do
        echo "  $id - ${SCENARIOS[$id]}"
    done

    echo
    print_info "These scenarios create practice systemd units."
    print_info "Original system services are not modified."
}

# Create snapshot
create_snapshot() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    mkdir -p "$snapshot_path"

    # List practice units for later cleanup
    echo "" > "$snapshot_path/created-units.txt"

    print_pass "Snapshot created"
}

# Cleanup scenario
cleanup_scenario() {
    local scenario="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${SCENARIO_NAME}-${scenario}"

    print_info "Cleaning up scenario: $scenario"

    # Remove practice service units
    rm -f "${PRACTICE_UNIT_DIR}/lpic1-practice-"*.service 2>/dev/null || true

    # Remove practice scripts
    rm -f "${PRACTICE_SCRIPT_DIR}/lpic1-"*.sh 2>/dev/null || true

    # Reload systemd
    systemctl daemon-reload

    print_pass "Cleanup complete"
}

# Start scenario
start_scenario() {
    local scenario="$1"

    if [[ -z "${SCENARIOS[$scenario]:-}" ]]; then
        print_fail "Unknown scenario: $scenario"
        list_scenarios
        exit 1
    fi

    print_header "Starting Scenario: $scenario"
    echo "${SCENARIOS[$scenario]}"
    echo

    # Ensure directories exist
    mkdir -p "$PRACTICE_SCRIPT_DIR"

    create_snapshot "$scenario"

    case "$scenario" in
        wrong-path)
            start_wrong_path
            ;;
        missing-deps)
            start_missing_deps
            ;;
        bad-user)
            start_bad_user
            ;;
        type-mismatch)
            start_type_mismatch
            ;;
        restart-loop)
            start_restart_loop
            ;;
    esac

    systemctl daemon-reload

    echo
    print_header "Scenario Active"
    print_info "A practice service has been created."
    print_info "Your task: Diagnose why the service fails and fix it."
    echo
    print_warn "When done, run: $0 --check $scenario"
    print_warn "To cleanup, run: $0 --restore $scenario"
}

# Scenario implementations
start_wrong_path() {
    local unit_name="lpic1-practice-webapp"
    local unit_file="${PRACTICE_UNIT_DIR}/${unit_name}.service"

    # Create a service pointing to non-existent path
    cat > "$unit_file" << 'EOF'
[Unit]
Description=LPIC-1 Practice - Web Application
After=network.target

[Service]
Type=simple
ExecStart=/opt/webapp/bin/start-server.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    print_pass "Created: $unit_file"
    echo
    echo "Problem: The service references an executable that doesn't exist."
    echo
    echo "Try these commands:"
    echo "  systemctl start $unit_name"
    echo "  systemctl status $unit_name"
    echo "  journalctl -u $unit_name"
    echo
    echo "Hint: What does the error message tell you?"
    echo "Hint: Where is the executable supposed to be?"
}

start_missing_deps() {
    local unit_name="lpic1-practice-app"
    local unit_file="${PRACTICE_UNIT_DIR}/${unit_name}.service"

    # Create a valid script
    cat > "${PRACTICE_SCRIPT_DIR}/lpic1-app.sh" << 'SCRIPT'
#!/bin/bash
echo "Application starting..."
while true; do
    sleep 60
done
SCRIPT
    chmod +x "${PRACTICE_SCRIPT_DIR}/lpic1-app.sh"

    # Create service with non-existent dependency
    cat > "$unit_file" << EOF
[Unit]
Description=LPIC-1 Practice - Application with Dependencies
After=lpic1-nonexistent-database.service
Requires=lpic1-nonexistent-database.service

[Service]
Type=simple
ExecStart=${PRACTICE_SCRIPT_DIR}/lpic1-app.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    print_pass "Created: $unit_file"
    echo
    echo "Problem: The service depends on another service that doesn't exist."
    echo
    echo "Try these commands:"
    echo "  systemctl start $unit_name"
    echo "  systemctl status $unit_name"
    echo "  systemctl list-dependencies $unit_name"
    echo
    echo "Hint: Check the After= and Requires= directives."
    echo "Hint: What's the difference between Requires= and Wants=?"
}

start_bad_user() {
    local unit_name="lpic1-practice-worker"
    local unit_file="${PRACTICE_UNIT_DIR}/${unit_name}.service"

    # Create a valid script
    cat > "${PRACTICE_SCRIPT_DIR}/lpic1-worker.sh" << 'SCRIPT'
#!/bin/bash
echo "Worker process starting as user: $(whoami)"
while true; do
    echo "Working..."
    sleep 60
done
SCRIPT
    chmod +x "${PRACTICE_SCRIPT_DIR}/lpic1-worker.sh"

    # Create service with non-existent user
    cat > "$unit_file" << EOF
[Unit]
Description=LPIC-1 Practice - Worker Process

[Service]
Type=simple
User=nonexistent_app_user
Group=nonexistent_app_group
ExecStart=${PRACTICE_SCRIPT_DIR}/lpic1-worker.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    print_pass "Created: $unit_file"
    echo
    echo "Problem: The service is configured to run as a user that doesn't exist."
    echo
    echo "Try these commands:"
    echo "  systemctl start $unit_name"
    echo "  systemctl status $unit_name"
    echo "  journalctl -u $unit_name"
    echo
    echo "Hint: Check the User= and Group= directives."
    echo "Hint: How do you create system users?"
}

start_type_mismatch() {
    local unit_name="lpic1-practice-daemon"
    local unit_file="${PRACTICE_UNIT_DIR}/${unit_name}.service"

    # Create a forking daemon script
    cat > "${PRACTICE_SCRIPT_DIR}/lpic1-daemon.sh" << 'SCRIPT'
#!/bin/bash
# This script forks to background
echo "Daemon starting..."
(
    while true; do
        echo "Daemon running in background"
        sleep 60
    done
) &
echo "Daemon forked with PID: $!"
# Parent exits immediately
exit 0
SCRIPT
    chmod +x "${PRACTICE_SCRIPT_DIR}/lpic1-daemon.sh"

    # Create service with wrong type (should be forking, but set to simple)
    cat > "$unit_file" << EOF
[Unit]
Description=LPIC-1 Practice - Daemon Process

[Service]
Type=simple
ExecStart=${PRACTICE_SCRIPT_DIR}/lpic1-daemon.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    print_pass "Created: $unit_file"
    echo
    echo "Problem: The service type doesn't match how the process behaves."
    echo "The script forks to background, but the service type is 'simple'."
    echo
    echo "Try these commands:"
    echo "  systemctl start $unit_name"
    echo "  systemctl status $unit_name"
    echo "  journalctl -u $unit_name -f"
    echo
    echo "Hint: What happens when a 'simple' service's main process exits?"
    echo "Hint: What's the difference between Type=simple and Type=forking?"
}

start_restart_loop() {
    local unit_name="lpic1-practice-flaky"
    local unit_file="${PRACTICE_UNIT_DIR}/${unit_name}.service"

    # Create a script that always fails
    cat > "${PRACTICE_SCRIPT_DIR}/lpic1-flaky.sh" << 'SCRIPT'
#!/bin/bash
echo "Service starting... checking requirements..."
# Simulate a startup check that always fails
if [[ ! -f /etc/lpic1-practice/app.conf ]]; then
    echo "ERROR: Configuration file not found!"
    exit 1
fi
echo "Configuration loaded, running..."
while true; do
    sleep 60
done
SCRIPT
    chmod +x "${PRACTICE_SCRIPT_DIR}/lpic1-flaky.sh"

    # Create service with aggressive restart
    cat > "$unit_file" << EOF
[Unit]
Description=LPIC-1 Practice - Flaky Service

[Service]
Type=simple
ExecStart=${PRACTICE_SCRIPT_DIR}/lpic1-flaky.sh
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

    print_pass "Created: $unit_file"
    echo
    echo "Problem: The service keeps failing and restarting."
    echo
    echo "Try these commands:"
    echo "  systemctl start $unit_name"
    echo "  systemctl status $unit_name"
    echo "  journalctl -u $unit_name -f"
    echo
    echo "Hint: Why is the service failing?"
    echo "Hint: What file does it expect to exist?"
    echo "Hint: How can you stop a service that keeps restarting?"
}

# Check if scenario is fixed
check_scenario() {
    local scenario="$1"
    local fixed=true

    print_header "Checking Scenario: $scenario"

    case "$scenario" in
        wrong-path)
            local unit_name="lpic1-practice-webapp"
            if systemctl is-active --quiet "$unit_name" 2>/dev/null; then
                print_pass "Service is running"
            elif systemctl start "$unit_name" 2>/dev/null && systemctl is-active --quiet "$unit_name"; then
                print_pass "Service started successfully"
            else
                print_fail "Service is not running"
                print_info "Check: systemctl status $unit_name"
                fixed=false
            fi
            ;;

        missing-deps)
            local unit_name="lpic1-practice-app"
            if systemctl is-active --quiet "$unit_name" 2>/dev/null; then
                print_pass "Service is running"
            elif systemctl start "$unit_name" 2>/dev/null && systemctl is-active --quiet "$unit_name"; then
                print_pass "Service started successfully"
            else
                print_fail "Service is not running"
                fixed=false
            fi
            ;;

        bad-user)
            local unit_name="lpic1-practice-worker"
            if systemctl is-active --quiet "$unit_name" 2>/dev/null; then
                print_pass "Service is running"
            elif systemctl start "$unit_name" 2>/dev/null && systemctl is-active --quiet "$unit_name"; then
                print_pass "Service started successfully"
            else
                print_fail "Service is not running"
                fixed=false
            fi
            ;;

        type-mismatch)
            local unit_name="lpic1-practice-daemon"
            if systemctl is-active --quiet "$unit_name" 2>/dev/null; then
                print_pass "Service is running (active)"
                # Check if it stays running for a few seconds
                sleep 3
                if systemctl is-active --quiet "$unit_name"; then
                    print_pass "Service is stable"
                else
                    print_fail "Service stopped unexpectedly"
                    fixed=false
                fi
            else
                print_fail "Service is not running"
                fixed=false
            fi
            ;;

        restart-loop)
            local unit_name="lpic1-practice-flaky"
            if systemctl is-active --quiet "$unit_name" 2>/dev/null; then
                print_pass "Service is running"
            elif systemctl start "$unit_name" 2>/dev/null && sleep 2 && systemctl is-active --quiet "$unit_name"; then
                print_pass "Service started and staying up"
            else
                print_fail "Service is not running"
                fixed=false
            fi
            ;;

        *)
            print_fail "Unknown scenario: $scenario"
            exit 1
            ;;
    esac

    echo
    if [[ "$fixed" == "true" ]]; then
        print_pass "Scenario $scenario: FIXED!"
        print_info "The service issue has been resolved."
    else
        print_fail "Scenario $scenario: Not yet fixed"
        print_info "Keep investigating with journalctl and systemctl status."
    fi
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Break/Fix Scenario: Broken Services

Usage: broken-services.sh <action> [scenario]

Actions:
  --list              List available scenarios
  --start <scenario>  Start a scenario
  --check <scenario>  Check if scenario is fixed
  --restore <scenario> Cleanup and restore

Scenarios:
  wrong-path      Service references non-existent executable
  missing-deps    Service has unmet dependency
  bad-user        Service runs as non-existent user
  type-mismatch   Service type doesn't match behavior
  restart-loop    Service keeps failing and restarting

Examples:
  sudo ./broken-services.sh --list
  sudo ./broken-services.sh --start wrong-path
  sudo ./broken-services.sh --check wrong-path
  sudo ./broken-services.sh --restore wrong-path

Note: Practice services are created in /etc/systemd/system/
      with names starting with "lpic1-practice-"
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
        --check|-c)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                exit 1
            fi
            check_scenario "$scenario"
            ;;
        --restore|-r)
            check_root "$@"
            if [[ -z "$scenario" ]]; then
                print_fail "Please specify a scenario"
                exit 1
            fi
            cleanup_scenario "$scenario"
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
