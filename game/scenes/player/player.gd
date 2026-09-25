class_name Player
extends CharacterBody2D
## Twin-stick player ship (design D4, D5, D12; player-ship spec
## capability). Movement is free-arena WASD, clamped to the arena bounds.
## Aim/fire target the mouse cursor exactly; only the ship sprite's
## rotation is quantized to 16 directions (design D4) -- bullets fly at
## the unquantized angle.
##
## Damage comes from two sources, both layer-based (design D11), never a
## manual bounding-box check: enemy bullets call [method take_damage]
## directly through their own [code]body_entered[/code] handler, and
## [member _hurtbox] polls overlapping enemy bodies for contact damage
## every physics frame the player is not invulnerable. [Enemy] implements
## [code]get_contact_damage() -> float[/code]; this duck-types the same
## way [code]bullet.gd[/code] duck-types [code]take_damage[/code].
##
## XP pickup is the same pattern: [member _pickup_magnet] polls overlapping
## [code]pickup[/code]-layer areas every physics frame and calls [method
## Node.has_method]-guarded [code]collect()[/code] on each -- [XpOrb]
## implements it.

signal died

const _ARENA_MARGIN := 8.0
const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)
const _AIM_DIRECTIONS := 16.0
const _MULTISHOT_SPREAD_DEG := 10.0
const _BLINK_INTERVAL_S := 0.08

## Set by the owning scene (design D10's pool contract: acquire/activate
## stay the caller's responsibility, not a NodePath auto-wire).
var bullet_pool: NodePool = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _pickup_magnet: Area2D = $PickupMagnet
@onready var _pickup_magnet_shape: CircleShape2D = $PickupMagnet/CollisionShape2D.shape

var _fire_cadence := FireCadence.new()
var _hp: float = 0.0
var _max_hp: float = 0.0
var _invuln_time_left: float = 0.0
var _blink_time: float = 0.0
var _dead: bool = false


func _ready() -> void:
	_max_hp = RunState.stats.value(StatBlock.Stat.MAX_HP)
	_hp = _max_hp
	EventBus.player_health_changed.emit(int(round(_hp)), int(round(_max_hp)))
	EventBus.stats_changed.connect(_on_stats_changed)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_move(delta)
	_aim()
	_tick_invulnerability(delta)
	_tick_contact_damage()
	_tick_pickup_magnet()
	_fire(delta)


func get_hp() -> float:
	return _hp


func is_dead() -> bool:
	return _dead


## Enemy bullets and, later, boss attacks call this directly (design
## D11's layer-based damage rule).
func take_damage(amount: float) -> void:
	if _dead or _invuln_time_left > 0.0:
		return
	_hp = max(_hp - amount, 0.0)
	EventBus.player_health_changed.emit(int(round(_hp)), int(round(_max_hp)))
	EventBus.damage_dealt.emit(global_position, amount)
	HitFlash.flash(_sprite)
	EventBus.shake_requested.emit(0.5)
	if _hp <= 0.0:
		_die()
	else:
		_invuln_time_left = RunState.base_stats.invuln_s


## Grants [param seconds] of invulnerability without a damage event (used
## when resuming from the level-up screen, design D14's level-up flow).
func grant_invulnerability(seconds: float) -> void:
	_invuln_time_left = max(_invuln_time_left, seconds)


## Restores [param amount] HP, clamped to the current max (an upgrade's
## [code]heal_amount[/code], design D14). A no-op while dead.
func heal(amount: float) -> void:
	if _dead:
		return
	_hp = min(_hp + amount, _max_hp)
	EventBus.player_health_changed.emit(int(round(_hp)), int(round(_max_hp)))


## An upgrade may change [constant StatBlock.Stat.MAX_HP]; every other
## stat is already read live each frame ([method _fire], [method _move],
## [method _tick_pickup_magnet]), but [member _max_hp] is cached, so it
## needs an explicit refresh on [signal EventBus.stats_changed] (design
## D14: "apply_upgrade -> StatBlock/heal/score -> stats_changed ->
## Player/HUD").
func _on_stats_changed() -> void:
	_max_hp = RunState.stats.value(StatBlock.Stat.MAX_HP)
	EventBus.player_health_changed.emit(int(round(_hp)), int(round(_max_hp)))


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


func _tick_invulnerability(delta: float) -> void:
	if _invuln_time_left <= 0.0:
		_sprite.visible = true
		return
	_invuln_time_left -= delta
	_blink_time += delta
	if _blink_time >= _BLINK_INTERVAL_S:
		_blink_time = 0.0
		_sprite.visible = not _sprite.visible
	if _invuln_time_left <= 0.0:
		_sprite.visible = true


func _tick_contact_damage() -> void:
	if _invuln_time_left > 0.0:
		return
	for body in _hurtbox.get_overlapping_bodies():
		if body.has_method("get_contact_damage"):
			take_damage(body.get_contact_damage())
			return


## Keeps the magnet's radius in sync with the live [constant
## StatBlock.Stat.PICKUP_RADIUS] (an upgrade can change it mid-run) and
## collects every pickup currently inside it (design D11's layer-based
## rule: [code]XpOrb.collect()[/code] is duck-typed the same way [code]
## Enemy.get_contact_damage()[/code] is).
func _tick_pickup_magnet() -> void:
	_pickup_magnet_shape.radius = RunState.stats.value(StatBlock.Stat.PICKUP_RADIUS)
	for area in _pickup_magnet.get_overlapping_areas():
		if area.has_method("collect"):
			area.collect()
			Squash.pulse(_sprite, Vector2(1.15, 1.15), 0.12)


func _fire(delta: float) -> void:
	var held := Input.is_action_pressed("fire")
	var shots_per_second: float = RunState.stats.value(StatBlock.Stat.FIRE_RATE)
	var shots := _fire_cadence.tick(delta, held, shots_per_second)
	if shots <= 0 or bullet_pool == null:
		return
	Squash.pulse(_sprite, Vector2(0.85, 1.15), 0.06)
	var base_angle := _aim_direction().angle()
	var count: int = max(1, RunState.stats.value_int(StatBlock.Stat.PROJECTILE_COUNT))
	var speed: float = RunState.stats.value(StatBlock.Stat.BULLET_SPEED)
	var damage: float = RunState.stats.value(StatBlock.Stat.DAMAGE)
	for i in range(shots):
		_spawn_fan(base_angle, count, speed, damage)


func _spawn_fan(base_angle: float, count: int, speed: float, damage: float) -> void:
	var spread := deg_to_rad(_MULTISHOT_SPREAD_DEG)
	var start := -spread * float(count - 1) / 2.0
	for i in range(count):
		var angle := base_angle + start + spread * i
		var bullet: Node = bullet_pool.acquire()
		if bullet == null:
			return
		bullet.activate({
			"position": global_position,
			"direction": Vector2.RIGHT.rotated(angle),
			"speed": speed,
			"damage": damage,
		})


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	EventBus.shake_requested.emit(1.0)
	died.emit()
	EventBus.player_died.emit()
