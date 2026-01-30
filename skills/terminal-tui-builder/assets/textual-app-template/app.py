from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, Static, Button, Input


class TrainingApp(App):
    CSS_PATH = "app.css"
    BINDINGS = [
        ("q", "quit", "Quit"),
        ("f1", "help", "Help"),
    ]

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal(id="body"):
            with Vertical(id="nav"):
                yield Static("Modes", classes="panel-title")
                yield Button("Dashboard", id="nav-dashboard")
                yield Button("Learn", id="nav-learn")
                yield Button("Practice", id="nav-practice")
                yield Button("Test", id="nav-test")
                yield Button("Exam", id="nav-exam")
            with Vertical(id="main"):
                yield Static("Welcome to LPIC-1 Training", id="main-title")
                yield Static("Select a mode to begin.", id="main-content")
                yield Input(placeholder="Type a command to practice...", id="command-input")
            with Vertical(id="context"):
                yield Static("Context", classes="panel-title")
                yield Static("Hints, objectives, and status appear here.", id="context-body")
        yield Static("Status: Ready", id="status")
        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        content = self.query_one("#main-content", Static)
        context = self.query_one("#context-body", Static)
        button_id = event.button.id or ""
        if button_id.startswith("nav-"):
            label = button_id.replace("nav-", "").capitalize()
            content.update(f"{label} view loaded.")
            context.update(f"Current mode: {label}")

    def action_help(self) -> None:
        content = self.query_one("#main-content", Static)
        content.update("Help: Use the left menu to switch modes. Press q to quit.")


if __name__ == "__main__":
    TrainingApp().run()
