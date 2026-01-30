#!/bin/bash
# LPIC-1 Training - grep Lesson
# Objective: 103.2 - Process text streams using filters

lesson_grep() {
    print_header "grep - Search Text Patterns"

    cat << 'INTRO'
grep searches for PATTERNS in each FILE. When it finds a line matching
the pattern, it prints that line. The name comes from the ed command
g/re/p (globally search for a regular expression and print matching lines).

INTRO

    # Real-world uses
    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Finding error messages in log files"
    echo "  ${BULLET} Searching code for function definitions"
    echo "  ${BULLET} Filtering command output through pipes"
    echo "  ${BULLET} Validating configuration files"
    echo "  ${BULLET} Security auditing (finding suspicious patterns)"

    wait_for_user

    # Essential Options
    print_subheader "Essential Options"

    echo -e "  ${CYAN}-i${NC}    Case insensitive search"
    echo -e "  ${CYAN}-v${NC}    Invert match (show non-matching lines)"
    echo -e "  ${CYAN}-n${NC}    Show line numbers"
    echo -e "  ${CYAN}-c${NC}    Count matches only"
    echo -e "  ${CYAN}-r${NC}    Recursive search in directories"
    echo -e "  ${CYAN}-l${NC}    Show only filenames with matches"
    echo -e "  ${CYAN}-w${NC}    Match whole words only"
    echo -e "  ${CYAN}-E${NC}    Extended regex (same as egrep)"
    echo -e "  ${CYAN}-F${NC}    Fixed strings (same as fgrep, no regex)"
    echo -e "  ${CYAN}-A N${NC}  Show N lines after match"
    echo -e "  ${CYAN}-B N${NC}  Show N lines before match"
    echo -e "  ${CYAN}-C N${NC}  Show N lines before and after (context)"

    wait_for_user

    # Live Examples Section
    print_subheader "Live Examples"

    local log_file
    log_file=$(get_practice_file "log" "system.log")
    local users_file
    users_file=$(get_practice_file "text" "users.txt")

    if [[ -f "$log_file" ]]; then
        # Example 1: Basic search
        echo -e "${CYAN}Example 1: Find lines containing 'error' (case insensitive)${NC}"
        echo -e "${BOLD}Command:${NC} grep -i 'error' logs/system.log"
        echo -e "${DIM}Output:${NC}"
        grep -i 'error' "$log_file" 2>/dev/null | head -5 | sed 's/^/  /'
        echo

        # Example 2: Count matches
        echo -e "${CYAN}Example 2: Count SSH-related entries${NC}"
        echo -e "${BOLD}Command:${NC} grep -c 'sshd' logs/system.log"
        echo -n "  "
        grep -c 'sshd' "$log_file" 2>/dev/null || echo "0"
        echo

        # Example 3: Show context
        echo -e "${CYAN}Example 3: Show context around matches${NC}"
        echo -e "${BOLD}Command:${NC} grep -B1 -A1 'Failed' logs/system.log"
        echo -e "${DIM}Output:${NC}"
        grep -B1 -A1 'Failed' "$log_file" 2>/dev/null | head -9 | sed 's/^/  /'
    else
        echo -e "${YELLOW}Practice files not found. Examples shown as reference.${NC}"
        echo
        echo "  grep -i 'error' /var/log/syslog"
        echo "  grep -c 'sshd' /var/log/auth.log"
        echo "  grep -B1 -A1 'Failed' /var/log/auth.log"
    fi

    wait_for_user

    # Inverted Matching
    print_subheader "Inverted Matching (-v)"

    cat << 'INVERT'
The -v option inverts the match, showing lines that do NOT contain
the pattern. This is incredibly useful for filtering out noise.
INVERT

    if [[ -f "$users_file" ]]; then
        echo
        echo -e "${CYAN}Example: Find users who CAN log in (not nologin)${NC}"
        echo -e "${BOLD}Command:${NC} grep -v 'nologin' text/users.txt"
        echo -e "${DIM}Output:${NC}"
        grep -v 'nologin' "$users_file" 2>/dev/null | head -6 | sed 's/^/  /'
        echo
        echo -e "${CYAN}Example: Show config without comments${NC}"
        echo -e "${BOLD}Command:${NC} grep -v '^#' /etc/ssh/sshd_config"
    fi

    wait_for_user

    # Regular Expressions
    print_subheader "Regular Expression Basics"

    echo "grep uses Basic Regular Expressions (BRE) by default."
    echo "Use -E for Extended Regular Expressions (ERE)."
    echo

    echo -e "${BOLD}Common Patterns:${NC}"
    echo -e "  ${CYAN}.${NC}       Match any single character"
    echo -e "  ${CYAN}*${NC}       Match zero or more of previous"
    echo -e "  ${CYAN}^${NC}       Match start of line"
    echo -e "  ${CYAN}\$${NC}       Match end of line"
    echo -e "  ${CYAN}[abc]${NC}   Match any character in set"
    echo -e "  ${CYAN}[^abc]${NC}  Match any character NOT in set"
    echo -e "  ${CYAN}\\<\\>${NC}   Word boundaries (BRE)"
    echo

    echo -e "${BOLD}Extended Regex (-E):${NC}"
    echo -e "  ${CYAN}+${NC}       Match one or more of previous"
    echo -e "  ${CYAN}?${NC}       Match zero or one of previous"
    echo -e "  ${CYAN}|${NC}       Alternation (OR)"
    echo -e "  ${CYAN}()${NC}      Grouping"
    echo -e "  ${CYAN}{n,m}${NC}   Match n to m occurrences"

    wait_for_user

    # Practical regex examples
    print_subheader "Regex Examples"

    local email_file
    email_file=$(get_practice_file "grep" "emails.txt")

    if [[ -f "$email_file" ]]; then
        echo -e "${CYAN}Example: Find valid-looking email addresses${NC}"
        echo -e "${BOLD}Command:${NC} grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}' emails.txt"
        echo -e "${DIM}Output:${NC}"
        grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$email_file" 2>/dev/null | sed 's/^/  /'
        echo
    fi

    echo -e "${CYAN}Example: Find lines starting with date format${NC}"
    echo -e "${BOLD}Command:${NC} grep '^[A-Z][a-z][a-z] [0-9]' logs/system.log"
    echo

    echo -e "${CYAN}Example: Find IP addresses${NC}"
    echo -e "${BOLD}Command:${NC} grep -E '([0-9]{1,3}\\.){3}[0-9]{1,3}' logs/system.log"

    wait_for_user

    # Recursive searching
    print_subheader "Recursive Search (-r, -R)"

    cat << 'RECURSIVE'
Search through directory trees with -r (follow symlinks) or -R.
Combine with --include/--exclude to filter file types.
RECURSIVE
    echo

    echo -e "${CYAN}Example: Search for 'password' in all config files${NC}"
    echo -e "${BOLD}Command:${NC} grep -r 'password' /etc/ 2>/dev/null"
    echo

    echo -e "${CYAN}Example: Search only .conf files${NC}"
    echo -e "${BOLD}Command:${NC} grep -r --include='*.conf' 'port' /etc/"
    echo

    echo -e "${CYAN}Example: List files containing pattern${NC}"
    echo -e "${BOLD}Command:${NC} grep -rl 'root' /etc/ 2>/dev/null | head"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} Know the difference between -i (case insensitive) and -v (invert)"
    echo -e "${MAGENTA}${BULLET}${NC} Remember: -c counts lines with matches, not total matches"
    echo -e "${MAGENTA}${BULLET}${NC} Use -w for whole words: grep -w 'root' won't match 'rooted'"
    echo -e "${MAGENTA}${BULLET}${NC} -E enables extended regex (egrep), -F disables regex (fgrep)"
    echo -e "${MAGENTA}${BULLET}${NC} Exit codes: 0 = match found, 1 = no match, 2 = error"
    echo -e "${MAGENTA}${BULLET}${NC} Combine with other commands: ps aux | grep nginx"

    wait_for_user

    # Common mistakes
    print_subheader "Common Mistakes"

    echo -e "${RED}${WARN}${NC} Forgetting to quote patterns with special characters"
    echo "    Wrong: grep hello world file.txt"
    echo "    Right: grep 'hello world' file.txt"
    echo

    echo -e "${RED}${WARN}${NC} Confusing -c (count) with wc -l"
    echo "    grep -c 'x' file counts lines with 'x'"
    echo "    grep 'x' file | wc -l does the same thing"
    echo

    echo -e "${RED}${WARN}${NC} Not escaping special regex characters"
    echo "    To find literal '.', use: grep '\\.' file"
    echo

    echo -e "${RED}${WARN}${NC} Using -v when you meant -i (or vice versa)"
    echo "    -v = invert (exclude matches)"
    echo "    -i = case insensitive"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. grep finds lines matching patterns in files"
    echo "2. Use -i for case insensitive, -v to invert"
    echo "3. Use -r for recursive directory search"
    echo "4. Use -E for extended regex (|, +, ?, {})"
    echo "5. Combine with pipes for powerful filtering"
    echo

    print_info "Ready to practice? Try: lpic-train practice grep"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_grep
fi
