#!/bin/bash
# LPIC-1 Training - awk Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: Print Specific Columns
# ============================================================================

exercise_awk_columns() {
    print_exercise "awk: Print Specific Columns"

    local practice_file="${PRACTICE_DIR}/text/users.txt"

    cat << 'SCENARIO'
SCENARIO:
You need to extract usernames from the /etc/passwd-style file.
The username is the first field, separated by colons (:).

File: /opt/LPIC-1/practice/text/users.txt
SCENARIO

    echo
    print_task "Print only the first field (username) using ':' as delimiter"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"-F:"* ]] || [[ "$user_cmd" == *"-F ':'"* ]] || \
           [[ "$user_cmd" == *'-F":"'* ]]; then
            if [[ "$user_cmd" == *'$1'* ]] || [[ "$user_cmd" == *"\$1"* ]]; then
                local user_output
                user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
                echo
                print_pass "Correct!"
                echo "Usernames:"
                echo "$user_output" | head -6 | sed 's/^/  /'
                record_exercise_attempt "awk" "columns" 1
                return 0
            fi
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -F to set the field separator.
  Fields are accessed with \$1, \$2, etc."
                    ;;
                2)
                    show_hint 2 "For colon separator: -F:
  Print first field: awk '{print \$1}'"
                    ;;
                *)
                    show_solution "awk -F: '{print \$1}' text/users.txt"
                    record_exercise_attempt "awk" "columns" 0
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
# Exercise 2: Multiple Columns
# ============================================================================

exercise_awk_multi() {
    print_exercise "awk: Print Multiple Columns"

    local practice_file="${PRACTICE_DIR}/text/users.txt"

    cat << 'SCENARIO'
SCENARIO:
You need a report showing username and their shell (fields 1 and 7)
from the passwd-style file.

File: /opt/LPIC-1/practice/text/users.txt
SCENARIO

    echo
    print_task "Print fields 1 (username) and 7 (shell)"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"\$1"* ]] && [[ "$user_cmd" == *"\$7"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Username and Shell:"
            echo "$user_output" | head -6 | sed 's/^/  /'
            record_exercise_attempt "awk" "multi" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to print both \$1 and \$7."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Print multiple fields by listing them in the print statement.
  Example: print \$1, \$2"
                    ;;
                2)
                    show_hint 2 "Don't forget the field separator -F:
  awk -F: '{print \$1, \$7}' file"
                    ;;
                *)
                    show_solution "awk -F: '{print \$1, \$7}' text/users.txt"
                    record_exercise_attempt "awk" "multi" 0
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
# Exercise 3: Pattern Filtering
# ============================================================================

exercise_awk_pattern() {
    print_exercise "awk: Filter by Pattern"

    local practice_file="${PRACTICE_DIR}/text/servers.txt"

    cat << 'SCENARIO'
SCENARIO:
You need to find all servers running Ubuntu from the server inventory.

File: /opt/LPIC-1/practice/text/servers.txt
SCENARIO

    echo
    print_task "Print only lines containing 'Ubuntu'"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"/Ubuntu/"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Ubuntu servers:"
            echo "$user_output" | sed 's/^/  /'
            record_exercise_attempt "awk" "pattern" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to use a pattern to filter."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "awk can filter lines using /pattern/
  Lines matching the pattern are processed."
                    ;;
                2)
                    show_hint 2 "Syntax: awk '/pattern/' file
  This prints lines containing 'pattern'"
                    ;;
                *)
                    show_solution "awk '/Ubuntu/' text/servers.txt"
                    record_exercise_attempt "awk" "pattern" 0
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
# Exercise 4: Conditional Filtering
# ============================================================================

exercise_awk_condition() {
    print_exercise "awk: Filter by Field Value"

    local practice_file="${PRACTICE_DIR}/text/awk-practice/employees.dat"

    cat << 'SCENARIO'
SCENARIO:
You need to find employees with salary greater than 70000.
The salary is in the 5th field.

File: /opt/LPIC-1/practice/text/awk-practice/employees.dat
SCENARIO

    echo
    print_task "Print employees where field 5 (salary) > 70000"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"\$5"* ]] && [[ "$user_cmd" == *"70000"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "High earners:"
            echo "$user_output" | head -6 | sed 's/^/  /'
            record_exercise_attempt "awk" "condition" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to compare \$5 to 70000."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "awk can use conditions like \$5 > 70000
  This selects lines where field 5 exceeds 70000."
                    ;;
                2)
                    show_hint 2 "Syntax: awk 'condition' file
  Condition: \$5 > 70000"
                    ;;
                *)
                    show_solution "awk '\$5 > 70000' text/awk-practice/employees.dat"
                    record_exercise_attempt "awk" "condition" 0
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
# Exercise 5: Sum a Column
# ============================================================================

exercise_awk_sum() {
    print_exercise "awk: Sum Column Values"

    local practice_file="${PRACTICE_DIR}/text/sales.csv"

    cat << 'SCENARIO'
SCENARIO:
You need to calculate the total quantity sold from the sales data.
The quantity is in column 3 (after the header line).

File: /opt/LPIC-1/practice/text/sales.csv (comma-separated)
SCENARIO

    echo
    print_task "Sum the quantity column (column 3), skipping the header"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"sum"* ]] && [[ "$user_cmd" == *"END"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Result: $user_output"
            record_exercise_attempt "awk" "sum" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to accumulate sum and print in END block."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use a variable to accumulate: sum += \$3
  Print the total in an END block."
                    ;;
                2)
                    show_hint 2 "Structure: awk '{sum+=\$3} END{print sum}'
  Skip header with NR>1 or 'NR>1'"
                    ;;
                *)
                    show_solution "awk -F, 'NR>1 {sum+=\$3} END{print sum}' text/sales.csv"
                    record_exercise_attempt "awk" "sum" 0
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

run_awk_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_awk_columns
        exercise_awk_multi
        exercise_awk_pattern
        exercise_awk_condition
        exercise_awk_sum
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
        print_info "Review the lesson: lpic-train learn awk"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_awk_exercises "$@"
fi
