"""Rebuild plane (no flame, thin sticker rim, 288x108) + pencil flame atlas."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageEnhance, ImageOps

ROOT = Path(r"d:\Godot\MyProjects\quizmatik")
PLANE_DST = ROOT / "src" / "features" / "plane"
CONCEPT = ROOT / "concepts" / "notebook_pencil"
ORIG = CONCEPT / "_orig_planes"
SHEET = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\plane_nofire_sheet.png")
FLAME_AI = Path(r"C:\Users\Admin\.cursor\projects\d-Godot-MyProjects-quizmatik\assets\flame_pencil_atlas.png")

CANVAS = (288, 108)
CREAM = (252, 248, 240, 255)
OUTLINE_RADIUS = 2  # thin


def flood_clear_bg(img: Image.Image, tol: int = 40) -> Image.Image:
	rgba = img.convert("RGBA")
	w, h = rgba.size
	px = rgba.load()
	visited: set[tuple[int, int]] = set()
	stack: list[tuple[int, int]] = []
	for x in range(0, w, 4):
		stack += [(x, 0), (x, h - 1)]
	for y in range(0, h, 4):
		stack += [(0, y), (w - 1, y)]
	seeds = []
	for sx, sy in stack:
		r, g, b, a = px[sx, sy]
		if max(r, g, b) <= tol + 25:
			seeds.append((sx, sy))
	for s in seeds:
		visited.add(s)
	stack = list(seeds)
	while stack:
		x, y = stack.pop()
		r, g, b, a = px[x, y]
		if max(r, g, b) > tol + 28 and a > 0:
			if max(r, g, b) < tol + 55:
				px[x, y] = (0, 0, 0, 0)
			continue
		px[x, y] = (0, 0, 0, 0)
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
				nr, ng, nb, na = px[nx, ny]
				if max(nr, ng, nb) <= tol + 55:
					visited.add((nx, ny))
					stack.append((nx, ny))
	return rgba


def add_thin_outline(img: Image.Image, radius: int = OUTLINE_RADIUS, color=CREAM) -> Image.Image:
	rgba = img.convert("RGBA")
	alpha = rgba.getchannel("A")
	expanded = alpha
	for _ in range(max(1, radius)):
		expanded = expanded.filter(ImageFilter.MaxFilter(3))
	# slight soften
	soft = expanded.filter(ImageFilter.GaussianBlur(0.35))
	outline = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
	op = outline.load()
	ap = soft.load()
	cr, cg, cb, _ = color
	w, h = rgba.size
	for y in range(h):
		for x in range(w):
			a = ap[x, y]
			if a > 12:
				op[x, y] = (cr, cg, cb, min(255, int(a)))
	return Image.alpha_composite(outline, rgba)


def components(mask: np.ndarray, min_count: int = 600) -> list[tuple[int, int, int, int]]:
	h, w = mask.shape
	visited = np.zeros_like(mask, dtype=bool)
	boxes: list[tuple[int, int, int, int]] = []
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
			if count >= min_count:
				boxes.append((min_x, min_y, max_x + 1, max_y + 1))
	return boxes


def fit_on_canvas(sprite: Image.Image, canvas_size=CANVAS, ref_bbox: tuple[int, int, int, int] | None = None) -> Image.Image:
	"""Scale sprite to similar content size as original, place on transparent 288x108."""
	cw, ch = canvas_size
	sprite = sprite.convert("RGBA")
	bbox = sprite.getbbox()
	if not bbox:
		return Image.new("RGBA", canvas_size, (0, 0, 0, 0))
	sprite = sprite.crop(bbox)
	# Target content height ~ original content height (leave margin for thin outline)
	if ref_bbox:
		ref_h = ref_bbox[3] - ref_bbox[1]
		ref_w = ref_bbox[2] - ref_bbox[0]
	else:
		ref_h, ref_w = 96, 260
	sw, sh = sprite.size
	scale = min((ref_w) / sw, (ref_h) / sh, (cw - 8) / sw, (ch - 6) / sh)
	nw = max(1, int(sw * scale))
	nh = max(1, int(sh * scale))
	sprite = sprite.resize((nw, nh), Image.Resampling.LANCZOS)
	out = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
	# Match original content placement if possible
	if ref_bbox:
		ox = ref_bbox[0] + (ref_w - nw) // 2
		oy = ref_bbox[1] + (ref_h - nh) // 2
	else:
		ox = (cw - nw) // 2
		oy = (ch - nh) // 2
	ox = max(0, min(cw - nw, ox))
	oy = max(0, min(ch - nh, oy))
	out.alpha_composite(sprite, (ox, oy))
	return out


def process_planes() -> None:
	img = flood_clear_bg(Image.open(SHEET))
	arr = np.array(img)
	boxes = sorted(components(arr[:, :, 3] > 20), key=lambda b: b[0])
	print("plane boxes", boxes)
	# L->R: idle, up, down
	names = ["Plane.png", "PlaneUp.png", "PlaneDown.png"]
	if len(boxes) < 3:
		raise RuntimeError(f"expected 3 planes, got {len(boxes)}")
	for name, box in zip(names, boxes):
		x0, y0, x1, y1 = box
		pad = 8
		crop = img.crop((max(0, x0 - pad), max(0, y0 - pad), min(img.size[0], x1 + pad), min(img.size[1], y1 + pad)))
		crop = add_thin_outline(crop, radius=OUTLINE_RADIUS)
		ref = Image.open(ORIG / name).convert("RGBA")
		ref_bbox = ref.getchannel("A").getbbox()
		out = fit_on_canvas(crop, CANVAS, ref_bbox)
		out.save(PLANE_DST / name, optimize=True)
		out.save(CONCEPT / f"sticker_{name}", optimize=True)
		print("saved", name, out.size, "content", out.getchannel("A").getbbox())


def pencilize_cell(cell: Image.Image) -> Image.Image:
	"""Restyle original flame cell: matte pencil look + thin white rim."""
	rgba = cell.convert("RGBA")
	# chroma near-black to alpha
	px = rgba.load()
	w, h = rgba.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if r < 20 and g < 20 and b < 30:
				px[x, y] = (0, 0, 0, 0)
	# boost texture / reduce glow smoothness
	rgb = rgba.convert("RGB")
	rgb = ImageEnhance.Color(rgb).enhance(1.15)
	rgb = ImageEnhance.Contrast(rgb).enhance(1.2)
	# light posterize for crayon bands
	rgb = ImageOps.posterize(rgb, 5)
	# grain
	arr = np.array(rgb).astype(np.int16)
	noise = np.random.default_rng(0).integers(-12, 13, arr.shape, dtype=np.int16)
	arr = np.clip(arr + noise, 0, 255).astype(np.uint8)
	rgb = Image.fromarray(arr, "RGB")
	out = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
	out.paste(rgb, mask=rgba.getchannel("A"))
	# thin white outline
	out = add_thin_outline(out, radius=2, color=CREAM)
	return out


def process_flame_from_original() -> None:
	"""Keep original animation shapes; restyle + thin outline. Same 300x161 atlas."""
	src = Image.open(ORIG / "flame.png").convert("RGBA")
	w, h = 300, 161
	out = Image.new("RGBA", (w, h), (0, 0, 0, 255))  # black bg like original atlas
	# Process all 3x4 cells for consistency; game uses middle column
	cols, rows = 3, 4
	cw, ch = 100, 40
	for row in range(rows):
		for col in range(cols):
			x0, y0 = col * cw, row * ch
			if y0 + ch > src.size[1]:
				continue
			cell = src.crop((x0, y0, x0 + cw, min(src.size[1], y0 + ch)))
			# pad to 100x40 if bottom row short
			if cell.size[1] < ch:
				pad = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
				pad.paste(cell, (0, 0))
				cell = pad
			styled = pencilize_cell(cell)
			# composite onto black cell
			cell_bg = Image.new("RGBA", (cw, ch), (0, 0, 0, 255))
			# styled may be larger due to outline — fit
			bbox = styled.getbbox()
			if bbox:
				styled = styled.crop(bbox)
			sw, sh = styled.size
			scale = min(cw / sw, ch / sh, 1.0)
			# keep similar footprint — slight shrink for outline room
			scale = min(scale, 0.92)
			nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
			styled = styled.resize((nw, nh), Image.Resampling.LANCZOS)
			ox = (cw - nw) // 2
			oy = (ch - nh) // 2
			cell_bg.alpha_composite(styled, (ox, oy))
			# flatten onto black atlas (no alpha in final? original had RGBA with black bg)
			out.paste(cell_bg.convert("RGB"), (x0, y0))
	# ensure bottom pixel row exists (161 vs 160)
	final = Image.new("RGBA", (300, 161), (0, 0, 0, 255))
	final.paste(out.convert("RGBA"), (0, 0))
	final.save(PLANE_DST / "flame.png", optimize=True)
	final.save(CONCEPT / "flame_pencil.png", optimize=True)
	print("flame saved", final.size)


def process_flame_from_ai_fallback() -> None:
	"""If needed: pack AI atlas into 300x161 grid."""
	img = flood_clear_bg(Image.open(FLAME_AI), tol=45)
	# build black atlas and place 12 components roughly in grid
	arr = np.array(img)
	boxes = sorted(components(arr[:, :, 3] > 25, min_count=80), key=lambda b: (b[1] // 40, b[0]))
	print("ai flame components", len(boxes))
	out = Image.new("RGBA", (300, 161), (0, 0, 0, 255))
	for i, box in enumerate(boxes[:12]):
		row, col = divmod(i, 3) if False else (i // 3, i % 3)
		# better: sort already by row approx
		pass
	# Use row-major from sorted by (cy, cx)
	enriched = []
	for b in boxes:
		cx = (b[0] + b[2]) / 2
		cy = (b[1] + b[3]) / 2
		enriched.append((cy, cx, b))
	enriched.sort()
	for i, (_, __, box) in enumerate(enriched[:12]):
		row, col = i // 3, i % 3
		crop = img.crop(box)
		crop = add_thin_outline(crop, radius=2)
		bbox = crop.getbbox()
		if bbox:
			crop = crop.crop(bbox)
		cw, ch = 100, 40
		sw, sh = crop.size
		scale = min((cw - 4) / sw, (ch - 4) / sh)
		nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
		crop = crop.resize((nw, nh), Image.Resampling.LANCZOS)
		cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 255))
		cell.alpha_composite(crop, ((cw - nw) // 2, (ch - nh) // 2))
		out.paste(cell.convert("RGB"), (col * 100, row * 40))
	out.save(PLANE_DST / "flame.png", optimize=True)
	print("flame from AI", out.size)


def main() -> None:
	process_planes()
	process_flame_from_original()
	print("done")


if __name__ == "__main__":
	main()
