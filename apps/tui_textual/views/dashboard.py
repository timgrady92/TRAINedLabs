from __future__ import annotations

from datetime import datetime
from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Static

from ..services.paths import CORE_DIR, LPIC_CHECK
from ..services.progress import load_progress
from .messages import RunCommand, UpdateContext


class DashboardView(Vertical):
    def compose(self) -> ComposeResult:
        yield Static("Dashboard", classes="view-title")
        yield Static(self._summary_text(), id="progress-summary")
        with Horizontal(classes="button-row"):
            yield Button("Refresh", id="dash-refresh")
            yield Button("Verify Packages", id="dash-verify")
            yield Button("Self-Test", id="dash-selftest")
            yield Button("Export Progress", id="dash-export")

    def _summary_text(self) -> str:
        summary = load_progress()
        if summary.total == 0:
            return "Progress database not found or empty. Run setup to initialize progress tracking."
        return f"Progress: {summary.completed}/{summary.total} objectives ({summary.percent}%)."

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "dash-refresh":
            self.query_one("#progress-summary", Static).update(self._summary_text())
            self.post_message(UpdateContext("Dashboard refreshed."))
        elif event.button.id == "dash-verify":
            self.post_message(RunCommand([str(LPIC_CHECK), "verify-packages"], cwd=str(CORE_DIR)))
        elif event.button.id == "dash-selftest":
            self.post_message(RunCommand([str(LPIC_CHECK), "self-test"], cwd=str(CORE_DIR)))
        elif event.button.id == "dash-export":
            out = Path.home() / f"lpic1-progress-{datetime.now().strftime('%Y%m%d')}.json"
            self.post_message(RunCommand([str(LPIC_CHECK), "export", str(out)], cwd=str(CORE_DIR)))
            self.post_message(UpdateContext(f"Exporting progress to {out}"))
