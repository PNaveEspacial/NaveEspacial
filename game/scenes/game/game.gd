extends Node2D
## Run scene (S16 scope): starts a run, wires the player to its bullet
## pool, drives enemy spawning through [WaveDirector], spawns an [XpOrb]
## and a death [Burst] on every [signal EventBus.enemy_killed], spawns a
## [DamageNumber] on every [signal EventBus.damage_dealt], and gives
## [LevelUpScreen], [Hud], [PauseMenu], and [DebugOverlay] the references
## they need. [GameOver] needs no wiring beyond instancing: it
## self-subscribes to [EventBus] and is the sole caller of [method
## RunState.end_run] (design D18's flow).

@onready var _player: Player = $World/Player
@onready var _player_bullet_pool: NodePool = $Pools/PlayerBulletPool
@onready var _enemy_pool: NodePool = $Pools/EnemyPool
@onready var _enemy_bullet_pool: NodePool = $Pools/EnemyBulletPool
@onready var _xp_orb_pool: NodePool = $Pools/XpOrbPool
@onready var _burst_pool: NodePool = $Pools/BurstPool
@onready var _damage_number_pool: NodePool = $Pools/DamageNumberPool
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _level_up_screen: LevelUpScreen = $LevelUpScreen
@onready var _hud: Hud = $Hud
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	if RunState.rng == null:
		RunState.prepare_new_run()
	_player.bullet_pool = _player_bullet_pool
	_player.died.connect(_on_player_died)

	_wave_director.target = _player
	_wave_director.enemy_pool = _enemy_pool
	_wave_director.enemy_bullet_pool = _enemy_bullet_pool
	_wave_director.start(RunState.rng)

	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.damage_dealt.connect(_on_damage_dealt)

	_level_up_screen.set_player(_player)
	_hud.set_player(_player)
	_pause_menu.set_level_up_screen(_level_up_screen)
	_debug_overlay.set_wave_director(_wave_director)
	_debug_overlay.set_pools({
		"PlayerBullet": _player_bullet_pool,
		"EnemyBullet": _enemy_bullet_pool,
		"Enemy": _enemy_pool,
		"XpOrb": _xp_orb_pool,
		"Burst": _burst_pool,
		"DamageNumber": _damage_number_pool,
	})


## Only stops the wave loop. [method RunState.end_run] (score submission
## + [signal EventBus.run_ended]) is [GameOver]'s job, fired after its own
## death-delay fx window -- calling it immediately here was S8b's
## placeholder, before [GameOver] existed to consume the delay.
func _on_player_died() -> void:
	_wave_director.stop()
	_spawn_burst(_player.global_position)


func _on_enemy_killed(_enemy_id: StringName, position: Vector2, _score_value: int, xp_value: int) -> void:
	var orb: Node = _xp_orb_pool.acquire()
	if orb != null:
		orb.activate({"position": position, "xp_value": xp_value})
	_spawn_burst(position)


func _on_damage_dealt(position: Vector2, amount: float) -> void:
	var number: Node = _damage_number_pool.acquire()
	if number == null:
		return
	number.activate({"position": position, "amount": amount})


func _spawn_burst(position: Vector2) -> void:
	var burst: Node = _burst_pool.acquire()
	if burst == null:
		return
	burst.activate({"position": position})
