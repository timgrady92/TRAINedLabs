#!/bin/bash
# LPIC-1 Training - systemd Lesson
# Objective: 101.3 - Change runlevels/boot targets and shutdown or reboot system

lesson_systemd() {
    print_header "systemd Service Management"

    cat << 'INTRO'
systemd is the init system and service manager for most modern Linux
distributions. It manages services (daemons), handles boot process,
logging, and much more. Understanding systemd is essential for system
administration.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Starting, stopping, and restarting services"
    echo "  ${BULLET} Enabling services to start at boot"
    echo "  ${BULLET} Viewing and analyzing system logs"
    echo "  ${BULLET} Managing boot targets (runlevels)"
    echo "  ${BULLET} Troubleshooting service failures"

    wait_for_user

    # systemctl basics
    print_subheader "systemctl - Service Management"

    echo -e "${BOLD}Service control:${NC}"
    echo "  systemctl start nginx        # Start service"
    echo "  systemctl stop nginx         # Stop service"
    echo "  systemctl restart nginx      # Stop then start"
    echo "  systemctl reload nginx       # Reload config (if supported)"
    echo "  systemctl status nginx       # Show status"
    echo

    echo -e "${BOLD}Enable/disable at boot:${NC}"
    echo "  systemctl enable nginx       # Start at boot"
    echo "  systemctl disable nginx      # Don't start at boot"
    echo "  systemctl enable --now nginx # Enable AND start"
    echo "  systemctl is-enabled nginx   # Check if enabled"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} systemctl status sshd"
    systemctl status sshd 2>/dev/null | head -10 | sed 's/^/  /' || \
        echo "  (sshd not available or not running)"

    wait_for_user

    # Viewing Services
    print_subheader "Viewing Services"

    echo -e "${BOLD}List services:${NC}"
    echo "  systemctl list-units --type=service"
    echo "  systemctl list-units --type=service --state=running"
    echo "  systemctl list-units --type=service --state=failed"
    echo "  systemctl list-unit-files --type=service"
    echo

    echo -e "${BOLD}Service states:${NC}"
    echo "  ${CYAN}active${NC}     - Running"
    echo "  ${CYAN}inactive${NC}   - Not running"
    echo "  ${CYAN}failed${NC}     - Failed to start/crashed"
    echo "  ${CYAN}enabled${NC}    - Will start at boot"
    echo "  ${CYAN}disabled${NC}   - Won't start at boot"
    echo "  ${CYAN}static${NC}     - Cannot be enabled (dependency only)"
    echo

    echo -e "${CYAN}Failed services:${NC}"
    echo "  systemctl --failed"

    wait_for_user

    # Unit Types
    print_subheader "Unit Types"

    echo "systemd manages different types of 'units':"
    echo
    echo -e "  ${CYAN}.service${NC}  - Daemons (nginx.service)"
    echo -e "  ${CYAN}.socket${NC}   - Network/IPC sockets"
    echo -e "  ${CYAN}.target${NC}   - Groups of units (like runlevels)"
    echo -e "  ${CYAN}.mount${NC}    - Filesystem mount points"
    echo -e "  ${CYAN}.timer${NC}    - Scheduled jobs (like cron)"
    echo -e "  ${CYAN}.path${NC}     - Path-based activation"
    echo -e "  ${CYAN}.device${NC}   - Kernel devices"
    echo

    echo -e "${DIM}When using systemctl, .service is assumed if omitted:${NC}"
    echo "  systemctl status nginx"
    echo "  systemctl status nginx.service  # Same thing"

    wait_for_user

    # Targets (Runlevels)
    print_subheader "Targets (Boot Targets)"

    echo "Targets are similar to traditional runlevels:"
    echo
    printf "  %-25s %-15s %s\n" "Target" "Old Runlevel" "Description"
    printf "  %-25s %-15s %s\n" "──────" "───────────" "───────────"
    printf "  %-25s %-15s %s\n" "poweroff.target" "0" "Halt system"
    printf "  %-25s %-15s %s\n" "rescue.target" "1, S" "Single user"
    printf "  %-25s %-15s %s\n" "multi-user.target" "3" "Multi-user, no GUI"
    printf "  %-25s %-15s %s\n" "graphical.target" "5" "Multi-user with GUI"
    printf "  %-25s %-15s %s\n" "reboot.target" "6" "Reboot"
    echo

    echo -e "${CYAN}View and change targets:${NC}"
    echo "  systemctl get-default              # Current default"
    echo "  systemctl set-default multi-user.target"
    echo "  systemctl isolate rescue.target    # Switch now"

    wait_for_user

    # journalctl - Logging
    print_subheader "journalctl - System Logs"

    echo "journalctl views logs from systemd's journal."
    echo

    echo -e "${BOLD}Basic usage:${NC}"
    echo "  journalctl                    # All logs"
    echo "  journalctl -e                 # Jump to end"
    echo "  journalctl -f                 # Follow (like tail -f)"
    echo "  journalctl -n 50              # Last 50 lines"
    echo

    echo -e "${BOLD}Filtering:${NC}"
    echo "  journalctl -u nginx           # Specific service"
    echo "  journalctl -p err             # Priority (emerg-debug)"
    echo "  journalctl --since '1 hour ago'"
    echo "  journalctl --since today"
    echo "  journalctl --since '2024-01-15 10:00'"
    echo "  journalctl -b                 # Current boot only"
    echo "  journalctl -b -1              # Previous boot"
    echo

    echo -e "${BOLD}Output formats:${NC}"
    echo "  journalctl -o verbose         # Detailed"
    echo "  journalctl -o json-pretty     # JSON format"
    echo "  journalctl --no-pager         # No paging"

    wait_for_user

    # Troubleshooting with journalctl
    print_subheader "Troubleshooting Services"

    echo -e "${CYAN}When a service fails to start:${NC}"
    echo
    echo "1. Check status:"
    echo "   systemctl status nginx"
    echo
    echo "2. View recent logs:"
    echo "   journalctl -u nginx -n 50"
    echo
    echo "3. Follow logs while starting:"
    echo "   journalctl -u nginx -f &"
    echo "   systemctl start nginx"
    echo
    echo "4. Check for syntax errors:"
    echo "   nginx -t  # Config test"
    echo
    echo "5. Reset failed state:"
    echo "   systemctl reset-failed nginx"

    wait_for_user

    # Unit Files
    print_subheader "Unit Files"

    echo -e "${BOLD}Unit file locations:${NC}"
    echo "  /lib/systemd/system/     # Package-provided"
    echo "  /etc/systemd/system/     # Admin customizations"
    echo "  /run/systemd/system/     # Runtime (temporary)"
    echo

    echo -e "${CYAN}View unit file:${NC}"
    echo "  systemctl cat nginx"
    echo

    echo -e "${CYAN}Edit unit file (override):${NC}"
    echo "  systemctl edit nginx         # Create drop-in override"
    echo "  systemctl edit --full nginx  # Edit full copy"
    echo

    echo -e "${CYAN}After editing:${NC}"
    echo "  systemctl daemon-reload"
    echo "  systemctl restart nginx"

    wait_for_user

    # System Control
    print_subheader "System Control"

    echo -e "${BOLD}Shutdown and reboot:${NC}"
    echo "  systemctl poweroff           # Shutdown"
    echo "  systemctl reboot             # Reboot"
    echo "  systemctl suspend            # Suspend"
    echo "  systemctl hibernate          # Hibernate"
    echo

    echo -e "${BOLD}Legacy commands (still work):${NC}"
    echo "  shutdown -h now              # Halt now"
    echo "  shutdown -r +5               # Reboot in 5 minutes"
    echo "  shutdown -c                  # Cancel scheduled"
    echo "  reboot                       # Immediate reboot"
    echo "  halt                         # Immediate halt"
    echo "  poweroff                     # Immediate poweroff"

    wait_for_user

    # Masking Services
    print_subheader "Masking Services"

    echo "Masking prevents a service from being started at all."
    echo

    echo -e "${BOLD}Commands:${NC}"
    echo "  systemctl mask nginx         # Completely disable"
    echo "  systemctl unmask nginx       # Re-enable"
    echo

    echo -e "${DIM}Masked services are symlinked to /dev/null${NC}"
    echo -e "${DIM}Even 'systemctl start' won't work on masked services${NC}"
    echo

    echo -e "${CYAN}Use case:${NC}"
    echo "  Prevent conflicting services (e.g., iptables vs firewalld)"
    echo "  Temporarily disable during maintenance"

    wait_for_user

    # Timers
    print_subheader "systemd Timers (Alternative to Cron)"

    echo "Timers are systemd's alternative to cron jobs."
    echo

    echo -e "${BOLD}View timers:${NC}"
    echo "  systemctl list-timers"
    echo "  systemctl list-timers --all"
    echo

    echo -e "${CYAN}Example: logrotate.timer${NC}"
    echo "  systemctl status logrotate.timer"
    echo "  systemctl cat logrotate.timer"
    echo

    echo -e "${BOLD}Timer units need:${NC}"
    echo "  1. A .timer unit (the schedule)"
    echo "  2. A .service unit (what to run)"
    echo "  Same name: backup.timer → backup.service"

    wait_for_user

    # Practical Examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Enable and start web server:${NC}"
    echo "   systemctl enable --now nginx"
    echo

    echo -e "${CYAN}2. View why service failed:${NC}"
    echo "   systemctl status myservice"
    echo "   journalctl -u myservice -p err"
    echo

    echo -e "${CYAN}3. Change to text-only boot:${NC}"
    echo "   systemctl set-default multi-user.target"
    echo

    echo -e "${CYAN}4. Find what's taking long at boot:${NC}"
    echo "   systemd-analyze"
    echo "   systemd-analyze blame"
    echo

    echo -e "${CYAN}5. Reload service after config change:${NC}"
    echo "   systemctl reload nginx    # If supported"
    echo "   systemctl restart nginx   # If reload not supported"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} systemctl start/stop/restart/reload/status"
    echo -e "${MAGENTA}${BULLET}${NC} systemctl enable/disable for boot behavior"
    echo -e "${MAGENTA}${BULLET}${NC} journalctl -u service shows service logs"
    echo -e "${MAGENTA}${BULLET}${NC} Targets replace runlevels: multi-user.target = runlevel 3"
    echo -e "${MAGENTA}${BULLET}${NC} systemctl daemon-reload after editing unit files"
    echo -e "${MAGENTA}${BULLET}${NC} mask prevents starting; disable just removes from boot"
    echo -e "${MAGENTA}${BULLET}${NC} journalctl -f follows logs like tail -f"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. systemctl manages services: start, stop, enable, status"
    echo "2. journalctl views logs: -u for service, -f to follow"
    echo "3. Targets are groups of services (like runlevels)"
    echo "4. Unit files in /etc/systemd/system/ override defaults"
    echo "5. daemon-reload required after changing unit files"
    echo "6. mask completely prevents service from starting"
    echo

    print_info "Ready to practice? Try: lpic-train practice systemd"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_systemd
fi
