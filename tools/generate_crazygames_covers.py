"""CrazyGames cover set (offline). Re-frames the Jet Math cover from tools/generate_store_cover.py output.

Run: python tools/generate_store_cover.py && python tools/generate_crazygames_covers.py
Writes store/banners/crazygames_cover_{1920x1080,800x1200,800x800}.png: the itch cover is scaled to fit,
the free space is its own blurred copy (no hard bars). Sizes: verify against the CrazyGames upload form.
"""
import os

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "store", "banners", "itch_cover_1260x1000.png")
OUT = os.path.join(ROOT, "store", "banners")
SIZES = [(1920, 1080), (800, 1200), (800, 800)]


def reframe(src, size):
    w, h = size
    fill_s = max(w / src.width, h / src.height)
    bg = src.resize((int(src.width * fill_s) + 1, int(src.height * fill_s) + 1), Image.LANCZOS)
    bg = bg.crop(((bg.width - w) // 2, (bg.height - h) // 2, (bg.width - w) // 2 + w, (bg.height - h) // 2 + h))
    bg = bg.filter(ImageFilter.GaussianBlur(28))
    fit_s = min(w / src.width, h / src.height)
    fg = src.resize((int(src.width * fit_s), int(src.height * fit_s)), Image.LANCZOS)
    bg.paste(fg, ((w - fg.width) // 2, (h - fg.height) // 2))
    return bg


def main():
    src = Image.open(SRC).convert("RGB")
    for size in SIZES:
        path = os.path.join(OUT, "crazygames_cover_%dx%d.png" % size)
        reframe(src, size).save(path)
        print("wrote", path)


if __name__ == "__main__":
    main()
