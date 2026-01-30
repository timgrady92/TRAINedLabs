#!/bin/bash
# LPIC-1 Training - Skill Checker
# Interactive command proficiency testing with randomized challenges
# Usage: skill-checker.sh [topic] [--timed]

set -euo pipefail

# Configuration
LPIC_DIR="/opt/LPIC-1/data"
DB_FILE="${LPIC_DIR}/progress.db"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Symbols
PASS="✓"
FAIL="✗"
WARN="⚠"

print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
print_header() { echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}\n"; }

# Challenge definitions
declare -A CHALLENGES

# Topic 103 - GNU and Unix Commands
CHALLENGES["grep-basic"]="Find lines containing 'error' in a log file|grep 'error' FILE|grep error /var/log/syslog"
CHALLENGES["grep-count"]="Count lines containing 'warning' in a file|grep -c 'warning' FILE|grep -c warning"
CHALLENGES["grep-recursive"]="Recursively search for 'TODO' in current directory|grep -r 'TODO' .|grep -rn TODO"
CHALLENGES["grep-invert"]="Show lines NOT containing 'comment'|grep -v 'comment' FILE|grep -v comment"

CHALLENGES["find-name"]="Find all .conf files in /etc|find /etc -name '*.conf'|find /etc -name *.conf"
CHALLENGES["find-type"]="Find all directories in /var|find /var -type d|find /var -type d"
CHALLENGES["find-size"]="Find files larger than 10MB in /home|find /home -size +10M|find /home -size +10M"
CHALLENGES["find-mtime"]="Find files modified in the last 7 days|find . -mtime -7|find -mtime -7"

CHALLENGES["sed-replace"]="Replace 'old' with 'new' in a file|sed 's/old/new/g' FILE|sed s/old/new/g"
CHALLENGES["sed-delete"]="Delete lines containing 'remove'|sed '/remove/d' FILE|sed /remove/d"
CHALLENGES["sed-line"]="Print only line 5 of a file|sed -n '5p' FILE|sed -n 5p"

CHALLENGES["awk-print"]="Print second column of a file|awk '{print \$2}' FILE|awk {print \$2}"
CHALLENGES["awk-sum"]="Sum the first column of a file|awk '{sum+=\$1} END{print sum}' FILE|awk sum"
CHALLENGES["awk-filter"]="Print lines where column 3 > 100|awk '\$3 > 100' FILE|awk \$3 > 100"

CHALLENGES["tar-create"]="Create a gzipped archive of /home/user|tar -czvf archive.tar.gz /home/user|tar -czvf"
CHALLENGES["tar-extract"]="Extract a tar.gz archive|tar -xzvf archive.tar.gz|tar -xzvf"
CHALLENGES["tar-list"]="List contents of a tar archive|tar -tvf archive.tar|tar -tvf"

# Topic 103.5 - Process Management
CHALLENGES["ps-all"]="Show all processes with full details|ps aux|ps aux"
CHALLENGES["ps-tree"]="Show process tree|ps axjf OR pstree|ps axjf"
CHALLENGES["kill-signal"]="Send SIGTERM to process 1234|kill 1234 OR kill -15 1234|kill"
CHALLENGES["kill-force"]="Force kill process 1234|kill -9 1234 OR kill -SIGKILL 1234|kill -9"

# Topic 104 - Filesystems
CHALLENGES["chmod-numeric"]="Set file permissions to rwxr-xr--|chmod 754 FILE|chmod 754"
CHALLENGES["chmod-symbolic"]="Add execute permission for owner|chmod u+x FILE|chmod u+x"
CHALLENGES["chown-both"]="Change owner to bob and group to staff|chown bob:staff FILE|chown bob:staff"

CHALLENGES["ln-symbolic"]="Create symbolic link 'link' pointing to 'target'|ln -s target link|ln -s"
CHALLENGES["ln-hard"]="Create hard link 'hardlink' to 'file'|ln file hardlink|ln file"

# Topic 107 - Administrative Tasks
CHALLENGES["useradd-home"]="Create user 'john' with home directory|useradd -m john|useradd -m"
CHALLENGES["usermod-group"]="Add user 'john' to group 'docker'|usermod -aG docker john|usermod -aG"
CHALLENGES["passwd-expire"]="Force user to change password on next login|passwd -e USERNAME|passwd -e"

CHALLENGES["cron-minute"]="Run script every 5 minutes|*/5 * * * * /path/script.sh|*/5"
CHALLENGES["cron-daily"]="Run script daily at 3:30 AM|30 3 * * * /path/script.sh|30 3"
CHALLENGES["cron-weekday"]="Run script every Monday at 9 AM|0 9 * * 1 /path/script.sh|* * 1"

# Topic 109 - Networking
CHALLENGES["ip-addr"]="Show all IP addresses|ip addr OR ip a|ip addr"
CHALLENGES["ip-route"]="Show routing table|ip route OR ip r|ip route"
CHALLENGES["ss-listen"]="Show listening TCP ports|ss -tlnp|ss -tln"

CHALLENGES["dig-simple"]="Query DNS for example.com|dig example.com|dig"
CHALLENGES["ping-count"]="Send exactly 3 pings to a host|ping -c 3 HOST|ping -c 3"

# Get random challenge
get_random_challenge() {
    local topic="${1:-all}"
    local keys=()

    for key in "${!CHALLENGES[@]}"; do
        if [[ "$topic" == "all" ]] || [[ "$key" == "$topic"* ]]; then
            keys+=("$key")
        fi
    done

    if [[ ${#keys[@]} -eq 0 ]]; then
        echo ""
        return
    fi

    local random_index=$((RANDOM % ${#keys[@]}))
    echo "${keys[$random_index]}"
}

# Parse challenge data
parse_challenge() {
    local challenge_data="$1"
    IFS='|' read -r description answer hint <<< "$challenge_data"
    echo "$description"
    echo "$answer"
    echo "$hint"
}

# Run a single challenge
run_challenge() {
    local challenge_id="$1"
    local timed="${2:-false}"

    if [[ -z "${CHALLENGES[$challenge_id]:-}" ]]; then
        print_fail "Unknown challenge: $challenge_id"
        return 1
    fi

    local challenge_data="${CHALLENGES[$challenge_id]}"
    local description answer hint
    IFS='|' read -r description answer hint <<< "$challenge_data"

    echo
    echo -e "${BOLD}Challenge:${NC} $description"
    echo

    local start_time
    start_time=$(date +%s)

    # Get user input
    echo -en "Your command: "
    read -r user_answer

    local end_time
    end_time=$(date +%s)
    local time_taken=$((end_time - start_time))

    # Normalize answers for comparison
    local normalized_user normalized_answer
    normalized_user=$(echo "$user_answer" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    normalized_answer=$(echo "$answer" | tr -s ' ' | sed 's/^ *//;s/ *$//')

    # Check if answer is correct (flexible matching)
    local correct=false

    # Exact match
    if [[ "$normalized_user" == "$normalized_answer" ]]; then
        correct=true
    fi

    # Check if user answer contains key elements
    if [[ "$correct" == "false" ]]; then
        # Split hint into key parts and check if all are present
        local hint_parts
        IFS=' ' read -ra hint_parts <<< "$hint"
        local matches=0
        for part in "${hint_parts[@]}"; do
            if [[ "$normalized_user" == *"$part"* ]]; then
                ((matches++)) || true
            fi
        done
        if [[ $matches -eq ${#hint_parts[@]} ]]; then
            correct=true
        fi
    fi

    echo

    if [[ "$correct" == "true" ]]; then
        print_pass "Correct!"
        if [[ "$timed" == "true" ]]; then
            echo "Time: ${time_taken}s"
        fi

        # Update database
        if [[ -f "$DB_FILE" ]]; then
            local cmd_name="${challenge_id%%-*}"
            sqlite3 "$DB_FILE" "UPDATE commands SET successes = successes + 1, attempts = attempts + 1, last_practiced = datetime('now') WHERE command LIKE '%$cmd_name%' LIMIT 1;" 2>/dev/null || true
        fi

        return 0
    else
        print_fail "Not quite right"
        echo -e "Expected: ${CYAN}$answer${NC}"
        echo -e "Hint: Key elements are: ${YELLOW}$hint${NC}"

        # Update database (attempt but no success)
        if [[ -f "$DB_FILE" ]]; then
            local cmd_name="${challenge_id%%-*}"
            sqlite3 "$DB_FILE" "UPDATE commands SET attempts = attempts + 1, last_practiced = datetime('now') WHERE command LIKE '%$cmd_name%' LIMIT 1;" 2>/dev/null || true
        fi

        return 1
    fi
}

# Run a skill check session
run_session() {
    local topic="${1:-all}"
    local count="${2:-5}"
    local timed="${3:-false}"

    print_header "LPIC-1 Skill Check"
    echo "Topic: $topic"
    echo "Questions: $count"
    echo "Timed: $timed"
    echo

    local correct=0
    local total=0

    for ((i=1; i<=count; i++)); do
        echo -e "${BOLD}Question $i of $count${NC}"

        local challenge_id
        challenge_id=$(get_random_challenge "$topic")

        if [[ -z "$challenge_id" ]]; then
            print_warn "No challenges found for topic: $topic"
            break
        fi

        ((total++)) || true
        if run_challenge "$challenge_id" "$timed"; then
            ((correct++)) || true
        fi

        echo
        if [[ $i -lt $count ]]; then
            echo -en "Press Enter for next question..."
            read -r _
        fi
    done

    print_header "Session Results"
    echo "Score: $correct/$total"
    local percent=$((correct * 100 / total))
    echo "Percentage: $percent%"

    if [[ $percent -ge 80 ]]; then
        print_pass "Excellent work!"
    elif [[ $percent -ge 60 ]]; then
        print_warn "Good effort, keep practicing"
    else
        print_fail "More practice needed"
    fi

    # Record session
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" "INSERT INTO sessions (started_at, ended_at, objectives_practiced) VALUES (datetime('now'), datetime('now'), '$topic');" 2>/dev/null || true
    fi
}

# List available topics
list_topics() {
    print_header "Available Topics"

    echo "Command categories:"
    echo "  grep     - Text searching with grep"
    echo "  find     - Finding files"
    echo "  sed      - Stream editing"
    echo "  awk      - Text processing"
    echo "  tar      - Archive management"
    echo "  ps       - Process listing"
    echo "  kill     - Process termination"
    echo "  chmod    - Permission changes"
    echo "  chown    - Ownership changes"
    echo "  ln       - Link creation"
    echo "  useradd  - User creation"
    echo "  usermod  - User modification"
    echo "  cron     - Cron scheduling"
    echo "  ip       - Network configuration"
    echo "  ss       - Socket statistics"
    echo "  dig      - DNS queries"
    echo "  ping     - Network connectivity"
    echo
    echo "Use 'all' to include all topics"
}

# Practice a specific command
practice_command() {
    local cmd="$1"

    print_header "Practice: $cmd"

    # Find challenges for this command
    local found=false
    for key in "${!CHALLENGES[@]}"; do
        if [[ "$key" == "$cmd"* ]]; then
            found=true
            echo "Challenge: $key"
            run_challenge "$key" false
            echo
        fi
    done

    if [[ "$found" == "false" ]]; then
        print_warn "No challenges found for: $cmd"
        echo
        echo "Try one of these:"
        list_topics
    fi
}

# Usage
usage() {
    cat << 'EOF'
LPIC-1 Skill Checker

Usage: skill-checker.sh [command] [options]

Commands:
  session [topic]     Run a practice session (default: 5 questions)
  practice <cmd>      Practice a specific command
  list                List available topics
  challenge <id>      Run a specific challenge

Options:
  -n, --count N       Number of questions (default: 5)
  -t, --timed         Enable timing for each question
  -h, --help          Show this help

Examples:
  skill-checker.sh session                 # Random questions from all topics
  skill-checker.sh session grep -n 10      # 10 grep questions
  skill-checker.sh practice find           # Practice find commands
  skill-checker.sh list                    # Show available topics

Topics:
  grep, find, sed, awk, tar, ps, kill, chmod, chown, ln,
  useradd, usermod, cron, ip, ss, dig, ping, all
EOF
}

# Main
main() {
    local command="${1:-session}"
    shift 2>/dev/null || true

    local topic="all"
    local count=5
    local timed=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--count)
                count="$2"
                shift 2
                ;;
            -t|--timed)
                timed=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                topic="$1"
                shift
                ;;
        esac
    done

    case $command in
        session)
            run_session "$topic" "$count" "$timed"
            ;;
        practice)
            practice_command "$topic"
            ;;
        list)
            list_topics
            ;;
        challenge)
            run_challenge "$topic" "$timed"
            ;;
        -h|--help)
            usage
            ;;
        *)
            # Treat as topic for session
            run_session "$command" "$count" "$timed"
            ;;
    esac
}

main "$@"
