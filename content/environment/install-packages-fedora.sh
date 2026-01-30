#!/bin/bash
# LPIC-1 Training Environment - Fedora Package Installer
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

# Check if Fedora
if [[ ! -f /etc/fedora-release ]]; then
    log_error "This script is for Fedora. Use install-packages-debian.sh for Debian/Ubuntu."
    exit 1
fi

log_info "LPIC-1 Training Environment Installer for Fedora"
log_info "================================================="
echo

# Update package cache
log_info "Updating package cache..."
dnf check-update || true  # Returns 100 if updates available, which is fine

# Topic 101: System Architecture
log_info "Installing Topic 101: System Architecture packages..."
dnf install -y \
    util-linux \
    pciutils \
    usbutils \
    kmod \
    systemd \
    initscripts \
    sysstat \
    lshw \
    dmidecode \
    hdparm

# Topic 102: Linux Installation and Package Management
log_info "Installing Topic 102: Linux Installation and Package Management packages..."
dnf install -y \
    grub2-tools \
    grub2-efi-x64 \
    grub2-pc \
    dnf \
    dnf-plugins-core \
    rpm \
    rpm-build \
    yum-utils \
    parted \
    gdisk \
    lvm2 \
    device-mapper \
    dracut \
    kernel-devel

# Topic 103: GNU and Unix Commands
log_info "Installing Topic 103: GNU and Unix Commands packages..."
# Note: Commands like wc, sort, cut, paste, join, split, head, tail, tee, od,
# nl, fmt, pr, expand, unexpand, tr are all part of coreutils (already installed).
# hexdump is part of util-linux, strings is part of binutils (installed in dev tools).
dnf install -y \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    tar \
    gzip \
    bzip2 \
    xz \
    zstd \
    unzip \
    zip \
    procps-ng \
    psmisc \
    screen \
    tmux \
    less \
    file \
    which

# Topic 104: Devices, Linux Filesystems, FHS
log_info "Installing Topic 104: Devices, Linux Filesystems, FHS packages..."
dnf install -y \
    e2fsprogs \
    xfsprogs \
    btrfs-progs \
    dosfstools \
    ntfs-3g \
    quota \
    quotatool \
    fuse \
    fuse-libs \
    autofs \
    nfs-utils \
    cifs-utils \
    sshfs \
    squashfs-tools \
    exfatprogs \
    mdadm

# Topic 105: Shells and Shell Scripting
log_info "Installing Topic 105: Shells and Shell Scripting packages..."
dnf install -y \
    bash \
    bash-completion \
    zsh \
    tcsh \
    ksh \
    vim-enhanced \
    nano \
    emacs-nox \
    bc

# Topic 106: User Interfaces and Desktops
log_info "Installing Topic 106: User Interfaces and Desktops packages..."
dnf install -y \
    xorg-x11-server-Xorg \
    xorg-x11-utils \
    xorg-x11-xauth \
    xorg-x11-xinit \
    xterm \
    tigervnc-server \
    xdpyinfo \
    xwininfo \
    dbus \
    dbus-daemon \
    mesa-dri-drivers \
    xclip

# Topic 107: Administrative Tasks
log_info "Installing Topic 107: Administrative Tasks packages..."
dnf install -y \
    shadow-utils \
    util-linux-user \
    cronie \
    cronie-anacron \
    at \
    acl \
    libcap \
    attr \
    newt \
    usermode

# Topic 108: Essential System Services
log_info "Installing Topic 108: Essential System Services packages..."
# Note: chrony is the modern replacement for ntp (deprecated/removed on modern systems)
dnf install -y \
    chrony \
    rsyslog \
    systemd-journal-remote \
    postfix \
    mailx \
    cups \
    cups-client \
    cups-lpd \
    cups-pdf \
    hplip \
    ghostscript

# Topic 109: Networking Fundamentals
log_info "Installing Topic 109: Networking Fundamentals packages..."
dnf install -y \
    iproute \
    net-tools \
    bind-utils \
    traceroute \
    mtr \
    whois \
    NetworkManager \
    NetworkManager-tui \
    hostname \
    ethtool \
    bridge-utils \
    tcpdump \
    nmap-ncat \
    socat \
    wget \
    curl \
    lftp \
    openssh-server \
    openssh-clients \
    rsync

# Topic 110: Security
log_info "Installing Topic 110: Security packages..."
dnf install -y \
    gnupg2 \
    sudo \
    firewalld \
    iptables \
    iptables-services \
    nftables \
    pam \
    libpwquality \
    openssl \
    openssh \
    fail2ban \
    aide \
    audit \
    selinux-policy \
    selinux-policy-targeted \
    policycoreutils \
    policycoreutils-python-utils \
    setroubleshoot-server

# Development tools (for compiling kernel modules, etc.)
log_info "Installing development tools..."
dnf install -y \
    gcc \
    gcc-c++ \
    make \
    automake \
    autoconf \
    libtool \
    kernel-headers \
    glibc-devel \
    binutils \
    elfutils \
    strace \
    ltrace \
    gdb \
    git

# Additional utilities for labs
log_info "Installing additional lab utilities..."
dnf install -y \
    tree \
    htop \
    iotop \
    iftop \
    ncdu \
    jq \
    sqlite \
    expect \
    dialog \
    man-db \
    man-pages \
    info \
    texinfo \
    words

# Enable essential services
log_info "Enabling essential services..."
systemctl enable sshd
systemctl enable rsyslog
systemctl enable crond
systemctl enable chronyd
systemctl enable firewalld
systemctl enable auditd

# Start services that are needed now
systemctl start sshd
systemctl start rsyslog
systemctl start crond
systemctl start chronyd
systemctl start firewalld
systemctl start auditd

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
    "dnf" "rpm" "grub2-mkconfig"
    "find" "grep" "sed" "awk" "tar"
    "mkfs.ext4" "mkfs.xfs" "fdisk" "parted" "pvcreate"
    "bash" "vim" "screen" "tmux"
    "useradd" "groupadd" "crontab" "at"
    "chronyc" "postfix" "lpstat"
    "ip" "ss" "dig" "traceroute"
    "ssh" "gpg" "sudo" "firewall-cmd" "iptables"
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

# Display summary
echo
log_success "================================================="
log_success "LPIC-1 Training Environment Installation Complete"
log_success "================================================="
echo
log_info "Installed packages for all 10 LPIC-1 exam topics"
log_info "Practice files location: /opt/lpic1-practice/"
log_info "Next steps:"
echo "  1. Run: ./create-practice-filesystems.sh"
echo "  2. Run: ./seed-data.sh"
echo "  3. Run: ../core/init-progress.sh (as regular user)"
echo

# Count installed packages
TOTAL=$(rpm -qa | wc -l)
log_info "Total packages installed: $TOTAL"
