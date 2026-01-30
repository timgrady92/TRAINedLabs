from __future__ import annotations

from typing import Optional

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, ListItem, ListView, Static

from ..services.content import load_topics
from ..services.paths import CORE_DIR, LPIC_TRAIN
from .messages import RunCommand, UpdateContext


class SandboxView(Vertical):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self._selected: Optional[str] = None

    def compose(self) -> ComposeResult:
        yield Static("Sandbox", classes="view-title")
        yield Static("Free experimentation with practice files.", classes="view-subtitle")
        topics = load_topics()
        list_view = ListView(id="sandbox-topics")
        for topic in topics:
            list_view.append(ListItem(Static(f"{topic.key} - {topic.description}"), id=topic.key))
        yield list_view
        with Horizontal(classes="button-row"):
            yield Button("Open Sandbox", id="sandbox-start")
            yield Button("Open Global Sandbox", id="sandbox-all")

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.item is None:
            return
        self._selected = event.item.id
        self.post_message(UpdateContext(f"Selected topic: {self._selected}"))

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "sandbox-all":
            self.post_message(RunCommand([str(LPIC_TRAIN), "sandbox"], cwd=str(CORE_DIR)))
            return
        if event.button.id == "sandbox-start" and self._selected:
            self.post_message(RunCommand([str(LPIC_TRAIN), "sandbox", self._selected], cwd=str(CORE_DIR)))
            return
        self.post_message(UpdateContext("Select a topic first."))
