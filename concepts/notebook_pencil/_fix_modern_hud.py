"""Fix chroma via edge flood-fill; synthesize lane dash + missing discrete button."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

HUD = Path(r"d:\Godot\MyProjects\quizmatik\src\ui\hud")
CONCEPT = Path(r"d:\Godot\MyProjects\quizmatik\concepts\notebook_pencil\hud_modern")
ATLAS = Path(r"d:\Godot\MyProjects\quizmatik\concepts\notebook_pencil\ui_atlas_modern.png")


def flood_clear_bg(img: Image.Image, tol: int = 48) -> Image.Image:
	rgba = img.convert("RGBA")
	w, h = rgba.size
	px = rgba.load()
	seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
	# also seed along edges every few pixels
	for x in range(0, w, 8):
		seeds.append((x, 0))
		seeds.append((x, h - 1))
	for y in range(0, h, 8):
		seeds.append((0, y))
		seeds.append((w - 1, y))

	visited = set()
	stack = []
	for sx, sy in seeds:
		r, g, b, a = px[sx, sy]
		if max(r, g, b) <= tol + 20:
			stack.append((sx, sy))
			visited.add((sx, sy))

	while stack:
		x, y = stack.pop()
		r, g, b, a = px[x, y]
		if max(r, g, b) > tol + 25 and a > 0:
			# soft fringe near black
			if max(r, g, b) < tol + 55:
				px[x, y] = (r, g, b, 0)
			continue
		px[x, y] = (0, 0, 0, 0)
		for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
			if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in visited:
				nr, ng, nb, na = px[nx, ny]
				if max(nr, ng, nb) <= tol + 55:
					visited.add((nx, ny))
					stack.append((nx, ny))
	return rgba


def make_lane_dash_strip(width: int = 1024, height: int = 64) -> Image.Image:
	img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	cy = height // 2
	dash_w = 28
	gap = 16
	thickness = 5
	x = 8
	graphite = (58, 68, 82, 220)
	graphite_soft = (58, 68, 82, 90)
	while x < width - 8:
		# slight wobble
		y0 = cy - thickness // 2 + ((x // 17) % 3) - 1
		y1 = y0 + thickness
		x1 = min(width - 8, x + dash_w)
		# soft understroke
		draw.rounded_rectangle([x - 1, y0 - 1, x1 + 1, y1 + 1], radius=3, fill=graphite_soft)
		draw.rounded_rectangle([x, y0, x1, y1], radius=2, fill=graphite)
		# tiny end caps like pencil lift
		draw.ellipse([x - 1, y0, x + 3, y1], fill=graphite)
		draw.ellipse([x1 - 3, y0, x1 + 1, y1], fill=graphite)
		x += dash_w + gap
	return img


def make_lane_selected_overlay(width: int = 256, height: int = 64) -> Image.Image:
	"""Short darker dash sample used conceptually; game draws procedurally."""
	img = make_lane_dash_strip(width, height)
	enh = ImageEnhance.Brightness(img)
	return enh.enhance(0.75)


def ensure_movement_discrete() -> None:
	src = HUD / "btn_movement_direct.png"
	if not src.exists():
		return
	# Prefer plane icon from atlas if we can find a component; else annotate direct button.
	atlas = Image.open(ATLAS).convert("RGBA") if ATLAS.exists() else None
	# Simple: take restart-sized circle from sound_on and redraw icon as 4 lane dashes + tiny triangle plane
	base = Image.open(src).convert("RGBA")
	# Clear icon area roughly — redraw on cream circle from sound_on
	template = Image.open(HUD / "btn_sound_on.png").convert("RGBA")
	out = template.copy()
	# wipe center by painting cream disc
	px = out.load()
	w, h = out.size
	cx, cy = w // 2, h // 2
	r_inner = int(min(w, h) * 0.34)
	for y in range(h):
		for x in range(w):
			if (x - cx) ** 2 + (y - cy) ** 2 <= r_inner ** 2:
				# keep paper tint from nearby pixel average
				pr, pg, pb, pa = px[x, y]
				if pa > 0:
					px[x, y] = (min(255, pr + 8), min(255, pg + 6), min(255, pb + 4), pa)
				else:
					px[x, y] = (243, 230, 200, 255)
	draw = ImageDraw.Draw(out)
	g = (45, 52, 64, 230)
	# four horizontal lane dashes
	for i, yy in enumerate((-28, -10, 8, 26)):
		y = cy + yy
		draw.rounded_rectangle([cx - 34, y - 2, cx + 18, y + 2], radius=2, fill=g)
	# tiny plane triangle on second lane
	plane_y = cy - 10
	draw.polygon([(cx + 20, plane_y), (cx + 36, plane_y - 7), (cx + 36, plane_y + 7)], fill=g)
	out = flood_clear_bg(out, tol=30)
	out.save(HUD / "btn_movement_discrete.png", optimize=True)
	CONCEPT.mkdir(parents=True, exist_ok=True)
	out.save(CONCEPT / "btn_movement_discrete.png", optimize=True)
	print("wrote movement_discrete", out.size)


def main() -> None:
	CONCEPT.mkdir(parents=True, exist_ok=True)
	for name in [
		"score_frame.png",
		"question_banner.png",
		"heart.png",
		"btn_sound_on.png",
		"btn_sound_off.png",
		"btn_movement_direct.png",
		"btn_restart.png",
		"btn_exit.png",
	]:
		path = HUD / name
		if not path.exists():
			print("skip missing", name)
			continue
		fixed = flood_clear_bg(Image.open(path))
		# trim
		bbox = fixed.getbbox()
		if bbox:
			fixed = fixed.crop(bbox)
		fixed.save(path, optimize=True)
		fixed.save(CONCEPT / name, optimize=True)
		print("fixed", name, fixed.size)

	lane = make_lane_dash_strip()
	lane.save(HUD / "lane_dash_strip.png", optimize=True)
	lane.save(CONCEPT / "lane_dash_strip.png", optimize=True)
	print("lane", lane.size)

	# single dash tile for atlas completeness
	tile = make_lane_dash_strip(96, 48)
	tile.save(HUD / "lane_dash_tile.png", optimize=True)
	tile.save(CONCEPT / "lane_dash_tile.png", optimize=True)

	ensure_movement_discrete()
	print("done")


if __name__ == "__main__":
	main()
