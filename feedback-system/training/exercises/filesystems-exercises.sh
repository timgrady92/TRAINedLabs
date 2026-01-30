#!/bin/bash
# LPIC-1 Training - Filesystems Exercises
# Guided exercises for disk and filesystem management

# Ensure common functions are loaded
if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# Load learning helpers for enhanced feedback
LEARNING_HELPERS="${SCRIPT_DIR}/training/learning-helpers.sh"
[[ -f "$LEARNING_HELPERS" ]] && source "$LEARNING_HELPERS"

# ============================================================================
# Exercise 1: Check disk usage with df
# ============================================================================

exercise_fs_df() {
    print_exercise "df: Display Disk Space Usage"

    cat << 'SCENARIO'
SCENARIO:
A user reports they can't save files. You need to check if the disk is full.
The df command shows filesystem disk space usage.

WHY THIS MATTERS:
"Disk full" is one of the most common issues sysadmins troubleshoot.
You need to quickly identify which filesystem is running out of space.
SCENARIO

    echo
    print_task "Show disk usage for all filesystems in human-readable format"
    echo -e "${DIM}Tip: Type 'skip' to skip, 'hint' for a hint${NC}"
    echo

    local attempts=0

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
            local user_output
            user_output=$(eval "$user_cmd" 2>&1) || true

            # Check if output looks like df -h (has headers and human sizes)
            if [[ "$user_cmd" == *"df"* ]] && [[ "$user_cmd" == *"-h"* || "$user_cmd" == *"--human"* ]]; then
                if [[ "$user_output" == *"Filesystem"* ]] || [[ "$user_output" == *"Size"* ]]; then
                    echo
                    print_pass "Correct!"
                    echo -e "${DIM}Output shows filesystems with human-readable sizes (K, M, G)${NC}"
                    record_exercise_attempt "filesystems" "df" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Not quite. Need human-readable output from df."
        fi

        if [[ "${LPIC_NO_HINTS:-}" == "1" ]]; then
            echo -e "${DIM}(Hints disabled)${NC}"
        else
            case $attempts in
                1)
                    show_hint 1 "The df command shows disk free space.
  There's an option for human-readable output (K, M, G instead of blocks)."
                    ;;
                2)
                    show_hint 2 "The option is -h (human-readable).
  Syntax: df -h"
                    ;;
                *)
                    show_solution "df -h"
                    echo
                    echo "Related options:"
                    echo "  df -h         Human-readable sizes"
                    echo "  df -T         Show filesystem type"
                    echo "  df -i         Show inode usage"
                    echo "  df -h /home   Show specific filesystem"
                    record_exercise_attempt "filesystems" "df" 0
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
# Exercise 2: Check directory size with du
# ============================================================================

exercise_fs_du() {
    print_exercise "du: Estimate Directory Size"

    cat << 'SCENARIO'
SCENARIO:
You've identified a full filesystem. Now you need to find which directories
are consuming the most space. The du command shows directory sizes.

Directory: ~/lpic1-practice/
SCENARIO

    echo
    print_task "Show the total size of the practice directory in human-readable format"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(cd "$PRACTICE_DIR" && eval "$user_cmd" 2>&1) || true

            # Check if using du with -h and -s (summary)
            if [[ "$user_cmd" == *"du"* ]] && [[ "$user_cmd" == *"-h"* || "$user_cmd" == *"--human"* ]]; then
                if [[ "$user_cmd" == *"-s"* || "$user_cmd" == *"--summarize"* ]]; then
                    echo
                    print_pass "Correct! Summary size displayed."
                    record_exercise_attempt "filesystems" "du" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Need human-readable summary of directory size."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The du command shows disk usage.
  Use -s for summary (total only) and -h for human-readable."
                    ;;
                2)
                    show_hint 2 "Combine -s and -h:
  du -sh directory/"
                    ;;
                *)
                    show_solution "du -sh ."
                    echo "Or: du -sh ~/lpic1-practice"
                    echo
                    echo "Useful du variations:"
                    echo "  du -sh *       Size of each item in current dir"
                    echo "  du -h --max-depth=1  One level deep"
                    echo "  du -sh * | sort -h   Sorted by size"
                    record_exercise_attempt "filesystems" "du" 0
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
# Exercise 3: View mount points
# ============================================================================

exercise_fs_mount_view() {
    print_exercise "mount: View Mounted Filesystems"

    cat << 'SCENARIO'
SCENARIO:
You need to verify which filesystems are currently mounted and their mount options.
The mount command without arguments shows all current mounts.

WHY THIS MATTERS:
Understanding mount points is essential for troubleshooting storage issues
and verifying that filesystems are mounted with correct options.
SCENARIO

    echo
    print_task "Display all currently mounted filesystems"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(eval "$user_cmd" 2>&1) || true

            # Accept mount, findmnt, or cat /proc/mounts
            if [[ "$user_cmd" == "mount" ]] || \
               [[ "$user_cmd" == *"findmnt"* ]] || \
               [[ "$user_cmd" == *"/proc/mounts"* ]] || \
               [[ "$user_cmd" == *"/etc/mtab"* ]]; then
                if [[ "$user_output" == *"on"* ]] || [[ "$user_output" == *"TARGET"* ]]; then
                    echo
                    print_pass "Correct! Mount information displayed."
                    record_exercise_attempt "filesystems" "mount_view" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Need to show mounted filesystems."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The mount command without arguments shows all mounts.
  Or try findmnt for a tree view."
                    ;;
                2)
                    show_hint 2 "Simply type: mount
  Or for better formatting: findmnt"
                    ;;
                *)
                    show_solution "mount"
                    echo "Better alternatives:"
                    echo "  findmnt           Tree view of mounts"
                    echo "  findmnt -t ext4   Filter by filesystem type"
                    echo "  cat /proc/mounts  Raw kernel mount table"
                    record_exercise_attempt "filesystems" "mount_view" 0
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
# Exercise 4: View fstab entries
# ============================================================================

exercise_fs_fstab() {
    print_exercise "/etc/fstab: View Persistent Mount Configuration"

    cat << 'SCENARIO'
SCENARIO:
You need to verify what filesystems are configured to mount at boot.
The /etc/fstab file defines persistent mounts.

EXAM NOTE: Understanding fstab fields is a key LPIC-1 objective:
  device  mountpoint  fstype  options  dump  pass
SCENARIO

    echo
    print_task "Display the contents of /etc/fstab"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(eval "$user_cmd" 2>&1) || true

            # Accept cat, less, more, head, view of /etc/fstab
            if [[ "$user_cmd" == *"/etc/fstab"* ]]; then
                echo
                print_pass "Correct! fstab displayed."
                echo
                echo -e "${DIM}fstab fields (left to right):${NC}"
                echo "  1. Device/UUID   - What to mount"
                echo "  2. Mount point   - Where to mount"
                echo "  3. Filesystem    - Type (ext4, xfs, etc.)"
                echo "  4. Options       - Mount options"
                echo "  5. Dump          - Backup flag (usually 0)"
                echo "  6. Pass          - fsck order (0=skip, 1=root, 2=other)"
                record_exercise_attempt "filesystems" "fstab" 1
                return 0
            fi

            ((attempts++))
            echo
            print_fail "Need to view /etc/fstab"
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use cat or less to view the file.
  The path is /etc/fstab"
                    ;;
                *)
                    show_solution "cat /etc/fstab"
                    echo "Or: less /etc/fstab (for paging)"
                    record_exercise_attempt "filesystems" "fstab" 0
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
# Exercise 5: Check filesystem type
# ============================================================================

exercise_fs_type() {
    print_exercise "Identify Filesystem Type"

    cat << 'SCENARIO'
SCENARIO:
You need to identify the filesystem type used on the root partition.
This is important when troubleshooting or planning maintenance.
SCENARIO

    echo
    print_task "Show the filesystem type of the root filesystem (/)"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(eval "$user_cmd" 2>&1) || true

            # Accept various methods to show filesystem type
            if [[ "$user_cmd" == *"df -T"* ]] || \
               [[ "$user_cmd" == *"df --print-type"* ]] || \
               [[ "$user_cmd" == *"findmnt"* ]] || \
               [[ "$user_cmd" == *"lsblk -f"* ]] || \
               [[ "$user_cmd" == *"blkid"* ]]; then
                if [[ "$user_output" == *"ext4"* ]] || \
                   [[ "$user_output" == *"xfs"* ]] || \
                   [[ "$user_output" == *"btrfs"* ]] || \
                   [[ "$user_output" == *"Type"* ]]; then
                    echo
                    print_pass "Correct! Filesystem type identified."
                    record_exercise_attempt "filesystems" "type" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Need to show filesystem type."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "df has an option to show filesystem type.
  Or try lsblk -f for a detailed view."
                    ;;
                2)
                    show_hint 2 "Use df -T to show the Type column:
  df -T /"
                    ;;
                *)
                    show_solution "df -T /"
                    echo "Alternatives:"
                    echo "  findmnt -n -o FSTYPE /"
                    echo "  lsblk -f"
                    echo "  blkid"
                    record_exercise_attempt "filesystems" "type" 0
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
# Exercise 6: Check inode usage
# ============================================================================

exercise_fs_inodes() {
    print_exercise "df: Check Inode Usage"

    cat << 'SCENARIO'
SCENARIO:
A filesystem shows space available but users can't create new files.
This is a classic symptom of inode exhaustion - the filesystem has run
out of inodes (file entries) even though there's disk space.

WHY THIS MATTERS:
Inode exhaustion is common with mail servers or applications that
create many small files. You must check both space AND inodes.
SCENARIO

    echo
    print_task "Display inode usage for all filesystems"
    echo

    local attempts=0

    while true; do
        read -rp "Your command: " user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ -n "$user_cmd" ]]; then
            local user_output
            user_output=$(eval "$user_cmd" 2>&1) || true

            # Check for df -i
            if [[ "$user_cmd" == *"df"* ]] && [[ "$user_cmd" == *"-i"* || "$user_cmd" == *"--inodes"* ]]; then
                if [[ "$user_output" == *"Inodes"* ]] || [[ "$user_output" == *"IUse%"* ]]; then
                    echo
                    print_pass "Correct! Inode usage displayed."
                    echo -e "${DIM}IUse% shows percentage of inodes used.${NC}"
                    echo -e "${DIM}100% = no more files can be created!${NC}"
                    record_exercise_attempt "filesystems" "inodes" 1
                    return 0
                fi
            fi

            ((attempts++))
            echo
            print_fail "Need to show inode information with df."
        fi

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "df has an option to show inode statistics instead of blocks.
  Think: i for inodes"
                    ;;
                *)
                    show_solution "df -i"
                    echo "Or combine with human-readable: df -ih (though inodes are just counts)"
                    record_exercise_attempt "filesystems" "inodes" 0
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

run_filesystems_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_fs_df
        exercise_fs_du
        exercise_fs_mount_view
        exercise_fs_fstab
        exercise_fs_type
        exercise_fs_inodes
    )

    local total=${#exercises[@]}
    [[ $count -gt $total ]] && count=$total

    local correct=0
    local attempted=0
    local start_time
    start_time=$(date +%s)

    # Session intro
    echo
    echo -e "${BOLD}${CYAN}Filesystems Practice Session${NC}"
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
        print_pass "Excellent! Your filesystem skills are solid."
        echo
        echo -e "${DIM}Key commands to remember:${NC}"
        echo "  df -h   Show disk space (human-readable)"
        echo "  df -i   Show inode usage"
        echo "  df -T   Show filesystem types"
        echo "  du -sh  Show directory size"
        echo "  mount   Show mounted filesystems"
        echo "  findmnt Better mount display"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good progress! Review df and du options."
    else
        print_info "Review the lesson: lpic1 learn filesystems"
        echo
        echo -e "${CYAN}Quick reference:${NC}"
        echo "  df = disk free (filesystem level)"
        echo "  du = disk usage (directory level)"
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_filesystems_exercises "$@"
fi
