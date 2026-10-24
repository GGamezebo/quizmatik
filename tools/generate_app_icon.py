"""Quizmatik app icon kit (offline). Notebook-pencil sticker look, see concepts/ART_DIRECTION.md.

Run: python tools/generate_app_icon.py
Writes assets/app_icon/: icon_512.png (main / web / desktop), adaptive_fg_432.png,
adaptive_bg_432.png, adaptive_mono_432.png, icon_192.png, icon_180.png, icon_144.png,
splash.png (Godot boot splash, big: stretch Keep), splash_android.png (Android 12+ launch
icon: main icon shrunk into the 2/3 safe circle); store/banners/play_icon_512.png (Play listing:
unframed art, opaque full square, Play rounds it itself). Plane sprite = starter column of
src/features/plane/planes_atlas_spaced.png.
"""
import math
import os
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "app_icon")
ATLAS = os.path.join(ROOT, "src", "features", "plane", "planes_atlas_spaced.png")
FONT = os.path.join(ROOT, "assets", "fonts", "Nunito-Bold.ttf")

S = 1024  # work canvas
INK = (42, 51, 64, 255)
CREAM = (243, 230, 200, 255)
WHITE = (255, 255, 255, 255)


def _ellipse_layer(box, fill, outline=None, width=0):
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(box, fill=fill, outline=outline, width=width)
    return layer


def sticker(img, rim=22, shadow=(14, 18), blur=14):
    """White die-cut rim + soft drop shadow around the alpha of `img` (S x S RGBA)."""
    alpha = img.getchannel("A")
    grown = alpha.filter(ImageFilter.MaxFilter(rim * 2 + 1)).filter(ImageFilter.GaussianBlur(2))
    grown = grown.point(lambda v: 255 if v > 90 else 0)
    shadow_layer = Image.new("RGBA", (S, S), (60, 45, 30, 0))
    shadow_layer.putalpha(grown.point(lambda v: int(v * 0.35)))
    shadow_layer = ImageChops.offset(shadow_layer, *shadow).filter(ImageFilter.GaussianBlur(blur))
    rim_layer = Image.new("RGBA", (S, S), WHITE)
    rim_layer.putalpha(grown)
    out = Image.alpha_composite(shadow_layer, rim_layer)
    return Image.alpha_composite(out, img)


def draw_star(d, cx, cy, r, fill, outline=INK, width=6):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=fill, outline=outline, width=width)


def make_balloon(cx, cy, w, h, digit="7", color=(236, 92, 88, 255)):
    """Red paper balloon with a big white digit, graphite outline."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # string (behind body)
    pts = []
    for i in range(40):
        t = i / 39
        pts.append((cx + math.sin(t * 5.0) * 16 + t * -40, cy + h * 0.5 + t * 190))
    d.line(pts, fill=INK, width=9, joint="curve")
    # knot
    d.polygon([(cx - 24, cy + h * 0.5 + 34), (cx + 24, cy + h * 0.5 + 34), (cx, cy + h * 0.5 - 6)],
              fill=color, outline=INK, width=8)
    # body
    d.ellipse((cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), fill=color, outline=INK, width=10)
    # pencil hatching
    hatch = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hatch)
    for k in range(-S, S, 26):
        hd.line([(cx + k - w, cy + h / 2), (cx + k + w * 0.3, cy - h / 2)], fill=(255, 255, 255, 38), width=6)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse((cx - w / 2 + 10, cy - h / 2 + 10, cx + w / 2 - 10, cy + h / 2 - 10), fill=255)
    hatch.putalpha(ImageChops.multiply(hatch.getchannel("A"), mask))
    layer = Image.alpha_composite(layer, hatch)
    # highlight
    d = ImageDraw.Draw(layer)
    d.ellipse((cx - w * 0.33, cy - h * 0.36, cx - w * 0.12, cy - h * 0.12), fill=(255, 255, 255, 120))
    # digit
    font = ImageFont.truetype(FONT, int(h * 0.62))
    d.text((cx + 4, cy + 6), digit, font=font, fill=WHITE, anchor="mm", stroke_width=9, stroke_fill=INK)
    return layer


def make_plane(scale, angle):
    atlas = Image.open(ATLAS).convert("RGBA")
    cell = atlas.crop((0, 0, 288, 108))
    cell = cell.crop(cell.getbbox())
    cell = cell.resize((int(cell.width * scale), int(cell.height * scale)), Image.LANCZOS)
    # firm graphite re-outline so the sprite reads at 48px
    a = cell.getchannel("A")
    edge = ImageChops.subtract(a.filter(ImageFilter.MaxFilter(9)), a)
    ink = Image.new("RGBA", cell.size, INK)
    ink.putalpha(edge)
    cell = Image.alpha_composite(ink, cell)
    pad = int(cell.width * 0.34)
    canvas = Image.new("RGBA", (cell.width + pad, cell.height + 40), (0, 0, 0, 0))
    fd = ImageDraw.Draw(canvas)
    fy = 20 + int(cell.height * 0.42)
    fd.polygon([(pad + 50, fy), (6, fy - 18), (pad * 0.55, fy + 2), (14, fy + 34), (pad + 50, fy + 24)],
               fill=(248, 160, 50, 255), outline=INK, width=7)
    fd.polygon([(pad + 4, fy + 2), (pad * 0.45, fy + 6), (pad + 4, fy + 16)], fill=(250, 214, 80, 255))
    canvas.paste(cell, (pad, 20), cell)
    cell = canvas
    return cell.rotate(angle, resample=Image.BICUBIC, expand=True)


def make_fg(zoom=1.0, with_sparks=True):
    """Foreground on transparent S x S; content stays inside ~60% box at zoom 1 (adaptive safe zone)."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # pencil trail (dashes behind the plane, bottom-left)
    d = ImageDraw.Draw(layer)
    for i in range(7):
        x0 = 232 - i * 0
        t = i / 6
        sx, sy = 420 - t * 190, 690 + t * 70
        d.ellipse((sx - 12 + t * 4, sy - 12, sx + 12 - t * 4, sy + 12), fill=(*INK[:3], int(210 - t * 130)))

    for cx, cy, digit, col in ((418, 350, "6", (84, 150, 220, 255)), (640, 320, "7", (236, 92, 88, 255))):
        balloon = make_balloon(cx, cy, 250, 320, digit, col)
        layer = Image.alpha_composite(layer, sticker(balloon, rim=18))

    plane = make_plane(1.75, 16)
    plane_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    plane_layer.paste(plane, (512 - plane.width // 2 + 10, 680 - plane.height // 2), plane)
    layer = Image.alpha_composite(layer, sticker(plane_layer, rim=20))

    if with_sparks:
        d = ImageDraw.Draw(layer)
        font = ImageFont.truetype(FONT, 160)
        for ch, x, y, col in (("+", 190, 250, (56, 112, 77, 255)), ("×", 190, 470, (214, 120, 40, 255)),
                              ("−", 834, 250, (60, 110, 200, 255)), ("÷", 834, 470, (140, 70, 180, 255))):
            d.text((x, y), ch, font=font, fill=col, anchor="mm", stroke_width=12, stroke_fill=WHITE)
            d.text((x, y), ch, font=font, fill=col, anchor="mm", stroke_width=0)

    if zoom != 1.0:
        n = int(S * zoom)
        layer = layer.resize((n, n), Image.LANCZOS)
        full = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        full.paste(layer, ((S - n) // 2, (S - n) // 2 + 6), layer)
        layer = full
    return layer


def make_bg():
    """Full-bleed sky-to-paper gradient + notebook grid + soft clouds."""
    bg = Image.new("RGBA", (S, S))
    px = bg.load()
    top, bot = (122, 196, 232), (252, 238, 205)
    for y in range(S):
        t = (y / S) ** 0.9
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)) + (255,)
        for x in range(S):
            px[x, y] = c
    grid = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    step = 64
    for k in range(0, S, step):
        gd.line([(k, 0), (k, S)], fill=(255, 255, 255, 70), width=3)
        gd.line([(0, k), (S, k)], fill=(255, 255, 255, 70), width=3)
    bg = Image.alpha_composite(bg, grid)
    clouds = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    for cx, cy, r in ((170, 820, 120), (300, 860, 150), (460, 840, 110), (820, 880, 150), (960, 830, 100), (690, 900, 120)):
        cd.ellipse((cx - r, cy - r * 0.62, cx + r, cy + r * 0.62), fill=(255, 255, 255, 235))
    bg = Image.alpha_composite(bg, clouds.filter(ImageFilter.GaussianBlur(5)))
    return bg


def rounded(img, radius_frac=0.22, border=14):
    n = img.width
    mask = Image.new("L", (n * 2, n * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, n * 2 - 1, n * 2 - 1), radius=int(n * 2 * radius_frac), fill=255)
    mask = mask.resize((n, n), Image.LANCZOS)
    out = img.copy()
    ring = Image.new("RGBA", (n * 2, n * 2), (0, 0, 0, 0))
    b = int(border * n / S * 2)
    ImageDraw.Draw(ring).rounded_rectangle((0, 0, n * 2 - 1, n * 2 - 1), radius=int(n * 2 * radius_frac),
                                           outline=INK, width=b)
    out = Image.alpha_composite(out, ring.resize((n, n), Image.LANCZOS))
    out.putalpha(mask)
    return out


# Launchers show the central 72/108 of the adaptive canvas cut to their own mask: the icon art
# (no frame, the mask is the shape) fills exactly that square; the sky background covers the rest.
ADAPTIVE_ART_FRAC = 72 / 108

# Android 12+ masks the launch icon to a circle of 2/3 of its canvas; a rounded square
# (corner radius 0.22) fits that circle when its side <= ~0.54 of the canvas.
ANDROID_SPLASH_FRAC = 0.52


def padded(img, frac):
    """img scaled to frac of the canvas, centered on transparent S x S."""
    n = int(S * frac)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img.resize((n, n), Image.LANCZOS), ((S - n) // 2, (S - n) // 2))
    return out


STORE_OUT = os.path.join(ROOT, "store", "banners")
# Play Store applies its own rounded mask to the 512 icon: submit the unframed art, opaque full square.
def play_store_icon(art):
    return art.resize((512, 512), Image.LANCZOS)


def save(img, name, size):
    os.makedirs(OUT, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(os.path.join(OUT, name), optimize=True)


def main():
    random.seed(7)
    bg = make_bg()
    fg_adaptive = make_fg(1.0)
    fg_main = make_fg(1.12)

    main_icon = rounded(Image.alpha_composite(bg, fg_main))
    save(main_icon, "icon_512.png", 512)
    save(main_icon, "icon_192.png", 192)
    save(main_icon, "icon_180.png", 180)
    save(main_icon, "icon_144.png", 144)
    save(padded(main_icon, 0.9), "splash.png", 1024)
    save(padded(main_icon, ANDROID_SPLASH_FRAC), "splash_android.png", 432)

    # launcher: unframed art edge to edge, the launcher mask gives the shape
    save(padded(Image.alpha_composite(bg, fg_main), ADAPTIVE_ART_FRAC), "adaptive_fg_432.png", 432)
    save(bg, "adaptive_bg_432.png", 432)
    mono = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    mono.putalpha(fg_adaptive.getchannel("A").point(lambda v: 255 if v > 40 else 0))
    mono = Image.merge("RGBA", (*(Image.new("L", (S, S), 255),) * 3, mono.getchannel("A")))
    save(mono, "adaptive_mono_432.png", 432)
    play_store_icon(Image.alpha_composite(bg, fg_main)).save(os.path.join(STORE_OUT, "play_icon_512.png"), optimize=True)
    print("ok ->", OUT)


if __name__ == "__main__":
    main()
