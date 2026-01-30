#!/bin/bash
# LPIC-1 Training - find Lesson
# Objective: 103.3 - Perform basic file management

lesson_find() {
    print_header "find - Search for Files"

    cat << 'INTRO'
find searches the directory tree starting from the specified path(s),
evaluating expressions for each file found. It's one of the most
powerful and flexible commands for locating files.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Finding files by name, size, or modification time"
    echo "  ${BULLET} Cleaning up old temporary files"
    echo "  ${BULLET} Finding files with specific permissions (security audits)"
    echo "  ${BULLET} Batch operations on matching files"
    echo "  ${BULLET} Finding large files consuming disk space"

    wait_for_user

    # Basic Syntax
    print_subheader "Basic Syntax"

    echo -e "${BOLD}find [path...] [expression]${NC}"
    echo
    echo "  path       - Where to start searching (default: current directory)"
    echo "  expression - Tests and actions to apply"
    echo

    echo -e "${CYAN}Example: Find all .txt files in current directory${NC}"
    echo "  find . -name '*.txt'"

    wait_for_user

    # Find by Name
    print_subheader "Finding by Name"

    echo -e "  ${CYAN}-name${NC} pattern      Case-sensitive filename match"
    echo -e "  ${CYAN}-iname${NC} pattern     Case-insensitive filename match"
    echo -e "  ${CYAN}-path${NC} pattern      Match against full path"
    echo -e "  ${CYAN}-regex${NC} pattern     Match path with regex"
    echo
    echo -e "${YELLOW}Note: Use quotes around patterns with wildcards!${NC}"

    local find_dir
    find_dir=$(get_practice_file "find" "")

    if [[ -d "$find_dir" ]]; then
        echo
        echo -e "${CYAN}Example: Find all .txt files${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -name '*.txt'"
        echo -e "${DIM}Output:${NC}"
        find "$find_dir" -name '*.txt' 2>/dev/null | head -8 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Find files starting with 'file'${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -name 'file*'"
        echo -e "${DIM}Output:${NC}"
        find "$find_dir" -name 'file*' 2>/dev/null | head -6 | sed 's/^/  /'
    fi

    wait_for_user

    # Find by Type
    print_subheader "Finding by Type"

    echo -e "${BOLD}File types (-type):${NC}"
    echo -e "  ${CYAN}f${NC}   Regular file"
    echo -e "  ${CYAN}d${NC}   Directory"
    echo -e "  ${CYAN}l${NC}   Symbolic link"
    echo -e "  ${CYAN}b${NC}   Block device"
    echo -e "  ${CYAN}c${NC}   Character device"
    echo -e "  ${CYAN}p${NC}   Named pipe (FIFO)"
    echo -e "  ${CYAN}s${NC}   Socket"

    if [[ -d "$find_dir" ]]; then
        echo
        echo -e "${CYAN}Example: Find all directories${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -type d"
        echo -e "${DIM}Output:${NC}"
        find "$find_dir" -type d 2>/dev/null | head -6 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Find only regular files${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -type f | head -5"
    fi

    wait_for_user

    # Find by Size
    print_subheader "Finding by Size"

    echo -e "${BOLD}Size specifiers (-size):${NC}"
    echo -e "  ${CYAN}c${NC}   Bytes"
    echo -e "  ${CYAN}k${NC}   Kilobytes (1024 bytes)"
    echo -e "  ${CYAN}M${NC}   Megabytes (1024 KB)"
    echo -e "  ${CYAN}G${NC}   Gigabytes (1024 MB)"
    echo
    echo -e "${BOLD}Modifiers:${NC}"
    echo -e "  ${CYAN}+N${NC}  Greater than N"
    echo -e "  ${CYAN}-N${NC}  Less than N"
    echo -e "  ${CYAN}N${NC}   Exactly N"

    if [[ -d "$find_dir" ]]; then
        echo
        echo -e "${CYAN}Example: Find files larger than 1MB${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -size +1M"
        echo -e "${DIM}Output:${NC}"
        find "$find_dir" -size +1M 2>/dev/null | sed 's/^/  /' || echo "  (no files >1MB)"
        echo

        echo -e "${CYAN}Example: Find files between 10KB and 100KB${NC}"
        echo -e "${BOLD}Command:${NC} find find-practice -size +10k -size -100k"
    fi

    wait_for_user

    # Find by Time
    print_subheader "Finding by Time"

    echo -e "${BOLD}Time options:${NC}"
    echo -e "  ${CYAN}-mtime N${NC}   Modified N*24 hours ago"
    echo -e "  ${CYAN}-atime N${NC}   Accessed N*24 hours ago"
    echo -e "  ${CYAN}-ctime N${NC}   Changed (metadata) N*24 hours ago"
    echo -e "  ${CYAN}-mmin N${NC}    Modified N minutes ago"
    echo -e "  ${CYAN}-amin N${NC}    Accessed N minutes ago"
    echo -e "  ${CYAN}-newer F${NC}   Modified more recently than file F"
    echo
    echo -e "${BOLD}Modifiers:${NC}"
    echo "  +7   More than 7 days ago"
    echo "  -7   Less than 7 days ago"
    echo "   7   Exactly 7 days ago (rarely useful)"

    echo
    echo -e "${CYAN}Example: Find files modified in last 7 days${NC}"
    echo "  find /var/log -mtime -7"
    echo
    echo -e "${CYAN}Example: Find files NOT accessed in 30 days${NC}"
    echo "  find /home -atime +30"
    echo
    echo -e "${CYAN}Example: Find files modified in last hour${NC}"
    echo "  find . -mmin -60"

    wait_for_user

    # Find by Permissions
    print_subheader "Finding by Permissions"

    echo -e "${BOLD}Permission options:${NC}"
    echo -e "  ${CYAN}-perm mode${NC}       Exact permission match"
    echo -e "  ${CYAN}-perm -mode${NC}      All of these bits set"
    echo -e "  ${CYAN}-perm /mode${NC}      Any of these bits set"
    echo

    echo -e "${CYAN}Example: Find world-writable files${NC}"
    echo "  find /var -perm -002"
    echo

    echo -e "${CYAN}Example: Find SUID executables${NC}"
    echo "  find /usr -perm -4000"
    echo

    echo -e "${CYAN}Example: Find files with exact permissions 755${NC}"
    echo "  find . -perm 755"
    echo

    echo -e "${CYAN}Example: Find files writable by group OR others${NC}"
    echo "  find . -perm /022"

    wait_for_user

    # Find by Owner
    print_subheader "Finding by Owner"

    echo -e "  ${CYAN}-user name${NC}     Owned by user"
    echo -e "  ${CYAN}-group name${NC}    Owned by group"
    echo -e "  ${CYAN}-uid N${NC}         Owned by numeric UID"
    echo -e "  ${CYAN}-gid N${NC}         Owned by numeric GID"
    echo -e "  ${CYAN}-nouser${NC}        No user in /etc/passwd"
    echo -e "  ${CYAN}-nogroup${NC}       No group in /etc/group"
    echo

    echo -e "${CYAN}Example: Find files owned by root${NC}"
    echo "  find /etc -user root"
    echo

    echo -e "${CYAN}Example: Find orphaned files (no owner)${NC}"
    echo "  find / -nouser 2>/dev/null"

    wait_for_user

    # Actions
    print_subheader "Actions"

    echo -e "${BOLD}What to do with found files:${NC}"
    echo -e "  ${CYAN}-print${NC}         Print pathname (default)"
    echo -e "  ${CYAN}-print0${NC}        Print with null terminator"
    echo -e "  ${CYAN}-ls${NC}            Long listing format"
    echo -e "  ${CYAN}-delete${NC}        Delete matching files"
    echo -e "  ${CYAN}-exec CMD {} \\;${NC}  Execute CMD for each file"
    echo -e "  ${CYAN}-exec CMD {} +${NC}  Execute CMD with multiple files"
    echo -e "  ${CYAN}-ok CMD {} \\;${NC}   Like -exec but prompts first"
    echo

    echo -e "${YELLOW}${WARN} -delete has no confirmation! Test with -print first${NC}"

    wait_for_user

    # Exec examples
    print_subheader "Using -exec"

    cat << 'EXEC'
The -exec action runs a command for each match. The {} is replaced
with the filename. Must end with \; (escaped semicolon).
EXEC
    echo

    echo -e "${CYAN}Example: Get details of found files${NC}"
    echo "  find . -name '*.log' -exec ls -lh {} \\;"
    echo

    echo -e "${CYAN}Example: Change permissions${NC}"
    echo "  find . -type f -name '*.sh' -exec chmod +x {} \\;"
    echo

    echo -e "${CYAN}Example: Search within found files${NC}"
    echo "  find /etc -name '*.conf' -exec grep -l 'port' {} \\;"
    echo

    echo -e "${CYAN}Example: Efficient execution (+ instead of \\;)${NC}"
    echo "  find . -name '*.txt' -exec grep 'pattern' {} +"
    echo "  (Passes multiple files to grep at once)"

    wait_for_user

    # Combining tests
    print_subheader "Combining Tests"

    echo -e "${BOLD}Logical operators:${NC}"
    echo -e "  ${CYAN}-a${NC} or nothing  AND (implicit)"
    echo -e "  ${CYAN}-o${NC}             OR"
    echo -e "  ${CYAN}!${NC} or ${CYAN}-not${NC}     NOT"
    echo -e "  ${CYAN}( )${NC}            Grouping (must escape)"
    echo

    echo -e "${CYAN}Example: Find .txt OR .log files${NC}"
    echo "  find . \\( -name '*.txt' -o -name '*.log' \\)"
    echo

    echo -e "${CYAN}Example: Find large, old files${NC}"
    echo "  find /var/log -size +100M -mtime +30"
    echo

    echo -e "${CYAN}Example: Find writable files NOT in /tmp${NC}"
    echo "  find / -perm -002 ! -path '/tmp/*'"

    wait_for_user

    # Practical examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Clean up old temp files:${NC}"
    echo "   find /tmp -mtime +7 -delete"
    echo

    echo -e "${CYAN}2. Find large files consuming space:${NC}"
    echo "   find /home -size +100M -exec ls -lh {} \\;"
    echo

    echo -e "${CYAN}3. Find files modified today:${NC}"
    echo "   find . -mtime 0"
    echo

    echo -e "${CYAN}4. Find empty files and directories:${NC}"
    echo "   find . -empty"
    echo

    echo -e "${CYAN}5. Security audit - find SUID/SGID:${NC}"
    echo "   find / -type f \\( -perm -4000 -o -perm -2000 \\) 2>/dev/null"
    echo

    echo -e "${CYAN}6. Find and compress old logs:${NC}"
    echo "   find /var/log -name '*.log' -mtime +30 -exec gzip {} \\;"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} Remember to quote patterns: -name '*.txt' not -name *.txt"
    echo -e "${MAGENTA}${BULLET}${NC} -mtime -7 means LESS than 7 days ago (recent)"
    echo -e "${MAGENTA}${BULLET}${NC} -mtime +7 means MORE than 7 days ago (old)"
    echo -e "${MAGENTA}${BULLET}${NC} -exec ends with \\; (one file) or + (batch)"
    echo -e "${MAGENTA}${BULLET}${NC} Know the type codes: f=file, d=directory, l=link"
    echo -e "${MAGENTA}${BULLET}${NC} -perm -mode means ALL bits set, /mode means ANY"
    echo -e "${MAGENTA}${BULLET}${NC} Always test with -print before using -delete"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. find searches directory trees for files matching criteria"
    echo "2. Use -name, -type, -size, -mtime for common searches"
    echo "3. Use -exec to perform actions on found files"
    echo "4. Combine tests with -a (AND), -o (OR), ! (NOT)"
    echo "5. Quote patterns to prevent shell expansion"
    echo

    print_info "Ready to practice? Try: lpic-train practice find"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_find
fi
