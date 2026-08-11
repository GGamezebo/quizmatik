"""Extract concept plane exactly; build idle / up / down stickers (no flame, no shadow)."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
DST = ROOT / "src" / "features" / "plane"
CONCEPT_DIR = ROOT / "concepts" / "notebook_pencil"
ASSETS = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets")
SRC = ASSETS / (
	"c__Users_Admin_AppData_Roaming_Cursor_User_workspaceStorage_"
	"c8485cde00ab0c3f6d0a538627ccb7be_images_image-338940e4-23dc-408b-80ca-68cf415ff307.png"
)

# Target game-ish height (body+outline); width follows aspect
TARGET_H = 122
CREAM = np.array([252, 248, 240, 255], dtype=np.uint8)
OUTLINE = 8


def flood_paper(img: Image.Image) -> Image.Image:
	"""Clear graph-paper bg + soft shadow from edges."""
	rgba = np.array(img.convert("RGBA"))
	h, w = rgba.shape[:2]
	seen = np.zeros((h, w), dtype=bool)
	q: deque[tuple[int, int]] = deque()

	def is_bg(y: int, x: int) -> bool:
		r, g, b, a = map(int, rgba[y, x])
		if a < 8:
			return True
		lum = (r + g + b) / 3
		sat = max(r, g, b) - min(r, g, b)
		# paper / cream grid
		if lum >= 168 and sat < 55:
			return True
		# soft gray shadow
		if lum < 120 and sat < 35:
			return True
		return False

	for x in range(0, w, 1):
		for y in (0, h - 1):
			if is_bg(y, x):
				q.append((y, x))
				seen[y, x] = True
	for y in range(0, h, 1):
		for x in (0, w - 1):
			if not seen[y, x] and is_bg(y, x):
				q.append((y, x))
				seen[y, x] = True
	while q:
		y, x = q.popleft()
		rgba[y, x] = 0
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and is_bg(ny, nx):
				seen[ny, nx] = True
				q.append((ny, nx))
	return Image.fromarray(rgba, "RGBA")


def remove_flame(arr: np.ndarray) -> np.ndarray:
	"""Drop icy cyan exhaust on the left of the sticker."""
	out = arr.copy()
	a = out[:, :, 3]
	ys, xs = np.where(a > 30)
	if len(xs) == 0:
		return out
	x0, x1 = int(xs.min()), int(xs.max())
	span = max(1, x1 - x0)
	# flame is left of body — kill cyan/ice in leftmost 18% of content
	cut = x0 + int(span * 0.18)
	rgb = out[:, :, :3].astype(np.float32)
	xx = np.arange(out.shape[1])[None, :]
	zone = (xx < cut) & (a > 0)
	ice = (rgb[:, :, 2] > rgb[:, :, 0] + 20) & (rgb[:, :, 1] > rgb[:, :, 0] - 5) & (rgb[:, :, 2] > 125)
	# also bright cyan sparks
	spark = (rgb[:, :, 2] > 160) & (rgb[:, :, 1] > 140) & (rgb[:, :, 0] < 150) & (xx < cut + span * 0.05)
	kill = zone & (ice | spark)
	# dilate
	kill_img = Image.fromarray((kill.astype(np.uint8) * 255), "L").filter(ImageFilter.MaxFilter(5))
	kill = np.array(kill_img) > 0
	out[kill] = 0
	return out


def remove_shadow_fringe(arr: np.ndarray) -> np.ndarray:
	out = arr.copy()
	rgb = out[:, :, :3].astype(np.float32)
	a = out[:, :, 3]
	lum = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	# soft dark under sticker
	shadow = (a > 5) & (lum < 115) & (sat < 40)
	out[shadow] = 0
	# semi-transparent gray
	soft = (a > 5) & (a < 200) & (lum < 140) & (sat < 30)
	out[soft] = 0
	return out


def largest_component(mask: np.ndarray) -> np.ndarray:
	h, w = mask.shape
	seen = np.zeros_like(mask, dtype=bool)
	best = None
	best_count = 0
	for y in range(h):
		for x in range(w):
			if not mask[y, x] or seen[y, x]:
				continue
			q = deque([(y, x)])
			seen[y, x] = True
			cells: list[tuple[int, int]] = []
			while q:
				cy, cx = q.popleft()
				cells.append((cy, cx))
				for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
					if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
						seen[ny, nx] = True
						q.append((ny, nx))
			if len(cells) > best_count:
				best_count = len(cells)
				best = cells
	out = np.zeros_like(mask)
	if best:
		for y, x in best:
			out[y, x] = True
	return out


def extract_concept() -> Image.Image:
	cleared = flood_paper(Image.open(SRC))
	arr = remove_shadow_fringe(np.array(cleared))
	arr = remove_flame(arr)
	mask = largest_component(arr[:, :, 3] > 25)
	arr[~mask] = 0
	ys, xs = np.where(mask)
	pad = 4
	y0, y1 = max(0, ys.min() - pad), min(arr.shape[0], ys.max() + 1 + pad)
	x0, x1 = max(0, xs.min() - pad), min(arr.shape[1], xs.max() + 1 + pad)
	crop = arr[y0:y1, x0:x1]
	img = Image.fromarray(crop, "RGBA")
	img.save(ASSETS / "concept_exact_cut.png")
	return img


def ensure_white_outline(body: Image.Image, radius: int = OUTLINE) -> Image.Image:
	"""If rim was partially eaten, rebuild a clean cream sticker outline."""
	arr = np.array(body.convert("RGBA"))
	# detect existing cream rim
	rgb = arr[:, :, :3]
	a = arr[:, :, 3]
	cream = (a > 100) & (rgb[:, :, 0] >= 230) & (rgb[:, :, 1] >= 220) & (rgb[:, :, 2] >= 200)
	# body = opaque non-cream
	body_m = (a > 80) & ~cream
	# if little cream left, rebuild from body
	if cream.sum() < body_m.sum() * 0.08:
		alpha = Image.fromarray((body_m.astype(np.uint8) * 255), "L")
		field = np.array(alpha.filter(ImageFilter.GaussianBlur(radius * 0.85)))
		outer = field >= 40
		canvas = np.zeros_like(arr)
		rim = outer & ~body_m
		canvas[rim] = CREAM
		base = arr.copy()
		base[~body_m] = 0
		sticker = Image.alpha_composite(Image.fromarray(canvas, "RGBA"), Image.fromarray(base, "RGBA"))
		return sticker
	# harden existing cream
	out = arr.copy()
	soft = (a > 0) & (a < 240) & ~cream & ~body_m
	out[soft] = 0
	return Image.fromarray(out, "RGBA")


def fit_height(img: Image.Image, target_h: int = TARGET_H) -> Image.Image:
	w, h = img.size
	if h == target_h:
		return img
	nw = max(1, int(round(w * (target_h / h))))
	return img.resize((nw, target_h), Image.Resampling.LANCZOS)


def rotate_sticker(img: Image.Image, degrees: float) -> Image.Image:
	"""Rotate with transparent expand; keep crisp."""
	# upscale for rotate quality
	hi = img.resize((img.size[0] * 2, img.size[1] * 2), Image.Resampling.LANCZOS)
	rot = hi.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True, fillcolor=(0, 0, 0, 0))
	rot = rot.resize((max(1, rot.size[0] // 2), max(1, rot.size[1] // 2)), Image.Resampling.LANCZOS)
	bb = rot.getbbox()
	if bb:
		rot = rot.crop(bb)
	return ensure_white_outline(rot, OUTLINE)


def to_canvas(img: Image.Image, canvas: tuple[int, int] | None = None) -> Image.Image:
	bb = img.getbbox()
	if bb:
		img = img.crop(bb)
	if canvas is None:
		# pad to common size later
		return img
	cw, ch = canvas
	out = Image.new("RGBA", canvas, (0, 0, 0, 0))
	x = (cw - img.size[0]) // 2
	y = (ch - img.size[1]) // 2
	out.alpha_composite(img, (max(0, x), max(0, y)))
	return out


def main() -> None:
	base = extract_concept()
	base = ensure_white_outline(base, OUTLINE)
	base = fit_height(base, TARGET_H)

	idle = base
	up = fit_height(rotate_sticker(base, 14), TARGET_H)  # nose up
	down = fit_height(rotate_sticker(base, -14), TARGET_H)  # nose down

	# common canvas = max extents
	cw = max(idle.size[0], up.size[0], down.size[0]) + 4
	ch = max(idle.size[1], up.size[1], down.size[1]) + 4
	# keep even
	cw += cw % 2
	ch += ch % 2

	mapping = {
		"Plane.png": idle,
		"PlaneUp.png": up,
		"PlaneDown.png": down,
	}
	for name, im in mapping.items():
		out = to_canvas(im, (cw, ch))
		out.save(DST / name, optimize=True)
		out.save(CONCEPT_DIR / f"sticker_{name}", optimize=True)
		print("saved", name, out.size, out.getchannel("A").getbbox())

	# preview
	imgs = [Image.open(DST / n).convert("RGBA") for n in mapping]
	W = sum(i.size[0] for i in imgs) + 40
	H = max(i.size[1] for i in imgs) + 20
	sheet = Image.new("RGBA", (W, H), (30, 30, 34, 255))
	x = 10
	for im in imgs:
		sheet.alpha_composite(im, (x, (H - im.size[1]) // 2))
		x += im.size[0] + 10
	sheet.save(ASSETS / "planes_exact_concept_sheet.png")
	print("preview", ASSETS / "planes_exact_concept_sheet.png", "canvas", cw, ch)


if __name__ == "__main__":
	main()
