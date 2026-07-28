"""One-off: chroma-key + resize concept assets into this folder. Not used by the game."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageDraw

SRC = Path(r"C:\Users\IYuBe\.cursor\projects\d-i-belov-GProjects-MyProject-quizmatik\assets")
DST = Path(__file__).resolve().parent

# Same order as BALLOON_TINTS in answer.gd + one extra peach for cell 16.
BALLOON_TINTS = [
    (0.683, 0.360, 0.389),
    (0.842, 0.718, 0.327),
    (0.604, 0.762, 0.655),
    (0.655, 0.769, 0.814),
    (0.759, 0.393, 0.558),
    (0.584, 0.468, 0.666),
    (0.850, 0.551, 0.309),
    (0.475, 0.773, 0.753),
    (0.374, 0.539, 0.420),
    (0.811, 0.641, 0.317),
    (0.230, 0.484, 0.487),
    (0.711, 0.747, 0.329),
    (0.271, 0.426, 0.683),
    (0.692, 0.584, 0.692),
    (0.577, 0.261, 0.276),
    (0.920, 0.720, 0.560),  # 16th: warm peach (not in game yet)
]


def chroma_key(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = ((r - 255) ** 2 + (g - 0) ** 2 + (b - 255) ** 2) ** 0.5
            score = min(r, b) - g
            magenta = score > 35 and g < 140 and r > 140 and b > 140
            pinky = r > 190 and b > 190 and g < 110
            if pinky or (magenta and dist < 200):
                px[x, y] = (0, 0, 0, 0)
            elif magenta and dist < 280:
                fade = int(max(0.0, min(1.0, (dist - 200.0) / 80.0)) * 255)
                px[x, y] = (r, g, b, min(a, fade))
    return rgba


def save_resized(img: Image.Image, path: Path, max_side: int) -> None:
    w, h = img.size
    scale = min(1.0, max_side / float(max(w, h)))
    if scale < 1.0:
        img = img.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)
    img.save(path, optimize=True)
    print(f"saved {path.name} {img.size} {img.mode}")


def _luma(r: float, g: float, b: float) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _inside_circle(x: int, y: int, cx: int, cy: int, radius: int) -> bool:
    dx, dy = x - cx, y - cy
    return dx * dx + dy * dy <= radius * radius


def paint_blank_balloon(size: int, tint: tuple[float, float, float]) -> Image.Image:
    """Procedural notebook-style balloon: tinted sphere, hatch shading, outline, highlight, nozzle."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = cy = size // 2
    radius = int(size * 0.38)
    tr, tg, tb = tint
    base = (int(tr * 255), int(tg * 255), int(tb * 255), 255)

    # Base fill slightly darker bottom-right
    for y in range(cy - radius, cy + radius + 1):
        for x in range(cx - radius, cx + radius + 1):
            if not _inside_circle(x, y, cx, cy, radius):
                continue
            # light from top-left
            nx = (x - (cx - radius * 0.35)) / (radius * 2.0)
            ny = (y - (cy - radius * 0.35)) / (radius * 2.0)
            shade = 0.72 + 0.38 * (1.0 - min(1.0, (nx * nx + ny * ny) ** 0.5))
            shade -= 0.12 * max(0.0, (x - cx) / float(radius))
            shade -= 0.10 * max(0.0, (y - cy) / float(radius))
            r = int(min(255, max(0, base[0] * shade)))
            g = int(min(255, max(0, base[1] * shade)))
            b = int(min(255, max(0, base[2] * shade)))
            img.putpixel((x, y), (r, g, b, 255))

    # Colored-pencil diagonal hatching (darker strokes)
    hatch = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(hatch)
    step = max(3, size // 42)
    for offset in range(-size, size * 2, step):
        # slight wobble for hand-drawn feel
        wobble = ((offset * 13) % 5) - 2
        points = []
        for t in range(0, size + 1, 2):
            x = t
            y = offset + t + wobble
            if _inside_circle(x, y, cx, cy, radius - 3):
                points.append((x, y))
            elif points:
                hdraw.line(points, fill=(25, 28, 36, 48), width=1)
                points = []
        if len(points) > 1:
            hdraw.line(points, fill=(25, 28, 36, 48), width=1)
    # Cross-hatch lighter pass
    for offset in range(-size, size * 2, step * 2):
        points = []
        for t in range(0, size + 1, 2):
            x = t
            y = offset - t
            if _inside_circle(x, y, cx, cy, radius - 6):
                points.append((x, y))
            elif points:
                hdraw.line(points, fill=(40, 45, 55, 28), width=1)
                points = []
        if len(points) > 1:
            hdraw.line(points, fill=(40, 45, 55, 28), width=1)
    img = Image.alpha_composite(img, hatch)

    # Pencil outline (slightly imperfect via double stroke)
    outline = (42, 48, 58, 255)
    bbox = (cx - radius, cy - radius, cx + radius, cy + radius)
    draw = ImageDraw.Draw(img)
    draw.ellipse(bbox, outline=outline, width=max(2, size // 42))
    draw.ellipse(
        (bbox[0] + 1, bbox[1] + 1, bbox[2] - 1, bbox[3] - 1),
        outline=(55, 60, 70, 160),
        width=1,
    )

    # Glossy highlight (top-left)
    hr = int(radius * 0.26)
    hx = cx - int(radius * 0.30)
    hy = cy - int(radius * 0.34)
    draw.ellipse((hx - hr, hy - hr, hx + hr, hy + int(hr * 0.65)), fill=(255, 255, 255, 200))
    draw.ellipse(
        (hx - int(hr * 0.4), hy - int(hr * 0.3), hx + int(hr * 0.12), hy + int(hr * 0.12)),
        fill=(255, 255, 255, 255),
    )

    # Bottom nozzle nub
    nw = max(3, size // 28)
    nh = max(4, size // 22)
    nx0 = cx - nw
    ny0 = cy + radius - 1
    draw.ellipse(
        (nx0, ny0, nx0 + nw * 2, ny0 + nh),
        fill=(int(tr * 190), int(tg * 190), int(tb * 190), 255),
        outline=outline,
    )
    return img


def build_balloons_atlas(cell: int = 256) -> Image.Image:
    cols = rows = 4
    canvas = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    for i, tint in enumerate(BALLOON_TINTS):
        row, col = divmod(i, cols)
        balloon = paint_blank_balloon(cell, tint)
        canvas.paste(balloon, (col * cell, row * cell), balloon)
    return canvas


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)

    bg = Image.open(SRC / "bg_grid_paper.png").convert("RGB")
    bg = ImageEnhance.Contrast(bg).enhance(1.05)
    save_resized(bg, DST / "bg_grid_paper.png", 1920)

    for name, max_side in [
        ("clouds_atlas.png", 1536),
        ("ui_atlas.png", 1536),
        ("plane_idle.png", 512),
        ("plane_up.png", 512),
        ("plane_down.png", 512),
    ]:
        keyed = chroma_key(Image.open(SRC / name))
        save_resized(keyed, DST / name, max_side)

    # Procedural 4x4 atlas: exact BALLOON_TINTS (+ peach #16), no numbers/strings.
    # AI drafts kept drawing digits on balloons, so we paint blanks ourselves.
    balloons = build_balloons_atlas(256)
    save_resized(balloons, DST / "balloons_atlas.png", 1024)
    print("done")


if __name__ == "__main__":
    main()
