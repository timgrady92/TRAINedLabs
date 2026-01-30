# Environment Setup Scripts

Scripts for preparing a Linux VM for LPIC-1 training. Run these in order on a fresh VM.

## Execution Order

1. **install-packages-*.sh** - Install required packages (choose one based on distro)
2. **create-practice-filesystems.sh** - Create loop devices for filesystem practice
3. **seed-data.sh** - Populate practice files and configurations

## Script Details

### install-packages-fedora.sh

Installs all packages needed for LPIC-1 practice on Fedora/RHEL/CentOS.

```bash
sudo ./install-packages-fedora.sh
```

**Requires:** Root privileges

**Installs packages for:**
- Hardware tools (pciutils, usbutils, lm_sensors)
- Boot management (grub2-tools)
- Package management (rpm, dnf)
- Filesystem tools (e2fsprogs, xfsprogs, btrfs-progs)
- Network tools (iproute, bind-utils, traceroute, nmap)
- Security tools (openssh, gnupg2)
- Printing (cups)
- And many more...

### install-packages-debian.sh

Installs all packages needed for LPIC-1 practice on Debian/Ubuntu.

```bash
sudo ./install-packages-debian.sh
```

**Requires:** Root privileges

**Installs equivalent Debian packages** for the same functionality.

### create-practice-filesystems.sh

Creates loop-mounted filesystems for safe partition/filesystem practice.

```bash
sudo ./create-practice-filesystems.sh
```

**Requires:** Root privileges

**Creates:**
- `/mnt/lpic1/ext4-practice` - ext4 formatted practice filesystem
- `/mnt/lpic1/xfs-practice` - XFS formatted practice filesystem
- `/mnt/lpic1/btrfs-practice` - Btrfs formatted practice filesystem
- `/mnt/lpic1/vfat-practice` - VFAT formatted practice filesystem
- `/mnt/lpic1/quota-test` - ext4 filesystem with quotas enabled
- `/mnt/lpic1/lvm-data`, `/mnt/lpic1/lvm-logs`, `/mnt/lpic1/lvm-backup` - LVM logical volumes
- Loop device images in `/opt/lpic1-practice/loop-images/`

**Options:**
- `--reset` - Remove existing practice filesystems and recreate

### seed-data.sh

Populates practice directories with sample data for exercises.

```bash
./seed-data.sh
```

**Creates:**
- Sample user data in `~/lpic1-practice/`
- Text files for grep/sed/awk practice (`~/lpic1-practice/text/`)
- Sample log files (`~/lpic1-practice/logs/`)
- Configuration file examples (`~/lpic1-practice/configs/`)
- Find practice directory structure (`~/lpic1-practice/find-practice/`)
- Permission testing files (`~/lpic1-practice/permissions-lab/`)
- Compression practice files (`~/lpic1-practice/compression/`)

## Post-Installation Verification

After running the scripts, verify the setup:

```bash
# Check essential commands
../core/lpic-check verify-packages

# Run system self-test
../core/lpic-check self-test

# Check a sample objective
../core/lpic-check objective 101.1
```

## Troubleshooting

### Package installation fails

```bash
# Fedora - update package cache
sudo dnf makecache

# Debian - update package lists
sudo apt update
```

### Loop device issues

```bash
# Check available loop devices
losetup -f

# If no loop devices available, load the module
sudo modprobe loop

# List current loop associations
losetup -a
```

### Filesystem creation fails

Ensure you have enough disk space (at least 5GB free):

```bash
df -h /var
```

## Cleanup

To remove all practice environments:

```bash
sudo ./create-practice-filesystems.sh --cleanup
```

This removes:
- Loop-mounted filesystems
- Practice image files
- Mount points
