#!/bin/bash
# LPIC-1 Training - sed Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: Basic Substitution
# ============================================================================

exercise_sed_substitute() {
    print_exercise "sed: Basic Substitution"

    local practice_file="${PRACTICE_DIR}/text/sed-practice/config.ini"

    cat << 'SCENARIO'
SCENARIO:
You need to replace 'localhost' with '127.0.0.1' in a configuration file.
Show the result without modifying the original file.

File: ~/lpic1-practice/text/sed-practice/config.ini
SCENARIO

    echo
    print_task "Replace 'localhost' with '127.0.0.1'"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"s/"*"localhost"*"127.0.0.1"* ]] || \
           [[ "$user_cmd" == *"s|"*"localhost"*"127.0.0.1"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            if [[ "$user_output" == *"127.0.0.1"* ]]; then
                echo
                print_pass "Correct!"
                echo "Result:"
                echo "$user_output" | head -8 | sed 's/^/  /'
                record_exercise_attempt "sed" "substitute" 1
                return 0
            fi
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "sed substitution syntax: s/old/new/
  This replaces 'old' with 'new'"
                    ;;
                2)
                    show_hint 2 "Full command: sed 's/pattern/replacement/' file
  Pattern: localhost, Replacement: 127.0.0.1"
                    ;;
                *)
                    show_solution "sed 's/localhost/127.0.0.1/' text/sed-practice/config.ini"
                    record_exercise_attempt "sed" "substitute" 0
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
# Exercise 2: Global Substitution
# ============================================================================

exercise_sed_global() {
    print_exercise "sed: Global Substitution"

    cat << 'SCENARIO'
SCENARIO:
A config file has multiple occurrences of 'localhost' on some lines.
You need to replace ALL occurrences, not just the first one per line.

File: ~/lpic1-practice/text/sed-practice/config.ini
SCENARIO

    echo
    print_task "Replace ALL occurrences of 'localhost' with '127.0.0.1' (global flag)"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"/g"* ]] && [[ "$user_cmd" == *"localhost"* ]]; then
            echo
            print_pass "Correct! The /g flag replaces all occurrences."
            record_exercise_attempt "sed" "global" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to use the global flag."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "By default, sed replaces only the first match per line.
  A flag makes it replace ALL matches."
                    ;;
                2)
                    show_hint 2 "Add 'g' at the end: s/old/new/g
  g = global (all occurrences)"
                    ;;
                *)
                    show_solution "sed 's/localhost/127.0.0.1/g' text/sed-practice/config.ini"
                    record_exercise_attempt "sed" "global" 0
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
# Exercise 3: Delete Lines
# ============================================================================

exercise_sed_delete() {
    print_exercise "sed: Delete Lines"

    local practice_file="${PRACTICE_DIR}/configs/sample-crontab"

    cat << 'SCENARIO'
SCENARIO:
You want to view a crontab file without comment lines (lines starting with #).
Delete all lines that begin with #.

File: ~/lpic1-practice/configs/sample-crontab
SCENARIO

    echo
    print_task "Delete lines starting with '#'"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"/^#/d"* ]] || [[ "$user_cmd" == *"/^#/"*"d"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Result (no comment lines):"
            echo "$user_output" | head -8 | sed 's/^/  /'
            record_exercise_attempt "sed" "delete" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use the 'd' command to delete lines.
  You can specify which lines using a pattern."
                    ;;
                2)
                    show_hint 2 "Pattern for 'starts with #': ^#
  Delete syntax: sed '/pattern/d' file"
                    ;;
                *)
                    show_solution "sed '/^#/d' configs/sample-crontab"
                    record_exercise_attempt "sed" "delete" 0
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
# Exercise 4: Print Specific Lines
# ============================================================================

exercise_sed_print() {
    print_exercise "sed: Print Specific Lines"

    local practice_file="${PRACTICE_DIR}/text/users.txt"

    cat << 'SCENARIO'
SCENARIO:
You need to see only lines 5 through 10 of a file.
Use sed to print only those specific lines.

File: ~/lpic1-practice/text/users.txt
SCENARIO

    echo
    print_task "Print only lines 5-10"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"-n"* ]] && [[ "$user_cmd" == *"5,10p"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Lines 5-10:"
            echo "$user_output" | sed 's/^/  /'
            record_exercise_attempt "sed" "print" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -n to suppress automatic printing,
  then use 'p' command to print specific lines."
                    ;;
                2)
                    show_hint 2 "Address range: 5,10 (lines 5 through 10)
  Syntax: sed -n '5,10p' file"
                    ;;
                *)
                    show_solution "sed -n '5,10p' text/users.txt"
                    record_exercise_attempt "sed" "print" 0
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
# Exercise 5: Delete Empty Lines
# ============================================================================

exercise_sed_empty() {
    print_exercise "sed: Delete Empty Lines"

    local practice_file="${PRACTICE_DIR}/text/sed-practice/messy-text.txt"

    cat << 'SCENARIO'
SCENARIO:
A text file has multiple empty lines that you want to remove
to clean up the output.

File: ~/lpic1-practice/text/sed-practice/messy-text.txt
SCENARIO

    echo
    print_task "Delete all empty lines"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"/^$/d"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Result (no empty lines):"
            echo "$user_output" | head -8 | sed 's/^/  /'
            record_exercise_attempt "sed" "empty" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "An empty line has nothing between start (^) and end (\$).
  Pattern for empty line: ^$"
                    ;;
                2)
                    show_hint 2 "Delete empty lines: sed '/^$/d' file
  ^$ matches lines with zero characters"
                    ;;
                *)
                    show_solution "sed '/^\$/d' text/sed-practice/messy-text.txt"
                    record_exercise_attempt "sed" "empty" 0
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

run_sed_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_sed_substitute
        exercise_sed_global
        exercise_sed_delete
        exercise_sed_print
        exercise_sed_empty
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
            read -rp "Press Enter for next exercise (or 'q' to quit)... " choice
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
        print_info "Review the lesson: lpic-train learn sed"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_sed_exercises "$@"
fi
