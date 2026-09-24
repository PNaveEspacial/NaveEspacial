extends CharacterBody2D
## Twin-stick player ship, movement and aim (design D4, D5; player-ship
## spec capability). Movement is free-arena WASD, clamped to the arena
## bounds. Aim targets the mouse cursor exactly; only the ship sprite's
## rotation is quantized to 16 directions (design D4) -- bullets fly at
## the unquantized angle once firing lands.
##
## Firing, health/i-frames, and death extend this same file in this
## slice's second work unit (S8.T3-T4), rather than replacing it.

const _ARENA_MARGIN := 8.0
const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)
const _AIM_DIRECTIONS := 16.0

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	_move(delta)
	_aim()


func _move(_delta: float) -> void:
	# move_and_slide() reads the physics tick's own delta internally; the
	# parameter exists only so callers can pass _physics_process's delta
	# uniformly across _move/_aim/_fire.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed: float = RunState.stats.value(StatBlock.Stat.MOVE_SPEED)
	velocity = input_dir * speed
	move_and_slide()
	global_position.x = clamp(
		global_position.x, _ARENA_RECT.position.x + _ARENA_MARGIN, _ARENA_RECT.end.x - _ARENA_MARGIN
	)
	global_position.y = clamp(
		global_position.y, _ARENA_RECT.position.y + _ARENA_MARGIN, _ARENA_RECT.end.y - _ARENA_MARGIN
	)


func _aim_direction() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() < 0.001:
		return Vector2.UP
	return to_mouse.normalized()


func _aim() -> void:
	var angle := _aim_direction().angle()
	var step := TAU / _AIM_DIRECTIONS
	_sprite.rotation = snapped(angle, step) + PI / 2.0
