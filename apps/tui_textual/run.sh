#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$(dirname "$SCRIPT_DIR"):${PYTHONPATH:-}"

python3 -m tui_textual.app
