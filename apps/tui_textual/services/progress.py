from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from pathlib import Path

from .paths import DB_FILE


@dataclass(frozen=True)
class ProgressSummary:
    completed: int
    total: int
    percent: int


def load_progress(db_path: Path = DB_FILE) -> ProgressSummary:
    if not db_path.exists():
        return ProgressSummary(0, 0, 0)
    try:
        with sqlite3.connect(str(db_path)) as conn:
            total = conn.execute("SELECT COUNT(*) FROM objectives").fetchone()[0]
            completed = conn.execute("SELECT COUNT(*) FROM objectives WHERE completed=1").fetchone()[0]
        percent = int(completed * 100 / total) if total else 0
        return ProgressSummary(completed, total, percent)
    except sqlite3.Error:
        return ProgressSummary(0, 0, 0)
