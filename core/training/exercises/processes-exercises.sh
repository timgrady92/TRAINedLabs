#!/bin/bash
# LPIC-1 Training - Process Management Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: View All Processes
# ============================================================================

exercise_ps_all() {
    print_exercise "ps: View All Processes"

    cat << 'SCENARIO'
SCENARIO:
You need to see all processes running on the system, with detailed
information including CPU and memory usage.

This is one of the most common Linux commands!
SCENARIO

    echo
    print_task "Show all processes with user-oriented format (BSD style)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"ps"* ]] && [[ "$user_cmd" == *"aux"* ]]; then
            echo
            print_pass "Correct!"
            echo "ps aux shows all processes with CPU/memory usage."
            echo
            echo "Sample output:"
            ps aux 2>/dev/null | head -5 | sed 's/^/  /'
            record_exercise_attempt "ps" "all" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "ps has BSD-style options (no dash).
  a = all users, u = user format, x = include background"
                    ;;
                2)
                    show_hint 2 "The most common combination: ps aux
  Shows all processes with detailed info."
                    ;;
                *)
                    show_solution "ps aux"
                    record_exercise_attempt "ps" "all" 0
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
# Exercise 2: Kill with SIGTERM
# ============================================================================

exercise_kill_term() {
    print_exercise "kill: Graceful Termination"

    cat << 'SCENARIO'
SCENARIO:
A process with PID 1234 needs to be stopped gracefully, allowing it
to clean up before exiting. Use the default signal (SIGTERM).
SCENARIO

    echo
    print_task "Send SIGTERM (graceful stop) to process 1234"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Accept: kill 1234, kill -15 1234, kill -TERM 1234, kill -SIGTERM 1234
        if [[ "$user_cmd" == "kill 1234" ]] || \
           [[ "$user_cmd" == *"kill -15 1234"* ]] || \
           [[ "$user_cmd" == *"kill -TERM"*"1234"* ]] || \
           [[ "$user_cmd" == *"kill -SIGTERM"*"1234"* ]]; then
            echo
            print_pass "Correct!"
            echo "kill without signal sends SIGTERM (15) by default."
            record_exercise_attempt "kill" "term" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The default signal is SIGTERM (15).
  It's sent if you don't specify a signal."
                    ;;
                2)
                    show_hint 2 "Simple syntax: kill PID
  This sends SIGTERM to let the process exit cleanly."
                    ;;
                *)
                    show_solution "kill 1234"
                    echo "Also valid: kill -15 1234, kill -TERM 1234"
                    record_exercise_attempt "kill" "term" 0
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
# Exercise 3: Force Kill
# ============================================================================

exercise_kill_force() {
    print_exercise "kill: Force Kill"

    cat << 'SCENARIO'
SCENARIO:
A process with PID 5678 is unresponsive and ignoring SIGTERM.
You need to force it to stop immediately using SIGKILL.
SCENARIO

    echo
    print_task "Force kill process 5678 with SIGKILL"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Accept: kill -9 5678, kill -KILL 5678, kill -SIGKILL 5678
        if [[ "$user_cmd" == *"kill"* ]] && [[ "$user_cmd" == *"5678"* ]] && \
           [[ "$user_cmd" == *"-9"* || "$user_cmd" == *"-KILL"* || "$user_cmd" == *"-SIGKILL"* ]]; then
            echo
            print_pass "Correct!"
            echo "SIGKILL (-9) cannot be caught - process terminates immediately."
            echo -e "${YELLOW}Note: Use -9 as last resort - no cleanup possible!${NC}"
            record_exercise_attempt "kill" "force" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to use signal 9 (SIGKILL)."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "SIGKILL has signal number 9.
  It cannot be caught or ignored by the process."
                    ;;
                2)
                    show_hint 2 "Syntax: kill -9 PID
  Or: kill -KILL PID"
                    ;;
                *)
                    show_solution "kill -9 5678"
                    record_exercise_attempt "kill" "force" 0
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
# Exercise 4: Background Job
# ============================================================================

exercise_bg_job() {
    print_exercise "jobs: Run in Background"

    cat << 'SCENARIO'
SCENARIO:
You want to start a long-running command (like sleep 300) in the
background so you can continue using the terminal.
SCENARIO

    echo
    print_task "Run 'sleep 300' in the background"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"sleep"* ]] && [[ "$user_cmd" == *"&"* ]]; then
            echo
            print_pass "Correct!"
            echo "The & at the end runs the command in background."
            echo "Use 'jobs' to see background jobs, 'fg' to bring one back."
            record_exercise_attempt "jobs" "bg" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to run command in background."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "To run a command in background, add something at the end.
  The shell returns immediately while command runs."
                    ;;
                2)
                    show_hint 2 "Add & at the end: command &
  Example: sleep 300 &"
                    ;;
                *)
                    show_solution "sleep 300 &"
                    record_exercise_attempt "jobs" "bg" 0
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
# Exercise 5: Nice Priority
# ============================================================================

exercise_nice() {
    print_exercise "nice: Run with Lower Priority"

    cat << 'SCENARIO'
SCENARIO:
You need to run a CPU-intensive backup script but don't want it
to slow down other processes. Run it with reduced priority (nice value 10).
SCENARIO

    echo
    print_task "Run a command with nice value 10 (lower priority)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"nice"* ]] && \
           [[ "$user_cmd" == *"10"* || "$user_cmd" == *"-n 10"* ]]; then
            echo
            print_pass "Correct!"
            echo "nice -n 10 runs with priority 10 (lower than default 0)."
            echo "Higher nice = lower priority = nicer to other processes."
            record_exercise_attempt "nice" "run" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to use nice with value 10."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The 'nice' command runs programs with modified priority.
  Higher nice value = lower priority."
                    ;;
                2)
                    show_hint 2 "Syntax: nice -n VALUE command
  Example: nice -n 10 backup.sh"
                    ;;
                *)
                    show_solution "nice -n 10 backup.sh"
                    echo "Also valid: nice -10 backup.sh"
                    record_exercise_attempt "nice" "run" 0
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

run_processes_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_ps_all
        exercise_kill_term
        exercise_kill_force
        exercise_bg_job
        exercise_nice
    )

    local total=${#exercises[@]}
    [[ $count -gt $total ]] && count=$total

    local correct=0
    local attempted=0

    for ((i=0; i<count; i++)); do
        echo
        echo -e "${BOLD}Exercise $((i+1)) of $count${NC}"

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

    echo
    print_header "Session Complete"
    echo "Score: $correct / $attempted"

    local percent=$((correct * 100 / attempted))
    if [[ $percent -ge 80 ]]; then
        print_pass "Excellent work!"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good progress, keep practicing"
    else
        print_info "Review the lesson: lpic-train learn processes"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_processes_exercises "$@"
fi
