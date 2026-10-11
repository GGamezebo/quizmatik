"""Store cover (offline). Same watercolor / pencil-sticker look as the game, built from game art.

Run: python tools/generate_store_cover.py
Writes store/banners/itch_cover_1260x1000.png (itch.io cover, 5:4; thumbnails scale it to 315x250).
Sources: valley painting, balloons_atlas.png, planes_atlas_spaced.png (starter column),
flame.png, question_banner.png, btn_cta_wide.png, Rubik Doodle Shadow + Nunito Bold.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store", "banners", "itch_cover_1260x1000.png")
W, H = 1260, 1000
INK = (42, 51, 64, 255)
CREAM = (250, 242, 222, 255)
WHITE = (255, 255, 255, 255)


def p(*parts):
    return os.path.join(ROOT, *parts)


def font(name, size):
    return ImageFont.truetype(p("assets", "fonts", name), size)


def shadowed(img, layer, pos, blur=16, alpha=0.35, offset=(8, 16)):
    sh = Image.new("RGBA", layer.size, (20, 30, 50, 0))
    sh.putalpha(layer.getchannel("A").point(lambda v: int(v * alpha)))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(sh, (pos[0] + offset[0], pos[1] + offset[1]))
    img.alpha_composite(layer, pos)


def nine_slice(src, size, corner):
    w, h = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    sw, sh = src.size
    c = corner
    xs = [(0, c, 0, c), (c, w - c, c, sw - c), (w - c, w, sw - c, sw)]
    ys = [(0, c, 0, c), (c, h - c, c, sh - c), (h - c, h, sh - c, sh)]
    for dx0, dx1, sx0, sx1 in xs:
        for dy0, dy1, sy0, sy1 in ys:
            tile = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS)
            out.alpha_composite(tile, (dx0, dy0))
    return out


def background():
    v = Image.open(p("assets", "ui", "backgrounds", "valleys", "valley_multiplication.png")).convert("RGB")
    s = H / v.height * 1.0
    v = v.resize((int(v.width * s), H), Image.LANCZOS)
    x0 = max(0, (v.width - W) // 2)
    img = v.crop((x0, 0, x0 + W, H)).convert("RGBA")
    # soft cream haze at top (title) and bottom (panel), like the paper wash in the game
    haze = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    for y in range(H):
        top = max(0.0, 1 - y / 330) ** 1.6
        bot = max(0.0, (y - 700) / 300) ** 1.4
        a = int(215 * max(top, bot))
        hd.line([(0, y), (W, y)], fill=(250, 240, 214, a))
    img.alpha_composite(haze)
    return img


def balloon(img, cell, num, center, height, tilt, string_len=230):
    atlas = Image.open(p("src", "features", "answer", "balloons_atlas.png")).convert("RGBA")
    r, c = cell
    b = atlas.crop((c * 256 + 30, r * 240 + 6, c * 256 + 226, r * 240 + 234))
    s = height / b.height
    b = b.resize((int(b.width * s), int(b.height * s)), Image.LANCZOS)
    d = ImageDraw.Draw(b)
    nf = font("Nunito-Bold.ttf", int(b.height * 0.5))
    cx, cy = b.width // 2, int(b.height * 0.42)
    d.text((cx + 4, cy + 6), str(num), font=nf, fill=(30, 40, 60, 110), anchor="mm")
    d.text((cx, cy), str(num), font=nf, fill=WHITE, anchor="mm", stroke_width=3, stroke_fill=(42, 51, 64, 70))
    # string (graphite pencil line) curling from the knot
    cw = b.width + 120
    layer = Image.new("RGBA", (cw, b.height + string_len + 20), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ox = 60
    pts = []
    for i in range(40):
        t = i / 39
        pts.append((ox + b.width / 2 + math.sin(t * 5.0) * 16 * t, b.height - 6 + t * string_len))
    ld.line(pts, fill=INK, width=5, joint="curve")
    layer.alpha_composite(b, (ox, 0))
    layer = layer.rotate(tilt, resample=Image.BICUBIC, expand=True, center=(ox + b.width / 2, b.height * 0.5))
    pos = (center[0] - layer.width // 2, center[1] - int(b.height * 0.5))
    shadowed(img, layer, pos, blur=18, alpha=0.28, offset=(10, 18))


def plane(img, pos, scale, angle):
    at = Image.open(p("src", "features", "plane", "planes_atlas_spaced.png")).convert("RGBA").crop((0, 0, 288, 108))
    pl = at.resize((int(288 * scale), int(108 * scale)), Image.LANCZOS)
    fl = Image.open(p("src", "features", "plane", "flame.png")).convert("RGBA").crop((100, 0, 200, 40))
    fl = fl.resize((int(100 * scale * 1.15), int(40 * scale * 1.15)), Image.LANCZOS)
    comp = Image.new("RGBA", (pl.width + fl.width, pl.height + 20), (0, 0, 0, 0))
    comp.alpha_composite(fl, (0, int(pl.height * 0.42) - fl.height // 2 + 8))
    comp.alpha_composite(pl, (fl.width - 55, 10))
    comp = comp.rotate(angle, resample=Image.BICUBIC, expand=True)
    shadowed(img, comp, pos, blur=20, alpha=0.3, offset=(14, 26))
    return comp.size


def title(img):
    f = font("RubikDoodleShadow-Regular.ttf", 190)
    size = (W, 300)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).text((W // 2, 30), "JET MATH", font=f, fill=255, anchor="ma", stroke_width=24, stroke_fill=255)
    # the face is made of overlapping contours: close the holes so the paper rim is one solid die-cut shape
    mask = mask.filter(ImageFilter.MaxFilter(31)).filter(ImageFilter.MinFilter(31)).filter(ImageFilter.GaussianBlur(1))
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    layer.paste(Image.new("RGBA", size, CREAM), (0, 0), mask)
    ImageDraw.Draw(layer).text((W // 2, 30), "JET MATH", font=f, fill=INK, anchor="ma")
    shadowed(img, layer, (0, 20), blur=10, alpha=0.4, offset=(6, 12))


def question_banner(img):
    ban = Image.open(p("assets", "ui", "hud", "question_banner.png")).convert("RGBA")
    ban = ban.resize((640, int(640 * ban.height / ban.width)), Image.LANCZOS)
    d = ImageDraw.Draw(ban)
    d.text((ban.width // 2, int(ban.height * 0.46)), "6 × 7 = ?", font=font("Nunito-Bold.ttf", 88), fill=INK, anchor="mm")
    shadowed(img, ban, (60, 258), blur=12, alpha=0.3, offset=(4, 12))


def info_panel(img):
    src = Image.open(p("src", "game", "scenes", "menu", "ui", "btn_cta_wide.png")).convert("RGBA")
    pw, ph = 1140, 176
    panel = nine_slice(src, (pw, ph), 44)
    d = ImageDraw.Draw(panel)
    d.text((pw // 2, 58), "A fun math trainer for kids", font=font("Nunito-Bold.ttf", 66), fill=INK, anchor="mm")
    d.text((pw // 2, 120), "Learn to count while you play: times tables, addition and more",
           font=font("Nunito-Bold.ttf", 32), fill=(78, 70, 58, 255), anchor="mm")
    shadowed(img, panel, ((W - pw) // 2, 790), blur=14, alpha=0.35, offset=(4, 14))


def sparkle(img, x, y, r, a=230):
    layer = Image.new("RGBA", (r * 4, r * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = r * 2
    d.polygon([(c, c - r * 2), (c + r * 0.35, c - r * 0.35), (c + r * 2, c), (c + r * 0.35, c + r * 0.35),
               (c, c + r * 2), (c - r * 0.35, c + r * 0.35), (c - r * 2, c), (c - r * 0.35, c - r * 0.35)],
              fill=(255, 250, 225, a))
    layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    img.alpha_composite(layer, (x - c, y - c))


def main():
    img = background()
    # distant small balloons for depth (no numbers)
    for cell, cx, cy, h, tilt in [((0, 1), 700, 520, 120, -8), ((1, 2), 1200, 650, 110, 9), ((1, 0), 110, 470, 130, 5),
                                  ((2, 1), 1130, 330, 120, -6)]:
        balloon(img, cell, "", (cx, cy), h, tilt, string_len=90)
    plane(img, (0, 528), 2.05, 6)
    balloon(img, (2, 2), 6, (890, 530), 300, 6, string_len=170)
    balloon(img, (0, 0), 7, (1075, 500), 300, -5, string_len=170)
    title(img)
    question_banner(img)
    info_panel(img)
    for x, y, r in [(740, 330, 14), (1180, 430, 11), (330, 520, 12), (900, 300, 9), (60, 330, 13)]:
        sparkle(img, x, y, r)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.convert("RGB").save(OUT)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
