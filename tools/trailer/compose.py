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


def atempo_chain(speed: float) -> str:
    """ffmpeg atempo is only valid in 0.5–2; chain it for anything faster or slower."""
    if abs(speed - 1.0) < 0.01:
        return ""
    parts = []
    remaining = speed
    while remaining > 2.0:
        parts.append("atempo=2.0")
        remaining /= 2.0
    while remaining < 0.5:
        parts.append("atempo=0.5")
        remaining /= 0.5
    parts.append(f"atempo={remaining:.4f}")
    return ",".join(parts) + ","


def _sfx_fx(seg, sc) -> str:
    """Optional ffmpeg audio filters in front of the take level (`sfx_fx` on the segment or the scenario)."""
    fx = seg.get("sfx_fx", sc.get("sfx_fx", "")) or ""
    fx = str(fx).strip().strip(",")
    return f"{fx}," if fx else ""


def music_volume_filter(seg, base: float) -> str:
    """Constant gain, or a hard dip (`music_duck`: [from, to] in segment seconds)."""
    duck = seg.get("music_duck")
    if not duck:
        return f"volume={base}"
    a, b = float(duck[0]), float(duck[1])
    return f"volume='{base}*if(between(t,{a:.3f},{b:.3f}),0,1)':eval=frame"


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
    elif kind == "doodle":  # big Rubik line, no card (ad punch-in)
        y = cap.get("y", POS[cap.get("pos", "bottom")])
        c.title(cap["text"] if isinstance(cap["text"], str) else cap["text"][0], y, cap.get("px", 110))
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
            src_dur = seg["to"] - seg["from"]
            spd = float(seg.get("speed", 1))
            dur = src_dur / spd
            seg["_spd"] = spd
            idx = add_input("-ss", str(seg["from"]), "-t", f"{src_dur:.3f}", "-i", str(ROOT / seg["src"]))
            pts = "setpts=PTS-STARTPTS" if abs(spd - 1) < 0.01 else f"setpts=(PTS-STARTPTS)/{spd:.4f}"
            fc.append(f"[{idx}:v]{pts},fps={fps},scale={size[0]}:{size[1]}[b{i}]")
            seg["_vin"] = idx
        durs.append(dur)
        last = f"b{i}"
        for j, cap in enumerate(seg.get("captions", [])):
            a, b = cap["at"]
            png = work / f"cap_{i}_{j}.png"
            render_caption(cap, size, png)
            ci = add_input("-loop", "1", "-t", str(b), "-i", str(png))
            fade = float(cap.get("fade", CAPTION_FADE))
            fades = ""
            if fade > 0 and b - a > fade * 2:
                if a > 0:
                    fades += f"fade=in:st={a}:d={fade}:alpha=1,"
                fades += f"fade=out:st={b - fade}:d={fade}:alpha=1,"
            fc.append(f"[{ci}:v]format=rgba,{fades}null[c{i}_{j}]")
            hop = ""
            if cap.get("hop"):
                hop = (f":y='-34*sin(PI*min(max(t-{a:.3f},0)/0.28,1))*lt(t-{a:.3f},0.28)'")
            fc.append(f"[{last}][c{i}_{j}]overlay=x=0{hop}:enable='between(t,{a},{b})'[o{i}_{j}]")
            last = f"o{i}_{j}"
        fc.append(f"[{last}]format=yuv420p,settb=1/{fps * 1000}[v{i}]")

    def junction(i: int) -> float:
        """Crossfade length into segment i (0 for the first)."""
        return 0.0 if i == 0 else float(segs[i].get("xfade", X))

    # Video crossfade chain. `transition` on the incoming segment (fade, wipeleft, hblur, circleopen, …).
    offset, cur = 0.0, "v0"
    for i in range(1, len(segs)):
        xd = junction(i)
        offset += durs[i - 1] - xd
        tr = segs[i].get("transition", sc.get("transition", "fade"))
        fc.append(f"[{cur}][v{i}]xfade=transition={tr}:duration={xd}:offset={offset:.3f}[x{i}]")
        cur = f"x{i}"
    total = sum(durs) - sum(junction(i) for i in range(1, len(segs)))
    fade_out = sc.get("fade_out", 0.5)
    fc.append(f"[{cur}]fade=out:st={total - fade_out:.3f}:d={fade_out},scale=out_range=tv,format=yuv420p[v]")

    # Audio. `bed` lays one music file under take SFX.
    # Segment `music: false` = SFX only (the bed playhead stays put, unless `advance_bed`).
    # Segment `music_src` plays that file instead (boss / win); `music_duck` [from, to] silences it.
    bed = bool(sc.get("bed", False))

    def uses_bed(seg) -> bool:
        if seg.get("music") is False or seg.get("music_src"):
            return False
        if bed:
            return True
        return seg.get("audio", "source") == "music" or seg["_vin"] is None

    music_ids = [i for i, s in enumerate(segs) if uses_bed(s)]
    music_idx = add_input("-i", str(ROOT / sc["music"])) if music_ids else None
    if music_ids:
        fc.append(f"[{music_idx}:a]asplit={len(music_ids)}" + "".join(f"[m{i}]" for i in music_ids))
    music_pos, first_music = 0.0, True

    def mix_sfx(i: int, seg, music_label: str) -> None:
        has_sfx = seg["_vin"] is not None and seg.get("audio", "source") == "source"
        if not has_sfx:
            fc.append(f"[{music_label}]anull[a{i}]")
            return
        sv = seg.get("sfx_volume", sc.get("sfx_volume", 1.0))
        tempo = atempo_chain(float(seg.get("_spd", 1)))
        fx = _sfx_fx(seg, sc)
        fc.append(f"[{seg['_vin']}:a]asetpts=PTS-STARTPTS,{tempo}{fx}volume={sv},aresample=48000[sfx{i}]")
        fc.append(f"[{music_label}][sfx{i}]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[a{i}]")

    for i, seg in enumerate(segs):
        dur = durs[i]
        next_x = junction(i + 1) if i + 1 < len(segs) else 0.0
        if seg.get("music_src"):
            mi = add_input("-i", str(ROOT / seg["music_src"]))
            mv = float(seg.get("music_volume", sc.get("music_volume", 0.55)))
            fade = float(seg.get("music_fade", 0.2))
            fin = f"afade=in:d={fade}," if fade > 0 else ""
            start = float(seg.get("music_from", 0))
            fc.append(f"[{mi}:a]atrim={start:.3f}:{start + dur:.3f},asetpts=PTS-STARTPTS,"
                      f"{fin}{music_volume_filter(seg, mv)},aresample=48000[mu{i}]")
            mix_sfx(i, seg, f"mu{i}")
            if seg.get("advance_bed", True):
                music_pos += dur - next_x
        elif i in music_ids:
            fade = seg.get("music_fade")
            if fade is None:
                fin = "afade=in:d=0.45," if first_music else ""
            else:
                fin = f"afade=in:d={float(fade)}," if float(fade) > 0 else ""
            first_music = False
            mv = float(seg.get("music_volume", sc.get("music_volume", 0.5 if bed else 0.85)))
            fc.append(f"[m{i}]atrim={music_pos:.3f}:{music_pos + dur:.3f},asetpts=PTS-STARTPTS,"
                      f"{fin}{music_volume_filter(seg, mv)},aresample=48000[mu{i}]")
            music_pos += dur - next_x
            mix_sfx(i, seg, f"mu{i}")
        else:
            if seg["_vin"] is None:
                fc.append(f"anullsrc=channel_layout=stereo:sample_rate=48000,atrim=0:{dur:.3f}[a{i}]")
            else:
                sv = seg.get("sfx_volume", sc.get("sfx_volume", 1.0))
                tempo = atempo_chain(float(seg.get("_spd", 1)))
                fx = _sfx_fx(seg, sc)
                fc.append(f"[{seg['_vin']}:a]asetpts=PTS-STARTPTS,{tempo}{fx}volume={sv},aresample=48000[a{i}]")
            if seg.get("advance_bed"):
                music_pos += dur - next_x
    cur = "a0"
    for i in range(1, len(segs)):
        fc.append(f"[{cur}][a{i}]acrossfade=d={junction(i)}[ax{i}]")
        cur = f"ax{i}"
    if sc.get("voice") or sc.get("voice_cues"):
        vv = sc.get("voice_volume", 1.0)
        if sc.get("voice_cues"):
            ids, off = {}, 0.0
            for i, seg in enumerate(segs):
                if seg.get("id"):
                    ids[seg["id"]] = off
                off += durs[i] - (junction(i + 1) if i + 1 < len(segs) else 0.0)
            labels = []
            for k, cue in enumerate(sc["voice_cues"]):
                ci = add_input("-i", str(ROOT / cue["src"]))
                at = ids[cue["id"]] + float(cue.get("at", 0))
                print(f"voice {cue['id']} {at:.2f}s")
                delay = int(round(at * 1000))
                fc.append(f"[{ci}:a]aresample=48000,adelay={delay}|{delay},volume={cue.get('volume', 1)}[cue{k}]")
                labels.append(f"[cue{k}]")
            fc.append("".join(labels) + f"amix=inputs={len(labels)}:duration=longest:dropout_transition=0:normalize=0,"
                      f"apad=whole_dur={total:.3f},atrim=0:{total:.3f},volume={vv},asplit[vo][vsc]")
        else:
            vi = add_input("-i", str(ROOT / sc["voice"]))
            fc.append(f"[{vi}:a]aresample=48000,apad=whole_dur={total:.3f},atrim=0:{total:.3f},volume={vv},asplit[vo][vsc]")
        fc.append(f"[{cur}][vsc]sidechaincompress=threshold=0.02:ratio=6:attack=40:release=450[ducked]")
        fc.append(f"[ducked][vo]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[amixed]")
        cur = "amixed"
    if sc.get("stinger"):
        si = add_input("-i", str(ROOT / sc["stinger"]))
        at = max(0.0, total - float(sc.get("stinger_from_end", 1.6)))
        delay = int(at * 1000)
        fc.append(f"[{si}:a]aresample=48000,adelay={delay}|{delay},volume={sc.get('stinger_volume', 0.7)}[sting]")
        fc.append(f"[{cur}][sting]amix=inputs=2:duration=first:dropout_transition=0:normalize=0[astung]")
        cur = "astung"
    audio_fade = float(sc.get("audio_fade", 0.45))
    fc.append(f"[{cur}]afade=out:st={max(0.0, total - audio_fade):.3f}:d={audio_fade},atrim=0:{total:.3f},"
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
