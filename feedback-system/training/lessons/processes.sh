#!/bin/bash
# LPIC-1 Training - Process Management Lesson
# Objective: 103.5 - Create, monitor, and kill processes

lesson_processes() {
    print_header "Process Management"

    cat << 'INTRO'
Every running program is a process. Linux provides tools to view,
control, and manage processes. Understanding process management is
essential for system administration, troubleshooting, and scripting.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Finding and killing unresponsive applications"
    echo "  ${BULLET} Monitoring system resource usage"
    echo "  ${BULLET} Running tasks in the background"
    echo "  ${BULLET} Automating server management"
    echo "  ${BULLET} Diagnosing performance issues"

    wait_for_user

    # Process Basics
    print_subheader "Process Fundamentals"

    echo -e "${BOLD}Every process has:${NC}"
    echo "  ${CYAN}PID${NC}    - Process ID (unique identifier)"
    echo "  ${CYAN}PPID${NC}   - Parent Process ID"
    echo "  ${CYAN}UID${NC}    - User ID (who owns the process)"
    echo "  ${CYAN}State${NC}  - Running, Sleeping, Stopped, Zombie"
    echo
    echo -e "${BOLD}Process states:${NC}"
    echo "  ${CYAN}R${NC}  Running or runnable"
    echo "  ${CYAN}S${NC}  Sleeping (waiting for event)"
    echo "  ${CYAN}D${NC}  Uninterruptible sleep (usually I/O)"
    echo "  ${CYAN}T${NC}  Stopped (by signal or debugger)"
    echo "  ${CYAN}Z${NC}  Zombie (terminated but not reaped)"

    wait_for_user

    # ps - Process Status
    print_subheader "ps - View Processes"

    echo -e "${BOLD}Common ps formats:${NC}"
    echo -e "  ${CYAN}ps${NC}              Your terminal's processes"
    echo -e "  ${CYAN}ps aux${NC}          All processes, detailed (BSD style)"
    echo -e "  ${CYAN}ps -ef${NC}          All processes, full format (POSIX style)"
    echo -e "  ${CYAN}ps axjf${NC}         Process tree with hierarchy"
    echo

    echo -e "${CYAN}Live Example: ps aux${NC}"
    echo -e "${BOLD}Command:${NC} ps aux | head -8"
    echo -e "${DIM}Output:${NC}"
    ps aux 2>/dev/null | head -8 | sed 's/^/  /'
    echo

    echo -e "${BOLD}ps aux columns:${NC}"
    echo "  USER  PID  %CPU  %MEM  VSZ  RSS  TTY  STAT  START  TIME  COMMAND"

    wait_for_user

    # ps Options
    print_subheader "Useful ps Options"

    echo -e "${BOLD}BSD-style options (no dash):${NC}"
    echo "  a    Include processes from all terminals"
    echo "  u    User-oriented format"
    echo "  x    Include processes without controlling terminal"
    echo
    echo -e "${BOLD}POSIX-style options (with dash):${NC}"
    echo "  -e   All processes"
    echo "  -f   Full format"
    echo "  -u   By effective user"
    echo "  -p   By PID"
    echo

    echo -e "${CYAN}Find specific processes:${NC}"
    echo "  ps aux | grep nginx"
    echo "  ps -ef | grep -i apache"
    echo

    echo -e "${CYAN}Show process tree:${NC}"
    echo "  ps axjf"
    echo "  ps -ef --forest"

    wait_for_user

    # pgrep and pkill
    print_subheader "pgrep and pkill"

    echo -e "${BOLD}pgrep - Find processes by name${NC}"
    echo "  pgrep bash              # PIDs of bash processes"
    echo "  pgrep -l bash           # PIDs and names"
    echo "  pgrep -u root           # Processes owned by root"
    echo "  pgrep -a ssh            # Full command lines"
    echo

    echo -e "${CYAN}Live Example:${NC}"
    echo -e "${BOLD}Command:${NC} pgrep -l bash"
    echo -e "${DIM}Output:${NC}"
    pgrep -l bash 2>/dev/null | head -5 | sed 's/^/  /' || echo "  (no bash processes)"
    echo

    echo -e "${BOLD}pkill - Kill processes by name${NC}"
    echo "  pkill firefox           # Send SIGTERM to firefox"
    echo "  pkill -9 hung_process   # Force kill"
    echo "  pkill -u john           # Kill all of john's processes"

    wait_for_user

    # top and htop
    print_subheader "top - Interactive Process Viewer"

    echo "top shows real-time process information, updating periodically."
    echo
    echo -e "${BOLD}Key commands inside top:${NC}"
    echo "  ${CYAN}q${NC}       Quit"
    echo "  ${CYAN}k${NC}       Kill process (prompts for PID)"
    echo "  ${CYAN}r${NC}       Renice process (change priority)"
    echo "  ${CYAN}P${NC}       Sort by CPU usage"
    echo "  ${CYAN}M${NC}       Sort by memory usage"
    echo "  ${CYAN}u${NC}       Filter by user"
    echo "  ${CYAN}1${NC}       Toggle per-CPU stats"
    echo

    echo -e "${BOLD}One-shot usage:${NC}"
    echo "  top -bn1 | head -20    # Batch mode, single iteration"
    echo
    echo -e "${DIM}Also try: htop (if installed) for a better interface${NC}"

    wait_for_user

    # Signals
    print_subheader "Signals"

    echo "Signals are software interrupts sent to processes."
    echo
    echo -e "${BOLD}Common signals:${NC}"
    printf "  %-8s %-12s %s\n" "Number" "Name" "Meaning"
    printf "  %-8s %-12s %s\n" "──────" "────" "───────"
    printf "  %-8s %-12s %s\n" "1" "SIGHUP" "Hangup - reload config"
    printf "  %-8s %-12s %s\n" "2" "SIGINT" "Interrupt (Ctrl+C)"
    printf "  %-8s %-12s %s\n" "9" "SIGKILL" "Force kill (cannot catch)"
    printf "  %-8s %-12s %s\n" "15" "SIGTERM" "Graceful termination (default)"
    printf "  %-8s %-12s %s\n" "18" "SIGCONT" "Continue stopped process"
    printf "  %-8s %-12s %s\n" "19" "SIGSTOP" "Stop process (cannot catch)"
    printf "  %-8s %-12s %s\n" "20" "SIGTSTP" "Stop from terminal (Ctrl+Z)"
    echo

    echo -e "${DIM}List all signals: kill -l${NC}"

    wait_for_user

    # kill
    print_subheader "kill - Send Signals"

    echo -e "${BOLD}kill syntax:${NC}"
    echo "  kill PID               # Send SIGTERM (15)"
    echo "  kill -15 PID           # Same as above"
    echo "  kill -SIGTERM PID      # Same as above"
    echo "  kill -9 PID            # Force kill (SIGKILL)"
    echo "  kill -KILL PID         # Same as above"
    echo
    echo -e "${CYAN}Reload daemon configuration:${NC}"
    echo "  kill -HUP \$(pgrep nginx)"
    echo "  systemctl reload nginx  # Modern way"
    echo
    echo -e "${CYAN}Graceful shutdown sequence:${NC}"
    echo "  kill PID               # Try SIGTERM first"
    echo "  sleep 5"
    echo "  kill -9 PID            # Force if still running"
    echo
    echo -e "${YELLOW}${WARN} SIGKILL (-9) should be last resort - no cleanup!${NC}"

    wait_for_user

    # killall
    print_subheader "killall - Kill by Name"

    echo -e "${BOLD}killall kills all processes matching a name:${NC}"
    echo "  killall firefox        # Kill all firefox processes"
    echo "  killall -9 hung_app    # Force kill"
    echo "  killall -u john bash   # Kill john's bash processes"
    echo "  killall -i process     # Interactive (confirm each)"
    echo
    echo -e "${RED}${WARN} Be careful on systems where killall may kill ALL processes!${NC}"
    echo -e "${DIM}On some Unix systems, killall without arguments kills everything.${NC}"

    wait_for_user

    # Background and Foreground
    print_subheader "Background and Foreground Jobs"

    echo -e "${BOLD}Running processes in background:${NC}"
    echo "  command &              # Start in background"
    echo "  Ctrl+Z                 # Suspend current process"
    echo "  bg                     # Resume in background"
    echo "  fg                     # Bring to foreground"
    echo
    echo -e "${BOLD}Job control:${NC}"
    echo "  jobs                   # List background jobs"
    echo "  jobs -l                # With PIDs"
    echo "  fg %1                  # Bring job 1 to foreground"
    echo "  bg %2                  # Resume job 2 in background"
    echo "  kill %1                # Kill job 1"
    echo

    echo -e "${CYAN}Example workflow:${NC}"
    echo "  \$ sleep 100           # Start process"
    echo "  ^Z                     # Press Ctrl+Z"
    echo "  [1]+  Stopped  sleep 100"
    echo "  \$ bg                   # Continue in background"
    echo "  \$ jobs"
    echo "  [1]+  Running  sleep 100 &"

    wait_for_user

    # nohup and disown
    print_subheader "nohup and disown"

    echo -e "${BOLD}nohup - Immune to hangups${NC}"
    echo "  nohup command &        # Won't die when terminal closes"
    echo "  nohup ./script.sh > output.log 2>&1 &"
    echo
    echo -e "${DIM}Output goes to nohup.out if not redirected${NC}"
    echo

    echo -e "${BOLD}disown - Detach from shell${NC}"
    echo "  command &              # Start in background"
    echo "  disown                 # Detach from shell"
    echo "  disown %1              # Detach specific job"
    echo "  disown -h              # Mark to ignore SIGHUP"
    echo
    echo -e "${CYAN}Which to use?${NC}"
    echo "  nohup: When starting a new command"
    echo "  disown: When process already running"

    wait_for_user

    # nice and renice
    print_subheader "nice and renice - Process Priority"

    echo -e "${BOLD}Priority levels:${NC}"
    echo "  Range: -20 (highest) to 19 (lowest)"
    echo "  Default: 0"
    echo "  Only root can set negative (higher) priority"
    echo

    echo -e "${BOLD}nice - Start with priority${NC}"
    echo "  nice command           # Priority 10 (lower)"
    echo "  nice -n 15 command     # Priority 15"
    echo "  nice -n -10 command    # Priority -10 (root only)"
    echo

    echo -e "${BOLD}renice - Change running process${NC}"
    echo "  renice 10 PID          # Set priority to 10"
    echo "  renice -n 5 PID        # Same"
    echo "  renice 10 -u john      # All of john's processes"
    echo

    echo -e "${CYAN}View priority:${NC}"
    echo "  ps -eo pid,ni,comm | head"
    echo -e "${DIM}NI column shows nice value${NC}"

    wait_for_user

    # Practical Examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Find and kill a hung process:${NC}"
    echo "   ps aux | grep firefox"
    echo "   kill 12345            # Try graceful first"
    echo "   kill -9 12345         # Force if needed"
    echo

    echo -e "${CYAN}2. Find memory-hungry processes:${NC}"
    echo "   ps aux --sort=-%mem | head"
    echo

    echo -e "${CYAN}3. Find CPU-hungry processes:${NC}"
    echo "   ps aux --sort=-%cpu | head"
    echo

    echo -e "${CYAN}4. Run backup without hogging CPU:${NC}"
    echo "   nice -n 19 tar -czvf backup.tar.gz /home/"
    echo

    echo -e "${CYAN}5. Long-running script that survives logout:${NC}"
    echo "   nohup ./long-script.sh > script.log 2>&1 &"
    echo

    echo -e "${CYAN}6. Reload daemon after config change:${NC}"
    echo "   kill -HUP \$(cat /var/run/nginx.pid)"
    echo "   # Or: systemctl reload nginx"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} ps aux = all processes, user format (BSD style)"
    echo -e "${MAGENTA}${BULLET}${NC} ps -ef = all processes, full format (POSIX style)"
    echo -e "${MAGENTA}${BULLET}${NC} kill with no signal = SIGTERM (15) = graceful"
    echo -e "${MAGENTA}${BULLET}${NC} kill -9 = SIGKILL = force (cannot be caught)"
    echo -e "${MAGENTA}${BULLET}${NC} & runs in background; Ctrl+Z suspends"
    echo -e "${MAGENTA}${BULLET}${NC} nice range: -20 to 19; only root can go negative"
    echo -e "${MAGENTA}${BULLET}${NC} nohup prevents SIGHUP from killing process"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. ps aux shows all processes with details"
    echo "2. kill sends signals; default is SIGTERM (graceful)"
    echo "3. SIGKILL (-9) forces termination but skips cleanup"
    echo "4. & runs in background; jobs/fg/bg manage jobs"
    echo "5. nohup keeps processes running after logout"
    echo "6. nice/renice control CPU priority"
    echo

    print_info "Ready to practice? Try: lpic-train practice processes"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_processes
fi
