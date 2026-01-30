#!/bin/bash
# LPIC-1 Training - sed Lesson
# Objective: 103.2 - Process text streams using filters

lesson_sed() {
    print_header "sed - Stream Editor"

    cat << 'INTRO'
sed (stream editor) performs text transformations on input streams
(files or piped data). It reads input line by line, applies editing
commands, and outputs the result. Perfect for automated text processing.

INTRO

    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Find and replace text in configuration files"
    echo "  ${BULLET} Delete or extract specific lines"
    echo "  ${BULLET} Automated config file updates in scripts"
    echo "  ${BULLET} Data transformation pipelines"
    echo "  ${BULLET} Removing comments or blank lines"

    wait_for_user

    # Basic Syntax
    print_subheader "Basic Syntax"

    echo -e "${BOLD}sed [options] 'command' file${NC}"
    echo -e "${BOLD}command | sed [options] 'command'${NC}"
    echo
    echo -e "${BOLD}Common Options:${NC}"
    echo -e "  ${CYAN}-n${NC}    Suppress automatic printing"
    echo -e "  ${CYAN}-i${NC}    Edit file in-place (careful!)"
    echo -e "  ${CYAN}-i.bak${NC} In-place with backup"
    echo -e "  ${CYAN}-e${NC}    Multiple commands"
    echo -e "  ${CYAN}-f${NC}    Read commands from file"
    echo -e "  ${CYAN}-r/-E${NC} Extended regex"

    wait_for_user

    # Substitution
    print_subheader "Substitution (s command)"

    echo -e "${BOLD}s/pattern/replacement/flags${NC}"
    echo
    echo -e "${BOLD}Flags:${NC}"
    echo -e "  ${CYAN}g${NC}   Global - replace all occurrences on line"
    echo -e "  ${CYAN}i${NC}   Case-insensitive matching"
    echo -e "  ${CYAN}N${NC}   Replace Nth occurrence only"
    echo -e "  ${CYAN}p${NC}   Print if substitution made"
    echo -e "  ${CYAN}w${NC}   Write to file if substitution made"

    local config_file
    config_file=$(get_practice_file "sed" "config.ini")

    if [[ -f "$config_file" ]]; then
        echo
        echo -e "${CYAN}Example: Replace first 'localhost' with '127.0.0.1'${NC}"
        echo -e "${BOLD}Command:${NC} sed 's/localhost/127.0.0.1/' text/sed-practice/config.ini"
        echo -e "${DIM}Output (first 5 lines):${NC}"
        sed 's/localhost/127.0.0.1/' "$config_file" 2>/dev/null | head -5 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Replace ALL occurrences (global)${NC}"
        echo -e "${BOLD}Command:${NC} sed 's/localhost/127.0.0.1/g' text/sed-practice/config.ini"
    fi

    wait_for_user

    # Delimiters
    print_subheader "Alternative Delimiters"

    cat << 'DELIM'
When your pattern contains /, use a different delimiter to avoid
escaping. Any character can be the delimiter after s.
DELIM
    echo

    echo -e "${CYAN}Standard (escaping required):${NC}"
    echo "  sed 's/\\/var\\/log/\\/tmp\\/log/g' file"
    echo

    echo -e "${CYAN}Better (use different delimiter):${NC}"
    echo "  sed 's|/var/log|/tmp/log|g' file"
    echo "  sed 's#/var/log#/tmp/log#g' file"
    echo "  sed 's@/var/log@/tmp/log@g' file"

    wait_for_user

    # Address ranges
    print_subheader "Address Ranges"

    echo "Commands can be limited to specific lines using addresses:"
    echo
    echo -e "${BOLD}Line Numbers:${NC}"
    echo -e "  ${CYAN}5${NC}      Line 5 only"
    echo -e "  ${CYAN}5,10${NC}   Lines 5 through 10"
    echo -e "  ${CYAN}5,\$${NC}    Line 5 to end of file"
    echo -e "  ${CYAN}1~2${NC}    Every odd line (1,3,5...)"
    echo -e "  ${CYAN}0~2${NC}    Every even line (2,4,6...)"
    echo
    echo -e "${BOLD}Pattern Addresses:${NC}"
    echo -e "  ${CYAN}/regex/${NC}            Lines matching regex"
    echo -e "  ${CYAN}/start/,/end/${NC}      Range between patterns"
    echo

    local users_file
    users_file=$(get_practice_file "text" "users.txt")

    if [[ -f "$users_file" ]]; then
        echo -e "${CYAN}Example: Print only line 5${NC}"
        echo -e "${BOLD}Command:${NC} sed -n '5p' text/users.txt"
        echo -n "  "
        sed -n '5p' "$users_file"
        echo

        echo -e "${CYAN}Example: Print lines 1-5${NC}"
        echo -e "${BOLD}Command:${NC} sed -n '1,5p' text/users.txt"
        echo -e "${DIM}Output:${NC}"
        sed -n '1,5p' "$users_file" | sed 's/^/  /'
    fi

    wait_for_user

    # Delete command
    print_subheader "Delete Command (d)"

    echo -e "${BOLD}d - Delete lines${NC}"
    echo

    if [[ -f "$users_file" ]]; then
        echo -e "${CYAN}Example: Delete lines containing 'nologin'${NC}"
        echo -e "${BOLD}Command:${NC} sed '/nologin/d' text/users.txt"
        echo -e "${DIM}Output (first 5 lines):${NC}"
        sed '/nologin/d' "$users_file" 2>/dev/null | head -5 | sed 's/^/  /'
        echo
    fi

    echo -e "${CYAN}Example: Delete comment lines${NC}"
    echo "  sed '/^#/d' config.file"
    echo

    echo -e "${CYAN}Example: Delete empty lines${NC}"
    echo "  sed '/^$/d' file.txt"
    echo

    echo -e "${CYAN}Example: Delete first 3 lines${NC}"
    echo "  sed '1,3d' file.txt"
    echo

    echo -e "${CYAN}Example: Delete last line${NC}"
    echo "  sed '\$d' file.txt"

    wait_for_user

    # Print command
    print_subheader "Print Command (p)"

    cat << 'PRINT'
p - Print lines (use with -n to suppress auto-print)
Without -n, matched lines print twice (auto + command).
PRINT
    echo

    if [[ -f "$users_file" ]]; then
        echo -e "${CYAN}Example: Print lines containing 'bash'${NC}"
        echo -e "${BOLD}Command:${NC} sed -n '/bash/p' text/users.txt"
        echo -e "${DIM}Output:${NC}"
        sed -n '/bash/p' "$users_file" | sed 's/^/  /'
        echo
    fi

    echo -e "${CYAN}Example: Print lines 10-20${NC}"
    echo "  sed -n '10,20p' file.txt"
    echo

    echo -e "${CYAN}Example: Print from 'START' to 'END'${NC}"
    echo "  sed -n '/START/,/END/p' file.txt"

    wait_for_user

    # Insert, Append, Change
    print_subheader "Insert, Append, Change"

    echo -e "${CYAN}i\\${NC}  Insert before line"
    echo -e "${CYAN}a\\${NC}  Append after line"
    echo -e "${CYAN}c\\${NC}  Change/replace line"
    echo

    echo -e "${CYAN}Example: Insert header at line 1${NC}"
    echo "  sed '1i\\# Configuration File' config.ini"
    echo

    echo -e "${CYAN}Example: Append line after matches${NC}"
    echo "  sed '/\\[database\\]/a\\# Database settings' config.ini"
    echo

    echo -e "${CYAN}Example: Replace entire line${NC}"
    echo "  sed '/^host/c\\host = 192.168.1.1' config.ini"

    wait_for_user

    # In-place editing
    print_subheader "In-Place Editing (-i)"

    echo -e "${RED}${WARN} -i modifies the original file! No undo!${NC}"
    echo
    echo -e "${BOLD}Always make a backup:${NC}"
    echo "  sed -i.bak 's/old/new/g' file.txt"
    echo "  (Creates file.txt.bak before modifying)"
    echo
    echo -e "${BOLD}Or test first:${NC}"
    echo "  sed 's/old/new/g' file.txt      # Preview"
    echo "  sed -i 's/old/new/g' file.txt   # Apply"
    echo

    echo -e "${CYAN}Example: Update config file${NC}"
    echo "  sed -i.bak 's/DEBUG=false/DEBUG=true/' app.conf"

    wait_for_user

    # Multiple commands
    print_subheader "Multiple Commands"

    echo -e "${BOLD}Use -e for multiple commands:${NC}"
    echo "  sed -e 's/foo/bar/' -e 's/baz/qux/' file"
    echo
    echo -e "${BOLD}Or use semicolons:${NC}"
    echo "  sed 's/foo/bar/; s/baz/qux/' file"
    echo
    echo -e "${BOLD}Or use a script file (-f):${NC}"
    echo "  cat > script.sed << 'EOF'"
    echo "  s/foo/bar/g"
    echo "  /^#/d"
    echo "  EOF"
    echo "  sed -f script.sed file"

    wait_for_user

    # Back-references
    print_subheader "Back-References"

    cat << 'BACKREF'
Capture groups in () can be referenced in replacement:
  \1 = first group, \2 = second group, etc.
  & = entire matched pattern
BACKREF
    echo

    echo -e "${CYAN}Example: Swap first and last names${NC}"
    echo "  sed 's/\\(.*\\) \\(.*\\)/\\2, \\1/' names.txt"
    echo "  'John Smith' becomes 'Smith, John'"
    echo

    echo -e "${CYAN}Example: Duplicate matched text${NC}"
    echo "  sed 's/[0-9]\\+/& &/' file.txt"
    echo "  'line 42' becomes 'line 42 42'"
    echo

    echo -e "${CYAN}Example: Add prefix to matched pattern${NC}"
    echo "  sed 's/error/[ALERT] &/gi' log.txt"

    wait_for_user

    # Practical examples
    print_subheader "Practical Examples"

    local messy_file
    messy_file=$(get_practice_file "sed" "messy-text.txt")

    echo -e "${CYAN}1. Remove trailing whitespace:${NC}"
    echo "   sed 's/[[:space:]]*\$//' file.txt"
    echo

    echo -e "${CYAN}2. Remove leading whitespace:${NC}"
    echo "   sed 's/^[[:space:]]*//' file.txt"
    echo

    echo -e "${CYAN}3. Squeeze multiple spaces to one:${NC}"
    echo "   sed 's/  */ /g' file.txt"
    echo

    echo -e "${CYAN}4. Convert DOS line endings to Unix:${NC}"
    echo "   sed 's/\\r\$//' file.txt"
    echo

    echo -e "${CYAN}5. Comment out a line:${NC}"
    echo "   sed '/pattern/s/^/# /' config.file"
    echo

    echo -e "${CYAN}6. Uncomment a line:${NC}"
    echo "   sed 's/^# //' config.file"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} Without -n, sed prints all lines; with -n, only explicit p"
    echo -e "${MAGENTA}${BULLET}${NC} Use -i with caution - it modifies files in place"
    echo -e "${MAGENTA}${BULLET}${NC} s/pattern/replace/ changes first occurrence; add g for all"
    echo -e "${MAGENTA}${BULLET}${NC} Use alternative delimiters for paths: s|/old|/new|"
    echo -e "${MAGENTA}${BULLET}${NC} \$ means last line: sed '\$d' deletes last line"
    echo -e "${MAGENTA}${BULLET}${NC} BRE requires \\( \\) for groups; ERE (-r) uses ( )"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. sed processes text line by line, applying commands"
    echo "2. s/pattern/replacement/g is the most common command"
    echo "3. Use -n with p to print only matching lines"
    echo "4. Use d to delete lines matching patterns"
    echo "5. Use -i for in-place editing (always backup!)"
    echo "6. Address ranges limit where commands apply"
    echo

    print_info "Ready to practice? Try: lpic-train practice sed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_sed
fi
