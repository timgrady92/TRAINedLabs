from __future__ import annotations

from pathlib import Path
from typing import List, Tuple

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Button, ListItem, ListView, Static

from ..services.paths import SCENARIOS_DIR
from .messages import RunCommand, UpdateContext


def _scenario_items() -> List[Tuple[str, Path]]:
    items: List[Tuple[str, Path]] = []
    for folder in ("break-fix", "build"):
        base = SCENARIOS_DIR / folder
        if not base.exists():
            continue
        for script in sorted(base.glob("*.sh")):
            key = f"{folder}:{script.stem}"
            items.append((key, script))
    return items


class ChallengesView(Vertical):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self._selected: Path | None = None

    def compose(self) -> ComposeResult:
        yield Static("Challenges", classes="view-title")
        yield Static("Break/fix and build scenarios.", classes="view-subtitle")
        list_view = ListView(id="challenge-list")
        for key, script in _scenario_items():
            list_view.append(ListItem(Static(key), id=str(script)))
        yield list_view
        with Horizontal(classes="button-row"):
            yield Button("Launch Scenario", id="challenge-start")
            yield Button("Refresh", id="challenge-refresh")

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.item is None:
            return
        self._selected = Path(event.item.id)
        self.post_message(UpdateContext(f"Selected scenario: {self._selected.name}"))

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "challenge-refresh":
            self.query_one("#challenge-list", ListView).clear()
            for key, script in _scenario_items():
                self.query_one("#challenge-list", ListView).append(ListItem(Static(key), id=str(script)))
            self.post_message(UpdateContext("Scenario list refreshed."))
            return
        if event.button.id == "challenge-start" and self._selected:
            self.post_message(RunCommand(["bash", str(self._selected)], cwd=str(self._selected.parent)))
            return
        self.post_message(UpdateContext("Select a scenario first."))
