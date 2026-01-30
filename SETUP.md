# Initial Setup Guide

This guide walks you through installing the LPIC-1 Training Platform from scratch.

## Prerequisites

You need:
- A fresh **Ubuntu 24.04** VM (other Debian-based distros work too)
- **5GB+ free disk space** (20GB recommended for practice filesystems)
- **Root/sudo access**
- **Internet connection** (for package installation)

## Step 1: Get the Code

**Option A: Clone from Git**
```bash
git clone https://github.com/YOUR-ORG/LPIC-1.git
cd LPIC-1
```

**Option B: Download and Extract**
```bash
# If you have a .tar.gz or .zip
tar xzf LPIC-1.tar.gz
cd LPIC-1
```

**Option C: Copy from USB/Network**
```bash
# Copy to the VM, then:
cd /path/to/LPIC-1
```

## Step 2: Run the Installer

```bash
sudo ./install.sh
```

The installer will:
1. Check system requirements
2. Create a training user (`student` with password `training123`)
3. Install required packages (dialog, sqlite3, vim, LVM tools, etc.)
4. Set up the training platform in `/opt/LPIC-1`
5. Create practice filesystems for storage exercises
6. Install a login banner

**Expected output:**
```
╔════════════════════════════════════════════════════════════════╗
║       LPIC-1 Training Platform - Hospital Deployment          ║
╚════════════════════════════════════════════════════════════════╝

═══ Pre-flight Checks ═══
[OK] Running as root
[OK] OS: Ubuntu 24.04.1 LTS
[OK] Disk space: 45GB free
[OK] Network connectivity: OK
...
═══ Installation Complete! ═══
```

## Step 3: Reboot

```bash
sudo reboot
```

## Step 4: Log In and Start Training

After reboot:

```bash
ssh student@<vm-ip>
# Password: training123
```

You'll see a welcome banner showing your progress. Then type:

```bash
lpic1
```

The interactive training menu will launch.

---

## Installation Options

### Custom Username/Password

```bash
sudo ./install.sh --user trainee --password MySecurePass123
```

### Skip Practice Filesystems (Saves Disk Space)

```bash
sudo ./install.sh --skip-filesystems
```

### Verify Existing Installation

```bash
sudo ./install.sh --verify
```

### Uninstall

```bash
sudo ./install.sh --uninstall
```

---

## Platform-Specific Notes

### VirtualBox / VMware

- Allocate at least **2GB RAM** and **20GB disk**
- Enable **nested virtualization** if available (not required)
- Use **NAT** or **Bridged** networking to allow package downloads

### Cloud VMs (AWS, GCP, Azure, DigitalOcean)

Works out of the box:
```bash
# SSH to your cloud VM
ssh ubuntu@<public-ip>

# Clone and install
git clone https://github.com/YOUR-ORG/LPIC-1.git
cd LPIC-1
sudo ./install.sh

sudo reboot
```

Then SSH back in as `student`.

### WSL2 (Windows Subsystem for Linux)

The platform works on WSL2 Ubuntu with limitations:
- Practice filesystems won't work (no loop devices)
- Use `--skip-filesystems` flag

```bash
sudo ./install.sh --skip-filesystems
```

### Existing User Account

If you don't want a new user created, install as yourself:
```bash
sudo ./install.sh --user $(whoami) --password yourpassword
```

---

## Verify Everything Works

After installation, run:

```bash
lpic1 debug
```

Expected output:
```
=== LPIC-1 Debug Info ===

Paths:
  SCRIPT_DIR:   /opt/LPIC-1
  ...

Core Files:
  lpic-train:     OK
  lpic-check:     OK
  tui/main.sh:    OK
  ...

TUI Tools:
  dialog:   installed
  ...
```

Check practice filesystems:
```bash
df -h /mnt/lpic1/*
```

Expected output:
```
Filesystem                     Size  Used Avail Use% Mounted on
/dev/loop10                    100M   24K   92M   1% /mnt/lpic1/ext4-practice
/dev/loop11                    100M  5.3M   95M   6% /mnt/lpic1/xfs-practice
/dev/loop12                    100M   17M   84M  17% /mnt/lpic1/btrfs-practice
...
```

---

## First Training Session

1. **Launch the platform:**
   ```bash
   lpic1
   ```

2. **Navigate with arrow keys**, press Enter to select

3. **Recommended first steps:**
   - Go to "Learn" > pick a topic (grep is a good start)
   - Try "Practice" for guided exercises
   - Check "Status" to see your progress

4. **Quick commands** (instead of the menu):
   ```bash
   lpic1 learn grep       # Learn grep
   lpic1 practice find    # Practice find exercises
   lpic1 status           # See your progress
   ```

---

## Troubleshooting

### "sudo: ./install.sh: command not found"

Make the script executable:
```bash
chmod +x install.sh
sudo ./install.sh
```

### "lpic1: command not found" after install

The symlink should be at `/usr/local/bin/lpic1`. If missing:
```bash
sudo ln -sf /opt/LPIC-1/lpic1 /usr/local/bin/lpic1
```

Or run directly:
```bash
/opt/LPIC-1/lpic1
```

### Package installation fails

If behind a proxy or firewall:
```bash
# Set proxy
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# Then run installer
sudo -E ./install.sh
```

### Practice filesystems not mounted

```bash
# Check status
sudo systemctl status lpic1-filesystems

# Start manually
sudo systemctl start lpic1-filesystems

# Enable for boot
sudo systemctl enable lpic1-filesystems
```

### Reset all progress

```bash
rm -rf ~/.lpic1
lpic1   # Reinitializes on next run
```

### View installation log

```bash
cat /var/log/lpic1-install.log
```

---

## What Gets Installed

| Component | Location | Purpose |
|-----------|----------|---------|
| Training platform | `/opt/LPIC-1/` | Core training system |
| Command | `/usr/local/bin/lpic1` | Main entry point |
| Practice filesystems | `/mnt/lpic1/*` | ext4, xfs, btrfs, LVM, quotas |
| Filesystem images | `/opt/lpic1-practice/` | Loop device backing files |
| User progress | `~/.lpic1/` | SQLite database, snapshots |
| Practice files | `~/lpic1-practice/` | Text files for grep/sed/awk |
| Systemd service | `/etc/systemd/system/lpic1-filesystems.service` | Auto-mount on boot |
| Login banner | `/etc/update-motd.d/99-lpic1-training` | Progress display on SSH login |

---

## Next Steps

Once installed:

1. Run `lpic1` to start training
2. Work through topics in order, or jump to weak areas
3. Use `lpic1 smart` for personalized recommendations
4. Track progress with `lpic1 status`

Good luck with your LPIC-1 certification!
