from __future__ import annotations

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Static

from ..services.paths import CORE_DIR, INIT_PROGRESS, LPIC_CHECK
from .messages import RunCommand, UpdateContext


class SettingsView(Vertical):
    def compose(self) -> ComposeResult:
        yield Static("Settings", classes="view-title")
        yield Static("Environment and maintenance.", classes="view-subtitle")
        with Horizontal(classes="button-row"):
            yield Button("Init Progress DB", id="settings-init")
            yield Button("Verify Packages", id="settings-verify")
            yield Button("Self-Test", id="settings-selftest")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "settings-init":
            self.post_message(RunCommand(["bash", str(INIT_PROGRESS)], cwd=str(CORE_DIR)))
            self.post_message(UpdateContext("Initializing progress database."))
        elif event.button.id == "settings-verify":
            self.post_message(RunCommand([str(LPIC_CHECK), "verify-packages"], cwd=str(CORE_DIR)))
        elif event.button.id == "settings-selftest":
            self.post_message(RunCommand([str(LPIC_CHECK), "self-test"], cwd=str(CORE_DIR)))
