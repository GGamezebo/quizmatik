class_name PaywallValleyCard
extends VBoxContainer

## A valley the purchase opens: landscape, name, what is inside.

@export var art_rect: TextureRect
@export var name_label: Label
@export var info_label: Label


func setup(container_id: String, title: String, info: String) -> void:
	art_rect.texture = LevelPackArt.get_art(container_id)
	name_label.text = title
	info_label.text = info
