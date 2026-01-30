from __future__ import annotations

from textual.message import Message


class RunCommand(Message):
    def __init__(self, cmd: list[str], cwd: str | None = None) -> None:
        super().__init__()
        self.cmd = cmd
        self.cwd = cwd


class UpdateContext(Message):
    def __init__(self, text: str) -> None:
        super().__init__()
        self.text = text
