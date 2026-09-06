"""Emit balloon_pop.tscn matching make_balloon_pop.py constants."""
from __future__ import annotations

import os

FRAMES = 24
CELL = 64
SPEED = 20.0
SCALE = 3.72

OUT = os.path.normpath(
    os.path.join(os.path.dirname(__file__), "..", "src", "features", "answer", "balloon_pop.tscn")
)


def main() -> None:
    lines = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Texture2D" path="res://src/features/answer/balloon_pop_atlas.png" id="1_atlas"]',
        '[ext_resource type="Script" path="res://src/features/answer/balloon_pop.gd" id="2_script"]',
        "",
    ]
    for i in range(FRAMES):
        lines += [
            f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]',
            'atlas = ExtResource("1_atlas")',
            f"region = Rect2({i * CELL}, 0, {CELL}, {CELL})",
            "",
        ]

    frame_entries = []
    for i in range(FRAMES):
        frame_entries.append(
            "{\n"
            '"duration": 1.0,\n'
            f'"texture": SubResource("AtlasTexture_{i}")\n'
            "}"
        )
    frames_joined = ",\n".join(frame_entries)

    lines += [
        '[sub_resource type="SpriteFrames" id="SpriteFrames_pop"]',
        "animations = [{",
        '"frames": [' + frames_joined + "],",
        '"loop": false,',
        '"name": &"default",',
        f'"speed": {SPEED}',
        "}]",
        "",
        '[node name="BalloonPop" type="AnimatedSprite2D"]',
        f"scale = Vector2({SCALE}, {SCALE})",
        'sprite_frames = SubResource("SpriteFrames_pop")',
        'autoplay = "default"',
        'script = ExtResource("2_script")',
        "",
    ]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
