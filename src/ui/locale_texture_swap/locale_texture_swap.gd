class_name LocaleTextureSwap
extends Node

## Art with baked text: swaps `target.texture` by UI language (live, on language switch).
## Language missing in `textures` → the texture set in the scene (Russian source art).

@export var target: TextureRect
## Language code (`GameLocale.SUPPORTED`) → texture variant.
@export var textures: Dictionary[String, Texture2D] = {}

var _source: Texture2D


func _ready() -> void:
	if target != null:
		_source = target.texture
	_apply()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply()


func _apply() -> void:
	if target == null:
		return
	target.texture = textures.get(TranslationServer.get_locale().get_slice("_", 0), _source)
