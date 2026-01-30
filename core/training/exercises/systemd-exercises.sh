#!/bin/bash
# LPIC-1 Training - systemd Exercises
# Guided exercises for service management and boot analysis

# Ensure common functions are loaded
if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# Load learning helpers for enhanced feedback
LEARNING_HELPERS="${SCRIPT_DIR}/training/learning-helpers.sh"
[[ -f "$LEARNING_HELPERS" ]] && source "$LEARNING_HELPERS"

# ============================================================================
# Exercise 1: Check service status
# ============================================================================

exercise_systemd_status() {
    print_exercise "systemctl: Check Service Status"

    cat << 'SCENARIO'
SCENARIO:
A user reports SSH connections are failing. Your first step is to check
if the SSH service is running.

WHY THIS MATTERS:
Checking service status is the most common systemd operation.
You'll do this dozens of times daily as a sysadmin.
SCENARIO

    echo
    print_task "Check the status of the sshd (or ssh) service"
    echo -e "${DIM}Tip: Type 'skip' to skip, 'hint' for a hint${NC}"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == "hint" || "$user_cmd" == "h" ]]; then
            ((attempts++))
            user_cmd=""
        fi

        if [[ -n "$user_cmd" ]]; then
            # Check if command structure is correct
            if [[ "$user_cmd" == *"systemctl"* ]] && [[ "$user_cmd" == *"status"* ]] && \
               [[ "$user_cmd" == *"ssh"* || "$user_cmd" == *"sshd"* ]]; then
                # Run the command to show output
                timeout 5 bash -c "$user_cmd" 2>&1 || true
                echo
                print_pass "Correct! This shows service status, state, and recent logs."
                record_exercise_attempt "systemd" "status" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to use systemctl status for the SSH service."
        fi

        if [[ "${LPIC_NO_HINTS:-}" == "1" ]]; then
            echo -e "${DIM}(Hints disabled)${NC}"
        else
            case $attempts in
                1)
                    show_hint 1 "Use systemctl with the 'status' subcommand.
  The service name is usually 'sshd' (Fedora/RHEL) or 'ssh' (Debian/Ubuntu)."
                    ;;
                2)
                    show_hint 2 "Syntax: systemctl status servicename
  Try: systemctl status sshd"
                    ;;
                *)
                    show_solution "systemctl status sshd"
                    echo "On Debian/Ubuntu: systemctl status ssh"
                    echo
                    echo "Status output shows:"
                    echo "  - Loaded: Whether unit file was found"
                    echo "  - Active: Running state (active/inactive)"
                    echo "  - Main PID: Process ID if running"
                    echo "  - Recent logs from journalctl"
                    record_exercise_attempt "systemd" "status" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 2: List running services
# ============================================================================

exercise_systemd_list() {
    print_exercise "systemctl: List Active Services"

    cat << 'SCENARIO'
SCENARIO:
You need to see which services are currently running on the system.
This helps identify what's consuming resources or might be misconfigured.
SCENARIO

    echo
    print_task "List all currently running services"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(timeout 5 bash -c "$user_cmd" 2>&1 | head -20) || true

            # Accept various valid approaches
            if [[ "$user_cmd" == *"systemctl"* ]] && \
               [[ "$user_cmd" == *"list-units"* || "$user_cmd" == *"--type=service"* || "$user_cmd" == *"-t service"* ]]; then
                if [[ "$user_output" == *".service"* ]] || [[ "$user_output" == *"UNIT"* ]]; then
                    echo "$user_output"
                    echo "..."
                    echo
                    print_pass "Correct! Active services listed."
                    record_exercise_attempt "systemd" "list" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Need to list running services with systemctl."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "systemctl can list units with list-units.
  Filter by type using --type=service"
                    ;;
                2)
                    show_hint 2 "Try: systemctl list-units --type=service
  Add --state=running to show only running services"
                    ;;
                *)
                    show_solution "systemctl list-units --type=service"
                    echo "Filter running only: systemctl list-units --type=service --state=running"
                    record_exercise_attempt "systemd" "list" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 3: Check if service is enabled
# ============================================================================

exercise_systemd_enabled() {
    print_exercise "systemctl: Check If Service Starts at Boot"

    cat << 'SCENARIO'
SCENARIO:
After a reboot, users report that a service didn't start automatically.
You need to verify if the service is enabled to start at boot.

EXAM NOTE: "enabled" means it starts at boot. "active" means it's running now.
These are independent states!
SCENARIO

    echo
    print_task "Check if the crond (or cron) service is enabled to start at boot"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            # Check command structure
            if [[ "$user_cmd" == *"systemctl"* ]] && [[ "$user_cmd" == *"is-enabled"* ]] && \
               [[ "$user_cmd" == *"cron"* ]]; then
                local user_output
                user_output=$(timeout 5 bash -c "$user_cmd" 2>&1) || true
                echo "$user_output"
                echo
                print_pass "Correct! is-enabled shows boot-time status."
                echo -e "${DIM}Output: enabled = starts at boot, disabled = manual start only${NC}"
                record_exercise_attempt "systemd" "enabled" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to check enabled status with systemctl."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "systemctl has an 'is-enabled' subcommand.
  It returns 'enabled' or 'disabled'."
                    ;;
                2)
                    show_hint 2 "Syntax: systemctl is-enabled servicename
  The cron service is 'crond' (RHEL) or 'cron' (Debian)"
                    ;;
                *)
                    show_solution "systemctl is-enabled crond"
                    echo "On Debian/Ubuntu: systemctl is-enabled cron"
                    record_exercise_attempt "systemd" "enabled" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 4: View journal logs
# ============================================================================

exercise_systemd_journal() {
    print_exercise "journalctl: View Service Logs"

    cat << 'SCENARIO'
SCENARIO:
A service is failing to start. You need to check its logs to find the error.
journalctl provides access to the systemd journal (centralized logging).

WHY THIS MATTERS:
Traditional /var/log files are being replaced by the journal.
journalctl is now the primary tool for log analysis on systemd systems.
SCENARIO

    echo
    print_task "View the last 20 log entries for the sshd (or ssh) service"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            # Check for journalctl with unit filter and line limit
            if [[ "$user_cmd" == *"journalctl"* ]] && \
               [[ "$user_cmd" == *"-u"* || "$user_cmd" == *"--unit"* ]] && \
               [[ "$user_cmd" == *"ssh"* ]]; then
                local user_output
                user_output=$(timeout 5 bash -c "$user_cmd" 2>&1 | head -5) || true
                echo "$user_output"
                if [[ -n "$user_output" ]]; then
                    echo "..."
                fi
                echo
                print_pass "Correct! Service-specific logs displayed."
                record_exercise_attempt "systemd" "journal" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need journalctl with unit filter for sshd."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use journalctl with -u to filter by unit (service).
  Use -n to limit number of lines."
                    ;;
                2)
                    show_hint 2 "Syntax: journalctl -u servicename -n NUMBER
  Example: journalctl -u sshd -n 20"
                    ;;
                *)
                    show_solution "journalctl -u sshd -n 20"
                    echo
                    echo "Useful journalctl options:"
                    echo "  -u unit    Filter by service/unit"
                    echo "  -n N       Show last N lines"
                    echo "  -f         Follow (like tail -f)"
                    echo "  -p err     Show only errors"
                    echo "  --since    Time filter (e.g., '1 hour ago')"
                    record_exercise_attempt "systemd" "journal" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 5: Analyze boot time
# ============================================================================

exercise_systemd_analyze() {
    print_exercise "systemd-analyze: Analyze Boot Performance"

    cat << 'SCENARIO'
SCENARIO:
Users complain the server takes too long to boot after a reboot.
You need to analyze the boot process to find slow services.

systemd-analyze provides boot performance metrics.
SCENARIO

    echo
    print_task "Show the total boot time breakdown"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            if [[ "$user_cmd" == *"systemd-analyze"* ]]; then
                local user_output
                user_output=$(timeout 5 bash -c "$user_cmd" 2>&1) || true
                echo "$user_output"
                echo
                print_pass "Correct! Boot analysis displayed."
                record_exercise_attempt "systemd" "analyze" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to use systemd-analyze command."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The command is systemd-analyze.
  Without arguments, it shows overall boot time."
                    ;;
                2)
                    show_hint 2 "Try: systemd-analyze
  For per-service times: systemd-analyze blame"
                    ;;
                *)
                    show_solution "systemd-analyze"
                    echo
                    echo "Related commands:"
                    echo "  systemd-analyze blame    Per-service boot time"
                    echo "  systemd-analyze critical-chain  Show blocking chain"
                    echo "  systemd-analyze plot > boot.svg  Visual timeline"
                    record_exercise_attempt "systemd" "analyze" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 6: List failed services
# ============================================================================

exercise_systemd_failed() {
    print_exercise "systemctl: List Failed Services"

    cat << 'SCENARIO'
SCENARIO:
After a system update, something isn't working. You need to quickly
identify any services that failed to start.

This is a critical troubleshooting command after reboots or updates.
SCENARIO

    echo
    print_task "List all services that are in a failed state"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            # Accept various valid approaches
            if [[ "$user_cmd" == *"systemctl"* ]] && \
               [[ "$user_cmd" == *"--failed"* || "$user_cmd" == *"--state=failed"* || "$user_cmd" == *"failed"* ]]; then
                local user_output
                user_output=$(timeout 5 bash -c "$user_cmd" 2>&1) || true
                echo "$user_output"
                echo
                print_pass "Correct! Failed services listed."
                echo -e "${DIM}No output usually means no failures - that's good!${NC}"
                record_exercise_attempt "systemd" "failed" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to show failed services with systemctl."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "systemctl has a --failed option to show only failed units."
                    ;;
                2)
                    show_hint 2 "Try: systemctl --failed
  Or: systemctl list-units --state=failed"
                    ;;
                *)
                    show_solution "systemctl --failed"
                    echo "Alternative: systemctl list-units --state=failed"
                    record_exercise_attempt "systemd" "failed" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 7: View boot targets
# ============================================================================

exercise_systemd_targets() {
    print_exercise "systemctl: View System Target (Runlevel)"

    cat << 'SCENARIO'
SCENARIO:
You need to verify the system's default boot target (equivalent to the
old "runlevel" concept). This determines what services start at boot.

EXAM NOTE: Targets replaced runlevels in systemd.
  multi-user.target = runlevel 3 (text mode)
  graphical.target = runlevel 5 (GUI)
SCENARIO

    echo
    print_task "Show the current default boot target"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            if [[ "$user_cmd" == *"systemctl"* ]] && [[ "$user_cmd" == *"get-default"* ]]; then
                local user_output
                user_output=$(timeout 5 bash -c "$user_cmd" 2>&1) || true
                echo "$user_output"
                echo
                print_pass "Correct! Default target shown."
                echo -e "${DIM}This is equivalent to the old default runlevel.${NC}"
                record_exercise_attempt "systemd" "targets" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to use systemctl get-default."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "systemctl has a 'get-default' subcommand.
  It shows which target is set for boot."
                    ;;
                *)
                    show_solution "systemctl get-default"
                    echo
                    echo "Related commands:"
                    echo "  systemctl set-default multi-user.target  Change default"
                    echo "  systemctl isolate multi-user.target      Switch now"
                    echo "  systemctl list-units --type=target       List all targets"
                    record_exercise_attempt "systemd" "targets" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise Runner
# ============================================================================

run_systemd_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_systemd_status
        exercise_systemd_list
        exercise_systemd_enabled
        exercise_systemd_journal
        exercise_systemd_analyze
        exercise_systemd_failed
        exercise_systemd_targets
    )

    local total=${#exercises[@]}
    [[ $count -gt $total ]] && count=$total

    local correct=0
    local attempted=0
    local start_time
    start_time=$(date +%s)

    # Session intro
    echo
    echo -e "${BOLD}${CYAN}systemd Practice Session${NC}"
    echo -e "${DIM}$count exercises - Type 'skip' to skip - Type 'hint' for help${NC}"
    echo

    for ((i=0; i<count; i++)); do
        echo
        echo -e "${BOLD}--- Exercise $((i+1)) of $count ---${NC}"

        if ${exercises[$i]}; then
            ((correct++))
        fi
        ((attempted++))

        if [[ $((i+1)) -lt $count ]]; then
            echo
            echo -en "Press Enter for next exercise (or 'q' to quit)... "
            read -r choice
            [[ "$choice" == "q" ]] && break
        fi
    done

    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local elapsed_min=$((elapsed / 60))
    local elapsed_sec=$((elapsed % 60))

    echo
    print_header "Session Complete"

    local percent=$((correct * 100 / attempted))
    local bar_width=20
    local filled=$((bar_width * correct / attempted))
    local empty=$((bar_width - filled))

    echo -e "Score: ${BOLD}$correct / $attempted${NC} ($percent%)"
    printf "       ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "]\n"
    echo -e "Time:  ${elapsed_min}m ${elapsed_sec}s"
    echo

    if [[ $percent -ge 80 ]]; then
        print_pass "Excellent! Your systemd skills are solid."
        echo
        echo -e "${DIM}Essential systemctl commands:${NC}"
        echo "  status SERVICE     Check service status"
        echo "  start/stop/restart Control services"
        echo "  enable/disable     Boot-time settings"
        echo "  is-enabled         Check boot-time status"
        echo "  --failed           List failed services"
        echo
        echo -e "${DIM}Essential journalctl:${NC}"
        echo "  -u SERVICE         Filter by service"
        echo "  -f                 Follow live"
        echo "  -n N               Last N lines"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good progress! Practice the systemctl subcommands."
    else
        print_info "Review the lesson: lpic1 learn systemd"
        echo
        echo -e "${CYAN}systemctl pattern:${NC}"
        echo "  systemctl <action> <service>"
        echo "  Actions: status, start, stop, restart, enable, disable"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_systemd_exercises "$@"
fi
