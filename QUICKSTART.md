# Quickstart

Short, pragmatic setup to get the LPIC-1 training platform running on a fresh Linux VM.

## 1) Install

```bash
# From the repo root
sudo ./ops/setup.sh
sudo reboot
```

## 2) Start

```bash
# Log in as the training user (default: student / training123)
# Then launch the platform
lpic1
```

## 3) Verify (optional)

```bash
/opt/LPIC-1/content/environment/verify-installation.sh
/opt/LPIC-1/ops/smoke-test.sh
```

Notes:
- Works on Ubuntu/Debian and Fedora/RHEL.
- The UI uses Python Textual; the installer will attempt to install it.
