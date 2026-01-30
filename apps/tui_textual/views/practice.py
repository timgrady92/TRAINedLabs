from __future__ import annotations

from typing import Optional

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, Input, ListItem, ListView, Static

from ..services.content import load_topics
from ..services.paths import CORE_DIR, LPIC_TRAIN
from .messages import RunCommand, UpdateContext


class PracticeView(Vertical):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self._selected: Optional[str] = None

    def compose(self) -> ComposeResult:
        yield Static("Practice", classes="view-title")
        yield Static("Guided exercises with hints and scoring.", classes="view-subtitle")
        topics = load_topics()
        list_view = ListView(id="practice-topics")
        for topic in topics:
            list_view.append(ListItem(Static(f"{topic.key} - {topic.description}"), id=topic.key))
        yield list_view
        yield Input(placeholder="Question count (default 5)", id="practice-count")
        with Horizontal(classes="button-row"):
            yield Button("Practice", id="practice-start")
            yield Button("Drill", id="practice-drill")
            yield Button("Mixed", id="practice-mix")
            yield Button("Smart Review", id="practice-smart")

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.item is None:
            return
        self._selected = event.item.id
        self.post_message(UpdateContext(f"Selected topic: {self._selected}"))

    def _count_args(self) -> list[str]:
        count = self.query_one("#practice-count", Input).value.strip()
        if count.isdigit():
            return ["--count", count]
        return []

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "practice-smart":
            self.post_message(RunCommand([str(LPIC_TRAIN), "smart"], cwd=str(CORE_DIR)))
            return
        if event.button.id == "practice-mix":
            self.post_message(RunCommand([str(LPIC_TRAIN), "mix"], cwd=str(CORE_DIR)))
            return
        if not self._selected:
            self.post_message(UpdateContext("Select a topic first."))
            return
        if event.button.id == "practice-start":
            cmd = [str(LPIC_TRAIN), "practice", self._selected] + self._count_args()
            self.post_message(RunCommand(cmd, cwd=str(CORE_DIR)))
        elif event.button.id == "practice-drill":
            cmd = [str(LPIC_TRAIN), "drill", self._selected] + self._count_args()
            self.post_message(RunCommand(cmd, cwd=str(CORE_DIR)))
