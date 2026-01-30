from __future__ import annotations

from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import ContentSwitcher, Footer, Header, ListItem, ListView, Static, TextLog

from .services.paths import CORE_DIR
from .views import (
    ChallengesView,
    DashboardView,
    ExamView,
    LearnView,
    PracticeView,
    SandboxView,
    SettingsView,
    TestView,
)
from .views.messages import RunCommand, UpdateContext
from .widgets import CommandConsole


NAV_ITEMS = [
    ("dashboard", "Dashboard"),
    ("learn", "Learn"),
    ("practice", "Practice"),
    ("test", "Test"),
    ("exam", "Exam"),
    ("challenges", "Challenges"),
    ("sandbox", "Sandbox"),
    ("settings", "Settings"),
]


class LpicEnterpriseApp(App):
    CSS_PATH = "styles.css"
    BINDINGS = [
        ("q", "quit", "Quit"),
        ("r", "refresh", "Refresh"),
        ("f1", "help", "Help"),
    ]

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="body"):
            with Vertical(id="nav"):
                yield Static("LPIC-1", classes="panel-title")
                nav = ListView(id="nav-list")
                for key, label in NAV_ITEMS:
                    nav.append(ListItem(Static(label), id=key))
                yield nav
            with Vertical(id="main"):
                switcher = ContentSwitcher(id="content")
                switcher.add_child(DashboardView(id="dashboard"))
                switcher.add_child(LearnView(id="learn"))
                switcher.add_child(PracticeView(id="practice"))
                switcher.add_child(TestView(id="test"))
                switcher.add_child(ExamView(id="exam"))
                switcher.add_child(ChallengesView(id="challenges"))
                switcher.add_child(SandboxView(id="sandbox"))
                switcher.add_child(SettingsView(id="settings"))
                yield switcher
                yield CommandConsole(id="console")
            with Vertical(id="context"):
                yield Static("Context", classes="panel-title")
                yield Static("Ready.", id="context-info")
                yield Static("Activity", classes="panel-title")
                yield TextLog(id="activity-log", wrap=True)
        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#content", ContentSwitcher).current = "dashboard"
        self.query_one("#nav-list", ListView).index = 0
        self.query_one("#activity-log", TextLog).write("App started.")

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        if event.list_view.id != "nav-list":
            return
        if event.item is None:
            return
        view_id = event.item.id
        self.query_one("#content", ContentSwitcher).current = view_id
        self.query_one("#context-info", Static).update(f"View: {view_id}")
        self.query_one("#activity-log", TextLog).write(f"Switched to {view_id}.")

    def on_run_command(self, message: RunCommand) -> None:
        console = self.query_one(CommandConsole)
        console.run(message.cmd, cwd=message.cwd or str(CORE_DIR))
        self.query_one("#activity-log", TextLog).write(f"Running: {' '.join(message.cmd)}")

    def on_update_context(self, message: UpdateContext) -> None:
        self.query_one("#context-info", Static).update(message.text)
        self.query_one("#activity-log", TextLog).write(message.text)

    def action_refresh(self) -> None:
        self.query_one("#activity-log", TextLog).write("Refreshed.")

    def action_help(self) -> None:
        self.query_one("#context-info", Static).update(
            "Help: Use the left nav to switch views. Console accepts input for running commands."
        )


if __name__ == "__main__":
    LpicEnterpriseApp().run()
