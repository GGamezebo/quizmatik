"""Transcode the real-gameplay takes to H.264 for the Remotion reel."""
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg

ROOT = Path(__file__).resolve().parents[2]
FF = imageio_ffmpeg.get_ffmpeg_exe()
OUT = ROOT / "tools" / "jet-math-spot" / "public" / "clips"
SRC = ROOT / "bin" / "trailer"

CLIPS = (
    "chase_l3",
    "boss_l5",
    "trophy_ru",
    "chase_l3_en",
    "boss_l5_en",
    "trophy_en",
)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    names = sys.argv[1:] or CLIPS
    for name in names:
        src = SRC / f"{name}.avi"
        if not src.exists():
            print("skip", src)
            continue
        dst = OUT / f"{name}.mp4"
        subprocess.run(
            [
                FF, "-y", "-i", str(src),
                "-c:v", "libx264", "-pix_fmt", "yuv420p",
                "-crf", "18", "-preset", "veryfast",
                "-c:a", "aac", "-b:a", "160k",
                "-movflags", "+faststart",
                str(dst),
            ],
            check=True,
        )
        print(dst, dst.stat().st_size)


if __name__ == "__main__":
    main()
