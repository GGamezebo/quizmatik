"""One English chase-on-space frame. Restores override.cfg. Does not touch other screenshots."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
DEFAULT_GODOT = Path("D:/Godot/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe")


def godot_exe() -> str:
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    if DEFAULT_GODOT.exists():
        return str(DEFAULT_GODOT)
    found = shutil.which("godot_console") or shutil.which("godot")
    if not found:
        sys.exit("Godot not found")
    return found


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    override = ROOT / "override.cfg"
    previous = override.read_text(encoding="utf-8") if override.exists() else None
    override.write_text(
        "[application]\n\n"
        'config/custom_user_dir_name="quizmatic_labtest"\n\n'
        "[display]\n\n"
        "window/size/window_width_override=1920\n"
        "window/size/window_height_override=1080\n"
        "window/size/borderless=true\n"
        "window/dpi/allow_hidpi=false\n",
        encoding="utf-8",
    )
    try:
        cmd = [
            godot_exe(), "--path", str(ROOT), "--script", str(HERE / "chase_en.gd"),
            "--fixed-fps", "60",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        log = res.stdout + res.stderr
        for line in log.splitlines():
            if any(key in line for key in ("SHOT ", "QUESTION ", "POSE ", "SCRIPT ERROR", "Parse Error", "ERROR")):
                print(line)
        if res.returncode != 0:
            print(log[-5000:])
            sys.exit(f"chase capture failed ({res.returncode})")
    finally:
        if previous is None:
            override.unlink(missing_ok=True)
        else:
            override.write_text(previous, encoding="utf-8")


if __name__ == "__main__":
    main()
