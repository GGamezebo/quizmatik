"""Record the Jet Math 30s ad takes (real gameplay). Music is muted; compose adds the bed.

    python tools/trailer/record_ad.py ru
    python tools/trailer/record_ad.py en
    python tools/trailer/record_ad.py ru hook
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECORD = ROOT / "tools" / "trailer" / "record.py"
OUT = ROOT / "bin" / "trailer"

HOOK = {
    "questions_count": 1,
    "allowed_operations": 4,
    "min_generate_number": 2,
    "max_generate_number": 9,
    "answer_speed": 190,
    "health": 3,
    "boss_chance": 0,
    "bonus_gold_chance": 0,
    "missing_operand_chance": 0,
    "review_chance": 1,
    "review_facts": {"mul:7:8": 8},
    "time_limit_sec": 0,
    "endless": False,
    "chase": False,
    "chase_chance": 0,
}
PLAY = {
    "questions_count": 6,
    "allowed_operations": 15,
    "min_generate_number": 2,
    "max_generate_number": 9,
    "answer_speed": 150,
    "health": 3,
    "boss_chance": 0,
    "bonus_gold_chance": 1,
    "missing_operand_chance": 0.55,
    "missing_operand_start_progress": 0,
    "review_chance": 1,
    "review_facts": {
        "add:7:8": 5, "add:9:6": 4, "add:5:8": 4,
        "mul:6:7": 5, "mul:4:8": 4, "mul:3:9": 4,
    },
    "time_limit_sec": 0,
    "endless": False,
    "chase": False,
    "chase_chance": 0,
}
BOSS = {
    "questions_count": 1,
    "allowed_operations": 1,
    "min_generate_number": 2,
    "max_generate_number": 8,
    "answer_speed": 200,
    "health": 3,
    "boss_chance": 1,
    "boss_armor": 2,
    "boss_armor_max": 0,
    "boss_rage_hits": 3,
    "boss_royal": False,
    "boss_royal_chance": 0,
    "bonus_gold_chance": 0,
    "missing_operand_chance": 0,
    "review_chance": 0,
    "time_limit_sec": 0,
    "endless": False,
    "chase": False,
    "chase_chance": 0,
}
ENDLESS = {
    "endless": True,
    "questions_count": 99,
    "allowed_operations": 15,
    "min_generate_number": 2,
    "max_generate_number": 9,
    "answer_speed": 180,
    "health": 3,
    "boss_chance": 0,
    "endless_boss_every_sec": 999,
    "bonus_gold_chance": 0,
    "missing_operand_chance": 0.35,
    "missing_operand_start_progress": 0,
    "time_limit_sec": 0,
    "chase": False,
    "chase_chance": 0,
}


def record(args: list[str]) -> None:
    print("RUN", " ".join(args[:3]), flush=True)
    subprocess.run([sys.executable, str(RECORD), *args], cwd=ROOT, check=True)


def _stash_override():
    """record.py refuses to start when override.cfg exists. Park the user's copy and put it back."""
    override = ROOT / "override.cfg"
    backup = ROOT / "override.cfg.userbackup"
    if not override.exists():
        return None
    backup.write_text(override.read_text(encoding="utf-8"), encoding="utf-8")
    override.unlink()
    return backup


def _restore_override(backup: Path | None) -> None:
    if backup is None or not backup.exists():
        return
    (ROOT / "override.cfg").write_text(backup.read_text(encoding="utf-8"), encoding="utf-8")
    backup.unlink()


# «Каждый ответ — в цвет»: one readable example per valley, a chase, a second 7×8 on a painted plane.
COLOR = {
    "add": {
        "valley": "addition", "plane": "fast", "paint": "paint_stars", "trail": "trail_rainbow", "shot": "shot_ink",
        "seed": 3, "max_sec": 9, "think": 0,
        "cfg": {
            "questions_count": 1, "allowed_operations": 1, "min_generate_number": 2, "max_generate_number": 9,
            "answer_speed": 210, "health": 3, "boss_chance": 0, "bonus_gold_chance": 0,
            "missing_operand_chance": 0, "review_chance": 1, "review_facts": {"add:8:7": 8},
            "time_limit_sec": 0, "endless": False, "chase": False, "chase_chance": 0,
        },
    },
    "sub": {
        "valley": "subtraction", "plane": "fast", "paint": "paint_none", "trail": "trail_pencil", "shot": "shot_hearts",
        "seed": 5, "max_sec": 9, "think": 0,
        "cfg": {
            "questions_count": 1, "allowed_operations": 2, "min_generate_number": 2, "max_generate_number": 20,
            "answer_speed": 210, "health": 3, "boss_chance": 0, "bonus_gold_chance": 0,
            "missing_operand_chance": 0, "review_chance": 1, "review_facts": {"add:6:8": 8},
            "time_limit_sec": 0, "endless": False, "chase": False, "chase_chance": 0,
        },
    },
    "div": {
        "valley": "division", "plane": "green", "paint": "paint_dots", "trail": "trail_colored", "shot": "shot_ink",
        "seed": 14, "max_sec": 9, "think": 0,
        "cfg": {
            "questions_count": 1, "allowed_operations": 8, "min_generate_number": 2, "max_generate_number": 9,
            "answer_speed": 210, "health": 3, "boss_chance": 0, "bonus_gold_chance": 0,
            "missing_operand_chance": 0, "review_chance": 1, "review_facts": {"mul:6:7": 8},
            "time_limit_sec": 0, "endless": False, "chase": False, "chase_chance": 0,
        },
    },
    "mix": {
        "valley": "mix", "plane": "gold", "paint": "paint_watercolor", "trail": "trail_confetti", "shot": "shot_gold",
        "seed": 11, "max_sec": 16, "think": 0,
        "cfg": {
            "questions_count": 4, "allowed_operations": 1, "min_generate_number": 2, "max_generate_number": 9,
            "answer_speed": 170, "health": 3, "boss_chance": 0, "bonus_gold_chance": 1,
            "missing_operand_chance": 1, "missing_operand_start_progress": 0,
            "review_chance": 1, "review_facts": {"add:3:4": 8},
            "time_limit_sec": 0, "endless": False, "chase": False, "chase_chance": 0,
        },
    },
}


def record_color(locale: str, which: str) -> None:
    """Takes for scenarios/color_ru.json. `which` is `color` or one take name."""
    tag = locale

    def battle(name, seed, valley, plane, paint, trail, shot, cfg, max_sec, think=0.0, think_at=0):
        if which not in (name, "color"):
            return
        args = [
            "battle", str(OUT / f"color_{name}_{tag}.avi"),
            "--seed", str(seed), "--locale", locale, "--valley", valley,
            "--plane", plane, "--paint", paint, "--trail", trail, "--shot", shot,
            "--max-sec", str(max_sec), "--mute-music",
            "--battle", json.dumps(cfg),
        ]
        if think > 0:
            args += ["--think", str(think), "--think-at", str(think_at)]
        record(args)

    battle("hook", 5, "multiplication", "fast", "paint_none", "trail_pencil", "shot_ink",
           {**HOOK, "answer_lines_count": 4}, 12, think=1.25)
    for name, spec in COLOR.items():
        battle(name, spec["seed"], spec["valley"], spec["plane"], spec["paint"], spec["trail"], spec["shot"],
               spec["cfg"], spec["max_sec"], spec["think"])
    battle("chase", 4, "multiplication", "fast", "paint_stars", "trail_rainbow", "shot_ink", {
        "chase": True, "chase_chance": 0, "chase_head_start": 1.05, "chase_answer_px": 500,
        "questions_count": 4, "boss_chance": 0, "allowed_operations": 1,
        "min_generate_number": 1, "max_generate_number": 9, "answer_speed": 170, "answer_lines_count": 4,
        "bonus_gold_chance": 0, "missing_operand_chance": 0, "review_chance": 0,
        "time_limit_sec": 0, "endless": False,
    }, 14, think=2.6)
    battle("boss", 7, "multiplication", "fast", "paint_none", "trail_pencil", "shot_ink", BOSS, 26)
    battle("bright", 6, "mix", "gold", "paint_rainbow", "trail_rainbow", "shot_rainbow",
           {**HOOK, "questions_count": 4, "answer_speed": 230, "answer_lines_count": 4}, 18)
    if which in ("looks", "color"):
        record(["looks", str(OUT / f"color_looks_{tag}.avi"), "--locale", locale, "--mute-music", "--max-sec", "14"])
    if which in ("boards", "color"):
        record(["boards", str(OUT / f"color_boards_{tag}.avi"), "--locale", locale, "--mute-music", "--max-sec", "20"])
    if which in ("trophy", "color"):
        record(["trophy", str(OUT / f"color_trophy_{tag}.avi"), "--locale", locale, "--tap-at", "2.2", "--end-at", "6.0"])


def main() -> None:
    locale = sys.argv[1] if len(sys.argv) > 1 else "ru"
    which = sys.argv[2] if len(sys.argv) > 2 else "all"
    if which == "color" or which in ("hook", "add", "sub", "div", "mix", "chase", "boss", "bright", "looks", "boards", "trophy") and "--color" in sys.argv:
        backup = _stash_override()
        try:
            record_color(locale, "color" if which == "color" else which)
        finally:
            _restore_override(backup)
        return
    tag = locale

    def battle(name, seed, valley, plane, paint, trail, shot, cfg, max_sec):
        if which not in (name, "all"):
            return
        record([
            "battle", str(OUT / f"ad_{name}_{tag}.avi"),
            "--seed", str(seed), "--locale", locale, "--valley", valley,
            "--plane", plane, "--paint", paint, "--trail", trail, "--shot", shot,
            "--max-sec", str(max_sec), "--mute-music",
            "--battle", json.dumps(cfg),
        ])

    battle("hook", 5, "multiplication", "fast", "paint_none", "trail_pencil", "shot_ink", HOOK, 12)
    battle("play", 8, "mix", "fast", "paint_watercolor", "trail_rainbow", "shot_rainbow", PLAY, 22)
    battle("playb", 13, "addition", "fast", "paint_stars", "trail_colored", "shot_hearts", PLAY, 22)
    battle("boss", 7, "subtraction", "fast", "paint_none", "trail_pencil", "shot_ink", BOSS, 26)
    battle("endless", 4, "division", "gold", "paint_stars", "trail_rainbow", "shot_gold", ENDLESS, 8)
    if which in ("looks", "all"):
        record(["looks", str(OUT / f"ad_looks_{tag}.avi"), "--locale", locale, "--mute-music", "--max-sec", "14"])
    if which in ("boards", "all"):
        record(["boards", str(OUT / f"ad_boards_{tag}.avi"), "--locale", locale, "--mute-music", "--max-sec", "20"])


if __name__ == "__main__":
    main()
