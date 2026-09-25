class_name DebugOverlay
extends CanvasLayer
## F3 debug overlay (design D15/D10; proves the pooling requirements'
## "no unbounded growth" claim): FPS, total node count, alive-enemy
## count, and per-pool usage. Debug builds only -- frees itself
## immediately in a release export. Hidden by default; [code]
## toggle_debug[/code] (F3) toggles visibility.

@onready var _label: Label = $Label

var _wave_director: WaveDirector = null
var _pools: Dictionary = {}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible
		get_viewport().set_input_as_handled()


## Set by the owning scene (design D10-style caller-owns-wiring).
func set_wave_director(wave_director: WaveDirector) -> void:
	_wave_director = wave_director


## Set by the owning scene. [param pools] maps a display name (for
## example [code]"PlayerBullet"[/code]) to its [NodePool].
func set_pools(pools: Dictionary) -> void:
	_pools = pools


func _process(_delta: float) -> void:
	if not visible:
		return
	var lines: PackedStringArray = []
	lines.append("FPS: %d" % Engine.get_frames_per_second())
	lines.append("Nodes: %d" % get_tree().get_node_count())
	if _wave_director != null:
		lines.append("Enemies alive: %d" % _wave_director.get_alive_enemy_count())
	for pool_name in _pools:
		var pool: NodePool = _pools[pool_name]
		lines.append("%s: %d/%d" % [pool_name, pool.get_active_count(), pool.max_size])
	_label.text = "\n".join(lines)
