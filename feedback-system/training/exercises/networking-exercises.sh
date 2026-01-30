#!/bin/bash
# LPIC-1 Training - Networking Exercises
# Guided exercises with progressive hints

if [[ -z "${PRACTICE_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
fi

# ============================================================================
# Exercise 1: View IP Addresses
# ============================================================================

exercise_ip_addr() {
    print_exercise "ip: View IP Addresses"

    cat << 'SCENARIO'
SCENARIO:
You need to check what IP addresses are configured on this system.
Use the modern 'ip' command (not the deprecated ifconfig).
SCENARIO

    echo
    print_task "Show all IP addresses using the 'ip' command"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == "ip addr"* ]] || [[ "$user_cmd" == "ip a"* ]] || \
           [[ "$user_cmd" == "ip address"* ]]; then
            echo
            print_pass "Correct!"
            echo "Output (abbreviated):"
            ip addr 2>/dev/null | head -12 | sed 's/^/  /'
            record_exercise_attempt "ip" "addr" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "The 'ip' command has subcommands.
  For addresses, use ip with the address object."
                    ;;
                2)
                    show_hint 2 "Command: ip addr
  Short form: ip a"
                    ;;
                *)
                    show_solution "ip addr"
                    echo "Also: ip a, ip address show"
                    record_exercise_attempt "ip" "addr" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 2: View Routing Table
# ============================================================================

exercise_ip_route() {
    print_exercise "ip: View Routing Table"

    cat << 'SCENARIO'
SCENARIO:
You need to check the system's routing table to see the default
gateway and network routes.
SCENARIO

    echo
    print_task "Show the routing table using 'ip' command"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == "ip route"* ]] || [[ "$user_cmd" == "ip r"* ]]; then
            echo
            print_pass "Correct!"
            echo "Routing table:"
            ip route 2>/dev/null | head -8 | sed 's/^/  /'
            record_exercise_attempt "ip" "route" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "Use ip with the route object.
  Think: ip route"
                    ;;
                2)
                    show_hint 2 "Command: ip route
  Short form: ip r"
                    ;;
                *)
                    show_solution "ip route"
                    echo "Also: ip r, ip route show"
                    record_exercise_attempt "ip" "route" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 3: View Listening Ports
# ============================================================================

exercise_ss_listen() {
    print_exercise "ss: View Listening TCP Ports"

    cat << 'SCENARIO'
SCENARIO:
You need to see what services are listening for connections on this
server. Show listening TCP ports with their process information.
SCENARIO

    echo
    print_task "Show listening TCP ports with process names (use ss, not netstat)"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"ss"* ]] && [[ "$user_cmd" == *"-t"* ]] && \
           [[ "$user_cmd" == *"-l"* ]]; then
            echo
            print_pass "Correct!"
            echo "Common options: -t=TCP, -l=listening, -n=numeric, -p=process"
            echo "Output:"
            ss -tlnp 2>/dev/null | head -8 | sed 's/^/  /' || \
                echo "  (may need root for -p)"
            record_exercise_attempt "ss" "listen" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need ss with TCP and listening options."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "ss shows socket statistics (like netstat).
  Use -t for TCP, -l for listening."
                    ;;
                2)
                    show_hint 2 "Common combination: ss -tlnp
  t=TCP, l=listening, n=numeric, p=process"
                    ;;
                *)
                    show_solution "ss -tlnp"
                    record_exercise_attempt "ss" "listen" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 4: DNS Lookup
# ============================================================================

exercise_dig() {
    print_exercise "dig: DNS Lookup"

    cat << 'SCENARIO'
SCENARIO:
You need to query DNS to find the IP address of example.com.
Use the 'dig' command for DNS queries.
SCENARIO

    echo
    print_task "Query DNS for example.com using dig"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"dig"* ]] && [[ "$user_cmd" == *"example.com"* ]]; then
            echo
            print_pass "Correct!"
            echo "dig performs DNS queries and shows detailed results."
            echo "Use +short for just the IP: dig +short example.com"
            record_exercise_attempt "dig" "query" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Not quite."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "dig is the DNS query tool.
  Basic syntax: dig hostname"
                    ;;
                2)
                    show_hint 2 "Simply: dig example.com
  For brief output: dig +short example.com"
                    ;;
                *)
                    show_solution "dig example.com"
                    record_exercise_attempt "dig" "query" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise 5: Ping with Count
# ============================================================================

exercise_ping() {
    print_exercise "ping: Test Connectivity"

    cat << 'SCENARIO'
SCENARIO:
You need to test network connectivity to google.com, but only send
3 ping packets (not continuous).
SCENARIO

    echo
    print_task "Send exactly 3 pings to google.com"
    echo

    local attempts=0

    while true; do
        echo -en "Your command: "
        read -r user_cmd

        if [[ "$user_cmd" == "skip" || "$user_cmd" == "s" ]]; then
            return 1
        fi

        if [[ "$user_cmd" == *"ping"* ]] && [[ "$user_cmd" == *"-c"* ]] && \
           [[ "$user_cmd" == *"3"* ]]; then
            echo
            print_pass "Correct!"
            echo "-c specifies the count of packets to send."
            record_exercise_attempt "ping" "count" 1
            return 0
        fi

        ((attempts++))
        echo
        print_fail "Need to specify count with -c."

        if [[ "${LPIC_NO_HINTS:-}" != "1" ]]; then
            case $attempts in
                1)
                    show_hint 1 "ping runs continuously by default.
  There's an option to limit the count."
                    ;;
                2)
                    show_hint 2 "Use -c to specify count.
  Syntax: ping -c 3 hostname"
                    ;;
                *)
                    show_solution "ping -c 3 google.com"
                    record_exercise_attempt "ping" "count" 0
                    return 1
                    ;;
            esac
        fi

        echo
        echo -en "Try again? [Y/n/skip] "
        read -r choice
        [[ "$choice" == "n" ]] && return 1
    done
}

# ============================================================================
# Exercise Runner
# ============================================================================

run_networking_exercises() {
    local count="${1:-5}"
    local exercises=(
        exercise_ip_addr
        exercise_ip_route
        exercise_ss_listen
        exercise_dig
        exercise_ping
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
            echo -en "Press Enter for next exercise (or 'q' to quit)... "
            read -r choice
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
        print_info "Review the lesson: lpic-train learn networking"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    run_networking_exercises "$@"
fi
