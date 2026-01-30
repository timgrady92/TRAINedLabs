#!/bin/bash
# Objective 108.3: Mail Transfer Agent (MTA) basics
# Weight: 3

# shellcheck disable=SC2088  # Tildes in description strings are intentional display text
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

echo "Checking Objective 108.3: Mail Transfer Agent (MTA) basics"
echo "==========================================================="
echo

# Check mail commands
echo "Mail Commands:"
if command -v mail &>/dev/null; then
    check "mail command available" "command -v mail"
elif command -v mailx &>/dev/null; then
    check "mailx command available" "command -v mailx"
else
    echo -e "${YELLOW}${WARN}${NC} mail/mailx not installed"
fi

if command -v sendmail &>/dev/null; then
    check "sendmail command available" "command -v sendmail"
else
    echo -e "${YELLOW}${WARN}${NC} sendmail not installed"
fi

if command -v mailq &>/dev/null; then
    check "mailq command available" "command -v mailq"
else
    echo -e "${YELLOW}${WARN}${NC} mailq not installed"
fi

if command -v newaliases &>/dev/null; then
    check "newaliases command available" "command -v newaliases"
fi
echo

# Check for MTAs
echo "Mail Transfer Agents:"
if command -v postfix &>/dev/null || test -f /etc/postfix/main.cf; then
    check "Postfix available" "command -v postfix || test -f /etc/postfix/main.cf"
fi
if test -f /etc/exim4/exim4.conf.template || command -v exim4 &>/dev/null; then
    check "Exim available" "test -f /etc/exim4/exim4.conf.template || command -v exim4"
fi
if test -f /etc/mail/sendmail.cf; then
    check "Sendmail config exists" "test -f /etc/mail/sendmail.cf"
fi
echo

# Check alias configuration
echo "Alias Configuration:"
check "/etc/aliases exists" "test -f /etc/aliases"
if [[ -f /etc/aliases ]]; then
    check "aliases file readable" "test -r /etc/aliases"
    check "aliases has entries" "grep -v '^#' /etc/aliases | grep -v '^$' | head -1 || true"
fi
echo

# Check mail forwarding
echo "Mail Forwarding:"
if [[ -f "$HOME/.forward" ]]; then
    check "~/.forward exists" "test -f \$HOME/.forward"
    echo "  Contents: $(cat "$HOME/.forward")"
else
    echo "  ~/.forward not configured (optional)"
fi
echo

# Check mail queue
echo "Mail Queue:"
if command -v mailq &>/dev/null; then
    check "mailq runs" "mailq 2>/dev/null || true"
fi
echo

# Check mail spool
echo "Mail Spool:"
check "/var/spool/mail exists" "test -d /var/spool/mail || test -d /var/mail"
if [[ -f /var/spool/mail/$USER ]] || [[ -f /var/mail/$USER ]]; then
    check "User mailbox exists" "test -f /var/spool/mail/\$USER || test -f /var/mail/\$USER"
fi
echo

# MTA awareness
echo "MTA Awareness:"
echo "  Common MTAs:"
echo "  - Postfix: Modern, secure, widely used"
echo "  - Sendmail: Traditional, complex configuration"
echo "  - Exim: Flexible, common on Debian"
echo
echo "  Key concepts:"
echo "  - /etc/aliases: System-wide mail forwarding"
echo "  - ~/.forward: Per-user mail forwarding"
echo "  - mailq: View mail queue"
echo "  - newaliases: Rebuild alias database"
echo

# Summary
total=$((passed + failed))
echo "==========================================================="
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective 108.3 requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
