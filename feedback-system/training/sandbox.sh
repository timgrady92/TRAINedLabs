#!/bin/bash
# LPIC-1 Training - Interactive Sandbox Mode
# Safe experimentation environment with practice files

# Source common if not already loaded
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Sandbox Hints by Topic
# ============================================================================

declare -A SANDBOX_HINTS

SANDBOX_HINTS["grep"]="
${CYAN}grep Practice Ideas:${NC}
  1. Find all lines with 'error' (case insensitive):
     ${BOLD}grep -i 'error' logs/system.log${NC}

  2. Show lines NOT containing 'nologin':
     ${BOLD}grep -v 'nologin' text/users.txt${NC}

  3. Count SSH connection attempts:
     ${BOLD}grep -c 'sshd' logs/system.log${NC}

  4. Find email patterns with regex:
     ${BOLD}grep -E '[a-z]+@[a-z]+\\.[a-z]+' text/grep-practice/emails.txt${NC}

  5. Search recursively for 'password':
     ${BOLD}grep -r 'password' configs/${NC}
"

SANDBOX_HINTS["sed"]="
${CYAN}sed Practice Ideas:${NC}
  1. Replace 'old' with 'new':
     ${BOLD}sed 's/old/new/g' text/sed-practice/config.ini${NC}

  2. Delete lines containing 'comment':
     ${BOLD}sed '/^#/d' configs/sample-crontab${NC}

  3. Print only lines 5-10:
     ${BOLD}sed -n '5,10p' text/users.txt${NC}

  4. Replace and save in-place (careful!):
     ${BOLD}sed -i.bak 's/localhost/127.0.0.1/g' file${NC}

  5. Delete empty lines:
     ${BOLD}sed '/^$/d' text/sed-practice/messy-text.txt${NC}
"

SANDBOX_HINTS["awk"]="
${CYAN}awk Practice Ideas:${NC}
  1. Print specific columns:
     ${BOLD}awk '{print \$1, \$3}' text/servers.txt${NC}

  2. Sum a column:
     ${BOLD}awk -F, '{sum+=\$3} END{print sum}' text/sales.csv${NC}

  3. Filter by condition:
     ${BOLD}awk '\$4 > 50000' text/awk-practice/employees.dat${NC}

  4. Custom field separator:
     ${BOLD}awk -F: '{print \$1, \$7}' text/users.txt${NC}

  5. Format output:
     ${BOLD}awk '{printf \"%-15s %s\\n\", \$1, \$4}' text/servers.txt${NC}
"

SANDBOX_HINTS["find"]="
${CYAN}find Practice Ideas:${NC}
  1. Find all .txt files:
     ${BOLD}find find-practice -name '*.txt'${NC}

  2. Find files modified in last 7 days:
     ${BOLD}find . -mtime -7${NC}

  3. Find files larger than 1MB:
     ${BOLD}find . -size +1M${NC}

  4. Find directories only:
     ${BOLD}find find-practice -type d${NC}

  5. Find and execute command:
     ${BOLD}find . -name '*.log' -exec wc -l {} \\;${NC}

  6. Find by permissions:
     ${BOLD}find . -perm 755${NC}
"

SANDBOX_HINTS["tar"]="
${CYAN}tar Practice Ideas:${NC}
  1. Create a gzipped archive:
     ${BOLD}tar -czvf archive.tar.gz compression/archive-me/${NC}

  2. List archive contents:
     ${BOLD}tar -tvf archive.tar.gz${NC}

  3. Extract archive:
     ${BOLD}tar -xzvf archive.tar.gz -C /tmp/${NC}

  4. Create bzip2 archive:
     ${BOLD}tar -cjvf archive.tar.bz2 compression/archive-me/${NC}

  5. Extract specific file:
     ${BOLD}tar -xzvf archive.tar.gz path/to/file${NC}
"

SANDBOX_HINTS["permissions"]="
${CYAN}Permissions Practice Ideas:${NC}
  1. View current permissions:
     ${BOLD}ls -la permissions-lab/${NC}

  2. Set numeric permissions:
     ${BOLD}chmod 755 permissions-lab/executable.sh${NC}

  3. Add execute for owner:
     ${BOLD}chmod u+x permissions-lab/script.sh${NC}

  4. Remove world read:
     ${BOLD}chmod o-r permissions-lab/private.txt${NC}

  5. Change owner (needs sudo):
     ${BOLD}sudo chown root:root permissions-lab/file.txt${NC}

  6. Set SUID bit:
     ${BOLD}chmod u+s permissions-lab/executable.sh${NC}
"

SANDBOX_HINTS["processes"]="
${CYAN}Process Practice Ideas:${NC}
  1. Show all processes:
     ${BOLD}ps aux${NC}

  2. Show process tree:
     ${BOLD}ps axjf${NC}  or  ${BOLD}pstree${NC}

  3. Find process by name:
     ${BOLD}ps aux | grep -i bash${NC}  or  ${BOLD}pgrep -l bash${NC}

  4. Start background process:
     ${BOLD}sleep 60 &${NC}

  5. View jobs and bring to foreground:
     ${BOLD}jobs${NC}  then  ${BOLD}fg %1${NC}

  6. Top processes by CPU:
     ${BOLD}ps aux --sort=-%cpu | head${NC}
"

SANDBOX_HINTS[""]="
${CYAN}Sandbox Mode - What to try:${NC}

  ${BOLD}Text Processing:${NC}
    grep -i 'error' logs/system.log
    awk -F: '{print \$1}' text/users.txt
    sed 's/localhost/127.0.0.1/g' configs/sample-crontab

  ${BOLD}File Operations:${NC}
    find . -name '*.txt'
    find . -type f -size +100k
    tar -czvf test.tar.gz text/

  ${BOLD}Examine Practice Files:${NC}
    ls -la text/
    head -20 logs/system.log
    cat text/servers.txt

Type 'hint' for topic-specific suggestions.
Type 'files' to see available practice files.
"

# ============================================================================
# Sandbox Mode
# ============================================================================

sandbox_mode() {
    local topic="${1:-}"

    print_header "Sandbox Mode${topic:+: $topic}"

    cat << 'INFO'
SANDBOX MODE - Experiment freely!

You're working with PRACTICE FILES that are safe to read, search, and modify.
Try commands, see what happens, learn by doing.

Commands:
  files     - List available practice files
  reset     - Reset practice files to original state
  hint      - Get suggestions for what to try
  help      - Show sandbox commands
  exit      - Leave sandbox mode

INFO

    # Check practice directory exists
    if [[ ! -d "$PRACTICE_DIR" ]]; then
        print_warn "Practice directory not found: $PRACTICE_DIR"
        print_info "Run seed-data.sh to create practice files"
        return 1
    fi

    # Show relevant files for topic
    show_topic_files "$topic"

    echo

    # Change to practice directory
    cd "$PRACTICE_DIR" || {
        print_fail "Could not change to practice directory"
        return 1
    }

    echo -e "${DIM}Working directory: $PRACTICE_DIR${NC}"
    echo

    # Interactive loop
    while true; do
        # Custom prompt showing pwd relative to practice dir
        local rel_path
        rel_path="${PWD#$PRACTICE_DIR}"
        rel_path="${rel_path:-/}"

        read -rp "${BOLD}sandbox${CYAN}${rel_path}${NC}> " cmd || {
            echo
            break
        }

        # Handle built-in commands
        case "$cmd" in
            exit|quit|q)
                echo "Leaving sandbox mode."
                break
                ;;

            files)
                sandbox_list_files
                ;;

            reset)
                sandbox_reset_files
                ;;

            hint|hints)
                sandbox_show_hint "$topic"
                ;;

            help|"?")
                sandbox_help
                ;;

            cd)
                # cd with no args goes to practice root
                cd "$PRACTICE_DIR"
                ;;

            cd\ *)
                # Handle cd command
                local target="${cmd#cd }"
                if [[ "$target" == "~" || "$target" == "\$HOME" ]]; then
                    print_warn "Stay in the practice directory for safety"
                    print_info "Use 'exit' to leave sandbox mode"
                elif [[ "$target" == /* && "$target" != "$PRACTICE_DIR"* ]]; then
                    print_warn "Sandbox restricts navigation to practice files"
                    print_info "Practice directory: $PRACTICE_DIR"
                else
                    cd "$target" 2>/dev/null || print_fail "Directory not found: $target"
                fi
                ;;

            pwd)
                echo "$PWD"
                ;;

            "")
                continue
                ;;

            *)
                # Safety check - block dangerous commands
                if sandbox_is_dangerous "$cmd"; then
                    print_warn "This command could affect files outside practice directory"
                    if ! confirm "Are you sure you want to run this?"; then
                        continue
                    fi
                fi

                # Execute command
                eval "$cmd" 2>&1 || true
                ;;
        esac
        echo
    done
}

# ============================================================================
# Sandbox Helper Functions
# ============================================================================

show_topic_files() {
    local topic="$1"

    case "$topic" in
        grep|sed|awk)
            echo -e "${CYAN}Suggested files for $topic practice:${NC}"
            echo "  text/users.txt          - User account data (passwd format)"
            echo "  text/groups.txt         - Group definitions"
            echo "  text/servers.txt        - Server inventory"
            echo "  text/sales.csv          - CSV sales data"
            echo "  logs/system.log         - System log entries"
            echo "  logs/access.log         - Web access log"
            echo "  text/grep-practice/     - Pattern matching files"
            echo "  text/sed-practice/      - Config files for editing"
            echo "  text/awk-practice/      - Data files for awk"
            ;;

        find)
            echo -e "${CYAN}Suggested directories for find practice:${NC}"
            echo "  find-practice/          - Nested directory structure"
            echo "    level1/               - Contains files of various types"
            echo "    level1/level2/        - Deeper nesting"
            echo "    level1/level2/level3/ - Deep files"
            echo "    temp/                 - Temporary files"
            echo "    level1/backup/        - Old backup files"
            ;;

        tar)
            echo -e "${CYAN}Suggested files for tar practice:${NC}"
            echo "  compression/            - Files for archiving"
            echo "  compression/archive-me/ - Directory to archive"
            echo "  compression/data-file-*.txt - Sample files"
            ;;

        permissions|chmod|chown)
            echo -e "${CYAN}Suggested files for permissions practice:${NC}"
            echo "  permissions-lab/        - Files with various permissions"
            echo "  permissions-lab/public-read.txt   - 644"
            echo "  permissions-lab/private.txt       - 600"
            echo "  permissions-lab/executable.sh     - 755"
            echo "  permissions-lab/team-project/     - 775 directory"
            ;;

        processes|ps|kill)
            echo -e "${CYAN}Process practice:${NC}"
            echo "  No files needed - work with live processes"
            echo "  Try: ps aux, pstree, top"
            echo "  Start background: sleep 60 &"
            echo "  View jobs: jobs"
            ;;

        *)
            echo -e "${CYAN}Available practice areas:${NC}"
            echo "  text/           - Text files for grep, sed, awk"
            echo "  logs/           - Log files for analysis"
            echo "  configs/        - Sample configuration files"
            echo "  find-practice/  - Directory structure for find"
            echo "  compression/    - Files for tar practice"
            echo "  permissions-lab/ - Files for chmod practice"
            ;;
    esac
}

sandbox_list_files() {
    echo -e "${BOLD}Practice Files:${NC}"
    echo

    if command -v tree &>/dev/null; then
        tree -L 2 --dirsfirst "$PRACTICE_DIR" 2>/dev/null || \
            find "$PRACTICE_DIR" -maxdepth 2 | head -50
    else
        find "$PRACTICE_DIR" -maxdepth 2 -type d | head -30
        echo
        echo -e "${DIM}(Install 'tree' for better output)${NC}"
    fi
}

sandbox_reset_files() {
    print_warn "This will reset all practice files to their original state"
    if confirm "Continue?"; then
        # Find the seed-data script
        local seed_script
        for path in \
            "${SCRIPT_DIR}/../environment/seed-data.sh" \
            "${SCRIPT_DIR}/../../environment/seed-data.sh" \
            "/opt/LPIC-1/environment/seed-data.sh"; do
            if [[ -f "$path" ]]; then
                seed_script="$path"
                break
            fi
        done

        if [[ -n "$seed_script" ]]; then
            echo "Resetting practice files..."
            bash "$seed_script" --reset
            print_pass "Practice files reset"
        else
            print_fail "seed-data.sh not found"
            print_info "Manually recreate files or re-run setup"
        fi
    fi
}

sandbox_show_hint() {
    local topic="${1:-}"
    local hint="${SANDBOX_HINTS[$topic]:-${SANDBOX_HINTS[""]}}"
    echo -e "$hint"
}

sandbox_help() {
    cat << 'EOF'
Sandbox Mode Commands:

  files     List available practice files
  reset     Reset practice files to original state
  hint      Show suggestions for commands to try
  help      Show this help
  exit      Leave sandbox mode

Navigation:
  cd <dir>  Change directory (restricted to practice files)
  pwd       Show current directory
  ls        List files (use any ls options)

You can run any command - it executes in the practice directory.
Changes you make to practice files can be reset with 'reset'.

Examples:
  grep 'error' logs/system.log
  find . -name '*.txt'
  awk -F: '{print $1}' text/users.txt
  tar -czvf test.tar.gz text/
EOF
}

sandbox_is_dangerous() {
    local cmd="$1"

    # Check for commands that could affect system files
    local dangerous_patterns=(
        "rm -rf /"
        "rm -rf /*"
        "chmod -R /"
        "chown -R /"
        "> /etc/"
        ">> /etc/"
        "mv /* "
        "cp /* "
        "sudo rm"
        "sudo chmod"
        "sudo chown"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$cmd" == *"$pattern"* ]]; then
            return 0
        fi
    done

    # Check for writes outside practice directory
    if [[ "$cmd" == *">"* ]]; then
        local output_file
        output_file=$(echo "$cmd" | grep -oP '>\s*\K[^\s]+' | head -1)
        if [[ -n "$output_file" && "$output_file" == /* && "$output_file" != "$PRACTICE_DIR"* ]]; then
            return 0
        fi
    fi

    return 1
}

# If run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sandbox_mode "$@"
fi
