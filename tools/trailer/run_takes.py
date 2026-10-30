"""One-off recorder for the real-gameplay reel. Not part of the game."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECORD = ROOT / "tools" / "trailer" / "record.py"
OUT = ROOT / "bin" / "trailer"


def record(args: list[str]) -> None:
    cmd = [sys.executable, str(RECORD), *args]
    print("RUN", args[0], args[1], flush=True)
    subprocess.run(cmd, cwd=ROOT, check=True)


def main() -> None:
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    if which in ("chase", "all"):
        record([
            "battle", str(OUT / "chase_l3.avi"),
            "--seed", "4", "--locale", "ru", "--valley", "addition", "--plane", "fast",
            "--battle", json.dumps({
                "chase": True,
                "questions_count": 4,
                "boss_chance": 0,
                "allowed_operations": 1,
                "min_generate_number": 1,
                "max_generate_number": 9,
                "answer_speed": 130,
                "answer_lines_count": 4,
                "bonus_gold_chance": 0,
            }),
        ])
    if which in ("boss", "all"):
        record([
            "battle", str(OUT / "boss_l5.avi"),
            "--seed", "7", "--locale", "ru", "--valley", "addition", "--plane", "gold",
            "--battle", json.dumps({
                "chase": False,
                "questions_count": 2,
                "boss_chance": 1,
                "boss_armor": 3,
                "boss_rage_hits": 4,
                "boss_royal": False,
                "allowed_operations": 1,
                "min_generate_number": 1,
                "max_generate_number": 9,
                "answer_speed": 150,
                "answer_lines_count": 4,
                "bonus_gold_chance": 0,
            }),
        ])
    if which in ("trophy", "all"):
        record([
            "trophy", str(OUT / "trophy_ru.avi"),
            "--locale", "ru", "--tap-at", "2.4", "--end-at", "8.0",
        ])
    if which == "en":
        record([
            "battle", str(OUT / "chase_l3_en.avi"),
            "--seed", "4", "--locale", "en", "--valley", "addition", "--plane", "fast",
            "--battle", json.dumps({
                "chase": True,
                "questions_count": 4,
                "boss_chance": 0,
                "allowed_operations": 1,
                "min_generate_number": 1,
                "max_generate_number": 9,
                "answer_speed": 130,
                "answer_lines_count": 4,
                "bonus_gold_chance": 0,
            }),
        ])
        record([
            "battle", str(OUT / "boss_l5_en.avi"),
            "--seed", "7", "--locale", "en", "--valley", "addition", "--plane", "gold",
            "--battle", json.dumps({
                "chase": False,
                "questions_count": 2,
                "boss_chance": 1,
                "boss_armor": 3,
                "boss_rage_hits": 4,
                "boss_royal": False,
                "allowed_operations": 1,
                "min_generate_number": 1,
                "max_generate_number": 9,
                "answer_speed": 150,
                "answer_lines_count": 4,
                "bonus_gold_chance": 0,
            }),
        ])
        record([
            "trophy", str(OUT / "trophy_en.avi"),
            "--locale", "en", "--tap-at", "2.4", "--end-at", "8.0",
        ])


if __name__ == "__main__":
    main()
