extends Node2D
## Crosshair rendered inside the internal-resolution viewport (design D5),
## so it scales and letterboxes exactly like every other sprite and never
## drifts into the letterbox bars: [method Viewport.get_mouse_position]
## already reports stretched, internal-resolution coordinates.

const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _process(_delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position().floor()
	position = Vector2(
		clamp(mouse_pos.x, _ARENA_RECT.position.x, _ARENA_RECT.end.x),
		clamp(mouse_pos.y, _ARENA_RECT.position.y, _ARENA_RECT.end.y)
	)
