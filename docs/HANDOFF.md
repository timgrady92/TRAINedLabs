# Deployment Handoff (LPIC-1 Training Platform)

## Purpose
Provide a production-ready, offline-first LPIC-1 training platform for hospital environments with a modern Textual terminal UI and a single-step installer.

## Repo Layout
- `apps/` Textual UI application (`apps/tui_textual/`)
- `core/` Training engine (validators, lessons, exercises, progress)
- `content/` VM setup, practice filesystems, scenarios, MOTD
- `ops/` Deployment tooling (`setup.sh`, `uninstall.sh`, `smoke-test.sh`)
- `bin/` Main launcher (`lpic1`)
- `docs/` Operational and technical documentation

## Single-Step Deployment (Ubuntu/Debian or Fedora/RHEL)
```bash
sudo ./ops/setup.sh
sudo reboot
```
After reboot: log in as `student` (default password `training123`), run `lpic1`.

### Custom user and password
```bash
sudo ./ops/setup.sh --user trainee --password SecurePass123
```

### Verification only
```bash
sudo ./ops/setup.sh --verify
```

## Post-Install Checks
```bash
/opt/LPIC-1/content/environment/verify-installation.sh
/opt/LPIC-1/ops/smoke-test.sh
```

## Offline Considerations
- All training content is local in `/opt/LPIC-1`.
- The only external dependency is the Python package `textual` installed via pip.
- For fully offline sites, pre-stage a wheelhouse and install Textual from local media before running setup.

## Core Commands
- `lpic1` launch the Textual UI
- `lpic1 learn <topic>` run lesson
- `lpic1 practice <topic>` run exercises
- `lpic1 test <topic>` run assessment
- `lpic1 exam` run exam simulation

## Support Paths
- Logs: `/var/log/lpic1-install.log`
- Data: `/opt/LPIC-1/data/`
- Practice: `/opt/LPIC-1/practice/`
- Scenarios: `/opt/LPIC-1/content/scenarios/`
