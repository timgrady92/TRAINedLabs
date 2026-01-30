#!/bin/bash
# LPIC-1 Training - User Administration Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: Create User
# ============================================================================

exercise_useradd() {
    print_exercise "useradd: Create a New User"

    cat << 'SCENARIO'
SCENARIO:
You need to create a new user account for an employee named 'john'.
The user should have a home directory created automatically.
SCENARIO

    echo
    print_task "Create user 'john' with a home directory"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"useradd"* ]] && [[ "$user_cmd" == *"-m"* ]] && \
           [[ "$user_cmd" == *"john"* ]]; then
            echo
            print_pass "Correct!"
            echo "useradd -m creates the home directory automatically."
            record_exercise_attempt "useradd" "create" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Need -m to create home directory."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "useradd creates users, but by default doesn't create home.
  There's an option to make home directory."
                    ;;
                2)
                    show_hint 2 "The -m option creates the home directory.
  Syntax: useradd -m username"
                    ;;
                *)
                    show_solution "useradd -m john"
                    echo "Optional: Add -s /bin/bash for bash shell"
                    record_exercise_attempt "useradd" "create" 0
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
# Exercise 2: Add User to Group
# ============================================================================

exercise_usermod_group() {
    print_exercise "usermod: Add User to Group"

    cat << 'SCENARIO'
SCENARIO:
User 'john' needs to be added to the 'docker' group so he can
run Docker containers. Don't remove him from his existing groups!
SCENARIO

    echo
    print_task "Add 'john' to the 'docker' group (append, don't replace)"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"usermod"* ]] && [[ "$user_cmd" == *"-aG"* ]] && \
           [[ "$user_cmd" == *"docker"* ]] && [[ "$user_cmd" == *"john"* ]]; then
            echo
            print_pass "Correct!"
            echo "-a appends (crucial!), -G specifies the group."
            echo -e "${RED}Without -a, all other groups would be removed!${NC}"
            record_exercise_attempt "usermod" "group" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need both -a and -G flags."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "usermod -G sets supplementary groups.
  But alone, it REPLACES all groups - dangerous!"
                    ;;
                2)
                    show_hint 2 "Use -a with -G to APPEND instead of replace.
  Syntax: usermod -aG groupname username"
                    ;;
                *)
                    show_solution "usermod -aG docker john"
                    echo "CRITICAL: Always use -aG together, never just -G"
                    record_exercise_attempt "usermod" "group" 0
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
# Exercise 3: Force Password Change
# ============================================================================

exercise_passwd_expire() {
    print_exercise "passwd: Force Password Change"

    cat << 'SCENARIO'
SCENARIO:
A new user has been given a temporary password. You need to force
them to change it at their next login.
SCENARIO

    echo
    print_task "Force user 'john' to change password at next login"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Accept passwd -e or chage -d 0
        if [[ "$user_cmd" == *"passwd"* ]] && [[ "$user_cmd" == *"-e"* ]] && \
           [[ "$user_cmd" == *"john"* ]]; then
            echo
            print_pass "Correct!"
            echo "passwd -e expires the password, forcing change at login."
            record_exercise_attempt "passwd" "expire" 1
            return 0
        elif [[ "$user_cmd" == *"chage"* ]] && [[ "$user_cmd" == *"-d 0"* ]] && \
             [[ "$user_cmd" == *"john"* ]]; then
            echo
            print_pass "Correct! (Using chage)"
            echo "chage -d 0 sets last change to epoch, forcing change."
            record_exercise_attempt "passwd" "expire" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "passwd has an option to expire the password,
  which forces the user to change it at next login."
                    ;;
                2)
                    show_hint 2 "Use -e to expire: passwd -e username
  Alternative: chage -d 0 username"
                    ;;
                *)
                    show_solution "passwd -e john"
                    echo "Or: chage -d 0 john"
                    record_exercise_attempt "passwd" "expire" 0
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
# Exercise 4: Delete User
# ============================================================================

exercise_userdel() {
    print_exercise "userdel: Remove User"

    cat << 'SCENARIO'
SCENARIO:
An employee has left the company. You need to delete their account
and their home directory to free up space.
SCENARIO

    echo
    print_task "Delete user 'john' and their home directory"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"userdel"* ]] && [[ "$user_cmd" == *"-r"* ]] && \
           [[ "$user_cmd" == *"john"* ]]; then
            echo
            print_pass "Correct!"
            echo "userdel -r removes the user AND their home directory."
            record_exercise_attempt "userdel" "delete" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need -r to remove home directory."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "userdel alone removes the user but keeps their files.
  There's an option to remove home directory too."
                    ;;
                2)
                    show_hint 2 "Use -r to remove home directory.
  Syntax: userdel -r username"
                    ;;
                *)
                    show_solution "userdel -r john"
                    echo "Note: Backup important files first!"
                    record_exercise_attempt "userdel" "delete" 0
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
# Exercise 5: View User Info
# ============================================================================

exercise_id() {
    print_exercise "id: View User Information"

    cat << 'SCENARIO'
SCENARIO:
You need to check a user's UID, GID, and group memberships.
This is useful for debugging permission issues.
SCENARIO

    echo
    print_task "View UID, GID, and groups for the current user"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == "id" ]] || [[ "$user_cmd" == "id "* ]]; then
            echo
            print_pass "Correct!"
            echo "Result:"
            id | sed 's/^/  /'
            record_exercise_attempt "id" "view" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "There's a simple command that shows user identity.
  It shows UID, GID, and group memberships."
                    ;;
                2)
                    show_hint 2 "The command is: id
  For another user: id username"
                    ;;
                *)
                    show_solution "id"
                    record_exercise_attempt "id" "view" 0
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

run_users_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_useradd
        exercise_usermod_group
        exercise_passwd_expire
        exercise_userdel
        exercise_id
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
        print_info "Review the lesson: lpic-train learn users"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_users_exercises "$@"
fi
