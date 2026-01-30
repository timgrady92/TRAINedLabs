# Core Engine

The core validation framework for LPIC-1 training. Provides automated objective checking, progress tracking, and command proficiency testing.

## Components

### lpic-check (Main Interface)

The primary tool for all validation operations.

```bash
./lpic-check <command> [options]
```

**Commands:**

| Command | Description | Example |
|---------|-------------|---------|
| `objective <id>` | Check specific objective | `lpic-check objective 103.1` |
| `topic <num>` | Check all objectives in topic | `lpic-check topic 107` |
| `command <cmd>` | Test command proficiency | `lpic-check command grep` |
| `progress` | Show training progress | `lpic-check progress` |
| `verify-packages` | Check required packages | `lpic-check verify-packages` |
| `self-test` | Run system diagnostics | `lpic-check self-test` |
| `exam-mode` | Start exam simulation | `lpic-check exam-mode` |

**Options:**
- `-v, --verbose` - Show detailed output
- `-h, --help` - Show help message

### init-progress.sh

Initializes the SQLite progress database.

```bash
./init-progress.sh
```

**Creates:** `/opt/LPIC-1/data/progress.db`

**Database schema:**

```sql
-- Objectives tracking
CREATE TABLE objectives (
    id TEXT PRIMARY KEY,      -- e.g., "101.1"
    topic INTEGER,            -- Topic number (101-110)
    number TEXT,              -- Full objective number
    title TEXT,               -- Objective title
    weight INTEGER,           -- Exam weight (1-5)
    completed INTEGER,        -- 0 or 1
    completed_at TEXT         -- Timestamp
);

-- Command practice tracking
CREATE TABLE commands (
    command TEXT PRIMARY KEY,
    objective_id TEXT,
    attempts INTEGER,
    successes INTEGER,
    last_practiced TEXT
);

-- Lab completion tracking
CREATE TABLE labs (
    lab_id TEXT PRIMARY KEY,
    started_at TEXT,
    completed_at TEXT,
    score INTEGER,
    hints_used INTEGER
);
```

### lab-validator.sh

Helper library with reusable validation functions for lab exercises.

**Available functions:**

```bash
# File system checks
check_file_exists <file> <description>
check_dir_exists <dir> <description>
check_file_contains <file> <pattern> <description>

# Permission checks
check_permissions <file> <expected_perms> <description>
check_ownership <file> <user> <group> <description>

# Link checks
check_symlink <link> <target> <description>
check_hard_links <file> <min_count> <description>

# System checks
check_service_running <service> <description>
check_service_enabled <service> <description>
check_user_exists <user> <description>
check_group_exists <group> <description>
check_user_in_group <user> <group> <description>

# Network checks
check_port_listening <port> <protocol> <description>
check_mount <device> <mountpoint> <description>
```

### skill-checker.sh

Interactive command proficiency testing with progressive challenges.

```bash
./skill-checker.sh <command>
```

Provides:
- Timed challenges
- Progressive difficulty
- Hints system
- Score tracking

## objectives/ Directory

Contains per-objective validation scripts. Each script:

1. Checks command availability
2. Verifies system configuration
3. Tests functional requirements
4. Reports pass/fail with summary

**Naming convention:** `<objective-id>.sh` (e.g., `101.1.sh`, `103.5.sh`)

**Return codes:**
- `0` - All checks passed
- `1` - One or more checks failed

## Extending the Framework

### Adding a New Validator

1. Create `objectives/<id>.sh`
2. Follow the template in [CONTRIBUTING.md](../CONTRIBUTING.md)
3. Ensure proper error handling with `set -euo pipefail`
4. Use the standard check functions and color output

### Adding Commands to Database

Edit `init-progress.sh` to add commands:

```sql
INSERT INTO commands (command, objective_id) VALUES ('newcmd', '103.X');
```

### Customizing Check Functions

Add new check functions to `lab-validator.sh`:

```bash
check_custom() {
    local desc="$1"
    local test_command="$2"

    if eval "$test_command" &>/dev/null; then
        print_pass "$desc"
        return 0
    else
        print_fail "$desc"
        return 1
    fi
}
```

## Progress Data Location

All progress data is stored in:

```
~/.lpic1/
├── progress.db    # SQLite database
└── snapshots/     # Scenario backup data
```

To reset progress:

```bash
rm -rf ~/.lpic1
./init-progress.sh
```

## Troubleshooting

### "Database not found"

```bash
./init-progress.sh
```

### Validator script fails

Run with verbose mode:

```bash
./lpic-check objective 101.1 --verbose
```

### Progress not updating

Check database permissions:

```bash
ls -la ~/.lpic1/progress.db
sqlite3 ~/.lpic1/progress.db "SELECT * FROM objectives WHERE completed=1;"
```
