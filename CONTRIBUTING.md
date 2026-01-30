# Contributing to LPIC-1 Training Environment

Guidelines for adding new validators, scenarios, and improvements.

## Code Style

### Shell Script Standards

All scripts must:

1. Use bash with strict mode:
   ```bash
   #!/bin/bash
   set -euo pipefail
   ```

2. Include header comment:
   ```bash
   # Objective 103.5: Create, monitor and kill processes
   # Weight: 4
   ```

3. Use consistent color definitions:
   ```bash
   GREEN='\033[0;32m'
   RED='\033[0;31m'
   YELLOW='\033[1;33m'
   CYAN='\033[0;36m'
   BOLD='\033[1m'
   NC='\033[0m'

   PASS="✓"
   FAIL="✗"
   WARN="⚠"
   INFO="ℹ"
   ```

4. Use standard output functions:
   ```bash
   print_pass() { echo -e "${GREEN}${PASS}${NC} $1"; }
   print_fail() { echo -e "${RED}${FAIL}${NC} $1"; }
   print_warn() { echo -e "${YELLOW}${WARN}${NC} $1"; }
   print_info() { echo -e "${CYAN}${INFO}${NC} $1"; }
   print_header() { echo -e "\n${BOLD}═══ $1 ═══${NC}\n"; }
   ```

5. Handle counter increments safely in pipefail mode:
   ```bash
   ((passed++)) || true
   ((failed++)) || true
   ```

## Adding Objective Validators

### Validator Template

Create `feedback-system/objectives/<objective-id>.sh`:

```bash
#!/bin/bash
# Objective <ID>: <Title from exam objectives>
# Weight: <N>

set -euo pipefail

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

echo "Checking Objective <ID>: <Title>"
echo "================================"
echo

# Section 1: Command Availability
echo "Essential Commands:"
check "command1 available" "command -v command1"
check "command2 available" "command -v command2"
echo

# Section 2: System Configuration
echo "System Configuration:"
check "Config file exists" "test -f /etc/config"
check "Service is running" "systemctl is-active --quiet service"
echo

# Section 3: Functional Tests
echo "Functional Tests:"
check "Operation works" "some_test_command"
echo

# Summary
total=$((passed + failed))
echo "================================"
echo "Results: $passed/$total checks passed"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}${PASS} Objective <ID> requirements met${NC}"
    exit 0
else
    echo -e "${YELLOW}${WARN} $failed checks need attention${NC}"
    exit 1
fi
```

### Validator Guidelines

1. **Check commands exist first** - Before testing functionality
2. **Test functionality, not just existence** - `lspci -nn | head -1` not just `command -v lspci`
3. **Group checks by category** - Commands, configuration, functionality
4. **Clean up temp files** - Use trap for cleanup:
   ```bash
   TESTDIR=$(mktemp -d)
   trap "rm -rf $TESTDIR" EXIT
   ```
5. **Support verbose mode** - Accept `$1` as verbose flag
6. **Match exam objectives** - Check items listed in official objectives

### Validation Patterns

**Command existence:**
```bash
check "grep available" "command -v grep"
```

**File existence:**
```bash
check "Config exists" "test -f /etc/ssh/sshd_config"
```

**Directory existence:**
```bash
check "/var/log exists" "test -d /var/log"
```

**Service running:**
```bash
check "SSH service active" "systemctl is-active --quiet sshd || systemctl is-active --quiet ssh"
```

**File permissions:**
```bash
check "Correct permissions" "test \$(stat -c %a /etc/shadow) = '640' || test \$(stat -c %a /etc/shadow) = '000'"
```

**File contains pattern:**
```bash
check "Setting configured" "grep -q '^PermitRootLogin' /etc/ssh/sshd_config"
```

**Environment variable:**
```bash
check "PATH set" "test -n \"\$PATH\""
```

**Command output test:**
```bash
check "Kernel module loaded" "lsmod | grep -q '^loop'"
```

## Adding Break/Fix Scenarios

### Scenario Structure

```bash
#!/bin/bash
# LPIC-1 Break/Fix Scenario: <Name>
# <Description>

set -euo pipefail

# Colors and output functions (standard set)

# Configuration
PRACTICE_DIR="${HOME}/lpic1-practice/<scenario-name>"
SNAPSHOT_DIR="${HOME}/.lpic1/snapshots"
SCENARIO_NAME="<scenario-name>"

# Available scenarios
declare -A SCENARIOS
SCENARIOS["variant1"]="Description of variant 1"
SCENARIOS["variant2"]="Description of variant 2"

# Required functions:
list_scenarios()      # Show available variants
setup_practice_dir()  # Create practice directory
create_snapshot()     # Save clean state
restore_snapshot()    # Restore from snapshot
start_scenario()      # Router to variant starters
check_scenario()      # Verify if fixed

# Per-variant functions:
start_variant1()      # Create variant1 problem
start_variant2()      # Create variant2 problem

# Main with standard interface:
# --list, --start <variant>, --check <variant>, --restore <variant>
```

### Scenario Guidelines

1. **Create snapshot before changes** - Always allow restore
2. **Prefer user space** - Avoid root when possible
3. **Clear problem description** - User knows what's broken
4. **Progressive hints** - Don't give away the answer
5. **Specific verification** - Check for correct fix, not just any fix

## Adding Build Scenarios

### Build Scenario Structure

```bash
#!/bin/bash
# LPIC-1 Build Scenario: <Service Name>
# <Description>

set -euo pipefail

# Requires root check
if [[ $EUID -ne 0 ]]; then
    echo "This scenario requires root privileges"
    exit 1
fi

# Distro detection
if command -v dnf &>/dev/null; then
    DISTRO="fedora"
elif command -v apt &>/dev/null; then
    DISTRO="debian"
fi

# Challenge tracking
START_TIME=""
HINTS_USED=0

# Required functions:
start_challenge()     # Initialize with instructions
give_hint()           # Progressive hints (1, 2, 3...)
check_challenge()     # Multi-step verification
cleanup()             # Remove test environment

# Scoring:
# base_score = (checks_passed / total_checks) * 100
# final_score = base_score - (hints_used * 5)
```

## Testing Your Changes

### Validator Testing

```bash
# Run your validator
./feedback-system/objectives/103.5.sh

# Run with verbose
./feedback-system/objectives/103.5.sh true

# Test via lpic-check
./feedback-system/lpic-check objective 103.5 --verbose
```

### Scenario Testing

```bash
# Test full cycle
./scenarios/break-fix/your-scenario.sh --start variant1
# Verify problem exists
./scenarios/break-fix/your-scenario.sh --check variant1  # Should fail
# Fix the problem
./scenarios/break-fix/your-scenario.sh --check variant1  # Should pass
# Test restore
./scenarios/break-fix/your-scenario.sh --restore variant1
```

## Checklist

Before submitting:

- [ ] Script uses `set -euo pipefail`
- [ ] Header comment with objective/scenario info
- [ ] Standard color/symbol definitions
- [ ] Uses `((var++)) || true` for counters
- [ ] Cleanup with trap for temp files
- [ ] Exit 0 on success, exit 1 on failure
- [ ] Works on both Fedora and Debian (where applicable)
- [ ] Tested manually
- [ ] Documentation updated

## File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Objective validator | `<objective-id>.sh` | `103.5.sh` |
| Break/fix scenario | `broken-<topic>.sh` | `broken-boot.sh` |
| Build scenario | `setup-<service>.sh` | `setup-web-server.sh` |

## Questions?

Review existing validators and scenarios for examples:
- `feedback-system/objectives/101.1.sh` - Basic validator
- `feedback-system/objectives/104.5.sh` - Validator with temp files
- `scenarios/break-fix/broken-permissions.sh` - Multi-variant scenario
- `scenarios/build/setup-web-server.sh` - Build challenge with hints
