from __future__ import annotations

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.message import Message
from textual.reactive import reactive
from textual.widgets import Input, Static, TextLog

from .services.runner import PtyRunner


class ConsoleOutput(Message):
    def __init__(self, text: str) -> None:
        super().__init__()
        self.text = text


class ConsoleExit(Message):
    def __init__(self, code: int) -> None:
        super().__init__()
        self.code = code


class CommandConsole(Vertical):
    running = reactive(False)

    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self._runner = PtyRunner(self._handle_output, self._handle_exit)

    def compose(self) -> ComposeResult:
        yield Static("Console", classes="panel-title")
        yield TextLog(id="console-log", highlight=True, wrap=True)
        yield Input(placeholder="Type input for the running command and press Enter", id="console-input")

    def on_input_submitted(self, event: Input.Submitted) -> None:
        if not event.value:
            return
        self._runner.send(event.value + "\n")
        event.input.value = ""

    def run(self, cmd: list[str], cwd: str | None = None) -> None:
        log = self.query_one("#console-log", TextLog)
        log.clear()
        log.write(f"$ {' '.join(cmd)}")
        self.running = True
        self._runner.start(cmd, cwd=cwd)

    def stop(self) -> None:
        self._runner.stop()
        self.running = False

    def _handle_output(self, text: str) -> None:
        self.app.call_from_thread(self.post_message, ConsoleOutput(text))

    def _handle_exit(self, code: int) -> None:
        self.app.call_from_thread(self.post_message, ConsoleExit(code))

    def on_console_output(self, message: ConsoleOutput) -> None:
        log = self.query_one("#console-log", TextLog)
        log.write(message.text.rstrip("\n"))

    def on_console_exit(self, message: ConsoleExit) -> None:
        log = self.query_one("#console-log", TextLog)
        log.write(f"\n[process exited with code {message.code}]")
        self.running = False
