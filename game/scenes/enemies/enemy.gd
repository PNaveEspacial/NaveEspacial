class_name Enemy
extends CharacterBody2D
## Pooled, data-driven enemy (design D13; enemies-and-waves spec
## capability). The same scene represents every [EnemyData] type: [method
## activate] re-targets the sprite's [AtlasTexture] region and the hurtbox
## [CircleShape2D]'s radius from [member EnemyData.texture]/[member
## EnemyData.frame]/[member EnemyData.hurt_radius] on every reuse.
##
## Movement switches on [member EnemyData.behavior] and uses the pure
## [Steering] primitives, eased through [method Steering.approach] so
## velocity changes stay accel-limited instead of snapping. CHASE seeks the
## target directly; KEEP_DISTANCE holds a range band and fires an aimed
## [code]EnemyBullet[/code] (with a telegraph flash) once past its spawn
## grace, only while fully inside the arena (design D13: "no instant
## snipes").
##
## Pooled-node contract (design D10): [method activate]/[method deactivate]
## and [signal despawn_requested]. Also implements the duck-typed
## [code]get_contact_damage() -> float[/code] contract [Player]'s Hurtbox
## has been calling since S8b.

signal despawn_requested

const _ATLAS_FRAME_SIZE := 32
const _ATLAS_COLUMNS := 4
const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var data: EnemyData
var target: Node2D = null
var bullet_pool: NodePool = null
var ai_rng: RandomNumberGenerator = null

var _hp: float = 0.0
var _speed: float = 0.0
var _strafe_sign: int = 1
var _spawn_time_left: float = 0.0
var _fire_time_left: float = 0.0
var _telegraph_time_left: float = 0.0
var _active: bool = false


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if _spawn_time_left > 0.0:
		_spawn_time_left = max(_spawn_time_left - delta, 0.0)
	match data.behavior:
		EnemyData.Behavior.CHASE:
			_tick_chase(delta)
		EnemyData.Behavior.KEEP_DISTANCE:
			_tick_keep_distance(delta)
	move_and_slide()


## Pooled-node contract (design D10 interfaces). [param params] keys:
## [code]"data"[/code] ([EnemyData], required), [code]"position"[/code]
## (Vector2), [code]"target"[/code] (Node2D, the player), the optional
## [code]"bullet_pool"[/code] ([NodePool], only used by KEEP_DISTANCE), the
## optional [code]"ai_rng"[/code] ([RandomNumberGenerator], the AI stream
## used to pick the strafe direction), and the difficulty scalers
## [code]"hp_multiplier"[/code]/[code]"speed_multiplier"[/code] (default
## 1.0).
func activate(params: Dictionary) -> void:
	data = params["data"]
	target = params.get("target")
	bullet_pool = params.get("bullet_pool")
	ai_rng = params.get("ai_rng")
	var hp_multiplier: float = params.get("hp_multiplier", 1.0)
	var speed_multiplier: float = params.get("speed_multiplier", 1.0)

	_hp = data.base_hp * hp_multiplier
	_speed = data.move_speed * speed_multiplier
	_strafe_sign = 1 if (ai_rng == null or ai_rng.randi_range(0, 1) == 0) else -1
	_spawn_time_left = data.spawn_grace_s
	_fire_time_left = data.fire_interval_s
	_telegraph_time_left = 0.0
	velocity = Vector2.ZERO

	global_position = params.get("position", Vector2.ZERO)
	_update_visual()

	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	_active = true
	reset_physics_interpolation()


func deactivate() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO


## Duck-typed contract [Player]'s Hurtbox calls on overlap (design D11's
## layer-based contact-damage rule).
func get_contact_damage() -> float:
	return data.contact_damage if data != null else 0.0


## Player bullets call this directly (design D11), the same way [Player]
## takes damage from enemy bullets.
func take_damage(amount: float) -> void:
	if not _active:
		return
	_hp -= amount
	if _hp <= 0.0:
		_die()


func _update_visual() -> void:
	var atlas := _sprite.texture as AtlasTexture
	atlas.atlas = data.texture
	var col := data.frame % _ATLAS_COLUMNS
	var row := data.frame / _ATLAS_COLUMNS
	atlas.region = Rect2(
		col * _ATLAS_FRAME_SIZE, row * _ATLAS_FRAME_SIZE, _ATLAS_FRAME_SIZE, _ATLAS_FRAME_SIZE
	)
	var shape := _collision_shape.shape as CircleShape2D
	shape.radius = data.hurt_radius


func _tick_chase(delta: float) -> void:
	if target == null:
		return
	var desired := Steering.seek(global_position, target.global_position, _speed)
	velocity = Steering.approach(velocity, desired, data.accel, delta)


func _tick_keep_distance(delta: float) -> void:
	if target == null:
		return
	var desired := Steering.keep_distance(
		global_position, target.global_position, data.range_min, data.range_max, _strafe_sign, _speed
	)
	velocity = Steering.approach(velocity, desired, data.accel, delta)
	_tick_fire(delta)


func _tick_fire(delta: float) -> void:
	if _spawn_time_left > 0.0:
		return
	if not _ARENA_RECT.has_point(global_position):
		return
	if _telegraph_time_left > 0.0:
		_telegraph_time_left -= delta
		if _telegraph_time_left <= 0.0:
			_fire_bullet()
		return
	_fire_time_left -= delta
	if _fire_time_left <= 0.0:
		_telegraph_time_left = data.telegraph_s
		_fire_time_left = data.fire_interval_s


func _fire_bullet() -> void:
	if bullet_pool == null or target == null:
		return
	var bullet: Node = bullet_pool.acquire()
	if bullet == null:
		return
	bullet.activate({
		"position": global_position,
		"direction": target.global_position - global_position,
		"speed": data.bullet_speed,
		"damage": data.bullet_damage,
	})


func _die() -> void:
	_active = false
	RunState.add_score(data.score_value)
	EventBus.enemy_killed.emit(data.id, global_position, data.score_value, data.xp_value)
	despawn_requested.emit()
