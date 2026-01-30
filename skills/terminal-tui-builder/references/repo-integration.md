# Repo integration map (LPIC-1 training)

Use this as the source of truth for where training content and validators live.

## Key paths

- Lessons: `core/training/lessons/`
- Exercises: `core/training/exercises/`
- Training helpers: `core/training/common.sh`, `core/training/learning-helpers.sh`
- Validators: `core/objectives/*.sh`
- Progress DB init: `core/init-progress.sh`
- Main checker: `core/lpic-check`
- Skill checker: `core/skill-checker.sh`
- Textual app: `apps/tui_textual/`

## Execution conventions

- Most scripts expect to run from their directory. Resolve paths with `SCRIPT_DIR` and call using absolute paths.
- Many scripts are bash and rely on `set -euo pipefail`. Surface non-zero exits as failures.
- Progress database path is usually `/opt/LPIC-1/data/progress.db` (from `core/training/common.sh`).

## Minimal integration strategy

1) Wrap the existing bash tools instead of rewriting their logic.
2) Collect stdout/stderr and display in a scrollable panel.
3) Parse status by exit code; do not scrape human text for logic.

## Useful commands

- Progress summary: `core/lpic-check progress`
- Verify packages: `core/lpic-check verify-packages`
- Objective check: `core/lpic-check objective <id>`
- Command practice: `core/lpic-check command <cmd>`
- Exam mode: `core/lpic-check exam-mode`

## Offline requirement

All tools and content in this repo are local. Do not add network calls.
