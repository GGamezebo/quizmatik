"""Record a trailer take with Godot Movie Maker (60 fps MJPEG AVI + audio).

    python tools/trailer/record.py battle bin/trailer/battle_en.avi --seed 7 --locale en
    python tools/trailer/record.py trophy bin/trailer/trophy_en.avi --locale en

Movie size = window size: a temporary `override.cfg` (window_*_override) is written to the project
root for the run and always removed. `project.godot` is never touched.
Godot binary: env GODOT, else the console exe next to the editor, else `godot_console` on PATH.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
TAKES = {"battle": HERE / "battle_autopilot.gd", "trophy": HERE / "trophy_room.gd"}
DEFAULT_GODOT = Path("D:/Godot/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe")


def godot_exe() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    if DEFAULT_GODOT.exists():
        return str(DEFAULT_GODOT)
    found = shutil.which("godot_console") or shutil.which("godot")
    if not found:
        sys.exit("Godot not found: set env GODOT to the console exe")
    return found


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser()
    p.add_argument("take", choices=TAKES)
    p.add_argument("out", help="output .avi (put work files under bin/trailer/)")
    p.add_argument("--size", default="1920x1080")
    p.add_argument("--fps", type=int, default=60)
    p.add_argument("--seed", type=int, default=7)
    p.add_argument("--locale", default="ru")
    p.add_argument("--valley", default="multiplication", help="addition|subtraction|multiplication|division|mix")
    p.add_argument("--plane", default="gold", help="PlaneCatalog id: starter|fast|green|red|gold")
    p.add_argument("--paint", default="paint_stars")
    p.add_argument("--trail", default="trail_rainbow")
    p.add_argument("--shot", default="shot_rainbow")
    p.add_argument("--battle", default="", help='JSON GameConfig overrides, e.g. {"questions_count":5}')
    p.add_argument("--tap-at", default="", help="trophy: seconds before the finger taps")
    p.add_argument("--end-at", default="", help="trophy: take length in seconds")
    a = p.parse_args()

    out = Path(a.out)
    if not out.is_absolute():
        out = ROOT / out
    out.parent.mkdir(parents=True, exist_ok=True)
    gdignore = ROOT / "bin" / "trailer" / ".gdignore"
    if out.is_relative_to(ROOT / "bin" / "trailer") and not gdignore.exists():
        gdignore.touch()  # Godot must not import work PNGs/AVIs

    if a.battle:
        json.loads(a.battle)  # fail early on bad JSON
    env = dict(os.environ)
    env.update({
        "TRAILER_SEED": str(a.seed), "TRAILER_LOCALE": a.locale, "TRAILER_VALLEY": a.valley,
        "TRAILER_PLANE": a.plane, "TRAILER_PAINT": a.paint, "TRAILER_TRAIL": a.trail,
        "TRAILER_SHOT": a.shot, "TRAILER_BATTLE": a.battle,
        "TRAILER_TAP_AT": a.tap_at, "TRAILER_END_AT": a.end_at,
    })
    w, h = a.size.lower().split("x")
    override = ROOT / "override.cfg"
    if override.exists():
        sys.exit("override.cfg already exists in the project root — not overwriting it")
    override.write_text(
        f"[display]\n\nwindow/size/window_width_override={w}\nwindow/size/window_height_override={h}\n",
        encoding="utf-8")
    try:
        cmd = [godot_exe(), "--path", str(ROOT), "--script", str(TAKES[a.take]),
               "--write-movie", str(out), "--fixed-fps", str(a.fps)]
        res = subprocess.run(cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace")
    finally:
        override.unlink(missing_ok=True)
    log = res.stdout + res.stderr
    for line in log.splitlines():
        if "SCRIPT ERROR" in line or "recording movie" in line or "frames at" in line:
            print(line)
    if res.returncode != 0 or not out.exists():
        print(log[-3000:])
        sys.exit(f"recording failed ({res.returncode})")


if __name__ == "__main__":
    main()
