# LPIC-1 Enterprise TUI (Textual)

Offline-first terminal UI for LPIC-1 training. Integrates existing training
scripts (`lpic-train`, `lpic-check`, `skill-checker.sh`) into a single-pane
application with a built-in console.

## Run

```bash
cd apps/tui_textual
./run.sh
```

## Notes

- Requires Python 3 and the `textual` package (see `requirements.txt`).
- Uses a pseudo-terminal to run interactive scripts within the console panel.
- Progress DB path defaults to `/opt/LPIC-1/data/progress.db` or `LPIC_DIR`.
