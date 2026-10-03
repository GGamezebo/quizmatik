extends Control

## HUD chip «ДИРИЖАБЛЬ ▮▮▮» under the question banner: boss armor plates left.
## Pops in on `ev_boss_appeared`, dims a pip per `ev_boss_hit`, fades out on `ev_boss_defeated`.

@export var game_events: GameEvents
@export var pips: Container
## One armor pip (editor template).
@export var pip_scene: PackedScene
@export_range(0.0, 1.0) var lost_pip_alpha: float = 0.2

var _listener: EventListener = EventListener.new()
var _tween: Tween


func _ready() -> void:
	visible = false
	if game_events:
		_listener.add(game_events.ev_boss_appeared, _on_boss_appeared)
		_listener.add(game_events.ev_boss_hit, _on_boss_hit)
		_listener.add(game_events.ev_boss_defeated, _on_boss_defeated)


func _exit_tree() -> void:
	_listener.deinit()


func _on_boss_appeared(armor: int) -> void:
	for child in pips.get_children():
		pips.remove_child(child)
		child.queue_free()
	for i in armor:
		pips.add_child(pip_scene.instantiate())
	visible = true
	modulate.a = 1.0
	_pop.call_deferred()


func _on_boss_hit(armor_left: int) -> void:
	if armor_left < 0 or armor_left >= pips.get_child_count():
		return
	var pip := pips.get_child(armor_left) as Control
	pip.pivot_offset = pip.size * 0.5
	var tween := pip.create_tween().set_parallel(true)
	tween.tween_property(pip, "modulate:a", lost_pip_alpha, 0.25)
	tween.tween_property(pip, "scale", Vector2(1.5, 1.5), 0.1)
	tween.chain().tween_property(pip, "scale", Vector2.ONE, 0.2)


func _on_boss_defeated() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(hide)


func _pop() -> void:
	if _tween:
		_tween.kill()
	pivot_offset = size * 0.5
	scale = Vector2.ZERO
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.35)
