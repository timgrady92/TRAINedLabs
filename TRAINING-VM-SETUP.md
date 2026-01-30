# LPIC-1 Training VM Setup Guide

A hands-on practice environment for LPIC-1 certification with interactive feedback and progress tracking.

## Architecture Overview

This setup uses **dual VMs** to cover both major Linux ecosystems tested on LPIC-1:

| VM | Distro | Purpose | Primary Focus |
|----|--------|---------|---------------|
| **lpic-fedora** | Fedora 39+ | RPM ecosystem | dnf, rpm, systemd, firewalld |
| **lpic-debian** | Ubuntu 22.04 / Debian 12 | DEB ecosystem | apt, dpkg, systemd, ufw |

Both VMs share the same training scripts via a shared folder or git clone.

## VM Specifications

### Minimum per VM

```
CPU:     2 vCPU
RAM:     4 GB
Disk:    30 GB (primary)
         10 GB (secondary - for partition/LVM labs)
Network: 2 NICs (NAT + Internal)
```

### Recommended per VM

```
CPU:     4 vCPU
RAM:     8 GB
Disk:    50 GB (primary)
         20 GB (secondary)
         10 GB (tertiary - for RAID labs)
Network: 2 NICs
```

## Quick Start

### 1. Create VMs

**VirtualBox:**
```bash
# Fedora VM
VBoxManage createvm --name "lpic-fedora" --ostype Fedora_64 --register
VBoxManage modifyvm "lpic-fedora" --cpus 2 --memory 4096 --vram 128
VBoxManage createhd --filename ~/VMs/lpic-fedora/lpic-fedora.vdi --size 30720
VBoxManage createhd --filename ~/VMs/lpic-fedora/lpic-fedora-disk2.vdi --size 10240
VBoxManage storagectl "lpic-fedora" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "lpic-fedora" --storagectl "SATA" --port 0 --device 0 --type hdd --medium ~/VMs/lpic-fedora/lpic-fedora.vdi
VBoxManage storageattach "lpic-fedora" --storagectl "SATA" --port 1 --device 0 --type hdd --medium ~/VMs/lpic-fedora/lpic-fedora-disk2.vdi

# Debian/Ubuntu VM
VBoxManage createvm --name "lpic-debian" --ostype Ubuntu_64 --register
VBoxManage modifyvm "lpic-debian" --cpus 2 --memory 4096 --vram 128
VBoxManage createhd --filename ~/VMs/lpic-debian/lpic-debian.vdi --size 30720
VBoxManage createhd --filename ~/VMs/lpic-debian/lpic-debian-disk2.vdi --size 10240
VBoxManage storagectl "lpic-debian" --name "SATA" --add sata --controller IntelAhci
VBoxManage storageattach "lpic-debian" --storagectl "SATA" --port 0 --device 0 --type hdd --medium ~/VMs/lpic-debian/lpic-debian.vdi
VBoxManage storageattach "lpic-debian" --storagectl "SATA" --port 1 --device 0 --type hdd --medium ~/VMs/lpic-debian/lpic-debian-disk2.vdi
```

**libvirt/KVM:**
```bash
# Fedora VM
virt-install \
  --name lpic-fedora \
  --memory 4096 \
  --vcpus 2 \
  --disk size=30 \
  --disk size=10 \
  --os-variant fedora39 \
  --network network=default \
  --network network=lpic-internal \
  --cdrom ~/ISOs/Fedora-Server-dvd-x86_64-39.iso

# Debian/Ubuntu VM
virt-install \
  --name lpic-debian \
  --memory 4096 \
  --vcpus 2 \
  --disk size=30 \
  --disk size=10 \
  --os-variant ubuntu22.04 \
  --network network=default \
  --network network=lpic-internal \
  --cdrom ~/ISOs/ubuntu-22.04-live-server-amd64.iso
```

### 2. Network Configuration

Create an internal network for inter-VM communication:

**VirtualBox:**
```bash
# Add internal network adapter to both VMs
VBoxManage modifyvm "lpic-fedora" --nic2 intnet --intnet2 "lpic-net"
VBoxManage modifyvm "lpic-debian" --nic2 intnet --intnet2 "lpic-net"
```

**libvirt:**
```bash
# Create internal network
cat > /tmp/lpic-internal.xml << 'EOF'
<network>
  <name>lpic-internal</name>
  <bridge name="virbr-lpic"/>
  <ip address="10.0.100.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.0.100.10" end="10.0.100.50"/>
      <host mac="52:54:00:aa:bb:01" name="lpic-fedora" ip="10.0.100.11"/>
      <host mac="52:54:00:aa:bb:02" name="lpic-debian" ip="10.0.100.12"/>
    </dhcp>
  </ip>
</network>
EOF
virsh net-define /tmp/lpic-internal.xml
virsh net-start lpic-internal
virsh net-autostart lpic-internal
```

**Static IPs (configure inside VMs):**

On Fedora:
```bash
nmcli con add con-name lpic-internal ifname eth1 type ethernet \
  ip4 10.0.100.11/24
nmcli con up lpic-internal
```

On Debian/Ubuntu:
```bash
# /etc/netplan/01-lpic-internal.yaml
cat > /etc/netplan/01-lpic-internal.yaml << 'EOF'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [10.0.100.12/24]
EOF
netplan apply
```

### 3. Install Training Environment

On each VM:

```bash
# Clone or copy training files
git clone https://github.com/YOUR_REPO/lpic1-training.git ~/lpic1-training
cd ~/lpic1-training

# Run distro-appropriate installer
# On Fedora:
sudo ./environment/install-packages-fedora.sh

# On Debian/Ubuntu:
sudo ./environment/install-packages-debian.sh

# Initialize progress tracking
./feedback-system/init-progress.sh

# Set up practice environments
sudo ./environment/create-practice-filesystems.sh
./environment/seed-data.sh

# Install MOTD integration
sudo ./motd-integration/training-motd.sh --install
```

### 4. Verify Installation

```bash
# Check all required packages installed
./feedback-system/lpic-check verify-packages

# Run self-tests on feedback system
./feedback-system/lpic-check self-test

# Check inter-VM connectivity (from Fedora)
ping -c 3 10.0.100.12
```

## Training Workflow

### Daily Practice

1. **Login** - See your progress and suggested next objective
2. **Study** - Review objective in CERTIFIed web app
3. **Practice** - Run hands-on labs
4. **Validate** - Check your work with `lpic-check`
5. **Record** - Progress automatically tracked

### Check Objective Completion

```bash
# Check specific objective
./feedback-system/lpic-check objective 101.1

# Check all objectives in a topic
./feedback-system/lpic-check topic 101

# See detailed results
./feedback-system/lpic-check objective 101.1 --verbose
```

### Run Break/Fix Scenarios

```bash
# List available scenarios
./scenarios/break-fix/broken-boot.sh --list

# Start a scenario (saves restore point)
sudo ./scenarios/break-fix/broken-boot.sh --start grub-missing

# After fixing, validate
sudo ./scenarios/break-fix/broken-boot.sh --check grub-missing

# Restore if stuck
sudo ./scenarios/break-fix/broken-boot.sh --restore grub-missing
```

### Run Build Scenarios

```bash
# Start a build challenge
./scenarios/build/setup-web-server.sh --start

# Check your progress
./scenarios/build/setup-web-server.sh --check

# Get hints (costs points)
./scenarios/build/setup-web-server.sh --hint
```

### View Progress

```bash
# Summary
./feedback-system/lpic-check progress

# Detailed by topic
./feedback-system/lpic-check progress --detailed

# Export for review
./feedback-system/lpic-check progress --export > my-progress.json
```

## Package Checklist

All packages required for LPIC-1 training are installed by the environment scripts. Key categories:

### System Architecture (101)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| util-linux | ✓ | ✓ | dmesg, lsblk, mount |
| pciutils | ✓ | ✓ | lspci |
| usbutils | ✓ | ✓ | lsusb |
| kmod | ✓ | ✓ | lsmod, modprobe, modinfo |
| systemd | ✓ | ✓ | systemctl, journalctl |
| sysvinit-tools | - | ✓ | SysV init compatibility |
| initscripts | ✓ | - | SysV init compatibility |

### Linux Installation & Package Management (102)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| grub2-tools | ✓ | - | GRUB bootloader |
| grub-common | - | ✓ | GRUB bootloader |
| dnf | ✓ | - | DNF package manager |
| rpm | ✓ | - | RPM package manager |
| apt | - | ✓ | APT package manager |
| dpkg | - | ✓ | DPKG package manager |
| parted | ✓ | ✓ | Partition management |
| lvm2 | ✓ | ✓ | Logical volume management |

### GNU and Unix Commands (103)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| coreutils | ✓ | ✓ | cat, cp, mv, rm, ls, etc. |
| findutils | ✓ | ✓ | find, xargs |
| grep | ✓ | ✓ | grep, egrep, fgrep |
| sed | ✓ | ✓ | Stream editor |
| gawk | ✓ | ✓ | AWK programming |
| tar | ✓ | ✓ | Archive utility |
| gzip | ✓ | ✓ | Compression |
| bzip2 | ✓ | ✓ | Compression |
| xz | ✓ | ✓ | Compression |
| procps-ng | ✓ | ✓ | ps, top, free, kill |
| psmisc | ✓ | ✓ | pstree, killall, fuser |
| screen | ✓ | ✓ | Terminal multiplexer |
| tmux | ✓ | ✓ | Terminal multiplexer |

### Devices, Filesystems, FHS (104)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| e2fsprogs | ✓ | ✓ | ext2/3/4 tools |
| xfsprogs | ✓ | ✓ | XFS tools |
| btrfs-progs | ✓ | ✓ | Btrfs tools |
| dosfstools | ✓ | ✓ | FAT/VFAT tools |
| quota | ✓ | ✓ | Disk quotas |
| gdisk | ✓ | ✓ | GPT partitioning |

### Shells and Shell Scripting (105)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| bash | ✓ | ✓ | Bash shell |
| bash-completion | ✓ | ✓ | Tab completion |
| vim-enhanced | ✓ | - | Vi IMproved |
| vim | - | ✓ | Vi IMproved |

### User Interfaces and Desktops (106)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| xorg-x11-server-Xorg | ✓ | - | X11 server |
| xserver-xorg | - | ✓ | X11 server |
| xauth | ✓ | ✓ | X authentication |
| tigervnc-server | ✓ | - | VNC server |
| tightvncserver | - | ✓ | VNC server |
| dbus | ✓ | ✓ | D-Bus messaging |

### Administrative Tasks (107)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| shadow-utils | ✓ | - | User management |
| passwd | - | ✓ | User management |
| cronie | ✓ | - | Cron daemon |
| cron | - | ✓ | Cron daemon |
| at | ✓ | ✓ | Job scheduling |
| systemd | ✓ | ✓ | systemd-logind |

### Essential System Services (108)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| chrony | ✓ | ✓ | NTP time sync |
| rsyslog | ✓ | ✓ | System logging |
| postfix | ✓ | ✓ | Mail transfer |
| cups | ✓ | ✓ | Printing |

### Networking Fundamentals (109)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| iproute | ✓ | ✓ | ip command |
| net-tools | ✓ | ✓ | ifconfig, route, netstat |
| bind-utils | ✓ | - | dig, nslookup |
| dnsutils | - | ✓ | dig, nslookup |
| traceroute | ✓ | ✓ | Network path tracing |
| NetworkManager | ✓ | ✓ | Network management |

### Security (110)

| Package | Fedora | Debian | Purpose |
|---------|--------|--------|---------|
| openssh-server | ✓ | ✓ | SSH server |
| openssh-clients | ✓ | - | SSH client |
| openssh-client | - | ✓ | SSH client |
| gnupg2 | ✓ | ✓ | GPG encryption |
| sudo | ✓ | ✓ | Privilege escalation |
| firewalld | ✓ | - | Firewall (Fedora) |
| ufw | - | ✓ | Firewall (Debian) |
| iptables | ✓ | ✓ | Packet filtering |

## Troubleshooting

### Common Issues

**"Command not found" after package install:**
```bash
hash -r  # Clear bash command cache
# Or start new shell
exec bash
```

**Secondary disk not visible:**
```bash
# Scan for new disks
echo "- - -" | sudo tee /sys/class/scsi_host/host*/scan
lsblk
```

**VMs can't ping each other:**
```bash
# Check firewall
sudo firewall-cmd --list-all  # Fedora
sudo ufw status              # Debian

# Temporarily allow all (for testing only)
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.0.100.0/24" accept'  # Fedora
sudo ufw allow from 10.0.100.0/24  # Debian
```

**Progress database corrupted:**
```bash
# Backup and reinitialize
mv ~/.lpic1/progress.db ~/.lpic1/progress.db.bak
./feedback-system/init-progress.sh
```

### Reset Environment

```bash
# Full reset (keeps progress)
sudo ./environment/create-practice-filesystems.sh --reset
./environment/seed-data.sh --reset

# Nuclear reset (loses progress)
rm -rf ~/.lpic1
./feedback-system/init-progress.sh
sudo ./environment/create-practice-filesystems.sh
./environment/seed-data.sh
```

## Exam Simulation

For exam-like conditions:

```bash
# Start timed practice session (90 minutes)
./feedback-system/lpic-check exam-mode --time 90

# Random objectives, no hints
./feedback-system/lpic-check exam-mode --random --no-hints

# Full exam simulation (60 questions, 90 min)
./feedback-system/lpic-check exam-mode --full
```

## File Locations

| Path | Purpose |
|------|---------|
| `~/.lpic1/` | User data directory |
| `~/.lpic1/progress.db` | SQLite progress database |
| `~/.lpic1/snapshots/` | Scenario restore points |
| `/opt/lpic1-practice/` | Shared practice files |
| `/mnt/lpic1/` | Loop device mountpoints |

## Next Steps

1. Complete the environment setup on both VMs
2. Run `lpic-check self-test` to verify everything works
3. Start with Topic 101 objectives
4. Use `lpic-check progress` to track your journey

---

*Generated for CERTIFIed LPIC-1 training. Questions? Open an issue in the training repo.*
