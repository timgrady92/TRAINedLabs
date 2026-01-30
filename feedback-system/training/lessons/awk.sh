#!/bin/bash
# LPIC-1 Training - awk Lesson
# Objective: 103.2 - Process text streams using filters

lesson_awk() {
    print_header "awk - Pattern Scanning and Processing"

    cat << 'INTRO'
awk is a powerful text processing language that excels at working with
columnar data. It automatically splits each line into fields and provides
built-in variables and functions for sophisticated data manipulation.

Named after its creators: Aho, Weinberger, and Kernighan.
INTRO

    echo
    echo -e "${BOLD}Real-World Uses:${NC}"
    echo "  ${BULLET} Processing CSV and columnar data"
    echo "  ${BULLET} Generating reports from log files"
    echo "  ${BULLET} Calculating sums, averages, statistics"
    echo "  ${BULLET} Reformatting output from other commands"
    echo "  ${BULLET} Extracting specific fields from text"

    wait_for_user

    # Basic Syntax
    print_subheader "Basic Syntax"

    echo -e "${BOLD}awk 'pattern { action }' file${NC}"
    echo -e "${BOLD}command | awk 'pattern { action }'${NC}"
    echo
    echo "  pattern - When to apply the action (optional)"
    echo "  action  - What to do (default: print entire line)"
    echo

    echo -e "${BOLD}Common Options:${NC}"
    echo -e "  ${CYAN}-F sep${NC}     Set field separator (default: whitespace)"
    echo -e "  ${CYAN}-v var=val${NC} Set variable"
    echo -e "  ${CYAN}-f file${NC}    Read program from file"

    wait_for_user

    # Fields
    print_subheader "Fields and Records"

    cat << 'FIELDS'
awk automatically splits each line (record) into fields:
  $0 = entire line
  $1 = first field
  $2 = second field
  ... and so on
  $NF = last field
FIELDS
    echo

    local users_file
    users_file=$(get_practice_file "text" "users.txt")
    local servers_file
    servers_file=$(get_practice_file "text" "servers.txt")

    if [[ -f "$users_file" ]]; then
        echo -e "${CYAN}Example: Print first field (usernames)${NC}"
        echo -e "${BOLD}Command:${NC} awk -F: '{print \$1}' text/users.txt"
        echo -e "${DIM}Output:${NC}"
        awk -F: '{print $1}' "$users_file" 2>/dev/null | head -5 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Print username and shell${NC}"
        echo -e "${BOLD}Command:${NC} awk -F: '{print \$1, \$7}' text/users.txt"
        echo -e "${DIM}Output:${NC}"
        awk -F: '{print $1, $7}' "$users_file" 2>/dev/null | head -5 | sed 's/^/  /'
    fi

    wait_for_user

    # Built-in Variables
    print_subheader "Built-in Variables"

    echo -e "${CYAN}NF${NC}      Number of fields in current record"
    echo -e "${CYAN}NR${NC}      Number of records processed (line number)"
    echo -e "${CYAN}FNR${NC}     Record number in current file"
    echo -e "${CYAN}FS${NC}      Field separator (input)"
    echo -e "${CYAN}OFS${NC}     Output field separator"
    echo -e "${CYAN}RS${NC}      Record separator (input)"
    echo -e "${CYAN}ORS${NC}     Output record separator"
    echo -e "${CYAN}FILENAME${NC} Current filename"
    echo

    if [[ -f "$servers_file" ]]; then
        echo -e "${CYAN}Example: Print line numbers with content${NC}"
        echo -e "${BOLD}Command:${NC} awk '{print NR, \$0}' text/servers.txt | head -3"
        echo -e "${DIM}Output:${NC}"
        awk '{print NR, $0}' "$servers_file" | head -3 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Print number of fields per line${NC}"
        echo -e "${BOLD}Command:${NC} awk '{print NF, \"fields:\", \$0}' text/servers.txt | head -3"
        echo -e "${DIM}Output:${NC}"
        awk '{print NF, "fields:", $0}' "$servers_file" | head -3 | sed 's/^/  /'
    fi

    wait_for_user

    # Pattern Matching
    print_subheader "Pattern Matching"

    echo -e "${BOLD}Types of patterns:${NC}"
    echo -e "  ${CYAN}/regex/${NC}           Lines matching regex"
    echo -e "  ${CYAN}expression${NC}        Lines where expression is true"
    echo -e "  ${CYAN}pattern1,pattern2${NC} Range between patterns"
    echo -e "  ${CYAN}BEGIN${NC}             Before first record"
    echo -e "  ${CYAN}END${NC}               After last record"
    echo

    if [[ -f "$servers_file" ]]; then
        echo -e "${CYAN}Example: Print lines containing 'Ubuntu'${NC}"
        echo -e "${BOLD}Command:${NC} awk '/Ubuntu/' text/servers.txt"
        echo -e "${DIM}Output:${NC}"
        awk '/Ubuntu/' "$servers_file" | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Print active servers only${NC}"
        echo -e "${BOLD}Command:${NC} awk '\$6 == \"active\"' text/servers.txt"
        echo -e "${DIM}Output:${NC}"
        awk '$6 == "active"' "$servers_file" | head -5 | sed 's/^/  /'
    fi

    wait_for_user

    # Comparison and Logic
    print_subheader "Comparisons and Logic"

    echo -e "${BOLD}Comparison operators:${NC}"
    echo -e "  ${CYAN}==${NC}  Equal          ${CYAN}!=${NC}  Not equal"
    echo -e "  ${CYAN}<${NC}   Less than      ${CYAN}>${NC}   Greater than"
    echo -e "  ${CYAN}<=${NC}  Less or equal  ${CYAN}>=${NC}  Greater or equal"
    echo -e "  ${CYAN}~${NC}   Regex match    ${CYAN}!~${NC}  Regex not match"
    echo
    echo -e "${BOLD}Logical operators:${NC}"
    echo -e "  ${CYAN}&&${NC}  AND"
    echo -e "  ${CYAN}||${NC}  OR"
    echo -e "  ${CYAN}!${NC}   NOT"
    echo

    local emp_file
    emp_file=$(get_practice_file "awk" "employees.dat")

    if [[ -f "$emp_file" ]]; then
        echo -e "${CYAN}Example: Employees with salary > 70000${NC}"
        echo -e "${BOLD}Command:${NC} awk '\$5 > 70000' text/awk-practice/employees.dat"
        echo -e "${DIM}Output:${NC}"
        awk '$5 > 70000' "$emp_file" | head -5 | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Engineering dept with salary > 75000${NC}"
        echo -e "${BOLD}Command:${NC} awk '\$4 == \"Engineering\" && \$5 > 75000' employees.dat"
        echo -e "${DIM}Output:${NC}"
        awk '$4 == "Engineering" && $5 > 75000' "$emp_file" | sed 's/^/  /'
    fi

    wait_for_user

    # BEGIN and END
    print_subheader "BEGIN and END Blocks"

    cat << 'BEGINEND'
BEGIN runs before processing any input - setup, headers
END runs after all input processed - summaries, totals
BEGINEND
    echo

    if [[ -f "$emp_file" ]]; then
        echo -e "${CYAN}Example: Sum salaries with header and total${NC}"
        echo -e "${BOLD}Command:${NC}"
        echo '  awk '\''BEGIN {print "Calculating salaries..."}'
        echo '       {sum += $5}'
        echo '       END {print "Total:", sum}'\'' employees.dat'
        echo -e "${DIM}Output:${NC}"
        awk 'BEGIN {print "Calculating salaries..."} {sum += $5} END {print "Total:", sum}' "$emp_file" | sed 's/^/  /'
        echo
    fi

    echo -e "${CYAN}Example: Count lines${NC}"
    echo "  awk 'END {print NR, \"lines\"}' file.txt"

    wait_for_user

    # Formatted Output
    print_subheader "Formatted Output (printf)"

    echo -e "${BOLD}printf format, values${NC}"
    echo
    echo -e "${BOLD}Format specifiers:${NC}"
    echo -e "  ${CYAN}%s${NC}    String"
    echo -e "  ${CYAN}%d${NC}    Integer"
    echo -e "  ${CYAN}%f${NC}    Float"
    echo -e "  ${CYAN}%e${NC}    Scientific notation"
    echo -e "  ${CYAN}%-10s${NC} Left-aligned, 10 chars wide"
    echo -e "  ${CYAN}%10s${NC}  Right-aligned, 10 chars wide"
    echo

    if [[ -f "$servers_file" ]]; then
        echo -e "${CYAN}Example: Formatted server list${NC}"
        echo -e "${BOLD}Command:${NC} awk '{printf \"%-12s %-15s %s\\n\", \$1, \$2, \$6}' servers.txt"
        echo -e "${DIM}Output:${NC}"
        awk '{printf "%-12s %-15s %s\n", $1, $2, $6}' "$servers_file" | head -6 | sed 's/^/  /'
    fi

    wait_for_user

    # Calculations
    print_subheader "Calculations"

    local sales_file
    sales_file=$(get_practice_file "text" "sales.csv")

    if [[ -f "$sales_file" ]]; then
        echo -e "${CYAN}Example: Sum a column${NC}"
        echo -e "${BOLD}Command:${NC} awk -F, 'NR>1 {sum+=\$3} END {print \"Total quantity:\", sum}' sales.csv"
        echo -e "${DIM}Output:${NC}"
        awk -F, 'NR>1 {sum+=$3} END {print "Total quantity:", sum}' "$sales_file" | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Calculate average${NC}"
        echo -e "${BOLD}Command:${NC} awk -F, 'NR>1 {sum+=\$4; count++} END {print \"Avg price:\", sum/count}' sales.csv"
        echo -e "${DIM}Output:${NC}"
        awk -F, 'NR>1 {sum+=$4; count++} END {printf "Avg price: %.2f\n", sum/count}' "$sales_file" | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Calculate line total (quantity * price)${NC}"
        echo -e "${BOLD}Command:${NC} awk -F, 'NR>1 {print \$2, \$3*\$4}' sales.csv | head -5"
        echo -e "${DIM}Output:${NC}"
        awk -F, 'NR>1 {printf "%s: $%.2f\n", $2, $3*$4}' "$sales_file" | head -5 | sed 's/^/  /'
    fi

    wait_for_user

    # String Functions
    print_subheader "String Functions"

    echo -e "${CYAN}length(s)${NC}        Length of string"
    echo -e "${CYAN}substr(s,i,n)${NC}    Substring from position i, n chars"
    echo -e "${CYAN}index(s,t)${NC}       Position of t in s"
    echo -e "${CYAN}split(s,a,sep)${NC}   Split s into array a"
    echo -e "${CYAN}gsub(r,s,t)${NC}      Global substitution"
    echo -e "${CYAN}sub(r,s,t)${NC}       Substitute first match"
    echo -e "${CYAN}tolower(s)${NC}       Convert to lowercase"
    echo -e "${CYAN}toupper(s)${NC}       Convert to uppercase"
    echo

    echo -e "${CYAN}Example: Print first 3 characters${NC}"
    echo "  awk '{print substr(\$1, 1, 3)}' file"
    echo

    echo -e "${CYAN}Example: Replace text${NC}"
    echo "  awk '{gsub(/old/, \"new\"); print}' file"

    wait_for_user

    # Arrays
    print_subheader "Associative Arrays"

    cat << 'ARRAYS'
awk supports associative arrays (like dictionaries/hashes).
Perfect for counting, grouping, and aggregating data.
ARRAYS
    echo

    if [[ -f "$sales_file" ]]; then
        echo -e "${CYAN}Example: Count sales by salesperson${NC}"
        echo -e "${BOLD}Command:${NC}"
        echo '  awk -F, '\''NR>1 {count[$5]++}'
        echo '             END {for (p in count) print p, count[p]}'\'' sales.csv'
        echo -e "${DIM}Output:${NC}"
        awk -F, 'NR>1 {count[$5]++} END {for (p in count) print p, count[p]}' "$sales_file" | sort | sed 's/^/  /'
        echo

        echo -e "${CYAN}Example: Total sales by product${NC}"
        echo -e "${BOLD}Command:${NC}"
        echo '  awk -F, '\''NR>1 {sales[$2] += $3*$4}'
        echo '             END {for (p in sales) printf "%s: $%.2f\n", p, sales[p]}'\'' sales.csv'
        echo -e "${DIM}Output:${NC}"
        awk -F, 'NR>1 {sales[$2] += $3*$4} END {for (p in sales) printf "%s: $%.2f\n", p, sales[p]}' "$sales_file" | sort | sed 's/^/  /'
    fi

    wait_for_user

    # Practical examples
    print_subheader "Practical Examples"

    echo -e "${CYAN}1. Print specific columns from ps:${NC}"
    echo "   ps aux | awk '{print \$1, \$2, \$11}'"
    echo

    echo -e "${CYAN}2. Sum disk usage:${NC}"
    echo "   df -h | awk 'NR>1 {sum+=\$3} END {print sum \"GB\"}'"
    echo

    echo -e "${CYAN}3. Find top memory processes:${NC}"
    echo "   ps aux | awk 'NR>1 {print \$4, \$11}' | sort -rn | head"
    echo

    echo -e "${CYAN}4. Extract IPs from log:${NC}"
    echo "   awk '{print \$1}' access.log | sort | uniq -c | sort -rn"
    echo

    echo -e "${CYAN}5. Skip header line:${NC}"
    echo "   awk 'NR>1 {print}' data.csv"
    echo

    echo -e "${CYAN}6. Print lines longer than 80 chars:${NC}"
    echo "   awk 'length > 80' file.txt"

    wait_for_user

    # Exam tips
    print_subheader "Exam Tips"

    echo -e "${MAGENTA}${BULLET}${NC} \$0 = whole line, \$1 = first field, \$NF = last field"
    echo -e "${MAGENTA}${BULLET}${NC} -F sets field separator: -F: for /etc/passwd"
    echo -e "${MAGENTA}${BULLET}${NC} NR is line number, NF is number of fields"
    echo -e "${MAGENTA}${BULLET}${NC} Patterns are optional: awk '{print \$1}' prints all lines"
    echo -e "${MAGENTA}${BULLET}${NC} BEGIN/END for setup/summary code"
    echo -e "${MAGENTA}${BULLET}${NC} Quote the awk program to prevent shell expansion"

    wait_for_user

    # Key takeaways
    print_subheader "Key Takeaways"

    echo "1. awk excels at processing columnar/structured data"
    echo "2. Fields accessed with \$1, \$2, etc. (\$0 = whole line)"
    echo "3. Use -F to set custom field separator"
    echo "4. Patterns select which lines to process"
    echo "5. BEGIN/END blocks for initialization and summaries"
    echo "6. Associative arrays enable powerful aggregations"
    echo

    print_info "Ready to practice? Try: lpic-train practice awk"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "${SCRIPT_DIR}/training/common.sh"
    lesson_awk
fi
