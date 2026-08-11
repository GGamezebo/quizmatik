"""Add thick creamy sticker outline to balloons; slice plane sheet; install assets."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageChops

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
PLANE_DST = ROOT / "src" / "features" / "plane"
ANSWER_DST = ROOT / "src" / "features" / "answer"
CONCEPT_PLANE = ROOT / "concepts" / "notebook_pencil"
SHEET = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\plane_sticker_sheet.png")

WHITE = (255, 255, 255, 255)
CREAM = (252, 248, 240, 255)


def flood_clear_bg(img: Image.Image, tol: int = 42) -> Image.Image:
	rgba = img.convert("RGBA")
	w, h = rgba.size
	px = rgba.load()
	visited = set()
	stack: list[tuple[int, int]] = []
	for x in range(0, w, 5):
		stack += [(x, 0), (x, h - 1)]
	for y in range(0, h, 5):
		stack += [(0, y), (w - 1, y)]
	seeds = []
	for sx, sy in stack:
		r, g, b, a = px[sx, sy]
		if max(r, g, b) <= tol + 25:
			seeds.append((sx, sy))
	stack = seeds
	for s in seeds:
		visited.add(s)
	while stack:
		x, y = stack.pop()
		r, g, b, a = px[x, y]
		if max(r, g, b) > tol + 30 and a > 0:
			if max(r, g, b) < tol + 60:
				px[x, y] = (0, 0, 0, 0)
			continue
		px[x, y] = (0, 0, 0, 0)
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
				nr, ng, nb, na = px[nx, ny]
				if max(nr, ng, nb) <= tol + 60:
					visited.add((nx, ny))
					stack.append((nx, ny))
	return rgba


def add_sticker_outline(img: Image.Image, radius: int = 8, color=CREAM) -> Image.Image:
	"""Dilate alpha and fill with cream white behind the sprite."""
	rgba = img.convert("RGBA")
	alpha = rgba.getchannel("A")
	# Expand alpha
	expanded = alpha
	for _ in range(radius):
		expanded = expanded.filter(ImageFilter.MaxFilter(3))
	# Soft outer edge
	soft = expanded.filter(ImageFilter.GaussianBlur(0.6))
	outline = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
	op = outline.load()
	ap = soft.load()
	w, h = rgba.size
	cr, cg, cb, _ = color
	for y in range(h):
		for x in range(w):
			a = ap[x, y]
			if a > 8:
				op[x, y] = (cr, cg, cb, a)
	# Keep original on top
	out = Image.alpha_composite(outline, rgba)
	return out


def components(mask: np.ndarray) -> list[tuple[int, int, int, int]]:
	h, w = mask.shape
	visited = np.zeros_like(mask, dtype=bool)
	boxes = []
	for y in range(h):
		for x in range(w):
			if not mask[y, x] or visited[y, x]:
				continue
			stack = [(x, y)]
			visited[y, x] = True
			min_x = max_x = x
			min_y = max_y = y
			count = 0
			while stack:
				cx, cy = stack.pop()
				count += 1
				min_x = min(min_x, cx)
				max_x = max(max_x, cx)
				min_y = min(min_y, cy)
				max_y = max(max_y, cy)
				for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
					if 0 <= nx < w and 0 <= ny < h and mask[ny, nx] and not visited[ny, nx]:
						visited[ny, nx] = True
						stack.append((nx, ny))
			if count < 800:
				continue
			boxes.append((min_x, min_y, max_x + 1, max_y + 1))
	return boxes


def process_planes_from_sheet() -> bool:
	if not SHEET.exists():
		print("sheet missing", SHEET)
		return False
	img = flood_clear_bg(Image.open(SHEET))
	arr = np.array(img)
	mask = arr[:, :, 3] > 20
	boxes = sorted(components(mask), key=lambda b: b[0])
	print("plane components", len(boxes), boxes)
	names = ["Plane.png", "PlaneUp.png", "PlaneDown.png"]
	# Sheet order: idle, up, down — map to game names
	mapping = {
		"Plane.png": 0,
		"PlaneUp.png": 1,
		"PlaneDown.png": 2,
	}
	if len(boxes) < 3:
		# fallback: use concept planes + outline
		return False
	for name, idx in mapping.items():
		box = boxes[idx]
		pad = 10
		x0, y0, x1, y1 = box
		x0 = max(0, x0 - pad)
		y0 = max(0, y0 - pad)
		x1 = min(img.size[0], x1 + pad)
		y1 = min(img.size[1], y1 + pad)
		crop = img.crop((x0, y0, x1, y1))
		# ensure sticker rim is thick enough
		crop = add_sticker_outline(crop, radius=6)
		bbox = crop.getbbox()
		if bbox:
			crop = crop.crop(bbox)
		# normalize height ~108 like old assets, keep aspect
		tw = int(288 * crop.size[0] / max(1, crop.size[1]) * (108 / 108))
		# target similar footprint
		scale = 108 / crop.size[1]
		nw = max(1, int(crop.size[0] * scale))
		nh = 108
		crop = crop.resize((nw, nh), Image.Resampling.LANCZOS)
		crop.save(PLANE_DST / name, optimize=True)
		crop.save(CONCEPT_PLANE / f"sticker_{name}", optimize=True)
		print("saved plane", name, crop.size)
	return True


def process_planes_from_concepts() -> None:
	pairs = [
		(CONCEPT_PLANE / "plane_idle.png", "Plane.png"),
		(CONCEPT_PLANE / "plane_up.png", "PlaneUp.png"),
		(CONCEPT_PLANE / "plane_down.png", "PlaneDown.png"),
	]
	for src, name in pairs:
		img = flood_clear_bg(Image.open(src))
		img = add_sticker_outline(img, radius=7)
		bbox = img.getbbox()
		if bbox:
			img = img.crop(bbox)
		scale = 108 / img.size[1]
		img = img.resize((max(1, int(img.size[0] * scale)), 108), Image.Resampling.LANCZOS)
		img.save(PLANE_DST / name, optimize=True)
		print("fallback plane", name, img.size)


def process_balloons() -> None:
	path = ANSWER_DST / "balloons_atlas.png"
	img = Image.open(path).convert("RGBA")
	w, h = img.size
	cols, rows = 5, 3
	cw, ch = w // cols, h // rows
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	for row in range(rows):
		for col in range(cols):
			idx = row * cols + col
			cell = img.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
			# Remove black bg leftovers inside cell
			cell = flood_clear_bg(cell, tol=35)
			# Pad so outline fits
			pad = 14
			padded = Image.new("RGBA", (cell.size[0] + pad * 2, cell.size[1] + pad * 2), (0, 0, 0, 0))
			padded.paste(cell, (pad, pad), cell)
			sticker = add_sticker_outline(padded, radius=9, color=CREAM)
			# Fit back into cell
			bbox = sticker.getbbox()
			if bbox:
				sticker = sticker.crop(bbox)
			# scale to fit cell with margin
			margin = 4
			max_w = cw - margin * 2
			max_h = ch - margin * 2
			sw, sh = sticker.size
			scale = min(max_w / sw, max_h / sh, 1.0)
			nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
			sticker = sticker.resize((nw, nh), Image.Resampling.LANCZOS)
			ox = col * cw + (cw - nw) // 2
			oy = row * ch + (ch - nh) // 2
			out.alpha_composite(sticker, (ox, oy))
			print("balloon", idx, sticker.size)
	out.save(path, optimize=True)
	(CONCEPT_PLANE / "balloons_atlas_sticker.png").parent.mkdir(parents=True, exist_ok=True)
	out.save(CONCEPT_PLANE / "balloons_atlas_sticker.png", optimize=True)
	print("balloons saved", out.size)


def main() -> None:
	ok = process_planes_from_sheet()
	if not ok:
		process_planes_from_concepts()
	process_balloons()
	print("done")


if __name__ == "__main__":
	main()
