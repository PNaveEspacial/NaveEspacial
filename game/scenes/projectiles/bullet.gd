class_name Bullet
extends Area2D
## Pooled, linear-motion bullet (design D10, D12). Shared by [code]
## player_bullet.tscn[/code] and [code]enemy_bullet.tscn[/code], which
## differ only in collision layer/mask and visuals (design D11).
##
## Damage is applied directly through the physics-layer collision (design
## D11's layer-based rule), not a manual bounding-box check: whichever body
## this bullet's [member collision_mask] lets it detect receives [method
## take_damage] if it defines one.

signal despawn_requested

## Seconds this bullet survives before self-despawning even if it never
## leaves the arena or hits anything. Overridable per-activation.
@export var lifetime_s: float = 1.5

## The margin, in pixels beyond the 640x360 internal arena, at which an
## in-flight bullet is considered off-arena and released (File Changes:
## "release off-arena or at lifetime").
const _ARENA_MARGIN := 32.0
const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)

var damage: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _time_left: float = 0.0
var _active: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0 or not _ARENA_RECT.grow(_ARENA_MARGIN).has_point(global_position):
		_request_despawn()


## Pooled-node contract (design D10 interfaces). [param params] keys:
## [code]"position"[/code] (Vector2), [code]"direction"[/code] (Vector2,
## need not be normalized), [code]"speed"[/code] (float),
## [code]"damage"[/code] (float), and the optional [code]"lifetime_s"[/code]
## override.
func activate(params: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = params.get("position", Vector2.ZERO)
	var direction: Vector2 = params.get("direction", Vector2.UP)
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	direction = direction.normalized()
	var speed: float = params.get("speed", 0.0)
	_velocity = direction * speed
	rotation = direction.angle() + PI / 2.0
	_time_left = params.get("lifetime_s", lifetime_s)
	damage = params.get("damage", 0.0)
	_active = true
	visible = true
	reset_physics_interpolation()


func deactivate() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_request_despawn()


func _request_despawn() -> void:
	if not _active:
		return
	_active = false
	despawn_requested.emit()
