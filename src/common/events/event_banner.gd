class_name EventBanner
extends Resource

## Main-menu event button look (`EventEntry`): picture, on-screen size and title color. An event has one
## (`SeasonalEvent.banner`); a run may bring its own (`EventWindow.banner`). The texts start 150 px from the left
## edge and the gift pile takes the right 200 px, so the art keeps its picture left of the texts.

@export var art: Texture2D
## Size of the whole button on screen (art stretched to it).
@export var size: Vector2 = Vector2(640, 140)
@export var title_color: Color = Color(0.98, 0.62, 0.22)
