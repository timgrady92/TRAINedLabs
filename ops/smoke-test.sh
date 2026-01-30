#!/bin/bash
# LPIC-1 Training Platform - Smoke Test
# Verifies core commands, Textual availability, and init progress pathing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -d "/opt/LPIC-1/core" ]]; then
    ROOT_DIR="/opt/LPIC-1"
fi

CORE_DIR="${ROOT_DIR}/core"
APPS_DIR="${ROOT_DIR}/apps/tui_textual"
BIN_DIR="${ROOT_DIR}/bin"
CONTENT_DIR="${ROOT_DIR}/content"

fail() { echo "[FAIL] $1"; exit 1; }
pass() { echo "[OK] $1"; }

[[ -d "$CORE_DIR" ]] || fail "core directory missing"
[[ -d "$APPS_DIR" ]] || fail "apps/tui_textual missing"
[[ -x "$BIN_DIR/lpic1" ]] || fail "bin/lpic1 missing or not executable"
[[ -x "$CORE_DIR/lpic-check" ]] || fail "core/lpic-check missing"
[[ -x "$CORE_DIR/lpic-train" ]] || fail "core/lpic-train missing"

python3 -c "import textual" &>/dev/null || fail "python3 or textual not available"
pass "textual import"

"$CORE_DIR/lpic-check" --help >/dev/null || fail "lpic-check help failed"
pass "lpic-check"

"$CORE_DIR/lpic-train" topics >/dev/null || fail "lpic-train topics failed"
pass "lpic-train topics"

# Run init-progress against temp dir to validate schema creation
TMP_DIR="/tmp/lpic1-smoke"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
LPIC_DIR="$TMP_DIR" "$CORE_DIR/init-progress.sh" >/dev/null || fail "init-progress.sh failed"
[[ -f "$TMP_DIR/progress.db" ]] || fail "progress.db not created"
pass "init-progress"

rm -rf "$TMP_DIR"

# Optional: verify environment scripts exist
[[ -f "$CONTENT_DIR/environment/verify-installation.sh" ]] && pass "verify-installation.sh present"

pass "smoke test complete"
