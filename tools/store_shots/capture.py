"""Capture Google Play phone screenshots (1920x1080, 24-bit PNG) in every game language.

    python tools/store_shots/capture.py
    python tools/store_shots/capture.py --locales en,de

One Godot run walks the real menu and a scripted battle. Sample progress stays in memory.
Practice settings on disk are restored afterwards (opening the practice window rewrites them).
"""
import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
DEFAULT_GODOT = Path("D:/Godot/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe")
LOCALES = ["ru", "en", "tr", "es", "pt", "de", "fr", "it", "pl", "uk", "id", "nl"]
PRACTICE_FILES = ("training_settings.json", "training_ui_presets.json")


def godot_exe() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    if DEFAULT_GODOT.exists():
        return str(DEFAULT_GODOT)
    found = shutil.which("godot_console") or shutil.which("godot")
    if not found:
        sys.exit("Godot not found: set env GODOT to the console exe")
    return found


def user_dir() -> Path:
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        sys.exit("APPDATA is not set; cannot protect practice settings")
    return Path(appdata) / "Godot" / "app_userdata" / "quizmatic"


SHOTS = (
    "01_battle.png", "02_boss.png", "03_menu.png", "04_valleys.png",
    "05_levels.png", "06_practice.png", "07_trophies.png", "08_hangar.png",
)
TARGET = (1920, 1080)


def _fit_pngs(out: Path, locales: list[str], started: float) -> None:
    """Play listing size. Borderless capture is 16:9 but often 1.5× because of DPI."""
    from PIL import Image

    missing: list[str] = []
    for code in locales:
        folder = out / code
        for name in SHOTS:
            path = folder / name
            if not path.exists() or path.stat().st_mtime < started:
                missing.append(f"{code}/{name}")
                continue
            with Image.open(path) as image:
                rgb = image.convert("RGB")
                if rgb.size != TARGET:
                    rgb = rgb.resize(TARGET, Image.Resampling.LANCZOS)
                    print(f"SHOT fit {code}/{name} {image.size[0]}x{image.size[1]} -> 1920x1080")
                rgb.save(path, "PNG")
    if missing:
        sys.exit("capture missing shots: " + ", ".join(missing))
    _drop_old_shots(out, locales)


def _drop_old_shots(out: Path, locales: list[str]) -> None:
    """Numbered leftovers from the previous store set must not sit next to the Play upload."""
    keep = set(SHOTS) | {"00_promo.png"}
    for code in locales:
        folder = out / code
        if not folder.is_dir():
            continue
        for path in folder.glob("*.png"):
            if path.name not in keep:
                path.unlink()
                print(f"SHOT drop {code}/{path.name}")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser()
    parser.add_argument("--locales", default=",".join(LOCALES))
    parser.add_argument("--out", default="store/screenshots")
    args = parser.parse_args()
    locales = [code.strip() for code in args.locales.split(",") if code.strip()]
    unknown = [code for code in locales if code not in LOCALES]
    if unknown:
        sys.exit(f"unknown locale: {', '.join(unknown)}")

    out = Path(args.out)
    if not out.is_absolute():
        out = ROOT / out
    out.mkdir(parents=True, exist_ok=True)

    override = ROOT / "override.cfg"
    previous_override = override.read_text(encoding="utf-8") if override.exists() else None
    override.write_text(
        "[display]\n\n"
        "window/size/window_width_override=1920\n"
        "window/size/window_height_override=1080\n"
        "window/size/borderless=true\n"
        "window/dpi/allow_hidpi=false\n",
        encoding="utf-8",
    )

    folder = user_dir()
    folder.mkdir(parents=True, exist_ok=True)
    backup = ROOT / "bin" / "store_shots_backup"
    backup.mkdir(parents=True, exist_ok=True)
    had: dict[str, bool] = {}
    for name in PRACTICE_FILES:
        src = folder / name
        had[name] = src.exists()
        if src.exists():
            shutil.copy2(src, backup / name)

    env = dict(os.environ)
    env["SHOT_DIR"] = str(out)
    env["SHOT_LOCALES"] = ",".join(locales)
    code = 1
    started = time.time()
    try:
        cmd = [godot_exe(), "--path", str(ROOT), "--script", str(HERE / "capture.gd"),
               "--fixed-fps", "60"]
        res = subprocess.run(cmd, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace")
        code = res.returncode
        log = res.stdout + res.stderr
        for line in log.splitlines():
            if any(key in line for key in ("SHOT ", "QUESTION ", "SCRIPT ERROR", "Parse Error")):
                print(line)
        if code != 0:
            print(log[-4000:])
            sys.exit(f"capture failed ({code})")
        _fit_pngs(out, locales, started)
    finally:
        if previous_override is None:
            override.unlink(missing_ok=True)
        else:
            override.write_text(previous_override, encoding="utf-8")
        for name in PRACTICE_FILES:
            src = folder / name
            if had[name]:
                shutil.copy2(backup / name, src)
            elif src.exists():
                src.unlink()
        shutil.rmtree(backup, ignore_errors=True)


if __name__ == "__main__":
    main()
