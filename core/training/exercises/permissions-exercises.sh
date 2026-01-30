#!/bin/bash
# LPIC-1 Training - Permissions Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: Numeric chmod
# ============================================================================

exercise_chmod_numeric() {
    print_exercise "chmod: Numeric Mode"

    cat << 'SCENARIO'
SCENARIO:
You need to set a script file's permissions to:
- Owner: read, write, execute (rwx = 7)
- Group: read, execute (r-x = 5)
- Others: read, execute (r-x = 5)

This is the standard permission for executable scripts.
SCENARIO

    echo
    print_task "Set permissions to 755 (rwxr-xr-x) using numeric mode"
    echo
    echo -e "${DIM}(You can use any filename - this tests your knowledge of the syntax)${NC}"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"chmod"* ]] && [[ "$user_cmd" == *"755"* ]]; then
            echo
            print_pass "Correct! 755 = rwxr-xr-x"
            echo "  Owner: rwx (4+2+1=7)"
            echo "  Group: r-x (4+0+1=5)"
            echo "  Others: r-x (4+0+1=5)"
            record_exercise_attempt "chmod" "numeric" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Numeric permissions: r=4, w=2, x=1
  Add values for each user category."
                    ;;
                2)
                    show_hint 2 "rwx = 4+2+1 = 7
  r-x = 4+0+1 = 5
  So rwxr-xr-x = 755"
                    ;;
                *)
                    show_solution "chmod 755 filename"
                    record_exercise_attempt "chmod" "numeric" 0
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
# Exercise 2: Symbolic chmod - Add
# ============================================================================

exercise_chmod_add() {
    print_exercise "chmod: Symbolic Mode - Add Permission"

    cat << 'SCENARIO'
SCENARIO:
A script file doesn't have execute permission. You need to add
execute permission for the owner only, keeping other permissions unchanged.
SCENARIO

    echo
    print_task "Add execute permission for owner (u+x)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"chmod"* ]] && [[ "$user_cmd" == *"u+x"* ]]; then
            echo
            print_pass "Correct!"
            echo "u+x adds execute for the user (owner) only."
            record_exercise_attempt "chmod" "add" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Symbolic mode uses letters: u=user, g=group, o=others
  + adds permission, - removes"
                    ;;
                2)
                    show_hint 2 "To add execute for user/owner: u+x
  Syntax: chmod u+x filename"
                    ;;
                *)
                    show_solution "chmod u+x filename"
                    record_exercise_attempt "chmod" "add" 0
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
# Exercise 3: Symbolic chmod - Remove
# ============================================================================

exercise_chmod_remove() {
    print_exercise "chmod: Symbolic Mode - Remove Permission"

    cat << 'SCENARIO'
SCENARIO:
A sensitive file is world-readable. You need to remove read permission
from others (everyone except owner and group).
SCENARIO

    echo
    print_task "Remove read permission from others (o-r)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"chmod"* ]] && [[ "$user_cmd" == *"o-r"* ]]; then
            echo
            print_pass "Correct!"
            echo "o-r removes read from others."
            record_exercise_attempt "chmod" "remove" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "o = others (world), r = read
  - removes a permission"
                    ;;
                2)
                    show_hint 2 "To remove read from others: o-r
  Syntax: chmod o-r filename"
                    ;;
                *)
                    show_solution "chmod o-r filename"
                    record_exercise_attempt "chmod" "remove" 0
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
# Exercise 4: Private File Permissions
# ============================================================================

exercise_chmod_private() {
    print_exercise "chmod: Private File"

    cat << 'SCENARIO'
SCENARIO:
You have a private key file that should only be readable/writable
by the owner. No one else should have any access.
(This is required for SSH keys!)
SCENARIO

    echo
    print_task "Set permissions to 600 (rw-------)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"chmod"* ]] && [[ "$user_cmd" == *"600"* ]]; then
            echo
            print_pass "Correct!"
            echo "600 (rw-------) is the standard for private keys."
            echo "SSH will refuse to use keys with looser permissions."
            record_exercise_attempt "chmod" "private" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Need 600 permissions."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Owner needs rw (4+2=6)
  Group and others need nothing (0)"
                    ;;
                2)
                    show_hint 2 "rw------- = 600
  chmod 600 filename"
                    ;;
                *)
                    show_solution "chmod 600 filename"
                    record_exercise_attempt "chmod" "private" 0
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
# Exercise 5: umask Calculation
# ============================================================================

exercise_umask() {
    print_exercise "umask: Understanding Default Permissions"

    cat << 'SCENARIO'
SCENARIO:
With umask 022, what permissions will a newly created file have?

Remember:
- Default file permissions: 666 (rw-rw-rw-)
- umask is subtracted from default
SCENARIO

    echo
    print_task "What permission (3 digits) will new files get with umask 022?"
    echo

    local attempts=0

    while true; do
        echo -en "Your answer: "
        read -r user_answer

        if [[ "$user_answer" == "skip" || "$user_answer" == "s" ]]; then
            return 1
        fi

        if [[ "$user_answer" == "644" ]]; then
            echo
            print_pass "Correct!"
            echo "666 - 022 = 644 (rw-r--r--)"
            record_exercise_attempt "umask" "calc" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Default file permissions are 666.
  umask removes permissions from this default."
                    ;;
                2)
                    show_hint 2 "666 (default) - 022 (umask) = ?
  Calculate each digit: 6-0=6, 6-2=4, 6-2=4"
                    ;;
                *)
                    show_solution "644"
                    echo "Files: 666 - 022 = 644"
                    echo "Directories: 777 - 022 = 755"
                    record_exercise_attempt "umask" "calc" 0
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

run_permissions_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_chmod_numeric
        exercise_chmod_add
        exercise_chmod_remove
        exercise_chmod_private
        exercise_umask
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
        print_info "Review the lesson: lpic-train learn permissions"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_permissions_exercises "$@"
fi
