#!/bin/bash
# LPIC-1 Training Environment - Practice Filesystems Setup
# Creates loop devices, filesystems, and LVM for hands-on practice
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

# Configuration
PRACTICE_DIR="/opt/lpic1-practice"
LOOP_DIR="${PRACTICE_DIR}/loop-images"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Parse arguments
RESET=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --reset)
            RESET=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--reset]"
            echo "  --reset  Remove existing practice filesystems and recreate"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Cleanup function
cleanup_existing() {
    log_info "Cleaning up existing practice environment..."

    # Unmount any existing mounts
    for mount in "${MOUNT_BASE}"/*; do
        if mountpoint -q "$mount" 2>/dev/null; then
            umount "$mount" || umount -l "$mount"
            log_info "Unmounted $mount"
        fi
    done

    # Deactivate LVM if exists
    if vgdisplay "$LVM_VG" &>/dev/null; then
        vgchange -an "$LVM_VG" || true
        for _pv in $(pvs --noheadings -o pv_name 2>/dev/null | grep loop); do
            vgreduce --removemissing "$LVM_VG" 2>/dev/null || true
        done
        vgremove -f "$LVM_VG" 2>/dev/null || true
    fi

    # Detach loop devices
    for loop in /dev/loop{10..19}; do
        if losetup "$loop" &>/dev/null; then
            losetup -d "$loop" 2>/dev/null || true
        fi
    done

    # Remove old image files
    rm -rf "${LOOP_DIR:?}"/*

    log_success "Cleanup complete"
}

# Create directory structure
setup_directories() {
    log_info "Setting up directories..."

    mkdir -p "$LOOP_DIR"
    mkdir -p "${MOUNT_BASE}"/{ext4-practice,xfs-practice,btrfs-practice,vfat-practice}
    mkdir -p "${MOUNT_BASE}"/{lvm-data,lvm-logs,lvm-backup}
    mkdir -p "${MOUNT_BASE}"/quota-test
    mkdir -p "${MOUNT_BASE}"/raid-practice

    log_success "Directories created"
}

# Create loop device images
create_loop_images() {
    log_info "Creating loop device images..."

    # Filesystem practice images
    # Note: XFS requires minimum 300MB on modern systems (Ubuntu 24.04+)
    dd if=/dev/zero of="${LOOP_DIR}/ext4.img" bs=1M count=100 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/xfs.img" bs=1M count=300 status=progress   # XFS needs 300MB minimum
    dd if=/dev/zero of="${LOOP_DIR}/btrfs.img" bs=1M count=300 status=progress # Btrfs needs ~256MB minimum
    dd if=/dev/zero of="${LOOP_DIR}/vfat.img" bs=1M count=100 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/quota.img" bs=1M count=100 status=progress

    # LVM practice images (300MB each to allow 300MB+ XFS logical volumes)
    dd if=/dev/zero of="${LOOP_DIR}/lvm-pv1.img" bs=1M count=300 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/lvm-pv2.img" bs=1M count=300 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/lvm-pv3.img" bs=1M count=300 status=progress

    # RAID practice images (100MB each)
    dd if=/dev/zero of="${LOOP_DIR}/raid1.img" bs=1M count=100 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/raid2.img" bs=1M count=100 status=progress
    dd if=/dev/zero of="${LOOP_DIR}/raid3.img" bs=1M count=100 status=progress

    log_success "Loop images created"
}

# Setup loop devices
setup_loop_devices() {
    log_info "Setting up loop devices..."

    # Use specific loop device numbers to avoid conflicts
    losetup /dev/loop10 "${LOOP_DIR}/ext4.img"
    losetup /dev/loop11 "${LOOP_DIR}/xfs.img"
    losetup /dev/loop12 "${LOOP_DIR}/btrfs.img"
    losetup /dev/loop13 "${LOOP_DIR}/vfat.img"
    losetup /dev/loop14 "${LOOP_DIR}/quota.img"
    losetup /dev/loop15 "${LOOP_DIR}/lvm-pv1.img"
    losetup /dev/loop16 "${LOOP_DIR}/lvm-pv2.img"
    losetup /dev/loop17 "${LOOP_DIR}/lvm-pv3.img"
    losetup /dev/loop18 "${LOOP_DIR}/raid1.img"
    losetup /dev/loop19 "${LOOP_DIR}/raid2.img"

    log_success "Loop devices configured"
    losetup -a | grep lpic1
}

# Create filesystems
create_filesystems() {
    log_info "Creating filesystems..."

    # ext4 with specific options
    mkfs.ext4 -L lpic1-ext4 -m 2 /dev/loop10
    log_success "ext4 filesystem created on /dev/loop10"

    # XFS
    mkfs.xfs -L lpic1-xfs /dev/loop11
    log_success "XFS filesystem created on /dev/loop11"

    # Btrfs
    mkfs.btrfs -L lpic1-btrfs /dev/loop12
    log_success "Btrfs filesystem created on /dev/loop12"

    # VFAT
    mkfs.vfat -n LPIC1VFAT /dev/loop13
    log_success "VFAT filesystem created on /dev/loop13"

    # ext4 for quota testing
    mkfs.ext4 -L lpic1-quota /dev/loop14
    log_success "Quota test filesystem created on /dev/loop14"
}

# Setup LVM
setup_lvm() {
    log_info "Setting up LVM..."

    # Create physical volumes
    pvcreate /dev/loop15 /dev/loop16 /dev/loop17
    log_success "Physical volumes created"

    # Create volume group
    vgcreate "$LVM_VG" /dev/loop15 /dev/loop16 /dev/loop17
    log_success "Volume group '$LVM_VG' created"

    # Create logical volumes
    # Note: lv_logs needs 300MB minimum for XFS on Ubuntu 24.04+
    lvcreate -L 200M -n lv_data "$LVM_VG"
    lvcreate -L 300M -n lv_logs "$LVM_VG"
    lvcreate -L 100M -n lv_backup "$LVM_VG"
    log_success "Logical volumes created"

    # Create filesystems on LVs
    mkfs.ext4 -L lv-data "/dev/${LVM_VG}/lv_data"
    mkfs.xfs -L lv-logs "/dev/${LVM_VG}/lv_logs"
    mkfs.ext4 -L lv-backup "/dev/${LVM_VG}/lv_backup"
    log_success "Filesystems created on logical volumes"

    # Display LVM status
    echo
    log_info "LVM Configuration:"
    pvs
    vgs
    lvs
}

# Mount filesystems
mount_filesystems() {
    log_info "Mounting filesystems..."

    mount /dev/loop10 "${MOUNT_BASE}/ext4-practice"
    mount /dev/loop11 "${MOUNT_BASE}/xfs-practice"
    mount /dev/loop12 "${MOUNT_BASE}/btrfs-practice"
    mount /dev/loop13 "${MOUNT_BASE}/vfat-practice"
    mount -o usrquota,grpquota /dev/loop14 "${MOUNT_BASE}/quota-test"

    mount "/dev/${LVM_VG}/lv_data" "${MOUNT_BASE}/lvm-data"
    mount "/dev/${LVM_VG}/lv_logs" "${MOUNT_BASE}/lvm-logs"
    mount "/dev/${LVM_VG}/lv_backup" "${MOUNT_BASE}/lvm-backup"

    log_success "Filesystems mounted"

    echo
    log_info "Mounted filesystems:"
    df -h "${MOUNT_BASE}"/*
}

# Setup disk quotas
setup_quotas() {
    log_info "Setting up disk quotas..."

    # Initialize quota
    quotacheck -cug "${MOUNT_BASE}/quota-test"
    quotaon "${MOUNT_BASE}/quota-test"

    # Create a test user for quota practice if not exists
    if ! id quotauser &>/dev/null; then
        useradd -m -s /bin/bash quotauser
        log_info "Created user 'quotauser' for quota testing"
    fi

    # Set sample quotas
    setquota -u quotauser 50000 100000 100 200 "${MOUNT_BASE}/quota-test"

    log_success "Quotas configured"
    repquota -a
}

# Create fstab entries (commented for reference)
create_fstab_reference() {
    log_info "Creating fstab reference file..."

    cat > "${PRACTICE_DIR}/fstab-examples.txt" << 'EOF'
# LPIC-1 Practice Filesystem fstab Examples
# These entries are for REFERENCE ONLY - do not add to actual /etc/fstab
# as they use loop devices that may not persist across reboots

# Loop device filesystems
/dev/loop10    /mnt/lpic1/ext4-practice    ext4    defaults        0 2
/dev/loop11    /mnt/lpic1/xfs-practice     xfs     defaults        0 2
/dev/loop12    /mnt/lpic1/btrfs-practice   btrfs   defaults        0 2
/dev/loop13    /mnt/lpic1/vfat-practice    vfat    defaults        0 0
/dev/loop14    /mnt/lpic1/quota-test       ext4    usrquota,grpquota 0 2

# LVM logical volumes
/dev/lpic1_vg/lv_data    /mnt/lpic1/lvm-data    ext4    defaults    0 2
/dev/lpic1_vg/lv_logs    /mnt/lpic1/lvm-logs    xfs     defaults    0 2
/dev/lpic1_vg/lv_backup  /mnt/lpic1/lvm-backup  ext4    defaults    0 2

# UUID-based mounting (more reliable)
# Use 'blkid' to find UUIDs, then:
# UUID=xxxx-xxxx-xxxx-xxxx    /mnt/lpic1/ext4-practice    ext4    defaults    0 2

# NFS example
# server:/export    /mnt/nfs    nfs    defaults,_netdev    0 0

# CIFS/SMB example
# //server/share    /mnt/smb    cifs    credentials=/etc/samba/creds,_netdev    0 0
EOF

    log_success "fstab reference created at ${PRACTICE_DIR}/fstab-examples.txt"
}

# Create persistence script
create_persistence_script() {
    log_info "Creating persistence script..."

    cat > "${PRACTICE_DIR}/mount-practice-fs.sh" << 'SCRIPT'
#!/bin/bash
# Re-mount LPIC-1 practice filesystems after reboot
# Run as root

set -e

LOOP_DIR="/opt/lpic1-practice/loop-images"
MOUNT_BASE="/mnt/lpic1"
LVM_VG="lpic1_vg"

# Setup loop devices
losetup /dev/loop10 "${LOOP_DIR}/ext4.img" 2>/dev/null || true
losetup /dev/loop11 "${LOOP_DIR}/xfs.img" 2>/dev/null || true
losetup /dev/loop12 "${LOOP_DIR}/btrfs.img" 2>/dev/null || true
losetup /dev/loop13 "${LOOP_DIR}/vfat.img" 2>/dev/null || true
losetup /dev/loop14 "${LOOP_DIR}/quota.img" 2>/dev/null || true
losetup /dev/loop15 "${LOOP_DIR}/lvm-pv1.img" 2>/dev/null || true
losetup /dev/loop16 "${LOOP_DIR}/lvm-pv2.img" 2>/dev/null || true
losetup /dev/loop17 "${LOOP_DIR}/lvm-pv3.img" 2>/dev/null || true

# Activate LVM
vgchange -ay "$LVM_VG"

# Mount filesystems
mount /dev/loop10 "${MOUNT_BASE}/ext4-practice" 2>/dev/null || echo "ext4 already mounted"
mount /dev/loop11 "${MOUNT_BASE}/xfs-practice" 2>/dev/null || echo "xfs already mounted"
mount /dev/loop12 "${MOUNT_BASE}/btrfs-practice" 2>/dev/null || echo "btrfs already mounted"
mount /dev/loop13 "${MOUNT_BASE}/vfat-practice" 2>/dev/null || echo "vfat already mounted"
mount -o usrquota,grpquota /dev/loop14 "${MOUNT_BASE}/quota-test" 2>/dev/null || echo "quota already mounted"

mount "/dev/${LVM_VG}/lv_data" "${MOUNT_BASE}/lvm-data" 2>/dev/null || echo "lvm-data already mounted"
mount "/dev/${LVM_VG}/lv_logs" "${MOUNT_BASE}/lvm-logs" 2>/dev/null || echo "lvm-logs already mounted"
mount "/dev/${LVM_VG}/lv_backup" "${MOUNT_BASE}/lvm-backup" 2>/dev/null || echo "lvm-backup already mounted"

# Enable quotas
quotaon "${MOUNT_BASE}/quota-test" 2>/dev/null || true

echo "Practice filesystems mounted:"
df -h "${MOUNT_BASE}"/*
SCRIPT

    chmod +x "${PRACTICE_DIR}/mount-practice-fs.sh"
    log_success "Persistence script created"
}

# Main execution
main() {
    log_info "LPIC-1 Practice Filesystems Setup"
    log_info "=================================="
    echo

    if [[ "$RESET" == true ]]; then
        cleanup_existing
    fi

    # Check if already set up
    if [[ -f "${LOOP_DIR}/ext4.img" ]] && losetup /dev/loop10 &>/dev/null; then
        log_warn "Practice filesystems appear to already exist."
        log_warn "Use --reset to recreate them."
        exit 0
    fi

    setup_directories
    create_loop_images
    setup_loop_devices
    create_filesystems
    setup_lvm
    mount_filesystems
    setup_quotas
    create_fstab_reference
    create_persistence_script

    echo
    log_success "=================================="
    log_success "Practice Filesystems Setup Complete"
    log_success "=================================="
    echo
    log_info "Summary:"
    echo "  - 5 loop filesystems (ext4, xfs, btrfs, vfat, quota)"
    echo "  - 3 LVM logical volumes"
    echo "  - Disk quotas enabled on /mnt/lpic1/quota-test"
    echo
    log_info "All mounted at: ${MOUNT_BASE}/"
    echo
    log_warn "Note: After reboot, run: sudo ${PRACTICE_DIR}/mount-practice-fs.sh"
}

main
