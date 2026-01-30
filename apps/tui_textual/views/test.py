from __future__ import annotations

from typing import Optional

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Input, ListItem, ListView, Static

from ..services.content import load_topics
from ..services.paths import CORE_DIR, LPIC_CHECK, LPIC_TRAIN
from .messages import RunCommand, UpdateContext


class TestView(Vertical):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self._selected: Optional[str] = None

    def compose(self) -> ComposeResult:
        yield Static("Test", classes="view-title")
        yield Static("Assessment mode (no hints).", classes="view-subtitle")
        topics = load_topics()
        list_view = ListView(id="test-topics")
        for topic in topics:
            list_view.append(ListItem(Static(f"{topic.key} - {topic.description}"), id=topic.key))
        yield list_view
        yield Input(placeholder="Question count (default 5)", id="test-count")
        yield Input(placeholder="Objective ID (e.g., 103.1)", id="objective-id")
        yield Input(placeholder="Skill-checker command (e.g., grep, find)", id="skill-command")
        with Horizontal(classes="button-row"):
            yield Button("Run Test", id="test-start")
            yield Button("Timed Test", id="test-timed")
            yield Button("Check Objective", id="test-objective")
            yield Button("Skill Session", id="test-skill-session")
            yield Button("Practice Command", id="test-skill-practice")

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.item is None:
            return
        self._selected = event.item.id
        self.post_message(UpdateContext(f"Selected topic: {self._selected}"))

    def _count_args(self) -> list[str]:
        count = self.query_one("#test-count", Input).value.strip()
        if count.isdigit():
            return ["--count", count]
        return []

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "test-objective":
            objective = self.query_one("#objective-id", Input).value.strip()
            if objective:
                self.post_message(RunCommand([str(LPIC_CHECK), "objective", objective], cwd=str(CORE_DIR)))
            else:
                self.post_message(UpdateContext("Enter an objective ID."))
            return
        if event.button.id == "test-skill-session":
            cmd = self.query_one("#skill-command", Input).value.strip()
            args = [str(LPIC_CHECK.parent / "skill-checker.sh"), "session"]
            if cmd:
                args.append(cmd)
            args += self._count_args()
            self.post_message(RunCommand(args, cwd=str(CORE_DIR)))
            return
        if event.button.id == "test-skill-practice":
            cmd = self.query_one("#skill-command", Input).value.strip()
            if not cmd:
                self.post_message(UpdateContext("Enter a command for skill-checker practice."))
                return
            self.post_message(RunCommand([str(LPIC_CHECK.parent / "skill-checker.sh"), "practice", cmd], cwd=str(CORE_DIR)))
            return
        if not self._selected:
            self.post_message(UpdateContext("Select a topic first."))
            return
        if event.button.id == "test-start":
            cmd = [str(LPIC_TRAIN), "test", self._selected] + self._count_args()
            self.post_message(RunCommand(cmd, cwd=str(CORE_DIR)))
        elif event.button.id == "test-timed":
            cmd = [str(LPIC_TRAIN), "test", self._selected, "--timed"] + self._count_args()
            self.post_message(RunCommand(cmd, cwd=str(CORE_DIR)))
