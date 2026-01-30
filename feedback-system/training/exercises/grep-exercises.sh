#!/bin/bash
# LPIC-1 Training - grep Exercises
# Guided exercises with progressive hints, error diagnosis, and elaboration

# Ensure common functions are loaded
if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# Load learning helpers for enhanced feedback
LEARNING_HELPERS="${SCRIPT_DIR}/training/learning-helpers.sh"
[[ -f "$LEARNING_HELPERS" ]] && source "$LEARNING_HELPERS"

# ============================================================================
# Exercise 1: Basic grep
# ============================================================================

exercise_grep_basic() {
    print_exercise "grep: Basic Pattern Search"

    local practice_file="${PRACTICE_DIR}/logs/system.log"

    # Real-world context helps retention
    cat << 'SCENARIO'
SCENARIO:
You're investigating system issues and need to find all error messages
in the system log. The errors might be written as "error", "Error", or "ERROR".

File: /opt/LPIC-1/practice/logs/system.log

WHY THIS MATTERS:
Log analysis is a daily task for sysadmins. Case-insensitive search
catches errors regardless of how applications format them.
SCENARIO

    echo
    print_task "Find all lines containing 'error' (case insensitive)"
    echo -e "${DIM}Tip: Type 'skip' to skip, 'hint' for a hint${NC}"
    echo

    local attempts=0
    local max_attempts=4
    local expected_output
    expected_output=$(grep -i 'error' "$practice_file" 2>/dev/null)

    while true; do
        read -rp "Your command: " user_cmd

        # Check if user wants to skip
        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Allow asking for hint explicitly
        if [[ "$user_cmd" == "hint" || "$user_cmd" == "h" ]]; then
            ((attempts++))
            user_cmd=""
        fi

        # Validate command
        local user_output
        if [[ -n "$user_cmd" ]]; then
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
        fi

        if [[ -n "$user_cmd" && "$user_output" == "$expected_output" ]]; then
            echo
            print_pass "Correct!"
            echo -e "${DIM}Your output matches expected ($(echo "$user_output" | wc -l) lines)${NC}"
            record_exercise_attempt "grep" "basic" 1

            # Elaboration prompt to deepen understanding
            if type -t ask_elaboration &>/dev/null; then
                ask_elaboration "grep" "$user_cmd"
            fi

            return 0
        fi

        if [[ -n "$user_cmd" ]]; then
            ((attempts++))
            echo
            print_fail "Not quite. Let's help you get there."

            # Error diagnosis - explain WHY it failed
            if type -t diagnose_command_error &>/dev/null; then
                diagnose_command_error "$user_cmd" "grep -i" "grep"
            fi
        fi

        if [[ "${LPIC_NO_HINTS:-}" == "1" ]]; then
            echo -e "${DIM}(Hints disabled)${NC}"
        else
            case $attempts in
                1)
                    show_hint 1 "grep has an option for case-insensitive matching.
  Think about what letter might represent 'ignore case'."
                    ;;
                2)
                    show_hint 2 "The option is -i (case Insensitive).
  Syntax: grep -i 'pattern' filename"
                    ;;
                3)
                    show_hint 3 "Try: grep -i 'error' <filename>
  The file is: logs/system.log (relative to practice directory)"
                    ;;
                *)
                    show_solution "grep -i 'error' logs/system.log"
                    echo
                    # Show expert thinking trace
                    if type -t show_expert_thinking &>/dev/null; then
                        show_expert_thinking "Find errors case-insensitively" "grep" "grep -i 'error' logs/system.log"
                    else
                        echo "This finds lines containing 'error', 'Error', 'ERROR', etc."
                        echo -e "${DIM}The -i flag makes grep ignore case differences.${NC}"
                    fi
                    record_exercise_attempt "grep" "basic" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 2: Invert Match
# ============================================================================

exercise_grep_invert() {
    print_exercise "grep: Invert Match"

    local practice_file="${PRACTICE_DIR}/text/users.txt"

    cat << 'SCENARIO'
SCENARIO:
You're reviewing user accounts. You need to find all users who CAN log in
(users whose shell is NOT /usr/sbin/nologin or /usr/sbin/nologin).

File: /opt/LPIC-1/practice/text/users.txt
SCENARIO

    echo
    print_task "Show lines NOT containing 'nologin'"
    echo

    local attempts=0
    local expected_output
    expected_output=$(grep -v 'nologin' "$practice_file" 2>/dev/null)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        if [[ "$user_output" == "$expected_output" ]]; then
            echo
            print_pass "Correct!"
            echo -e "\n${DIM}Users who can log in:${NC}"
            echo "$user_output" | head -5 | sed 's/^/  /'
            record_exercise_attempt "grep" "invert" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "grep has an option to INVERT the match.
  This shows lines that DON'T contain the pattern."
                    ;;
                2)
                    show_hint 2 "The option is -v (inVert or reVerse).
  Syntax: grep -v 'pattern' filename"
                    ;;
                3)
                    show_hint 3 "The command structure is:
  grep -v 'nologin' text/users.txt"
                    ;;
                *)
                    show_solution "grep -v 'nologin' text/users.txt"
                    record_exercise_attempt "grep" "invert" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 3: Count Matches
# ============================================================================

exercise_grep_count() {
    print_exercise "grep: Count Matches"

    local practice_file="${PRACTICE_DIR}/logs/system.log"

    cat << 'SCENARIO'
SCENARIO:
You need to report how many SSH-related events are in the system log.
Rather than counting manually, use grep's counting feature.

File: /opt/LPIC-1/practice/logs/system.log
SCENARIO

    echo
    print_task "Count lines containing 'sshd'"
    echo

    local attempts=0
    local expected_output
    expected_output=$(grep -c 'sshd' "$practice_file" 2>/dev/null)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        # Accept either grep -c or piping to wc -l
        if [[ "$user_output" == "$expected_output" ]]; then
            echo
            print_pass "Correct! There are $expected_output SSH-related entries."
            record_exercise_attempt "grep" "count" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Expected output: $expected_output"

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "grep can count matches instead of printing them.
  Look for an option that might mean 'count'."
                    ;;
                2)
                    show_hint 2 "The option is -c (Count).
  It outputs just the number of matching lines."
                    ;;
                *)
                    show_solution "grep -c 'sshd' logs/system.log"
                    echo "Alternative: grep 'sshd' logs/system.log | wc -l"
                    record_exercise_attempt "grep" "count" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 4: Line Numbers
# ============================================================================

exercise_grep_linenum() {
    print_exercise "grep: Show Line Numbers"

    local practice_file="${PRACTICE_DIR}/logs/system.log"

    cat << 'SCENARIO'
SCENARIO:
You found errors in a log file and need to know exactly which line numbers
they're on so you can reference them in a bug report.

File: /opt/LPIC-1/practice/logs/system.log
SCENARIO

    echo
    print_task "Show lines containing 'Failed' with their line numbers"
    echo

    local attempts=0
    local expected_output
    expected_output=$(grep -n 'Failed' "$practice_file" 2>/dev/null)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        if [[ "$user_output" == "$expected_output" ]]; then
            echo
            print_pass "Correct!"
            echo -e "\n${DIM}Output shows line_number:content${NC}"
            echo "$user_output" | head -3 | sed 's/^/  /'
            record_exercise_attempt "grep" "linenum" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "grep has an option to show line numbers.
  Think: n for number."
                    ;;
                2)
                    show_hint 2 "The option is -n.
  Output format: line_number:matching_line"
                    ;;
                *)
                    show_solution "grep -n 'Failed' logs/system.log"
                    record_exercise_attempt "grep" "linenum" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 5: Extended Regex
# ============================================================================

exercise_grep_regex() {
    print_exercise "grep: Extended Regular Expressions"

    local practice_file="${PRACTICE_DIR}/logs/system.log"

    cat << 'SCENARIO'
SCENARIO:
You need to find log entries related to either 'error' OR 'warning'.
Use extended regex to match multiple patterns in one command.

File: /opt/LPIC-1/practice/logs/system.log
SCENARIO

    echo
    print_task "Find lines containing 'error' OR 'Warning' (case insensitive)"
    echo

    local attempts=0
    local expected_output
    expected_output=$(grep -iE 'error|warning' "$practice_file" 2>/dev/null)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        if [[ "$user_output" == "$expected_output" ]]; then
            echo
            print_pass "Correct!"
            echo -e "\n${DIM}Found $(echo "$user_output" | wc -l) matching lines${NC}"
            record_exercise_attempt "grep" "regex" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Make sure you're catching both error AND warning, case insensitive."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Extended regex uses | for alternation (OR).
  You'll need -E to enable extended regex."
                    ;;
                2)
                    show_hint 2 "Combine -E for regex and -i for case insensitive.
  Pattern: 'pattern1|pattern2'"
                    ;;
                *)
                    show_solution "grep -iE 'error|warning' logs/system.log"
                    echo "Or: grep -i -E 'error|warning' logs/system.log"
                    echo "Or: egrep -i 'error|warning' logs/system.log"
                    record_exercise_attempt "grep" "regex" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 6: Recursive Search
# ============================================================================

exercise_grep_recursive() {
    print_exercise "grep: Recursive Directory Search"

    cat << 'SCENARIO'
SCENARIO:
You need to search for the word "password" across all files in the configs
directory to audit for any hardcoded credentials.

Directory: /opt/LPIC-1/practice/configs/
SCENARIO

    echo
    print_task "Recursively search for 'password' in the configs/ directory"
    echo

    local attempts=0
    local expected_files
    expected_files=$(grep -rl 'password' "${PRACTICE_DIR}/configs" 2>/dev/null | wc -l)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        # Check if using -r and getting results
        if [[ "$user_cmd" == *"-r"* || "$user_cmd" == *"-R"* ]] && \
           [[ "$user_output" == *"password"* ]]; then
            echo
            print_pass "Correct! You found password references in config files."
            record_exercise_attempt "grep" "recursive" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Need to search recursively through configs/ directory."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "grep has an option for recursive directory search.
  Think: r for recursive."
                    ;;
                2)
                    show_hint 2 "The option is -r (or -R).
  Syntax: grep -r 'pattern' directory/"
                    ;;
                *)
                    show_solution "grep -r 'password' configs/"
                    echo "Add -l to only show filenames: grep -rl 'password' configs/"
                    record_exercise_attempt "grep" "recursive" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise Runner
# ============================================================================

run_grep_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_grep_basic
        exercise_grep_invert
        exercise_grep_count
        exercise_grep_linenum
        exercise_grep_regex
        exercise_grep_recursive
    )

    local total=${#exercises[@]}
    [[ $count -gt $total ]] && count=$total

    local correct=0
    local attempted=0
    local start_time
    start_time=$(date +%s)

    # Session intro
    echo
    echo -e "${BOLD}${CYAN}grep Practice Session${NC}"
    echo -e "${DIM}$count exercises • Type 'skip' to skip • Type 'hint' for help${NC}"
    echo

    for ((i=0; i<count; i++)); do
        echo
        echo -e "${BOLD}━━━ Exercise $((i+1)) of $count ━━━${NC}"

        if ${exercises[$i]}; then
            ((correct++))
        fi
        ((attempted++))

        if [[ $((i+1)) -lt $count ]]; then
            echo
            read -rp "Press Enter for next exercise (or 'q' to quit)... " choice
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

    # Visual score display
    local percent=$((correct * 100 / attempted))
    local bar_width=20
    local filled=$((bar_width * correct / attempted))
    local empty=$((bar_width - filled))

    echo -e "Score: ${BOLD}$correct / $attempted${NC} ($percent%)"
    printf "       ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]\n"
    echo -e "Time:  ${elapsed_min}m ${elapsed_sec}s"
    echo

    # Detailed feedback based on performance
    if [[ $percent -ge 80 ]]; then
        print_pass "Excellent work! Your grep skills are solid."
        echo
        echo -e "${DIM}Next steps:${NC}"
        echo "  • Try harder exercises: lpic-train test grep"
        echo "  • Build muscle memory: quick drills in sandbox mode"
        echo "  • Move to related commands: sed, awk"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good progress! A few areas to strengthen."
        echo
        echo -e "${DIM}Recommendations:${NC}"
        echo "  • Review the lesson: lpic-train learn grep"
        echo "  • Practice weak spots: focus on flags you missed"
        echo "  • Try again soon: repetition builds memory"

        # Show specific areas to work on
        echo
        echo -e "${YELLOW}Key grep flags to memorize:${NC}"
        echo "  -i  Case insensitive"
        echo "  -v  Invert match (exclude)"
        echo "  -c  Count matches"
        echo "  -n  Show line numbers"
        echo "  -r  Recursive search"
        echo "  -E  Extended regex (for | + ?)"
    else
        print_info "Keep practicing! grep is fundamental to Linux mastery."
        echo
        echo -e "${DIM}Learning path:${NC}"
        echo "  1. Review basics: lpic-train learn grep"
        echo "  2. Study the flags one at a time"
        echo "  3. Practice in sandbox: lpic-train sandbox grep"
        echo "  4. Return here when ready"
        echo
        echo -e "${CYAN}Remember:${NC} Every expert was once a beginner."
        echo "The key is consistent practice, not perfection."
    fi

    # Spaced repetition suggestion
    if type -t show_review_recommendation &>/dev/null && [[ $percent -lt 80 ]]; then
        echo
        show_review_recommendation
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_grep_exercises "$@"
fi
