#!/bin/bash
# LPIC-1 Training - Learning Helpers
# Educational enhancements for deeper understanding and muscle memory
#
# This module provides:
# - Error diagnosis (WHY commands fail)
# - Elaboration prompts (deeper understanding after success)
# - Expert thinking traces (step-by-step command building)
# - Spaced repetition (smart review scheduling)
# - Interleaved practice (mixed-topic exercises)

# Source common if not already loaded
[[ -z "${NC:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# ============================================================================
# Error Diagnosis System
# ============================================================================
# Analyzes user commands and explains WHY they failed

diagnose_command_error() {
    local user_cmd="$1"
    local expected_pattern="$2"
    local command_type="$3"  # grep, find, chmod, etc.

    echo -e "\n${YELLOW}Let's analyze what went wrong:${NC}"

    # Check for empty command
    if [[ -z "$user_cmd" ]]; then
        echo -e "  ${RED}Empty command${NC} - You didn't enter anything."
        echo -e "  ${DIM}Try thinking about: What command handles $command_type?${NC}"
        return
    fi

    # Command-specific diagnosis
    case "$command_type" in
        chmod)
            _diagnose_chmod "$user_cmd" "$expected_pattern"
            ;;
        find)
            _diagnose_find "$user_cmd" "$expected_pattern"
            ;;
        grep)
            _diagnose_grep "$user_cmd" "$expected_pattern"
            ;;
        ps|kill|processes)
            _diagnose_processes "$user_cmd" "$expected_pattern"
            ;;
        tar)
            _diagnose_tar "$user_cmd" "$expected_pattern"
            ;;
        sed)
            _diagnose_sed "$user_cmd" "$expected_pattern"
            ;;
        *)
            _diagnose_generic "$user_cmd" "$expected_pattern"
            ;;
    esac
}

_diagnose_chmod() {
    local cmd="$1"
    local expected="$2"

    # Check if wrong command entirely
    if [[ "$cmd" != chmod* ]]; then
        echo -e "  ${RED}Wrong command${NC} - chmod changes permissions"
        echo -e "  ${DIM}You used '${cmd%% *}' but need 'chmod'${NC}"
        return
    fi

    # Check for common chmod mistakes
    if [[ "$cmd" == *"+"* && "$expected" == *[0-9][0-9][0-9]* ]]; then
        echo -e "  ${YELLOW}Mode format${NC} - You used symbolic (+x) but numeric was expected"
        echo -e "  ${DIM}Remember: numeric mode is 3 digits (e.g., 755)${NC}"
        echo -e "  ${DIM}Each digit = r(4) + w(2) + x(1)${NC}"
    elif [[ "$cmd" == *[0-9][0-9][0-9]* && "$expected" == *"+"* ]]; then
        echo -e "  ${YELLOW}Mode format${NC} - You used numeric but symbolic was expected"
        echo -e "  ${DIM}Symbolic uses: u/g/o and +/-/= with r/w/x${NC}"
    elif [[ ! "$cmd" =~ [0-9]{3} && ! "$cmd" =~ [+=-] ]]; then
        echo -e "  ${RED}Missing mode${NC} - chmod needs a permission mode"
        echo -e "  ${DIM}Examples: chmod 755 file OR chmod u+x file${NC}"
    fi

    # Check for missing filename
    local parts=($cmd)
    if [[ ${#parts[@]} -lt 3 ]]; then
        echo -e "  ${RED}Missing target${NC} - chmod needs: chmod MODE FILE"
    fi

    # Check for wrong numeric value
    if [[ "$cmd" =~ ([0-9]{3}) ]]; then
        local user_mode="${BASH_REMATCH[1]}"
        if [[ "$expected" =~ ([0-9]{3}) ]]; then
            local expected_mode="${BASH_REMATCH[1]}"
            if [[ "$user_mode" != "$expected_mode" ]]; then
                echo -e "  ${YELLOW}Wrong permission value${NC}"
                _explain_permission_math "$expected_mode"
            fi
        fi
    fi
}

_explain_permission_math() {
    local mode="$1"
    local u="${mode:0:1}"
    local g="${mode:1:1}"
    local o="${mode:2:1}"

    echo -e "\n  ${CYAN}Permission breakdown for $mode:${NC}"
    echo -e "    User:  $u = $(_decode_perm_digit "$u")"
    echo -e "    Group: $g = $(_decode_perm_digit "$g")"
    echo -e "    Other: $o = $(_decode_perm_digit "$o")"
}

_decode_perm_digit() {
    local d="$1"
    local result=""
    [[ $((d & 4)) -ne 0 ]] && result+="r(4)"
    [[ $((d & 2)) -ne 0 ]] && result+="+w(2)"
    [[ $((d & 1)) -ne 0 ]] && result+="+x(1)"
    [[ -z "$result" ]] && result="none(0)"
    echo "$result"
}

_diagnose_find() {
    local cmd="$1"
    local expected="$2"

    if [[ "$cmd" != find* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'find' to search for files"
        return
    fi

    # Check for path
    if [[ ! "$cmd" =~ find[[:space:]]+[./~] ]]; then
        echo -e "  ${YELLOW}Missing path${NC} - find needs a starting directory"
        echo -e "  ${DIM}Example: find . -name '*.txt' (search from current dir)${NC}"
    fi

    # Check for common test mistakes
    if [[ "$expected" == *"-name"* && "$cmd" != *"-name"* ]]; then
        echo -e "  ${YELLOW}Missing -name${NC} - Use -name to match filenames"
    fi

    if [[ "$expected" == *"-type"* && "$cmd" != *"-type"* ]]; then
        echo -e "  ${YELLOW}Missing -type${NC} - Use -type f (files) or -type d (dirs)"
    fi

    # Check for quoting issues
    if [[ "$cmd" == *"*"* && "$cmd" != *"'"* && "$cmd" != *'"'* ]]; then
        echo -e "  ${RED}Quoting issue${NC} - Wildcards must be quoted!"
        echo -e "  ${DIM}Without quotes, the shell expands * before find sees it${NC}"
        echo -e "  ${DIM}Use: -name '*.txt' not -name *.txt${NC}"
    fi

    # Check -exec syntax
    if [[ "$expected" == *"-exec"* && "$cmd" == *"-exec"* ]]; then
        if [[ "$cmd" != *"{}"* ]]; then
            echo -e "  ${YELLOW}Missing {}${NC} - -exec needs {} as placeholder"
        fi
        if [[ "$cmd" != *"\\;"* && "$cmd" != *";"* && "$cmd" != *"+"* ]]; then
            echo -e "  ${YELLOW}Missing terminator${NC} - -exec needs \\; or +"
        fi
    fi
}

_diagnose_grep() {
    local cmd="$1"
    local expected="$2"

    if [[ "$cmd" != grep* && "$cmd" != egrep* && "$cmd" != fgrep* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'grep' to search file contents"
        return
    fi

    # Check for pattern
    local parts=($cmd)
    if [[ ${#parts[@]} -lt 2 ]]; then
        echo -e "  ${RED}Missing pattern${NC} - grep needs a search pattern"
        echo -e "  ${DIM}Example: grep 'error' logfile.txt${NC}"
    fi

    # Check for common flag mistakes
    if [[ "$expected" == *"-i"* && "$cmd" != *"-i"* ]]; then
        echo -e "  ${YELLOW}Case sensitivity${NC} - Use -i for case-insensitive"
    fi

    if [[ "$expected" == *"-r"* && "$cmd" != *"-r"* && "$cmd" != *"-R"* ]]; then
        echo -e "  ${YELLOW}Recursion${NC} - Use -r to search directories recursively"
    fi

    if [[ "$expected" == *"-v"* && "$cmd" != *"-v"* ]]; then
        echo -e "  ${YELLOW}Inversion${NC} - Use -v to show non-matching lines"
    fi

    if [[ "$expected" == *"-c"* && "$cmd" != *"-c"* ]]; then
        echo -e "  ${YELLOW}Counting${NC} - Use -c to count matches"
    fi

    # Check for regex vs literal
    if [[ "$expected" == *"-E"* && "$cmd" != *"-E"* ]]; then
        echo -e "  ${YELLOW}Extended regex${NC} - Use -E for extended regex (+, ?, |)"
    fi
}

_diagnose_processes() {
    local cmd="$1"
    local expected="$2"

    if [[ "$expected" == *"ps"* && "$cmd" != *"ps"* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'ps' to list processes"
        return
    fi

    if [[ "$expected" == *"kill"* && "$cmd" != *"kill"* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'kill' to send signals"
        return
    fi

    # ps diagnosis
    if [[ "$cmd" == ps* ]]; then
        if [[ "$expected" == *"aux"* && "$cmd" != *"aux"* && "$cmd" != *"a"*"u"*"x"* ]]; then
            echo -e "  ${YELLOW}Options${NC} - Use 'aux' to see all processes with details"
            echo -e "  ${DIM}a = all users, u = user format, x = no terminal required${NC}"
        fi
    fi

    # kill diagnosis
    if [[ "$cmd" == kill* ]]; then
        if [[ ! "$cmd" =~ [0-9]+ ]]; then
            echo -e "  ${RED}Missing PID${NC} - kill needs a process ID"
        fi

        if [[ "$expected" == *"-9"* && "$cmd" != *"-9"* && "$cmd" != *"-KILL"* && "$cmd" != *"-SIGKILL"* ]]; then
            echo -e "  ${YELLOW}Signal${NC} - Use -9 (SIGKILL) for forceful termination"
        fi
    fi
}

_diagnose_tar() {
    local cmd="$1"
    local expected="$2"

    if [[ "$cmd" != tar* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'tar' for archives"
        return
    fi

    # Check for operation mode
    if [[ ! "$cmd" =~ -[cxtv] && ! "$cmd" =~ [cxtv] ]]; then
        echo -e "  ${RED}Missing operation${NC} - tar needs c (create), x (extract), or t (list)"
    fi

    # Check for file flag
    if [[ "$expected" == *"-f"* && "$cmd" != *"-f"* && "$cmd" != *"f"* ]]; then
        echo -e "  ${YELLOW}Missing -f${NC} - Use -f to specify archive filename"
    fi

    # Check compression
    if [[ "$expected" == *".gz"* && "$cmd" != *"-z"* && "$cmd" != *"z"* ]]; then
        echo -e "  ${YELLOW}Compression${NC} - Use -z for gzip (.gz) compression"
    fi
    if [[ "$expected" == *".bz2"* && "$cmd" != *"-j"* && "$cmd" != *"j"* ]]; then
        echo -e "  ${YELLOW}Compression${NC} - Use -j for bzip2 (.bz2) compression"
    fi
    if [[ "$expected" == *".xz"* && "$cmd" != *"-J"* && "$cmd" != *"J"* ]]; then
        echo -e "  ${YELLOW}Compression${NC} - Use -J for xz (.xz) compression"
    fi
}

_diagnose_sed() {
    local cmd="$1"
    local expected="$2"

    if [[ "$cmd" != sed* ]]; then
        echo -e "  ${RED}Wrong command${NC} - Use 'sed' for stream editing"
        return
    fi

    # Check for substitution syntax
    if [[ "$expected" == *"s/"* && "$cmd" != *"s/"* ]]; then
        echo -e "  ${YELLOW}Substitution${NC} - Use s/pattern/replacement/ syntax"
    fi

    # Check for global flag
    if [[ "$expected" == *"/g"* && "$cmd" != *"/g"* ]]; then
        echo -e "  ${YELLOW}Global flag${NC} - Add /g to replace ALL occurrences"
        echo -e "  ${DIM}Without /g, only the first match per line is replaced${NC}"
    fi

    # Check for in-place editing
    if [[ "$expected" == *"-i"* && "$cmd" != *"-i"* ]]; then
        echo -e "  ${YELLOW}In-place${NC} - Use -i to modify file directly"
    fi
}

_diagnose_generic() {
    local cmd="$1"
    local expected="$2"

    echo -e "  ${DIM}Your command: $cmd${NC}"
    echo -e "  ${DIM}Compare with the expected pattern and look for differences${NC}"
}

# ============================================================================
# Elaboration Prompts
# ============================================================================
# Deepens understanding after correct answers

ask_elaboration() {
    local command_type="$1"
    local user_cmd="$2"

    # Only ask sometimes (30% chance) to avoid fatigue
    if [[ $((RANDOM % 100)) -gt 30 ]]; then
        return
    fi

    echo
    echo -e "${CYAN}Quick check - can you explain?${NC}"

    case "$command_type" in
        chmod)
            _elaborate_chmod "$user_cmd"
            ;;
        find)
            _elaborate_find "$user_cmd"
            ;;
        grep)
            _elaborate_grep "$user_cmd"
            ;;
        *)
            return  # Skip elaboration for types we haven't defined
            ;;
    esac
}

_elaborate_chmod() {
    local cmd="$1"

    if [[ "$cmd" =~ ([0-9]{3}) ]]; then
        local mode="${BASH_REMATCH[1]}"
        echo -e "  What does ${CYAN}$mode${NC} mean in words?"
        echo -e "  ${DIM}(Think: who gets what permissions?)${NC}"
        echo
        echo -en "  Your explanation (or Enter to skip): "
        read -r explanation

        if [[ -n "$explanation" ]]; then
            echo
            echo -e "  ${GREEN}Good thinking!${NC} Here's the breakdown:"
            _explain_permission_math "$mode"
        fi
    fi
}

_elaborate_find() {
    local cmd="$1"

    if [[ "$cmd" == *"-exec"* ]]; then
        echo -e "  Why do we need ${CYAN}{}${NC} and ${CYAN}\\;${NC} in -exec?"
        echo
        echo -en "  Your explanation (or Enter to skip): "
        read -r explanation

        if [[ -n "$explanation" ]]; then
            echo
            echo -e "  ${GREEN}Right track!${NC}"
            echo -e "  ${DIM}{} = placeholder where each found file goes${NC}"
            echo -e "  ${DIM}\\; = marks end of the -exec command (escaped from shell)${NC}"
        fi
    elif [[ "$cmd" == *"-name"* ]]; then
        echo -e "  Why must we ${CYAN}quote${NC} the pattern in -name '*.txt'?"
        echo
        echo -en "  Your explanation (or Enter to skip): "
        read -r explanation

        if [[ -n "$explanation" ]]; then
            echo
            echo -e "  ${GREEN}Exactly!${NC}"
            echo -e "  ${DIM}Without quotes, the shell expands * BEFORE find runs${NC}"
            echo -e "  ${DIM}find needs to see the literal * to do its own matching${NC}"
        fi
    fi
}

_elaborate_grep() {
    local cmd="$1"

    if [[ "$cmd" == *"-v"* ]]; then
        echo -e "  When would you use ${CYAN}grep -v${NC} in real work?"
        echo
        echo -en "  Your answer (or Enter to skip): "
        read -r answer

        if [[ -n "$answer" ]]; then
            echo
            echo -e "  ${GREEN}Good thinking!${NC} Common uses:"
            echo -e "  ${DIM}• Exclude comments: grep -v '^#' config.conf${NC}"
            echo -e "  ${DIM}• Filter out noise: ps aux | grep -v grep${NC}"
            echo -e "  ${DIM}• Remove blank lines: grep -v '^$' file${NC}"
        fi
    fi
}

# ============================================================================
# Expert Thinking Traces
# ============================================================================
# Shows step-by-step command building like an expert would

show_expert_thinking() {
    local task_description="$1"
    local command_type="$2"
    local final_command="$3"

    echo
    echo -e "${BOLD}${CYAN}Expert Thinking Process:${NC}"
    echo -e "${DIM}\"Let me think through this step by step...\"${NC}"
    echo

    case "$command_type" in
        find)
            _expert_thinking_find "$task_description" "$final_command"
            ;;
        tar)
            _expert_thinking_tar "$task_description" "$final_command"
            ;;
        permissions)
            _expert_thinking_chmod "$task_description" "$final_command"
            ;;
        pipeline)
            _expert_thinking_pipeline "$task_description" "$final_command"
            ;;
        *)
            _expert_thinking_generic "$final_command"
            ;;
    esac
}

_expert_thinking_find() {
    local task="$1"
    local cmd="$2"

    echo -e "  ${YELLOW}Step 1: Start with 'find'${NC}"
    echo -e "  ${DIM}\"I need to search for files, so find is my tool.\"${NC}"
    sleep 0.5

    echo -e "\n  ${YELLOW}Step 2: Where to search?${NC}"
    if [[ "$cmd" == *" . "* || "$cmd" == "find ."* ]]; then
        echo -e "  ${DIM}\"Starting from current directory: find .\"${NC}"
    elif [[ "$cmd" == *" / "* ]]; then
        echo -e "  ${DIM}\"Searching entire system: find /\"${NC}"
    else
        local path
        path=$(echo "$cmd" | grep -oP 'find \K[^ ]+')
        echo -e "  ${DIM}\"Searching in specific path: find $path\"${NC}"
    fi
    sleep 0.5

    echo -e "\n  ${YELLOW}Step 3: What criteria?${NC}"
    if [[ "$cmd" == *"-name"* ]]; then
        local pattern
        pattern=$(echo "$cmd" | grep -oP -- "-name ['\"]?\K[^'\"]+")
        echo -e "  ${DIM}\"Matching by name pattern: -name '$pattern'\"${NC}"
    fi
    if [[ "$cmd" == *"-type"* ]]; then
        local type
        type=$(echo "$cmd" | grep -oP -- '-type \K[fd]')
        [[ "$type" == "f" ]] && echo -e "  ${DIM}\"Only regular files: -type f\"${NC}"
        [[ "$type" == "d" ]] && echo -e "  ${DIM}\"Only directories: -type d\"${NC}"
    fi
    sleep 0.5

    if [[ "$cmd" == *"-exec"* ]]; then
        echo -e "\n  ${YELLOW}Step 4: What action?${NC}"
        echo -e "  ${DIM}\"Run a command on each match: -exec ... {} \\;\"${NC}"
        echo -e "  ${DIM}\"The {} is where the filename goes\"${NC}"
    fi

    echo -e "\n  ${GREEN}Final command: $cmd${NC}"
}

_expert_thinking_tar() {
    local task="$1"
    local cmd="$2"

    echo -e "  ${YELLOW}Step 1: What operation?${NC}"
    if [[ "$cmd" == *"c"* && "$cmd" != *"x"* ]]; then
        echo -e "  ${DIM}\"Creating an archive: need -c flag\"${NC}"
    elif [[ "$cmd" == *"x"* ]]; then
        echo -e "  ${DIM}\"Extracting from archive: need -x flag\"${NC}"
    elif [[ "$cmd" == *"t"* ]]; then
        echo -e "  ${DIM}\"Listing contents: need -t flag\"${NC}"
    fi
    sleep 0.5

    echo -e "\n  ${YELLOW}Step 2: Compression?${NC}"
    if [[ "$cmd" == *"z"* ]]; then
        echo -e "  ${DIM}\"Using gzip compression: -z for .gz files\"${NC}"
    elif [[ "$cmd" == *"j"* ]]; then
        echo -e "  ${DIM}\"Using bzip2 compression: -j for .bz2 files\"${NC}"
    elif [[ "$cmd" == *"J"* ]]; then
        echo -e "  ${DIM}\"Using xz compression: -J for .xz files\"${NC}"
    else
        echo -e "  ${DIM}\"No compression: plain .tar archive\"${NC}"
    fi
    sleep 0.5

    echo -e "\n  ${YELLOW}Step 3: Archive file${NC}"
    echo -e "  ${DIM}\"Specify the archive with -f: -f archive.tar.gz\"${NC}"
    sleep 0.5

    echo -e "\n  ${YELLOW}Step 4: Verbose?${NC}"
    if [[ "$cmd" == *"v"* ]]; then
        echo -e "  ${DIM}\"Show progress with -v: see files as they're processed\"${NC}"
    fi

    echo -e "\n  ${GREEN}Final command: $cmd${NC}"
}

_expert_thinking_chmod() {
    local task="$1"
    local cmd="$2"

    echo -e "  ${YELLOW}Step 1: Who needs permission changes?${NC}"

    if [[ "$cmd" =~ ([0-9]{3}) ]]; then
        local mode="${BASH_REMATCH[1]}"
        local u="${mode:0:1}"
        local g="${mode:1:1}"
        local o="${mode:2:1}"

        echo -e "  ${DIM}\"Breaking down $mode:\"${NC}"
        echo -e "  ${DIM}  User (owner):  $u = $(_decode_perm_digit "$u")${NC}"
        echo -e "  ${DIM}  Group:         $g = $(_decode_perm_digit "$g")${NC}"
        echo -e "  ${DIM}  Others:        $o = $(_decode_perm_digit "$o")${NC}"
    elif [[ "$cmd" == *"u+"* || "$cmd" == *"g+"* || "$cmd" == *"o+"* ]]; then
        echo -e "  ${DIM}\"Using symbolic mode to ADD permissions\"${NC}"
        [[ "$cmd" == *"u+"* ]] && echo -e "  ${DIM}  u+ = add for user${NC}"
        [[ "$cmd" == *"g+"* ]] && echo -e "  ${DIM}  g+ = add for group${NC}"
        [[ "$cmd" == *"o+"* ]] && echo -e "  ${DIM}  o+ = add for others${NC}"
        [[ "$cmd" == *"a+"* ]] && echo -e "  ${DIM}  a+ = add for all${NC}"
    fi

    echo -e "\n  ${GREEN}Final command: $cmd${NC}"
}

_expert_thinking_pipeline() {
    local task="$1"
    local cmd="$2"

    echo -e "  ${YELLOW}Building a pipeline step by step:${NC}"

    # Split by pipe
    IFS='|' read -ra stages <<< "$cmd"
    local step=1

    for stage in "${stages[@]}"; do
        stage=$(echo "$stage" | xargs)  # Trim whitespace
        echo -e "\n  ${CYAN}Stage $step:${NC} $stage"

        case "$stage" in
            grep*) echo -e "  ${DIM}\"Filter: keep only matching lines\"${NC}" ;;
            awk*)  echo -e "  ${DIM}\"Transform: extract/format specific fields\"${NC}" ;;
            sed*)  echo -e "  ${DIM}\"Edit: modify text on the fly\"${NC}" ;;
            sort*) echo -e "  ${DIM}\"Order: arrange lines alphabetically/numerically\"${NC}" ;;
            uniq*) echo -e "  ${DIM}\"Dedupe: remove consecutive duplicate lines\"${NC}" ;;
            wc*)   echo -e "  ${DIM}\"Count: lines, words, or characters\"${NC}" ;;
            head*) echo -e "  ${DIM}\"Limit: show only first N lines\"${NC}" ;;
            tail*) echo -e "  ${DIM}\"Limit: show only last N lines\"${NC}" ;;
            cut*)  echo -e "  ${DIM}\"Extract: specific columns/fields\"${NC}" ;;
            *)     echo -e "  ${DIM}\"Process the data...\"${NC}" ;;
        esac

        ((step++))
        sleep 0.3
    done

    echo -e "\n  ${GREEN}Data flows left to right through each stage${NC}"
}

_expert_thinking_generic() {
    local cmd="$1"

    echo -e "  ${DIM}\"The command: $cmd\"${NC}"
    echo -e "  ${DIM}\"Each part has a purpose - let's break it down...\"${NC}"

    local parts=($cmd)
    echo -e "\n  ${CYAN}${parts[0]}${NC} - the command/program"

    for ((i=1; i<${#parts[@]}; i++)); do
        local part="${parts[$i]}"
        if [[ "$part" == -* ]]; then
            echo -e "  ${CYAN}$part${NC} - an option/flag"
        else
            echo -e "  ${CYAN}$part${NC} - an argument"
        fi
    done
}

# ============================================================================
# Spaced Repetition Helpers
# ============================================================================
# Identifies weak commands and suggests optimal review timing

get_weak_commands() {
    local limit="${1:-5}"

    [[ ! -f "$DB_FILE" ]] && return

    # Get commands with attempts but low success rate
    sqlite3 "$DB_FILE" << SQL
SELECT command, successes, attempts,
       ROUND(100.0 * successes / attempts, 0) as rate
FROM commands
WHERE attempts >= 2
  AND (100.0 * successes / attempts) < 70
ORDER BY rate ASC, attempts DESC
LIMIT $limit;
SQL
}

get_stale_commands() {
    local days="${1:-7}"

    [[ ! -f "$DB_FILE" ]] && return

    # Get commands not practiced recently
    sqlite3 "$DB_FILE" << SQL
SELECT command,
       COALESCE(julianday('now') - julianday(last_practiced), 999) as days_ago
FROM commands
WHERE attempts > 0
  AND (last_practiced IS NULL
       OR julianday('now') - julianday(last_practiced) > $days)
ORDER BY days_ago DESC
LIMIT 5;
SQL
}

suggest_review_topic() {
    [[ ! -f "$DB_FILE" ]] && echo "grep" && return

    # Priority 1: Weak commands (low success rate)
    local weak
    weak=$(get_weak_commands 1)
    if [[ -n "$weak" ]]; then
        local cmd
        cmd=$(echo "$weak" | cut -d'|' -f1)
        _command_to_topic "$cmd"
        return
    fi

    # Priority 2: Stale commands (not practiced recently)
    local stale
    stale=$(get_stale_commands 1)
    if [[ -n "$stale" ]]; then
        local cmd
        cmd=$(echo "$stale" | cut -d'|' -f1)
        _command_to_topic "$cmd"
        return
    fi

    # Default
    echo "grep"
}

_command_to_topic() {
    local cmd="$1"

    case "$cmd" in
        grep|egrep|fgrep) echo "grep" ;;
        sed) echo "sed" ;;
        awk|gawk) echo "awk" ;;
        find|locate) echo "find" ;;
        tar|gzip|bzip2|xz) echo "tar" ;;
        chmod|chown|chgrp|umask) echo "permissions" ;;
        ps|kill|jobs|bg|fg|nice|nohup) echo "processes" ;;
        useradd|usermod|userdel|groupadd|passwd) echo "users" ;;
        ip|ss|ping|dig|netstat|traceroute) echo "networking" ;;
        mount|umount|df|du|fdisk|lsblk|mkfs*) echo "filesystems" ;;
        systemctl|journalctl) echo "systemd" ;;
        *) echo "grep" ;;  # Default
    esac
}

show_review_recommendation() {
    echo
    echo -e "${BOLD}${CYAN}Smart Review Recommendation${NC}"
    echo

    local weak
    weak=$(get_weak_commands 3)
    if [[ -n "$weak" ]]; then
        echo -e "${YELLOW}Commands needing practice:${NC}"
        while IFS='|' read -r cmd successes attempts rate; do
            [[ -z "$cmd" ]] && continue
            echo -e "  ${RED}•${NC} $cmd ($successes/$attempts = $rate%)"
        done <<< "$weak"
        echo
    fi

    local stale
    stale=$(get_stale_commands 3)
    if [[ -n "$stale" ]]; then
        echo -e "${YELLOW}Haven't practiced recently:${NC}"
        while IFS='|' read -r cmd days; do
            [[ -z "$cmd" ]] && continue
            local days_int="${days%.*}"
            if [[ "$days_int" -gt 30 ]]; then
                echo -e "  ${RED}•${NC} $cmd (${days_int} days ago)"
            else
                echo -e "  ${YELLOW}•${NC} $cmd (${days_int} days ago)"
            fi
        done <<< "$stale"
        echo
    fi

    local suggested
    suggested=$(suggest_review_topic)
    echo -e "${GREEN}Suggested focus:${NC} lpic-train practice $suggested"
}

# ============================================================================
# Interleaved Practice Generator
# ============================================================================
# Creates mixed-topic exercise sessions

generate_interleaved_session() {
    local count="${1:-10}"

    # Topics to interleave
    local topics=("grep" "find" "chmod" "ps" "tar" "sed")
    local challenges=()

    for ((i=0; i<count; i++)); do
        # Pick random topic
        local topic="${topics[$((RANDOM % ${#topics[@]}))]}"
        challenges+=("$topic")
    done

    echo "${challenges[@]}"
}

# ============================================================================
# Muscle Memory Reinforcement
# ============================================================================
# Quick-fire drills for building automatic recall

run_quick_drill() {
    local topic="$1"
    local rounds="${2:-5}"

    echo
    echo -e "${BOLD}${CYAN}Quick Drill: $topic${NC}"
    echo -e "${DIM}Answer as fast as you can! Speed builds muscle memory.${NC}"
    echo

    local correct=0
    local start_time
    start_time=$(date +%s)

    for ((i=1; i<=rounds; i++)); do
        local question answer
        _get_drill_question "$topic" question answer

        echo -e "${YELLOW}Q$i:${NC} $question"
        echo -en ">>> "
        read -r user_answer

        if _check_drill_answer "$user_answer" "$answer"; then
            echo -e "${GREEN}✓${NC}"
            ((correct++))
        else
            echo -e "${RED}✗${NC} Answer: $answer"
        fi
        echo
    done

    local end_time
    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    echo -e "${BOLD}Results:${NC} $correct/$rounds correct in ${elapsed}s"

    if [[ $correct -eq $rounds ]]; then
        echo -e "${GREEN}Perfect! Your $topic recall is solid.${NC}"
    elif [[ $correct -ge $((rounds * 7 / 10)) ]]; then
        echo -e "${YELLOW}Good! Keep practicing to build speed.${NC}"
    else
        echo -e "${RED}Review the basics: lpic-train learn $topic${NC}"
    fi
}

_get_drill_question() {
    local topic="$1"
    local -n q=$2
    local -n a=$3

    case "$topic" in
        chmod)
            local drills=(
                "rwxr-xr-x in numeric?|755"
                "rw-r--r-- in numeric?|644"
                "rwx------ in numeric?|700"
                "r=? w=? x=?|4 2 1"
                "What does 777 mean?|rwxrwxrwx"
                "Execute permission for owner only?|u+x or 100"
            )
            ;;
        grep)
            local drills=(
                "Case insensitive flag?|-i"
                "Recursive search flag?|-r"
                "Show line numbers?|-n"
                "Invert match (exclude)?|-v"
                "Count matches only?|-c"
                "Extended regex flag?|-E"
            )
            ;;
        find)
            local drills=(
                "Find by name pattern?|-name"
                "Find only files?|-type f"
                "Find only directories?|-type d"
                "Execute command on results?|-exec"
                "Find by size?|-size"
                "Find modified in last day?|-mtime -1"
            )
            ;;
        ps)
            local drills=(
                "Show all processes BSD style?|aux"
                "Show all processes UNIX style?|-ef"
                "Show process tree?|--forest or axjf"
                "Filter by user?|-u username"
                "Default signal for kill?|15 or TERM"
                "Force kill signal?|9 or KILL"
            )
            ;;
        *)
            local drills=(
                "What command searches file contents?|grep"
                "What command finds files?|find"
                "What command changes permissions?|chmod"
                "What command lists processes?|ps"
            )
            ;;
    esac

    local random_drill="${drills[$((RANDOM % ${#drills[@]}))]}"
    q="${random_drill%%|*}"
    a="${random_drill##*|}"
}

_check_drill_answer() {
    local user="$1"
    local expected="$2"

    # Normalize
    user=$(echo "$user" | tr '[:upper:]' '[:lower:]' | xargs)
    expected=$(echo "$expected" | tr '[:upper:]' '[:lower:]')

    # Check if user answer contains the expected answer
    [[ "$user" == *"$expected"* ]] || [[ "$expected" == *"$user"* ]]
}
