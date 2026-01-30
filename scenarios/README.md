# Scenarios

Hands-on practice scenarios for LPIC-1 training. These provide realistic troubleshooting and configuration challenges.

## Scenario Types

### Break/Fix Scenarios

Located in `break-fix/`. These create intentional problems for you to diagnose and repair.

**Learning approach:**
1. Run scenario to create a problem
2. Investigate using standard tools
3. Fix the issue
4. Verify with the check command

### Build Scenarios

Located in `build/`. These guide you through configuring services from scratch.

**Learning approach:**
1. Read the challenge requirements
2. Configure the service
3. Use hints if stuck
4. Verify your configuration

## Available Scenarios

### Break/Fix Scenarios

| Script | Difficulty | Time | Topics Covered |
|--------|------------|------|----------------|
| `broken-permissions.sh` | Beginner | 10-20 min | chmod, chown, umask, special bits |
| `broken-boot.sh` | Intermediate | 20-30 min | GRUB, systemd targets, recovery |
| `broken-services.sh` | Intermediate | 15-25 min | systemctl, service dependencies |
| `full-disk.sh` | Beginner | 10-15 min | df, du, find, log rotation |
| `orphaned-packages.sh` | Beginner | 10-15 min | apt, dpkg, rpm, dnf |

### Build Scenarios

| Script | Difficulty | Time | Topics Covered |
|--------|------------|------|----------------|
| `setup-web-server.sh` | Intermediate | 30-45 min | Apache/Nginx, firewall, permissions |
| `setup-mail-server.sh` | Advanced | 45-60 min | Postfix, aliases, mail queue |
| `setup-print-server.sh` | Intermediate | 20-30 min | CUPS, lpd, printer configuration |
| `create-users.sh` | Beginner | 15-20 min | useradd, groups, /etc/skel |

## Usage

### Break/Fix Workflow

```bash
# List available scenarios within a script
./break-fix/broken-permissions.sh --list

# Start a specific scenario
./break-fix/broken-permissions.sh --start no-execute

# After fixing, verify your solution
./break-fix/broken-permissions.sh --check no-execute

# If you need to start over
./break-fix/broken-permissions.sh --restore no-execute
```

### Build Workflow

```bash
# Start the challenge (usually requires sudo)
sudo ./build/setup-web-server.sh --start

# Get progressive hints (1, 2, 3...)
sudo ./build/setup-web-server.sh --hint 1
sudo ./build/setup-web-server.sh --hint 2

# Verify your configuration
sudo ./build/setup-web-server.sh --check

# Clean up when done
sudo ./build/setup-web-server.sh --cleanup
```

## Scenario Design Principles

### Difficulty Ratings

- **Beginner**: Single concept, clear error messages
- **Intermediate**: Multiple steps, requires investigation
- **Advanced**: Complex troubleshooting, multiple interacting issues

### Time Estimates

Times assume familiarity with basic commands. First attempts may take longer.

### Safe by Design

- Break/fix scenarios work in user space when possible
- All scenarios create snapshots before making changes
- Restore capability for quick reset
- Build scenarios include cleanup commands

## Creating Practice Habits

### Recommended Practice Schedule

**Week 1-2: Foundations**
- Complete all "Beginner" break/fix scenarios
- Focus on file permissions and package management

**Week 3-4: Core Skills**
- Complete "Intermediate" scenarios
- Start build scenarios (web server, users)

**Week 5-6: Advanced Practice**
- Complete all scenarios without hints
- Time yourself on break/fix scenarios
- Practice mail and print server setup

### Tips for Effective Learning

1. **Don't rush to hints** - Spend at least 5 minutes investigating before asking for help
2. **Use man pages** - `man chmod`, `man systemctl`, etc.
3. **Check logs** - `journalctl`, `/var/log/`
4. **Document solutions** - Keep notes on what fixed each issue
5. **Repeat scenarios** - Come back after a few days and try again

## Exam Relevance

| Scenario | LPIC-1 Objectives |
|----------|-------------------|
| broken-permissions | 104.5, 104.6 |
| broken-boot | 101.2, 101.3 |
| broken-services | 101.3, 108.x |
| full-disk | 104.2, 104.3 |
| orphaned-packages | 102.4, 102.5 |
| setup-web-server | 108.x, 109.x, 110.x |
| setup-mail-server | 108.3 |
| setup-print-server | 108.4 |
| create-users | 107.1, 107.2 |

## Troubleshooting

### "Permission denied" when running scenario

Most break/fix scenarios work as regular user. Build scenarios often need sudo:

```bash
sudo ./build/setup-web-server.sh --start
```

### Scenario won't start (already active)

Clean up the previous attempt:

```bash
./break-fix/broken-permissions.sh --restore <scenario>
# or for build scenarios
sudo ./build/setup-web-server.sh --cleanup
```

### Restore fails

If automatic restore fails, manually clean up:

```bash
# For permissions scenarios
rm -rf ~/lpic1-practice/permissions-challenge

# For service scenarios (root required)
sudo systemctl stop <service>
sudo rm /etc/<config-file>
```

## Contributing

See [../CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on adding new scenarios.

### Scenario Template

New scenarios should include:
- `--list` - Show available variants
- `--start <variant>` - Begin scenario
- `--check <variant>` - Verify fix
- `--restore <variant>` - Reset to clean state
- Snapshot creation before making changes
- Clear problem description and hints
