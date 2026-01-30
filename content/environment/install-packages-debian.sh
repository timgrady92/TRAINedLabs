#!/bin/bash
# LPIC-1 Training Environment - Debian/Ubuntu Package Installer
# Installs all packages required for LPIC-1 exam objectives
# Run as root or with sudo

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if Debian/Ubuntu
if [[ ! -f /etc/debian_version ]]; then
    log_error "This script is for Debian/Ubuntu. Use install-packages-fedora.sh for Fedora."
    exit 1
fi

log_info "LPIC-1 Training Environment Installer for Debian/Ubuntu"
log_info "========================================================"
echo

# Prevent interactive prompts during install
export DEBIAN_FRONTEND=noninteractive

# Update package cache
log_info "Updating package cache..."
apt-get update

# Topic 101: System Architecture
log_info "Installing Topic 101: System Architecture packages..."
apt-get install -y \
    util-linux \
    pciutils \
    usbutils \
    kmod \
    systemd \
    sysvinit-utils \
    sysstat \
    lshw \
    dmidecode \
    hdparm

# Topic 102: Linux Installation and Package Management
log_info "Installing Topic 102: Linux Installation and Package Management packages..."
apt-get install -y \
    grub-common \
    grub2-common \
    grub-pc-bin \
    grub-efi-amd64-bin \
    apt \
    apt-utils \
    aptitude \
    dpkg \
    dpkg-dev \
    parted \
    gdisk \
    lvm2 \
    dmsetup \
    initramfs-tools \
    linux-headers-generic

# Topic 103: GNU and Unix Commands
log_info "Installing Topic 103: GNU and Unix Commands packages..."
apt-get install -y \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    mawk \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zstd \
    unzip \
    zip \
    procps \
    psmisc \
    screen \
    tmux \
    less \
    file \
    debianutils

# Topic 104: Devices, Linux Filesystems, FHS
log_info "Installing Topic 104: Devices, Linux Filesystems, FHS packages..."
apt-get install -y \
    e2fsprogs \
    xfsprogs \
    btrfs-progs \
    dosfstools \
    ntfs-3g \
    quota \
    quotatool \
    fuse3 \
    autofs \
    nfs-common \
    nfs-kernel-server \
    cifs-utils \
    sshfs \
    squashfs-tools \
    exfatprogs \
    mdadm

# Topic 105: Shells and Shell Scripting
log_info "Installing Topic 105: Shells and Shell Scripting packages..."
apt-get install -y \
    bash \
    bash-completion \
    zsh \
    tcsh \
    ksh \
    vim \
    vim-common \
    nano \
    emacs-nox \
    bc

# Topic 106: User Interfaces and Desktops
log_info "Installing Topic 106: User Interfaces and Desktops packages..."
apt-get install -y \
    xserver-xorg \
    xserver-xorg-core \
    x11-utils \
    x11-xserver-utils \
    xauth \
    xinit \
    xterm \
    x11-apps \
    dbus \
    dbus-daemon \
    mesa-utils \
    xclip

# VNC server (package name varies by release)
apt-get install -y tigervnc-standalone-server 2>/dev/null || \
    apt-get install -y tightvncserver 2>/dev/null || \
    log_warn "VNC server not installed - may need manual installation"

# Topic 107: Administrative Tasks
log_info "Installing Topic 107: Administrative Tasks packages..."
apt-get install -y \
    passwd \
    login \
    cron \
    anacron \
    at \
    acl \
    libcap2-bin \
    attr \
    whiptail \
    adduser

# Topic 108: Essential System Services
log_info "Installing Topic 108: Essential System Services packages..."
# Note: chrony is the modern replacement for ntp/ntpdate (deprecated/removed on modern systems)
apt-get install -y \
    chrony \
    rsyslog \
    systemd-journal-remote \
    postfix \
    bsd-mailx \
    mailutils \
    cups \
    cups-client \
    cups-bsd \
    cups-pdf \
    ghostscript

# Printer drivers (package name varies - hplip is the modern replacement for hpijs)
apt-get install -y hplip 2>/dev/null || \
    apt-get install -y printer-driver-hpcups 2>/dev/null || \
    apt-get install -y printer-driver-hpijs 2>/dev/null || \
    log_warn "HP printer drivers not installed - may need manual installation"

# Topic 109: Networking Fundamentals
log_info "Installing Topic 109: Networking Fundamentals packages..."
apt-get install -y \
    iproute2 \
    net-tools \
    dnsutils \
    traceroute \
    mtr-tiny \
    whois \
    network-manager \
    hostname \
    ethtool \
    bridge-utils \
    tcpdump \
    netcat-openbsd \
    socat \
    wget \
    curl \
    lftp \
    openssh-server \
    openssh-client \
    rsync

# Topic 110: Security
log_info "Installing Topic 110: Security packages..."
# Note: On Ubuntu 24.04+, ufw and iptables-persistent conflict (both try to manage firewall rules)
# We install ufw (simpler, LPIC-1 focused) and iptables (for learning iptables commands)
# but NOT iptables-persistent which would conflict with ufw
apt-get install -y \
    gnupg \
    gnupg2 \
    sudo \
    ufw \
    iptables \
    nftables \
    libpam-modules \
    libpwquality1 \
    libpwquality-tools \
    openssl \
    openssh-server \
    fail2ban \
    aide \
    auditd \
    apparmor \
    apparmor-utils \
    apparmor-profiles

# Development tools (for compiling kernel modules, etc.)
log_info "Installing development tools..."
apt-get install -y \
    gcc \
    g++ \
    make \
    automake \
    autoconf \
    libtool \
    linux-headers-generic \
    libc6-dev \
    binutils \
    elfutils \
    strace \
    ltrace \
    gdb \
    git

# Additional utilities for labs
log_info "Installing additional lab utilities..."
apt-get install -y \
    tree \
    htop \
    iotop \
    iftop \
    ncdu \
    jq \
    sqlite3 \
    expect \
    dialog \
    man-db \
    manpages \
    info \
    texinfo \
    wamerican

# Enable essential services
log_info "Enabling essential services..."
systemctl enable ssh
systemctl enable rsyslog
systemctl enable cron
systemctl enable chrony
systemctl enable auditd

# Start services that are needed now
systemctl start ssh
systemctl start rsyslog
systemctl start cron
systemctl start chrony
systemctl start auditd || true  # May fail if not fully configured

# Enable UFW but don't activate (let user configure first)
log_info "UFW installed but not activated - configure rules first"

# Create practice directories
log_info "Creating practice directory structure..."
mkdir -p /opt/lpic1-practice/{files,logs,scripts,configs}
chmod 755 /opt/lpic1-practice
chmod 1777 /opt/lpic1-practice/files  # Sticky bit for multi-user practice

# Verify critical commands are available
log_info "Verifying command availability..."
FAILED_CMDS=()
CMDS_TO_CHECK=(
    "systemctl" "journalctl" "dmesg" "lsblk" "mount"
    "apt" "apt-get" "dpkg" "grub-mkconfig"
    "find" "grep" "sed" "awk" "tar"
    "mkfs.ext4" "mkfs.xfs" "fdisk" "parted" "pvcreate"
    "bash" "vim" "screen" "tmux"
    "useradd" "groupadd" "crontab" "at"
    "chronyc" "postfix" "lpstat"
    "ip" "ss" "dig" "traceroute"
    "ssh" "gpg" "sudo" "ufw" "iptables"
)

for cmd in "${CMDS_TO_CHECK[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        FAILED_CMDS+=("$cmd")
    fi
done

echo
if [[ ${#FAILED_CMDS[@]} -gt 0 ]]; then
    log_warn "Some commands not found: ${FAILED_CMDS[*]}"
    log_warn "These may need manual installation or are in a different package"
else
    log_success "All critical commands verified"
fi

# Clean up
log_info "Cleaning up..."
apt-get autoremove -y
apt-get clean

# Display summary
echo
log_success "========================================================"
log_success "LPIC-1 Training Environment Installation Complete"
log_success "========================================================"
echo
log_info "Installed packages for all 10 LPIC-1 exam topics"
log_info "Practice files location: /opt/lpic1-practice/"
log_info "Next steps:"
echo "  1. Run: ./create-practice-filesystems.sh"
echo "  2. Run: ./seed-data.sh"
echo "  3. Run: ../core/init-progress.sh (as regular user)"
echo

# Count installed packages
TOTAL=$(dpkg -l | grep -c '^ii')
log_info "Total packages installed: $TOTAL"
