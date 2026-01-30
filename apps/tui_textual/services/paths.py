from __future__ import annotations

import os
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
CORE_DIR = REPO_ROOT / "core"
TRAINING_DIR = CORE_DIR / "training"
LESSONS_DIR = TRAINING_DIR / "lessons"
EXERCISES_DIR = TRAINING_DIR / "exercises"
SCENARIOS_DIR = REPO_ROOT / "content" / "scenarios"

LPIC_DIR = Path(os.environ.get("LPIC_DIR", "/opt/LPIC-1/data"))
DB_FILE = LPIC_DIR / "progress.db"

LPIC_CHECK = CORE_DIR / "lpic-check"
LPIC_TRAIN = CORE_DIR / "lpic-train"
SKILL_CHECKER = CORE_DIR / "skill-checker.sh"
INIT_PROGRESS = CORE_DIR / "init-progress.sh"
