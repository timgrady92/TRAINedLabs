#!/bin/bash
# LPIC-1 Training - find Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: Find by Name
# ============================================================================

exercise_find_name() {
    print_exercise "find: Search by Name"

    cat << 'SCENARIO'
SCENARIO:
You need to locate all text files (.txt) in the find-practice directory
to catalog them for documentation.

Directory: /opt/LPIC-1/practice/find-practice/
SCENARIO

    echo
    print_task "Find all files ending with .txt"
    echo

    local attempts=0
    local find_dir="${PRACTICE_DIR}/find-practice"
    local expected_count
    expected_count=$(find "$find_dir" -name '*.txt' 2>/dev/null | wc -l)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
        local user_count
        user_count=$(echo "$user_output" | grep -c '\.txt' || echo "0")

        # Check if they found the right number of .txt files
        if [[ $user_count -ge $((expected_count - 1)) ]] && [[ "$user_cmd" == *"-name"* ]]; then
            echo
            print_pass "Correct! Found $user_count .txt files."
            echo "$user_output" | head -5 | sed 's/^/  /'
            record_exercise_attempt "find" "name" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Should find $expected_count .txt files."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use find with the -name option.
  Remember to quote patterns with wildcards!"
                    ;;
                2)
                    show_hint 2 "Syntax: find <directory> -name '<pattern>'
  Pattern for .txt files: '*.txt'"
                    ;;
                *)
                    show_solution "find find-practice -name '*.txt'"
                    record_exercise_attempt "find" "name" 0
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
# Exercise 2: Find by Type
# ============================================================================

exercise_find_type() {
    print_exercise "find: Search by Type"

    cat << 'SCENARIO'
SCENARIO:
You need to list all directories (not files) within the find-practice
structure to understand the folder organization.

Directory: /opt/LPIC-1/practice/find-practice/
SCENARIO

    echo
    print_task "Find all directories (not files) in find-practice/"
    echo

    local attempts=0
    local find_dir="${PRACTICE_DIR}/find-practice"
    local expected_count
    expected_count=$(find "$find_dir" -type d 2>/dev/null | wc -l)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        local user_output
        user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

        if [[ "$user_cmd" == *"-type d"* ]] || [[ "$user_cmd" == *"-type=d"* ]]; then
            local user_count
            user_count=$(echo "$user_output" | wc -l)
            if [[ $user_count -ge $((expected_count - 1)) ]]; then
                echo
                print_pass "Correct! Found $user_count directories."
                echo "$user_output" | head -6 | sed 's/^/  /'
                record_exercise_attempt "find" "type" 1
                return 0
            fi
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Should find $expected_count directories."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "find has a -type option to filter by file type.
  Directories have a specific type code."
                    ;;
                2)
                    show_hint 2 "The type code for directories is 'd'.
  Syntax: find <path> -type d"
                    ;;
                *)
                    show_solution "find find-practice -type d"
                    echo "Type codes: f=file, d=directory, l=symlink"
                    record_exercise_attempt "find" "type" 0
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
# Exercise 3: Find by Size
# ============================================================================

exercise_find_size() {
    print_exercise "find: Search by Size"

    cat << 'SCENARIO'
SCENARIO:
You're investigating disk usage and need to find files larger than
1 megabyte in the find-practice directory.

Directory: /opt/LPIC-1/practice/find-practice/
SCENARIO

    echo
    print_task "Find files larger than 1MB"
    echo

    local attempts=0
    local find_dir="${PRACTICE_DIR}/find-practice"

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Check if using correct size syntax
        if [[ "$user_cmd" == *"-size +1M"* ]] || [[ "$user_cmd" == *"-size +1m"* ]] || \
           [[ "$user_cmd" == *"-size +1024k"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            if [[ -n "$user_output" ]]; then
                echo "Large files found:"
                echo "$user_output" | head -5 | sed 's/^/  /'
            else
                echo "No files larger than 1MB (that's fine for practice files)"
            fi
            record_exercise_attempt "find" "size" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Check your size specification."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -size option with a size modifier.
  + means 'greater than', - means 'less than'"
                    ;;
                2)
                    show_hint 2 "Size units: c=bytes, k=kilobytes, M=megabytes, G=gigabytes
  For 'larger than 1MB': -size +1M"
                    ;;
                *)
                    show_solution "find find-practice -size +1M"
                    echo "For files SMALLER than 1MB: find . -size -1M"
                    record_exercise_attempt "find" "size" 0
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
# Exercise 4: Find by Time
# ============================================================================

exercise_find_time() {
    print_exercise "find: Search by Modification Time"

    cat << 'SCENARIO'
SCENARIO:
You need to find all files modified within the last 7 days for a
backup verification report.

Directory: /opt/LPIC-1/practice/
SCENARIO

    echo
    print_task "Find files modified in the last 7 days"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Check for correct mtime syntax
        if [[ "$user_cmd" == *"-mtime -7"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            local count
            count=$(echo "$user_output" | wc -l)
            echo "Found $count recently modified files."
            record_exercise_attempt "find" "time" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -mtime for modification time.
  The value is in 24-hour periods (days)."
                    ;;
                2)
                    show_hint 2 "-mtime -7 means 'less than 7 days ago' (recent)
  -mtime +7 means 'more than 7 days ago' (old)"
                    ;;
                *)
                    show_solution "find . -mtime -7"
                    echo "Memory trick: minus = recent, plus = old"
                    record_exercise_attempt "find" "time" 0
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
# Exercise 5: Find with Exec
# ============================================================================

exercise_find_exec() {
    print_exercise "find: Execute Command on Results"

    cat << 'SCENARIO'
SCENARIO:
You need to get detailed information (ls -l) about all .sh script files
in the find-practice directory.

Directory: /opt/LPIC-1/practice/find-practice/
SCENARIO

    echo
    print_task "Find all .sh files and run 'ls -l' on each"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Check for -exec with ls
        if [[ "$user_cmd" == *"-exec"* ]] && [[ "$user_cmd" == *"ls"* ]] && \
           [[ "$user_cmd" == *"{}"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            echo "Output:"
            echo "$user_output" | head -5 | sed 's/^/  /'
            record_exercise_attempt "find" "exec" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite. Need to use -exec with ls -l."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -exec to run a command on each found file.
  {} is replaced with the filename."
                    ;;
                2)
                    show_hint 2 "-exec must end with \\; (escaped semicolon)
  Format: -exec command {} \\;"
                    ;;
                3)
                    show_hint 3 "Structure: find <path> -name '*.sh' -exec ls -l {} \\;"
                    ;;
                *)
                    show_solution "find find-practice -name '*.sh' -exec ls -l {} \\;"
                    echo "Alternative with +: find find-practice -name '*.sh' -exec ls -l {} +"
                    record_exercise_attempt "find" "exec" 0
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
# Exercise 6: Combining Tests
# ============================================================================

exercise_find_combine() {
    print_exercise "find: Combining Multiple Tests"

    cat << 'SCENARIO'
SCENARIO:
You need to find regular files (not directories) that are larger than 10KB
in the find-practice directory.

Directory: /opt/LPIC-1/practice/find-practice/
SCENARIO

    echo
    print_task "Find regular files (-type f) larger than 10KB (-size +10k)"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        # Check for both -type f and -size
        if [[ "$user_cmd" == *"-type f"* ]] && [[ "$user_cmd" == *"-size +10k"* ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true
            echo
            print_pass "Correct!"
            if [[ -n "$user_output" ]]; then
                echo "Files found:"
                echo "$user_output" | head -5 | sed 's/^/  /'
            else
                echo "(No files matching criteria - that's OK for test data)"
            fi
            record_exercise_attempt "find" "combine" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need both -type f AND -size +10k"

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Multiple conditions are combined with AND by default.
  Just list them one after another."
                    ;;
                2)
                    show_hint 2 "-type f = regular files only
  -size +10k = larger than 10 kilobytes"
                    ;;
                *)
                    show_solution "find find-practice -type f -size +10k"
                    record_exercise_attempt "find" "combine" 0
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

run_find_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_find_name
        exercise_find_type
        exercise_find_size
        exercise_find_time
        exercise_find_exec
        exercise_find_combine
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
        print_info "Review the lesson: lpic-train learn find"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_find_exercises "$@"
fi
