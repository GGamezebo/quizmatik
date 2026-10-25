"""Assemble a trailer MP4 from recorded takes + a JSON scenario (see tools/trailer/scenarios/).

    python tools/trailer/compose.py tools/trailer/scenarios/parents_en.json

Segments play in order with crossfades; captions are rendered with the game fonts (Nunito Bold,
Rubik Doodle Shadow) and faded in/out. ffmpeg comes from the `imageio-ffmpeg` package.
Scenario schema — see `.claude/skills/trailer/SKILL.md`.
"""
import json
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"
BODY_FONT = FONTS / "Nunito-Bold.ttf"
TITLE_FONT = FONTS / "RubikDoodleShadow-Regular.ttf"
COLORS = {
    "ink": (30, 42, 60, 255), "orange": (214, 120, 40, 255), "grey": (90, 100, 120, 255),
    "white": (255, 255, 255, 255), "cream": (255, 250, 236, 240),
}
CAPTION_FADE = 0.3


def color(c):
    return tuple(c) if isinstance(c, list) else COLORS[c]


class Canvas:
    """Transparent full-frame layer; coordinates authored for 1080p and scaled to `size`."""

    def __init__(self, size):
        self.w, self.h = size
        self.k = self.h / 1080.0
        self.img = Image.new("RGBA", size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def font(self, path, px):
        return ImageFont.truetype(str(path), max(8, int(px * self.k)))

    def title(self, text, cy, px=190):
        f = self.font(TITLE_FONT, px)
        size = f.size
        w = self.d.textlength(text, font=f)
        self.d.text(((self.w - w) / 2, cy * self.k - size * 0.62), text, font=f, fill=COLORS["white"],
                    stroke_width=int(size * 0.09), stroke_fill=COLORS["ink"])

    def text(self, text, cy, px, fill="ink"):
        f = self.font(BODY_FONT, px)
        w = self.d.textlength(text, font=f)
        self.d.text(((self.w - w) / 2, cy * self.k - f.size / 2), text, font=f, fill=color(fill))

    def pill(self, lines, cy, px=56, accent_first=False):
        f = self.font(BODY_FONT, px)
        lh = int(f.size * 1.22)
        ws = [self.d.textlength(t, font=f) for t in lines]
        bw, bh = max(ws) + 90 * self.k, lh * len(lines) + 44 * self.k
        x0, y0 = (self.w - bw) / 2, cy * self.k - bh / 2
        self.d.rounded_rectangle((x0, y0, x0 + bw, y0 + bh), radius=int(34 * self.k), fill=COLORS["cream"],
                                 outline=COLORS["ink"], width=max(2, int(5 * self.k)))
        for i, t in enumerate(lines):
            fill = COLORS["orange"] if accent_first and i == 0 else COLORS["ink"]
            self.d.text(((self.w - ws[i]) / 2, y0 + 22 * self.k + i * lh), t, font=f, fill=fill)

    def card(self, box):
        x0, y0, x1, y1 = [v * self.k for v in box]
        self.d.rounded_rectangle((x0, y0, x1, y1), radius=int(60 * self.k), fill=(255, 250, 236, 228),
                                 outline=COLORS["ink"], width=max(2, int(6 * self.k)))

    def shadowed(self):
        a = self.img.split()[3].filter(ImageFilter.GaussianBlur(12 * self.k))
        sh = Image.new("RGBA", self.img.size, (20, 30, 45, 0))
        sh.putalpha(a.point(lambda v: int(v * 0.4)))
        out = Image.new("RGBA", self.img.size, (0, 0, 0, 0))
        out.alpha_composite(sh, (0, int(7 * self.k)))
        out.alpha_composite(self.img)
        return out


POS = {"bottom": 985, "bottom_low": 1022, "top": 105, "center": 540}


def render_caption(cap, size, path):
    c = Canvas(size)
    kind = cap.get("kind", "pill")
    if kind == "pill":
        lines = cap["text"] if isinstance(cap["text"], list) else [cap["text"]]
        y = cap.get("y", POS[cap.get("pos", "bottom")])
        c.pill(lines, y, cap.get("px", 54))
    elif kind == "title":  # big doodle title + optional pill under it (hook)
        y = cap.get("y", 700)
        c.title(cap["title"], y, cap.get("px", 190))
        if cap.get("sub"):
            c.pill([cap["sub"]], y + 200, cap.get("sub_px", 60))
    elif kind == "panel":  # cream card with title + lines over the video (outro)
        c.card(cap.get("box", [300, 250, 1620, 780]))
        c.title(cap["title"], cap.get("y", 400), cap.get("px", 170))
        for i, ln in enumerate(cap.get("lines", [])):
            c.text(ln["text"], ln.get("y", 600 + i * 90), ln.get("px", 60), ln.get("color", "ink"))
    else:
        sys.exit(f"unknown caption kind {kind}")
    c.shadowed().save(path)


def render_card(card, size, path):
    w, h = size
    bg = Image.open(ROOT / card["bg"]).convert("RGBA")
    s = max(w / bg.width, h / bg.height)
    bg = bg.resize((int(bg.width * s) + 2, int(bg.height * s) + 2), Image.LANCZOS)
    left, top = (bg.width - w) // 2, (bg.height - h) // 2
    bg = bg.crop((left, top, left + w, top + h)).filter(ImageFilter.GaussianBlur(card.get("blur", 3)))
    c = Canvas(size)
    c.card(card.get("box", [260, 190, 1660, 890]))
    c.title(card["title"], card.get("y", 380), card.get("px", 190))
    for i, ln in enumerate(card.get("lines", [])):
        c.text(ln["text"], ln.get("y", 560 + i * 100), ln.get("px", 60), ln.get("color", "ink"))
    bg.alpha_composite(c.shadowed())
    bg.convert("RGB").save(path)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sc_path = Path(sys.argv[1])
    sc = json.loads(sc_path.read_text(encoding="utf-8"))
    size = tuple(sc.get("size", [1920, 1080]))
    fps = sc.get("fps", 60)
    X = sc.get("xfade", 0.35)
    work = ROOT / sc.get("work", "bin/trailer") / sc_path.stem
    work.mkdir(parents=True, exist_ok=True)
    (ROOT / "bin" / "trailer" / ".gdignore").touch()
    segs = sc["segments"]

    inputs, fc = [], []

    def add_input(*args):
        inputs.extend(args)
        return len([a for a in inputs if a == "-i"]) - 1

    durs = []
    for i, seg in enumerate(segs):
        if "card" in seg:
            dur = seg["dur"]
            png = work / f"card_{i}.png"
            render_card(seg["card"], size, png)
            idx = add_input("-loop", "1", "-t", str(dur), "-i", str(png))
            frames = int(dur * fps)
            fc.append(f"[{idx}:v]scale={int(size[0] * 1.1)}:-1,zoompan=z='1.0+0.0004*on':x='iw/2-(iw/zoom/2)':"
                      f"y='ih/2-(ih/zoom/2)':d={frames}:s={size[0]}x{size[1]}:fps={fps}[b{i}]")
            seg["_vin"] = None
        else:
            dur = seg["to"] - seg["from"]
            idx = add_input("-ss", str(seg["from"]), "-t", str(dur), "-i", str(ROOT / seg["src"]))
            fc.append(f"[{idx}:v]setpts=PTS-STARTPTS,fps={fps},scale={size[0]}:{size[1]}[b{i}]")
            seg["_vin"] = idx
        durs.append(dur)
        last = f"b{i}"
        for j, cap in enumerate(seg.get("captions", [])):
            a, b = cap["at"]
            png = work / f"cap_{i}_{j}.png"
            render_caption(cap, size, png)
            ci = add_input("-loop", "1", "-t", str(b), "-i", str(png))
            fin = "" if a <= 0 else f"fade=in:st={a}:d={CAPTION_FADE}:alpha=1,"
            fc.append(f"[{ci}:v]format=rgba,{fin}fade=out:st={b - CAPTION_FADE}:d={CAPTION_FADE}:alpha=1[c{i}_{j}]")
            fc.append(f"[{last}][c{i}_{j}]overlay=enable='between(t,{a},{b})'[o{i}_{j}]")
            last = f"o{i}_{j}"
        fc.append(f"[{last}]format=yuv420p,settb=1/{fps * 1000}[v{i}]")

    # Video crossfade chain.
    offset, cur = 0.0, "v0"
    for i in range(1, len(segs)):
        offset += durs[i - 1] - X
        fc.append(f"[{cur}][v{i}]xfade=transition=fade:duration={X}:offset={offset:.3f}[x{i}]")
        cur = f"x{i}"
    total = sum(durs) - X * (len(segs) - 1)
    fade_out = sc.get("fade_out", 0.5)
    fc.append(f"[{cur}]fade=out:st={total - fade_out:.3f}:d={fade_out},scale=out_range=tv,format=yuv420p[v]")

    # Audio: per segment either its own take audio or a running slice of the music track.
    music_idx = add_input("-i", str(ROOT / sc["music"])) if any(s.get("audio") == "music" for s in segs) else None
    music_segs = [i for i, s in enumerate(segs) if s.get("audio", "source") == "music" or s["_vin"] is None]
    if music_segs:
        fc.append(f"[{music_idx}:a]asplit={len(music_segs)}" + "".join(f"[m{i}]" for i in music_segs))
    music_pos, first_music = 0.0, True
    for i, seg in enumerate(segs):
        dur = durs[i]
        if i in music_segs:
            fin = "afade=in:d=0.6," if first_music else ""
            first_music = False
            fc.append(f"[m{i}]atrim={music_pos:.3f}:{music_pos + dur:.3f},asetpts=PTS-STARTPTS,"
                      f"{fin}volume={sc.get('music_volume', 0.85)},aresample=48000[a{i}]")
            music_pos += dur - X
        else:
            fc.append(f"[{seg['_vin']}:a]asetpts=PTS-STARTPTS,aresample=48000[a{i}]")
    cur = "a0"
    for i in range(1, len(segs)):
        fc.append(f"[{cur}][a{i}]acrossfade=d={X}[ax{i}]")
        cur = f"ax{i}"
    fc.append(f"[{cur}]afade=out:st={total - 1.2:.3f}:d=1.2,atrim=0:{total:.3f},"
              f"alimiter=limit=0.89:level=false[a]")

    out = ROOT / sc["out"]
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-y", *inputs, "-filter_complex", ";".join(fc),
           "-map", "[v]", "-map", "[a]", "-t", f"{total:.3f}",
           "-c:v", "libx264", "-preset", "slow", "-crf", str(sc.get("crf", 20)), "-r", str(fps),
           "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
           "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(out)]
    subprocess.run(cmd, check=True)
    print(f"{out}  {total:.2f} s  {out.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
