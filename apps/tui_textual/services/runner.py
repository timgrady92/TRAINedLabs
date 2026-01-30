from __future__ import annotations

import os
import pty
import subprocess
import threading
from dataclasses import dataclass
from typing import Callable, Optional, Sequence


@dataclass
class CommandResult:
    exit_code: int
    stdout: str


class PtyRunner:
    def __init__(
        self,
        on_output: Callable[[str], None],
        on_exit: Callable[[int], None],
    ) -> None:
        self._on_output = on_output
        self._on_exit = on_exit
        self._process: Optional[subprocess.Popen[bytes]] = None
        self._master_fd: Optional[int] = None
        self._reader: Optional[threading.Thread] = None

    @property
    def running(self) -> bool:
        return self._process is not None and self._process.poll() is None

    def start(self, cmd: Sequence[str], cwd: Optional[str] = None, env: Optional[dict] = None) -> None:
        self.stop()
        master_fd, slave_fd = pty.openpty()
        self._process = subprocess.Popen(
            list(cmd),
            stdin=slave_fd,
            stdout=slave_fd,
            stderr=slave_fd,
            cwd=cwd,
            env=env,
            close_fds=True,
        )
        os.close(slave_fd)
        self._master_fd = master_fd
        self._reader = threading.Thread(target=self._read_loop, daemon=True)
        self._reader.start()

    def send(self, data: str) -> None:
        if self._master_fd is None or not self.running:
            return
        os.write(self._master_fd, data.encode())

    def stop(self) -> None:
        if self._process and self._process.poll() is None:
            self._process.terminate()
        if self._master_fd is not None:
            try:
                os.close(self._master_fd)
            except OSError:
                pass
        self._process = None
        self._master_fd = None

    def _read_loop(self) -> None:
        if self._master_fd is None or self._process is None:
            return
        while True:
            try:
                data = os.read(self._master_fd, 4096)
            except OSError:
                break
            if not data:
                break
            text = data.decode(errors="replace")
            self._on_output(text)
        exit_code = self._process.poll()
        self._on_exit(exit_code if exit_code is not None else 0)
