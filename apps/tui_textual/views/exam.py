from __future__ import annotations

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Input, Static

from ..services.paths import CORE_DIR, LPIC_CHECK
from .messages import RunCommand, UpdateContext


class ExamView(Vertical):
    def compose(self) -> ComposeResult:
        yield Static("Exam", classes="view-title")
        yield Static("Timed LPIC-1 simulation.", classes="view-subtitle")
        yield Input(placeholder="Exam number (e.g., 101 or 102)", id="exam-number")
        yield Input(placeholder="Time limit minutes (default 60)", id="exam-time")
        yield Input(placeholder="Objective count (default 10)", id="exam-count")
        with Horizontal(classes="button-row"):
            yield Button("Start Exam", id="exam-start")
            yield Button("Exam History", id="exam-history")
            yield Button("Exam Tips", id="exam-tips")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "exam-history":
            self.post_message(RunCommand([str(LPIC_CHECK), "exam-mode", "--history"], cwd=str(CORE_DIR)))
            return
        if event.button.id == "exam-tips":
            self.post_message(RunCommand([str(LPIC_CHECK), "exam-mode", "--tips"], cwd=str(CORE_DIR)))
            return
        if event.button.id == "exam-start":
            args = [str(LPIC_CHECK), "exam-mode"]
            exam = self.query_one("#exam-number", Input).value.strip()
            time_limit = self.query_one("#exam-time", Input).value.strip()
            count = self.query_one("#exam-count", Input).value.strip()
            if exam:
                args += ["--exam", exam]
            if time_limit.isdigit():
                args += ["--time", time_limit]
            if count.isdigit():
                args += ["--count", count]
            self.post_message(RunCommand(args, cwd=str(CORE_DIR)))
            self.post_message(UpdateContext("Exam started."))
