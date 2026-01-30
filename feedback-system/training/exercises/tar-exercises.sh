#!/bin/bash
# LPIC-1 Training - tar Exercises
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
# Exercise 1: Create a gzip archive
# ============================================================================

exercise_tar_create_gzip() {
    print_exercise "tar: Create a Gzip Compressed Archive"

    cat << 'SCENARIO'
SCENARIO:
You need to back up the text directory before making changes.
Create a compressed archive using gzip compression.

Directory: ~/lpic1-practice/text/

WHY THIS MATTERS:
Compressed backups are essential for system administration.
gzip (.tar.gz or .tgz) is the most common format on Linux.
SCENARIO

    echo
    print_task "Create a gzip-compressed archive of the text/ directory named backup.tar.gz"
    echo -e "${DIM}Tip: Type 'skip' to skip, 'hint' for a hint${NC}"
    echo

    local attempts=0
    local max_attempts=4

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == "hint" || "$user_cmd" == "h" ]]; then
            ((attempts++))
            user_cmd=""
        fi

        if [[ -n "$user_cmd" ]]; then
            # Execute in practice directory
            (cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            # Check if archive was created
            if [[ -f "${PRACTICE_DIR}/backup.tar.gz" ]]; then
                # Verify it's a valid gzip archive
                if file "${PRACTICE_DIR}/backup.tar.gz" | grep -q "gzip"; then
                    echo
                    print_pass "Correct! Archive created successfully."
                    echo -e "${DIM}Archive size: $(du -h "${PRACTICE_DIR}/backup.tar.gz" | cut -f1)${NC}"
                    rm -f "${PRACTICE_DIR}/backup.tar.gz"  # Clean up
                    record_exercise_attempt "tar" "create_gzip" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Archive not created or not in correct format."
        fi

        if [[ "${LPIC_NO_HINTS:-}" == "1" ]]; then
            echo -e "${DIM}(Hints disabled)${NC}"
        else
            case $attempts in
                1)
                    show_hint 1 "tar uses -c to Create, -z for gzip compression, -f for filename.
  Think: czf = Create Zipped File"
                    ;;
                2)
                    show_hint 2 "The basic syntax is: tar -czf archive.tar.gz source/
  -c = create, -z = gzip, -f = file"
                    ;;
                3)
                    show_hint 3 "Add -v for verbose output to see what's happening:
  tar -czvf backup.tar.gz text/"
                    ;;
                *)
                    show_solution "tar -czvf backup.tar.gz text/"
                    echo
                    echo "Breakdown:"
                    echo "  -c  Create a new archive"
                    echo "  -z  Compress with gzip"
                    echo "  -v  Verbose (show files being added)"
                    echo "  -f  Specify filename (must come right before filename)"
                    rm -f "${PRACTICE_DIR}/backup.tar.gz"  # Clean up
                    record_exercise_attempt "tar" "create_gzip" 0
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
# Exercise 2: Create a bzip2 archive
# ============================================================================

exercise_tar_create_bzip2() {
    print_exercise "tar: Create a Bzip2 Compressed Archive"

    cat << 'SCENARIO'
SCENARIO:
You need to create a highly compressed archive for long-term storage.
Bzip2 typically provides better compression than gzip (but is slower).

Directory: ~/lpic1-practice/logs/
SCENARIO

    echo
    print_task "Create a bzip2-compressed archive of the logs/ directory named logs-archive.tar.bz2"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            (cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            if [[ -f "${PRACTICE_DIR}/logs-archive.tar.bz2" ]]; then
                if file "${PRACTICE_DIR}/logs-archive.tar.bz2" | grep -qi "bzip2"; then
                    echo
                    print_pass "Correct! Bzip2 archive created."
                    rm -f "${PRACTICE_DIR}/logs-archive.tar.bz2"
                    record_exercise_attempt "tar" "create_bzip2" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Archive not created or wrong compression type."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Bzip2 uses -j instead of -z.
  Think: j for bzip2 (historical reason: b was taken)"
                    ;;
                2)
                    show_hint 2 "The syntax is: tar -cjf archive.tar.bz2 source/
  -j = bzip2 compression"
                    ;;
                *)
                    show_solution "tar -cjvf logs-archive.tar.bz2 logs/"
                    rm -f "${PRACTICE_DIR}/logs-archive.tar.bz2"
                    record_exercise_attempt "tar" "create_bzip2" 0
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
# Exercise 3: List archive contents
# ============================================================================

exercise_tar_list() {
    print_exercise "tar: List Archive Contents"

    # Create a test archive first
    (cd "$PRACTICE_DIR" && tar -czf test-archive.tar.gz text/ 2>/dev/null)

    cat << 'SCENARIO'
SCENARIO:
You've received an archive and need to see what's inside WITHOUT extracting it.
This is a common safety practice before extracting unknown archives.

File: ~/lpic1-practice/test-archive.tar.gz
SCENARIO

    echo
    print_task "List the contents of test-archive.tar.gz without extracting"
    echo

    local attempts=0
    local expected_output
    expected_output=$(cd "$PRACTICE_DIR" && tar -tzf test-archive.tar.gz 2>/dev/null | head -5)

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            rm -f "${PRACTICE_DIR}/test-archive.tar.gz"
            return 1
        fi

        local user_output
        if [[ -n "$user_cmd" ]]; then
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1 | head -10) || true

            # Check if output looks like a listing (contains paths)
            if [[ "$user_output" == *"text/"* ]] && [[ "$user_cmd" == *"-t"* || "$user_cmd" == *"--list"* ]]; then
                echo
                print_pass "Correct! Archive contents listed."
                rm -f "${PRACTICE_DIR}/test-archive.tar.gz"
                record_exercise_attempt "tar" "list" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "That didn't list the archive contents correctly."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -t to list (Table of contents).
  Think: t = table/list"
                    ;;
                2)
                    show_hint 2 "Combine with -z for gzip and -f for file:
  tar -tzf archive.tar.gz"
                    ;;
                *)
                    show_solution "tar -tzvf test-archive.tar.gz"
                    echo "Or simply: tar -tzf test-archive.tar.gz"
                    rm -f "${PRACTICE_DIR}/test-archive.tar.gz"
                    record_exercise_attempt "tar" "list" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && { rm -f "${PRACTICE_DIR}/test-archive.tar.gz"; return 1; }
    done
}

# ============================================================================
# Exercise 4: Extract to specific directory
# ============================================================================

exercise_tar_extract() {
    print_exercise "tar: Extract to Specific Directory"

    # Create a test archive
    (cd "$PRACTICE_DIR" && tar -czf extract-test.tar.gz configs/ 2>/dev/null)
    mkdir -p "${PRACTICE_DIR}/restore-target"

    cat << 'SCENARIO'
SCENARIO:
You need to restore a backup to a specific location rather than
the current directory. This is crucial for disaster recovery.

Archive: ~/lpic1-practice/extract-test.tar.gz
Target:  ~/lpic1-practice/restore-target/
SCENARIO

    echo
    print_task "Extract extract-test.tar.gz into the restore-target/ directory"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            rm -f "${PRACTICE_DIR}/extract-test.tar.gz"
            rm -rf "${PRACTICE_DIR}/restore-target"
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            (cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            # Check if files were extracted to target
            if [[ -d "${PRACTICE_DIR}/restore-target/configs" ]]; then
                echo
                print_pass "Correct! Files extracted to restore-target/"
                echo -e "${DIM}Contents:${NC}"
                ls "${PRACTICE_DIR}/restore-target/" | head -5 | sed 's/^/  /'
                rm -f "${PRACTICE_DIR}/extract-test.tar.gz"
                rm -rf "${PRACTICE_DIR}/restore-target"
                record_exercise_attempt "tar" "extract" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Files not extracted to the correct location."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use -C to specify the target directory.
  Think: C = Change to directory before extracting"
                    ;;
                2)
                    show_hint 2 "Syntax: tar -xzf archive.tar.gz -C target-dir/
  -x = extract, -C = change directory"
                    ;;
                *)
                    show_solution "tar -xzvf extract-test.tar.gz -C restore-target/"
                    rm -f "${PRACTICE_DIR}/extract-test.tar.gz"
                    rm -rf "${PRACTICE_DIR}/restore-target"
                    record_exercise_attempt "tar" "extract" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && {
            rm -f "${PRACTICE_DIR}/extract-test.tar.gz"
            rm -rf "${PRACTICE_DIR}/restore-target"
            return 1
        }
    done
}

# ============================================================================
# Exercise 5: Extract specific file from archive
# ============================================================================

exercise_tar_extract_single() {
    print_exercise "tar: Extract Single File from Archive"

    # Create test archive with known structure
    (cd "$PRACTICE_DIR" && tar -czf single-extract.tar.gz text/users.txt text/servers.txt text/groups.txt 2>/dev/null)

    cat << 'SCENARIO'
SCENARIO:
You have a large backup archive but only need to restore ONE specific file.
Extracting the entire archive would waste time and disk space.

Archive: ~/lpic1-practice/single-extract.tar.gz
You need: text/users.txt (only this file!)
SCENARIO

    echo
    print_task "Extract ONLY text/users.txt from single-extract.tar.gz"
    echo

    local attempts=0
    # Remove any existing file first
    rm -f "${PRACTICE_DIR}/text/users.txt.restored"

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            rm -f "${PRACTICE_DIR}/single-extract.tar.gz"
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            # Save original to detect extraction
            local orig_mtime=""
            [[ -f "${PRACTICE_DIR}/text/users.txt" ]] && orig_mtime=$(stat -c %Y "${PRACTICE_DIR}/text/users.txt" 2>/dev/null || true)

            (cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            # Check if command targeted just users.txt
            if [[ "$user_cmd" == *"users.txt"* ]] && [[ "$user_cmd" == *"-x"* || "$user_cmd" == *"--extract"* ]]; then
                echo
                print_pass "Correct! Single file extracted."
                echo -e "${DIM}Tip: You can extract multiple specific files by listing them:${NC}"
                echo -e "${DIM}  tar -xzf archive.tar.gz path/file1 path/file2${NC}"
                rm -f "${PRACTICE_DIR}/single-extract.tar.gz"
                record_exercise_attempt "tar" "extract_single" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to extract specifically text/users.txt"
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "You can specify which file(s) to extract after the archive name.
  tar -xzf archive.tar.gz path/to/file"
                    ;;
                2)
                    show_hint 2 "The path must match exactly as shown in 'tar -tzf':
  tar -xzf single-extract.tar.gz text/users.txt"
                    ;;
                *)
                    show_solution "tar -xzvf single-extract.tar.gz text/users.txt"
                    rm -f "${PRACTICE_DIR}/single-extract.tar.gz"
                    record_exercise_attempt "tar" "extract_single" 0
                    return 1
                    ;;
            esac
        fi

        echo
        read -rp "Try again? [Y/n/skip] " choice
        [[ "$choice" == "n" ]] && { rm -f "${PRACTICE_DIR}/single-extract.tar.gz"; return 1; }
    done
}

# ============================================================================
# Exercise 6: Create xz archive (best compression)
# ============================================================================

exercise_tar_create_xz() {
    print_exercise "tar: Create an XZ Compressed Archive"

    cat << 'SCENARIO'
SCENARIO:
You need maximum compression for archival storage. XZ provides
the best compression ratio (but is slower than gzip/bzip2).

Directory: ~/lpic1-practice/configs/

EXAM NOTE: xz compression uses -J flag (capital J).
SCENARIO

    echo
    print_task "Create an xz-compressed archive of configs/ named configs-archive.tar.xz"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            (cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            if [[ -f "${PRACTICE_DIR}/configs-archive.tar.xz" ]]; then
                if file "${PRACTICE_DIR}/configs-archive.tar.xz" | grep -qi "xz"; then
                    echo
                    print_pass "Correct! XZ archive created."
                    echo -e "${DIM}XZ provides ~30% better compression than gzip${NC}"
                    rm -f "${PRACTICE_DIR}/configs-archive.tar.xz"
                    record_exercise_attempt "tar" "create_xz" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Archive not created or wrong compression type."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "XZ uses -J (capital J) for compression.
  Memory trick: J is 'Just better' compression"
                    ;;
                2)
                    show_hint 2 "Syntax: tar -cJf archive.tar.xz source/
  -J = xz compression"
                    ;;
                *)
                    show_solution "tar -cJvf configs-archive.tar.xz configs/"
                    echo
                    echo "Compression comparison (best to worst ratio):"
                    echo "  -J  xz     (.tar.xz)  - Best compression, slowest"
                    echo "  -j  bzip2  (.tar.bz2) - Good compression"
                    echo "  -z  gzip   (.tar.gz)  - Fast, moderate compression"
                    rm -f "${PRACTICE_DIR}/configs-archive.tar.xz"
                    record_exercise_attempt "tar" "create_xz" 0
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

run_tar_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_tar_create_gzip
        exercise_tar_create_bzip2
        exercise_tar_list
        exercise_tar_extract
        exercise_tar_extract_single
        exercise_tar_create_xz
    )

    local total=${#exercises[@]}
    [[ $count -gt $total ]] && count=$total

    local correct=0
    local attempted=0
    local start_time
    start_time=$(date +%s)

    # Session intro
    echo
    echo -e "${BOLD}${CYAN}tar Practice Session${NC}"
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
        print_pass "Excellent! Your tar skills are solid."
        echo
        echo -e "${DIM}Key flags to remember:${NC}"
        echo "  -c create  -x extract  -t list"
        echo "  -z gzip    -j bzip2    -J xz"
        echo "  -f file    -v verbose  -C directory"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good progress! Keep practicing the compression flags."
    else
        print_info "Review the lesson: lpic1 learn tar"
        echo
        echo -e "${CYAN}Compression flag memory trick:${NC}"
        echo "  -z (gzip)  = z is for zip (common)"
        echo "  -j (bzip2) = j because b was taken"
        echo "  -J (xz)    = J is 'Just better'"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_tar_exercises "$@"
fi
