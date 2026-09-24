class_name WaveDirector
extends Node
## Drives the infinite wave loop (design D9; enemies-and-waves spec
## capability). Owns no rendering; it asks the pure core
## ([DifficultyCurve], [WaveComposer], [SpawnRing]) what to spawn and when,
## then acquires pooled [Enemy] instances and activates them.
##
## [method tick] is called every physics frame while running (this node's
## own [method _physics_process] does that automatically once it is in the
## tree), but it is also callable directly --
## [code]test_wave_director.gd[/code] drives it with large, explicit deltas
## to exercise wave-escalation sequencing without a live [SceneTree] or
## pooled scenes.
##
## Sequencing (design D9): a wave is fully spawned once every
## [WaveComposer.SpawnGroup] in its plan has reached its scheduled time
## (a group whose spawn would exceed [member WaveComposer.WavePlan.max_alive]
## is held, not skipped, until room frees). Once fully spawned AND (every
## spawned enemy has died OR the wave's duration has elapsed), a fixed
## breather elapses before the next wave starts. The only stop condition is
## [method stop] -- the owning scene (game.gd) calls it on [signal
## EventBus.player_died].
##
## Pool sizing (set on [code]game.tscn[/code]'s [code]EnemyPool[/code]/
## [code]EnemyBulletPool[/code], not here): Enemy's [code]max_size[/code] is
## 48, matching [member DifficultyParams.max_alive_cap] exactly -- the
## gameplay ceiling never needs more concurrent enemies than that, so a
## larger pool would only waste memory. EnemyBullet's max_size (64) is
## smaller than PlayerBullet's (128) because only KEEP_DISTANCE enemies
## fire, at a slower cadence than the player. Both use a 1:3 prewarm-to-max
## ratio, matching the ratio S8b already established for PlayerBullet
## (32/128).

const _BREATHER_S := 2.0
const _ARENA_RECT := Rect2(0.0, 0.0, 640.0, 360.0)
const _ARENA_MARGIN := 16.0
const _MIN_PLAYER_SPAWN_DISTANCE := 160.0

## Every enemy type eligible to spawn, gated by [member EnemyData.unlock_wave].
@export var roster: Array[EnemyData] = []

## Tunable escalation curve inputs (design D9).
@export var difficulty_params: DifficultyParams

## Set by the owning scene (design D10's pool contract: acquire/activate
## stay the caller's responsibility): the player [Node2D] enemies seek/flee
## from and spawn positions are measured against.
var target: Node2D = null

## Set by the owning scene: pooled [Enemy] and [code]EnemyBullet[/code]
## sources. Spawning is silently skipped while either is unset, which is
## what lets [code]test_wave_director.gd[/code] exercise sequencing without
## pooled scenes.
var enemy_pool: NodePool = null
var enemy_bullet_pool: NodePool = null

## The wave currently in progress (or about to start after the breather).
## 0 before [method start] is called.
var current_wave: int = 0

var _rng: RunRng
var _curve: DifficultyCurve
var _composer: WaveComposer
var _spawn_ring: SpawnRing
var _plan: WaveComposer.WavePlan
var _spawned_groups: Array[bool] = []
var _alive_enemies: Array[Node] = []
var _elapsed_s: float = 0.0
var _breather_time_left: float = 0.0
var _running: bool = false


func _physics_process(delta: float) -> void:
	tick(delta)


## Begins the infinite loop from wave 1, deriving every draw from [param
## rng]'s [constant RunRng.Stream.WAVES], [constant RunRng.Stream.SPAWNS],
## and [constant RunRng.Stream.AI] streams.
func start(rng: RunRng) -> void:
	_rng = rng
	_curve = DifficultyCurve.new(difficulty_params)
	_composer = WaveComposer.new(_curve, roster)
	_spawn_ring = SpawnRing.new(_ARENA_RECT, _ARENA_MARGIN, _MIN_PLAYER_SPAWN_DISTANCE)
	current_wave = 0
	_breather_time_left = 0.0
	_alive_enemies.clear()
	_running = true
	_start_next_wave()


## Halts the loop. The only intended caller is the owning scene, on
## [signal EventBus.player_died] (design D9's stop condition).
func stop() -> void:
	_running = false


## Advances the loop by [param delta] seconds: spawns any due groups
## (unless the current [code]max_alive[/code] cap holds them back),
## resolves the wave-clear/timeout condition, and runs the between-wave
## breather.
func tick(delta: float) -> void:
	if not _running:
		return
	if _breather_time_left > 0.0:
		_breather_time_left -= delta
		if _breather_time_left <= 0.0:
			_start_next_wave()
		return
	_elapsed_s += delta
	_spawn_due_groups()
	if _wave_cleared_or_timed_out():
		_breather_time_left = _BREATHER_S


func _start_next_wave() -> void:
	current_wave += 1
	RunState.wave = current_wave
	_plan = _composer.compose(current_wave, _rng.stream(RunRng.Stream.WAVES))
	_elapsed_s = 0.0
	_spawned_groups.clear()
	for i in range(_plan.groups.size()):
		_spawned_groups.append(false)
	EventBus.wave_started.emit(current_wave)


func _spawn_due_groups() -> void:
	for i in range(_plan.groups.size()):
		if _spawned_groups[i]:
			continue
		var group: WaveComposer.SpawnGroup = _plan.groups[i]
		if _elapsed_s < group.at_time_s:
			continue
		if _alive_enemies.size() >= _plan.max_alive:
			continue
		_spawn_group(group)
		_spawned_groups[i] = true


func _spawn_group(group: WaveComposer.SpawnGroup) -> void:
	if enemy_pool == null or target == null:
		return
	var enemy_data := _find_enemy_data(group.enemy_id)
	if enemy_data == null:
		return
	var positions := _spawn_ring.pick_group(
		_rng.stream(RunRng.Stream.SPAWNS), target.global_position, group.count
	)
	for spawn_position in positions:
		if _alive_enemies.size() >= _plan.max_alive:
			return
		var enemy: Node = enemy_pool.acquire()
		if enemy == null:
			return
		enemy.despawn_requested.connect(_on_enemy_despawned.bind(enemy), CONNECT_ONE_SHOT)
		enemy.activate({
			"data": enemy_data,
			"position": spawn_position,
			"target": target,
			"bullet_pool": enemy_bullet_pool,
			"ai_rng": _rng.stream(RunRng.Stream.AI),
			"hp_multiplier": _curve.hp_multiplier(current_wave),
			"speed_multiplier": _curve.speed_multiplier(current_wave),
		})
		_alive_enemies.append(enemy)


func _on_enemy_despawned(enemy: Node) -> void:
	_alive_enemies.erase(enemy)


func _wave_cleared_or_timed_out() -> bool:
	if _spawned_groups.has(false):
		return false
	return _alive_enemies.is_empty() or _elapsed_s >= _plan.duration_s


func _find_enemy_data(enemy_id: StringName) -> EnemyData:
	for enemy_data in roster:
		if enemy_data.id == enemy_id:
			return enemy_data
	return null
