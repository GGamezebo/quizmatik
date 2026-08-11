"""Keep exact original plane silhouettes; concept pencil colors + thin white outline."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageEnhance, ImageOps

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
ORIG = ROOT / "concepts" / "notebook_pencil" / "_orig_planes"
DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
CREAM = np.array([252, 248, 240, 235], dtype=np.uint8)

# Concept pencil palette (RGB)
PURPLE = np.array([118, 72, 196], dtype=np.float32)
PURPLE_DARK = np.array([72, 38, 130], dtype=np.float32)
PURPLE_LIGHT = np.array([160, 110, 230], dtype=np.float32)
CYAN = np.array([110, 190, 230], dtype=np.float32)
CYAN_DARK = np.array([70, 140, 190], dtype=np.float32)
BLUE = np.array([55, 105, 210], dtype=np.float32)
BLUE_DARK = np.array([35, 70, 160], dtype=np.float32)
SILVER = np.array([210, 215, 225], dtype=np.float32)
SILVER_DARK = np.array([140, 145, 155], dtype=np.float32)
GREY = np.array([150, 155, 165], dtype=np.float32)


def strip_outline(arr: np.ndarray, white_thresh: int = 210, depth: float = 4.0) -> np.ndarray:
	"""Remove near-white outer sticker rim from original."""
	out = arr.copy()
	alpha = out[:, :, 3] > 10
	# chamfer-ish distance
	h, w = alpha.shape
	inf = float(h + w)
	dist = np.where(alpha, inf, 0.0).astype(np.float32)
	for y in range(h):
		for x in range(w):
			if not alpha[y, x]:
				continue
			best = dist[y, x]
			if x:
				best = min(best, dist[y, x - 1] + 1)
			if y:
				best = min(best, dist[y - 1, x] + 1)
			dist[y, x] = best
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			if not alpha[y, x]:
				continue
			best = dist[y, x]
			if x + 1 < w:
				best = min(best, dist[y, x + 1] + 1)
			if y + 1 < h:
				best = min(best, dist[y + 1, x] + 1)
			dist[y, x] = best
	rgb = out[:, :, :3]
	whitish = (rgb[:, :, 0] >= white_thresh) & (rgb[:, :, 1] >= white_thresh) & (rgb[:, :, 2] >= white_thresh - 10)
	out[whitish & (dist <= depth) & alpha] = (0, 0, 0, 0)
	return out


def outline_1px(arr: np.ndarray, color: np.ndarray = CREAM) -> np.ndarray:
	alpha = arr[:, :, 3] > 10
	h, w = alpha.shape
	dil = alpha.copy()
	ys, xs = np.where(alpha)
	for y, x in zip(ys, xs):
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w:
				dil[ny, nx] = True
	rim = dil & ~alpha
	canvas = np.zeros_like(arr)
	canvas[rim] = color
	m = arr[:, :, 3] > 10
	canvas[m] = arr[m]
	return canvas


def classify_pixel(r: float, g: float, b: float, y_rel: float, x_rel: float) -> str:
	"""Map original watercolor pixel into concept material bucket."""
	mx = max(r, g, b) + 1e-5
	mn = min(r, g, b)
	sat = (mx - mn) / mx
	lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
	# near white / silver nose
	if lum > 170 and sat < 0.25:
		return "silver"
	if lum > 140 and sat < 0.18:
		return "grey"
	# cyan / light blue tops
	if b > r + 15 and b > g - 10 and lum > 120 and g > 100:
		return "cyan"
	# strong blue wing
	if b > r + 25 and b >= g and lum < 160:
		return "blue"
	# purple / magenta body (r and b present)
	if r > 80 and b > 80:
		return "purple"
	if lum < 70:
		return "purple_dark"
	# fallback by vertical band
	if y_rel < 0.35:
		return "cyan"
	if y_rel > 0.7:
		return "blue"
	return "purple"


def mix(a: np.ndarray, b: np.ndarray, t: float) -> np.ndarray:
	return a * (1.0 - t) + b * t


def recolor(arr: np.ndarray) -> np.ndarray:
	h, w = arr.shape[:2]
	ys, xs = np.where(arr[:, :, 3] > 10)
	if len(ys) == 0:
		return arr
	y0, y1 = ys.min(), ys.max()
	x0, x1 = xs.min(), xs.max()
	yh = max(1, y1 - y0)
	xh = max(1, x1 - x0)
	out = arr.copy()
	rng = np.random.default_rng(7)
	for y, x in zip(ys, xs):
		r, g, b, a = arr[y, x]
		y_rel = (y - y0) / yh
		x_rel = (x - x0) / xh
		lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
		shade = 1.0 - abs(lum - 0.55) * 0.8
		bucket = classify_pixel(float(r), float(g), float(b), y_rel, x_rel)
		if bucket == "cyan":
			base = mix(CYAN_DARK, CYAN, shade)
		elif bucket == "blue":
			base = mix(BLUE_DARK, BLUE, shade)
		elif bucket == "silver":
			base = mix(SILVER_DARK, SILVER, shade)
		elif bucket == "grey":
			base = mix(SILVER_DARK, GREY, 0.5)
		elif bucket == "purple_dark":
			base = mix(PURPLE_DARK, PURPLE, 0.35)
		else:
			base = mix(PURPLE_DARK, PURPLE_LIGHT, shade)
		# pencil grain
		n = float(rng.integers(-14, 15))
		col = np.clip(base + n, 0, 255)
		out[y, x, 0] = int(col[0])
		out[y, x, 1] = int(col[1])
		out[y, x, 2] = int(col[2])
		out[y, x, 3] = a
	return out


def enhance_pencil(img: Image.Image) -> Image.Image:
	rgb = img.convert("RGB")
	rgb = ImageEnhance.Color(rgb).enhance(1.2)
	rgb = ImageEnhance.Contrast(rgb).enhance(1.15)
	rgb = ImageOps.posterize(rgb, 6)
	out = Image.new("RGBA", img.size, (0, 0, 0, 0))
	out.paste(rgb, mask=img.getchannel("A"))
	return out


def process_one(name: str) -> None:
	src = Image.open(ORIG / name).convert("RGBA")
	arr = np.array(src)
	arr = strip_outline(arr, white_thresh=205, depth=3.5)
	arr = recolor(arr)
	img = enhance_pencil(Image.fromarray(arr, "RGBA"))
	# slight sharpen of edges
	arr = np.array(img)
	arr = outline_1px(arr)
	out = Image.fromarray(arr, "RGBA")
	# ensure canvas size preserved
	if out.size != (288, 108):
		canvas = Image.new("RGBA", (288, 108), (0, 0, 0, 0))
		canvas.paste(out, (0, 0), out)
		out = canvas
	out.save(DST / name, optimize=True)
	out.save(CONCEPT / f"sticker_{name}", optimize=True)
	print("saved", name, out.size, out.getchannel("A").getbbox())


def main() -> None:
	for name in ("Plane.png", "PlaneUp.png", "PlaneDown.png"):
		process_one(name)
	print("done")


if __name__ == "__main__":
	main()
