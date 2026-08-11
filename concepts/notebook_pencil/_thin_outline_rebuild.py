"""Thin 1px sticker outline; planes 288x108 no flame; pencil flame atlas."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
PLANE_DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
ORIG = CONCEPT / "_orig_planes"
SHEET = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\plane_nofire_sheet.png")
CREAM = np.array([252, 248, 240, 230], dtype=np.uint8)


def flood_clear_bg(img: Image.Image, tol: int = 40) -> Image.Image:
	rgba = np.array(img.convert("RGBA"))
	h, w = rgba.shape[:2]
	seen = np.zeros((h, w), dtype=bool)
	q: deque[tuple[int, int]] = deque()
	for x in range(0, w, 3):
		for y in (0, h - 1):
			r, g, b, _a = rgba[y, x]
			if max(int(r), int(g), int(b)) <= tol + 25:
				q.append((y, x))
				seen[y, x] = True
	for y in range(0, h, 3):
		for x in (0, w - 1):
			r, g, b, _a = rgba[y, x]
			if max(int(r), int(g), int(b)) <= tol + 25 and not seen[y, x]:
				q.append((y, x))
				seen[y, x] = True
	while q:
		y, x = q.popleft()
		rgba[y, x] = (0, 0, 0, 0)
		for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
			if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx]:
				r, g, b, _a = rgba[ny, nx]
				if max(int(r), int(g), int(b)) <= tol + 55:
					seen[ny, nx] = True
					q.append((ny, nx))
	return Image.fromarray(rgba, "RGBA")


def alpha_distance(alpha: np.ndarray) -> np.ndarray:
	"""Approx Euclidean distance to transparent via chamfer."""
	h, w = alpha.shape
	inf = h + w + 5
	dist = np.where(alpha, inf, 0).astype(np.float32)
	for y in range(h):
		for x in range(w):
			if not alpha[y, x]:
				continue
			best = dist[y, x]
			if x > 0:
				best = min(best, dist[y, x - 1] + 1)
			if y > 0:
				best = min(best, dist[y - 1, x] + 1)
			if x > 0 and y > 0:
				best = min(best, dist[y - 1, x - 1] + 1.414)
			if x + 1 < w and y > 0:
				best = min(best, dist[y - 1, x + 1] + 1.414)
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
			if x + 1 < w and y + 1 < h:
				best = min(best, dist[y + 1, x + 1] + 1.414)
			if x > 0 and y + 1 < h:
				best = min(best, dist[y + 1, x - 1] + 1.414)
			dist[y, x] = best
	return dist


def strip_white_sticker(img: Image.Image, depth: float = 12.0, thresh: int = 200) -> Image.Image:
	arr = np.array(img.convert("RGBA"))
	alpha = arr[:, :, 3] > 10
	dist = alpha_distance(alpha)
	rgb = arr[:, :, :3]
	whitish = (rgb[:, :, 0] >= thresh) & (rgb[:, :, 1] >= thresh) & (rgb[:, :, 2] >= thresh - 8)
	remove = whitish & (dist <= depth) & alpha
	arr[remove] = (0, 0, 0, 0)
	return Image.fromarray(arr, "RGBA")


def outline_1px(img: Image.Image, color: np.ndarray = CREAM) -> Image.Image:
	arr = np.array(img.convert("RGBA"))
	alpha = arr[:, :, 3] > 10
	h, w = alpha.shape
	dil = alpha.copy()
	# binary dilation 1px
	for y in range(h):
		for x in range(w):
			if alpha[y, x]:
				continue
			for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
				if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx]:
					dil[y, x] = True
					break
	rim = dil & ~alpha
	canvas = np.zeros_like(arr)
	canvas[rim] = color
	m = arr[:, :, 3] > 10
	canvas[m] = arr[m]
	return Image.fromarray(canvas, "RGBA")


def components(mask: np.ndarray, min_count: int = 600) -> list[tuple[int, int, int, int]]:
	h, w = mask.shape
	seen = np.zeros_like(mask, dtype=bool)
	boxes: list[tuple[int, int, int, int]] = []
	for y in range(h):
		for x in range(w):
			if not mask[y, x] or seen[y, x]:
				continue
			q = deque([(y, x)])
			seen[y, x] = True
			min_x = max_x = x
			min_y = max_y = y
			count = 0
			while q:
				cy, cx = q.popleft()
				count += 1
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
					if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
						seen[ny, nx] = True
						q.append((ny, nx))
			if count >= min_count:
				boxes.append((min_x, min_y, max_x + 1, max_y + 1))
	return boxes


def process_planes() -> None:
	img = flood_clear_bg(Image.open(SHEET))
	boxes = sorted(components(np.array(img)[:, :, 3] > 20), key=lambda b: b[0])
	names = ["Plane.png", "PlaneUp.png", "PlaneDown.png"]
	for name, box in zip(names, boxes):
		x0, y0, x1, y1 = box
		crop = img.crop((max(0, x0 - 2), max(0, y0 - 2), min(img.size[0], x1 + 2), min(img.size[1], y1 + 2)))
		crop = strip_white_sticker(crop, depth=16, thresh=195)
		bb = crop.getbbox()
		if not bb:
			continue
		crop = crop.crop(bb)
		cw, ch = 288, 108
		sw, sh = crop.size
		scale = min((cw - 16) / sw, (ch - 14) / sh)
		crop = crop.resize((max(1, int(sw * scale)), max(1, int(sh * scale))), Image.Resampling.LANCZOS)
		crop = outline_1px(crop)
		out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
		out.alpha_composite(crop, ((cw - crop.size[0]) // 2, (ch - crop.size[1]) // 2))
		out.save(PLANE_DST / name, optimize=True)
		out.save(CONCEPT / f"sticker_{name}", optimize=True)
		print("plane", name, out.getchannel("A").getbbox())


def pencilize(cell: Image.Image) -> Image.Image:
	rgba = np.array(cell.convert("RGBA"))
	dark = (rgba[:, :, 0] < 20) & (rgba[:, :, 1] < 20) & (rgba[:, :, 2] < 30)
	rgba[dark, 3] = 0
	im = Image.fromarray(rgba, "RGBA")
	rgb = im.convert("RGB")
	rgb = ImageEnhance.Color(rgb).enhance(1.25)
	rgb = ImageEnhance.Contrast(rgb).enhance(1.3)
	rgb = ImageOps.posterize(rgb, 5)
	arr = np.array(rgb).astype(np.int16)
	noise = np.random.default_rng(2).integers(-16, 17, arr.shape, dtype=np.int16)
	rgb = Image.fromarray(np.clip(arr + noise, 0, 255).astype(np.uint8), "RGB")
	out = Image.new("RGBA", im.size, (0, 0, 0, 0))
	out.paste(rgb, mask=im.getchannel("A"))
	return out


def process_flame() -> None:
	src = Image.open(ORIG / "flame.png").convert("RGBA")
	final = Image.new("RGBA", (300, 161), (0, 0, 0, 255))
	for row in range(4):
		for col in range(3):
			x0, y0 = col * 100, row * 40
			cell = src.crop((x0, y0, x0 + 100, min(161, y0 + 40)))
			if cell.size[1] < 40:
				pad = Image.new("RGBA", (100, 40), (0, 0, 0, 0))
				pad.paste(cell, (0, 0))
				cell = pad
			styled = pencilize(cell)
			bb = styled.getbbox()
			if not bb:
				continue
			body = styled.crop(bb)
			sw, sh = body.size
			scale = min(94 / sw, 34 / sh, 1.0)
			body = body.resize((max(1, int(sw * scale)), max(1, int(sh * scale))), Image.Resampling.LANCZOS)
			body = outline_1px(body)
			cell_bg = Image.new("RGBA", (100, 40), (0, 0, 0, 255))
			bw, bh = body.size
			cell_bg.alpha_composite(body, ((100 - bw) // 2, (40 - bh) // 2))
			final.paste(cell_bg.convert("RGB"), (x0, y0))
	final.save(PLANE_DST / "flame.png", optimize=True)
	final.save(CONCEPT / "flame_pencil.png", optimize=True)
	print("flame", final.size)


def main() -> None:
	process_planes()
	process_flame()
	print("done")


if __name__ == "__main__":
	main()
