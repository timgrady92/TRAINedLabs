# LPIC-1 Training Platform

A hands-on training environment for LPIC-1 Linux certification with interactive lessons, guided exercises, and progress tracking.

> **New here?** See the [Initial Setup Guide](SETUP.md) for detailed step-by-step installation instructions.

## Quick Start

For deploying on a fresh Ubuntu 24.04 VM:

```bash
git clone <repository-url> /tmp/LPIC-1
cd /tmp/LPIC-1
sudo ./ops/setup.sh
sudo reboot
```

After reboot, log in as `student` (password: `training123`) and type `lpic1` to start.

### Installation Options

```bash
# Standard installation (creates 'student' user)
sudo ./ops/setup.sh

# Custom user and password
sudo ./ops/setup.sh --user trainee --password MySecurePass

# Skip practice filesystems (for limited disk space)
sudo ./ops/setup.sh --skip-filesystems

# Verify existing installation
sudo ./ops/setup.sh --verify

# Remove installation
sudo ./ops/setup.sh --uninstall
```

## Alternative Installation (Advanced)

If you already have a user account set up, you can still use the same installer:

```bash
sudo ./ops/setup.sh --user $(whoami)
```

## Start Training

```bash
lpic1
```

That's it. The interactive menu will guide you from there.

## What's Included

| Feature | Description |
|---------|-------------|
| **Interactive Lessons** | 11 topics with live command examples |
| **Guided Exercises** | Practice with progressive hints |
| **Quick Drills** | Build muscle memory with rapid-fire recall |
| **Challenge Scenarios** | Break/fix and build-from-scratch labs |
| **Exam Simulation** | Timed tests matching real exam format |
| **Progress Tracking** | Track completion across all 42 objectives |
| **Practice Filesystems** | Real ext4, XFS, Btrfs, LVM for hands-on storage practice |

## Usage

### Interactive Mode (Recommended)

Launch the menu-driven interface:

```bash
lpic1
```

### Command Line Mode

```bash
# Learning
lpic1 learn grep          # Interactive lesson
lpic1 practice permissions # Guided exercises
lpic1 drill chmod         # Quick-fire drills

# Assessment
lpic1 test find           # Test without hints
lpic1 exam                # Full exam simulation

# Progress
lpic1 status              # View your progress
lpic1 smart               # Get personalized recommendations
```

## LPIC-1 Exam Coverage

The platform covers all objectives for both LPIC-1 exams:

| Exam 101 (Topics 101-104) | Exam 102 (Topics 105-110) |
|---------------------------|---------------------------|
| System Architecture | Shells & Scripting |
| Linux Installation | User Interfaces |
| Package Management | Administrative Tasks |
| GNU/Unix Commands | Essential Services |
| Devices & Filesystems | Networking |
| | Security |

## Practice Filesystems

The training environment includes real filesystems for hands-on practice:

- **ext4, XFS, Btrfs, VFAT** - Different filesystem types to explore
- **LVM** - Volume group with 3 logical volumes
- **Disk Quotas** - Pre-configured quota filesystem

All practice filesystems are mounted at `/mnt/lpic1/` and persist across reboots via systemd.

## System Requirements

- Linux VM (Ubuntu 24.04 recommended)
- 2GB RAM minimum
- 20GB disk space (5GB minimum without practice filesystems)
- Root/sudo access

## Directory Structure

```
LPIC-1/
├── ops/
│   ├── setup.sh            # Single-step deployment
│   └── uninstall.sh        # Clean removal script
├── bin/
│   └── lpic1               # Main training command
├── apps/
│   └── tui_textual/         # Enterprise Textual TUI
├── core/                    # Training engine (validators + lessons)
│   ├── training/            # Lessons and exercises
│   └── objectives/          # Validation scripts
├── content/
│   ├── environment/         # VM setup + practice filesystem tools
│   ├── scenarios/           # Challenge labs
│   └── motd/                # Login banner
├── docs/                    # Docs and guides
└── skills/                  # Codex skills
```

## Learning Path

1. **Start with Learn** - Understand concepts with live examples
2. **Practice with Hints** - Guided exercises build confidence
3. **Drill for Speed** - Quick-fire exercises build automaticity
4. **Mix Topics** - Interleaved practice improves retention
5. **Test Yourself** - Assess without hints
6. **Simulate the Exam** - Timed, realistic practice

## Verification

To verify the installation is working correctly:

```bash
sudo /opt/LPIC-1/content/environment/verify-installation.sh
```

## Troubleshooting

### "lpic1: command not found"

The installer creates `/usr/local/bin/lpic1`. If this doesn't work:
```bash
# Run directly
/opt/LPIC-1/bin/lpic1

# Or verify symlink
ls -la /usr/local/bin/lpic1
```

### TUI doesn't launch

Install Textual:
```bash
sudo apt install python3-pip && pip3 install textual   # Ubuntu/Debian
sudo dnf install python3-pip && pip3 install textual   # Fedora/RHEL
```

### Practice filesystems not mounted after reboot

```bash
# Check service status
sudo systemctl status lpic1-filesystems

# Manually start
sudo systemctl start lpic1-filesystems

# Check mounts
df -h /mnt/lpic1/*
```

### Reset all progress

```bash
rm -rf ~/.lpic1
lpic1  # Will reinitialize on first run
```

### View installation log

```bash
cat /var/log/lpic1-install.log
```

## Uninstalling

To remove the training environment:

```bash
sudo /opt/LPIC-1/ops/uninstall.sh
```

To also remove user progress data:

```bash
sudo /opt/LPIC-1/ops/uninstall.sh --purge
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding content.

## License

MIT License. See [LICENSE](LICENSE) file.

Based on publicly available LPIC-1 exam objectives from [LPI](https://www.lpi.org/).
