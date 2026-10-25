"""Contact sheet of a take with timecodes — pick segment `from`/`to` and caption times from it.

    python tools/trailer/sheet.py bin/trailer/battle_en.avi            # 1 frame/s
    python tools/trailer/sheet.py bin/trailer/battle_en.avi --every 0.5 --start 16 --cols 4
"""
import argparse
import math
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser()
    p.add_argument("video")
    p.add_argument("--every", type=float, default=1.0, help="seconds between frames")
    p.add_argument("--start", type=float, default=0.0)
    p.add_argument("--length", type=float, default=0.0, help="0 = to the end")
    p.add_argument("--cols", type=int, default=6)
    p.add_argument("--width", type=int, default=400, help="tile width px")
    p.add_argument("--out", default="")
    a = p.parse_args()
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    src = Path(a.video) if Path(a.video).is_absolute() else ROOT / a.video
    probe = subprocess.run([ff, "-i", str(src)], capture_output=True, text=True, errors="replace").stderr
    dur_s = probe.split("Duration: ")[1].split(",")[0]
    h, m, s = dur_s.split(":")
    total = int(h) * 3600 + int(m) * 60 + float(s)
    span = (a.length or total - a.start)
    n = max(1, math.ceil(span / a.every))
    rows = math.ceil(n / a.cols)
    out = Path(a.out) if a.out else src.with_name(src.stem + "_sheet.png")
    font = str(ROOT / "assets/fonts/Nunito-Bold.ttf").replace("\\", "/").replace(":", r"\:")
    # Timecodes = position in the source take (offset by --start), i.e. what scenarios use.
    vf = (f"fps=1/{a.every},scale={a.width}:-1,"
          rf"drawtext=fontfile='{font}':text='%{{pts\:hms\:{a.start}}}':x=w-tw-6:y=6:fontsize={a.width // 14}:"
          f"fontcolor=red:box=1:boxcolor=white@0.8,tile={a.cols}x{rows}")
    args = [ff, "-v", "error", "-y", "-ss", str(a.start)]
    if a.length:
        args += ["-t", str(a.length)]
    subprocess.run(args + ["-i", str(src), "-vf", vf, "-frames:v", "1", str(out)], check=True)
    print(out)


if __name__ == "__main__":
    main()
