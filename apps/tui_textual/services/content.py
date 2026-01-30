from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

from .paths import EXERCISES_DIR, LESSONS_DIR, LPIC_TRAIN


@dataclass(frozen=True)
class Topic:
    key: str
    description: str


def load_topics() -> List[Topic]:
    topics: Dict[str, str] = {}
    if LPIC_TRAIN.exists():
        content = LPIC_TRAIN.read_text(errors="ignore")
        for match in re.finditer(r"\[\"([a-z0-9_-]+)\"\]="\"([^\"]+)\"", content):
            topics[match.group(1)] = match.group(2)
    if not topics:
        for lesson in LESSONS_DIR.glob("*.sh"):
            key = lesson.stem
            topics[key] = key
    return [Topic(k, topics[k]) for k in sorted(topics.keys())]


def list_lessons() -> List[Path]:
    if not LESSONS_DIR.exists():
        return []
    return sorted(LESSONS_DIR.glob("*.sh"))


def list_exercises() -> List[Path]:
    if not EXERCISES_DIR.exists():
        return []
    return sorted(EXERCISES_DIR.glob("*.sh"))


def extract_lesson_summary(path: Path) -> Tuple[str, str]:
    title = path.stem
    desc = "Lesson file"
    try:
        for line in path.read_text(errors="ignore").splitlines():
            if line.startswith("# "):
                title = line.replace("#", "").strip()
                continue
            if line.startswith("# Objective"):
                desc = line.replace("#", "").strip()
                break
    except OSError:
        pass
    return title, desc
