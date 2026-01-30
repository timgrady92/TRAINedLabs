#!/bin/bash
# Objective 107.3: Localisation and internationalisation
# Weight: 3

set -euo pipefail

# shellcheck disable=SC2034  # VERBOSE available for debugging
VERBOSE="${1:-false}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="✓"
FAIL="✗"
WARN="⚠"

passed=0
failed=0

check() {
    local desc="$1"
    local cmd="$2"

    if eval "$cmd" &>/dev/null; then
        echo -e "${GREEN}${PASS}${NC} $desc"
        ((passed++)) || true
        return 0
    else
        echo -e "${RED}${FAIL}${NC} $desc"
        ((failed++)) || true
        return 1
    fi
}

echo "Checking Objective 107.3: Localisation and internationalisation"
echo "================================================================"
echo

# Check locale commands
echo "Locale Commands:"
check "locale available" "command -v locale"
check "localectl available" "command -v localectl"
check "iconv available" "command -v iconv"
echo

# Check timezone commands
echo "Timezone Commands:"
check "timedatectl available" "command -v timedatectl"
check "tzselect available" "command -v tzselect"
check "date available" "command -v date"
echo

# Check locale configuration
echo "Locale Configuration:"
check "locale shows settings" "locale"
check "LANG is set" "test -n \"\${LANG:-}\""
echo "  Current LANG: ${LANG:-not set}"
check "locale -a lists available" "locale -a | head -5"
echo

# Check LC_* variables
echo "LC Variables:"
check "Can display LC settings" "locale | grep -q 'LC_'"
# Show current settings
locale | grep -E '^(LANG|LC_)' | head -5
echo

# Check timezone configuration
echo "Timezone Configuration:"
check "/etc/localtime exists" "test -f /etc/localtime || test -L /etc/localtime"
if [[ -f /etc/timezone ]]; then
    check "/etc/timezone exists" "test -f /etc/timezone"
    echo "  Timezone: $(cat /etc/timezone)"
fi
check "/usr/share/zoneinfo exists" "test -d /usr/share/zoneinfo"
echo

# Check timedatectl
echo "Timedatectl:"
check "timedatectl works" "timedatectl status | head -5"
check "timedatectl list-timezones" "timedatectl list-timezones | head -3"
echo

# Check date command
echo "Date Command:"
check "date shows current time" "date"
check "date with format" "date '+%Y-%m-%d %H:%M:%S'"
check "TZ variable works" "TZ=UTC date"
echo

# Check character encoding
echo "Character Encoding:"
check "UTF-8 locale available" "locale -a | grep -qi 'utf-8\|utf8'"
check "iconv can convert" "echo 'test' | iconv -f UTF-8 -t ASCII"
check "file command detects encoding" "command -v file && echo 'test' | file -"
echo

# Check encoding awareness
echo "Encoding Standards:"
echo "  UTF-8: Unicode (most common)"
echo "  ISO-8859-1: Western European (Latin-1)"
echo "  ASCII: 7-bit basic characters"
check "UTF-8 in current locale" "locale | grep -qi 'utf-8\|utf8'"
echo

# Check LANG=C usage
echo "LANG=C Usage:"
check "LANG=C works" "LANG=C date"
echo "  LANG=C provides consistent, portable output"
echo "  Useful for scripts that parse command output"
echo

# Summary
total=$((passed + failed))
echo "================================================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 107.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
