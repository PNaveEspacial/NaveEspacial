extends Node2D
## Run scene (S12 scope): starts a run, wires the player to its bullet
## pool, drives enemy spawning through [WaveDirector], spawns an [XpOrb]
## on every [signal EventBus.enemy_killed], and gives [LevelUpScreen] the
## player reference it needs to heal/grant i-frames. HUD, pause, and
## game-over all land in a later slice (S14).

@onready var _player: Player = $World/Player
@onready var _player_bullet_pool: NodePool = $Pools/PlayerBulletPool
@onready var _enemy_pool: NodePool = $Pools/EnemyPool
@onready var _enemy_bullet_pool: NodePool = $Pools/EnemyBulletPool
@onready var _xp_orb_pool: NodePool = $Pools/XpOrbPool
@onready var _wave_director: WaveDirector = $WaveDirector
@onready var _level_up_screen: LevelUpScreen = $LevelUpScreen


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

	_level_up_screen.set_player(_player)


func _on_player_died() -> void:
	_wave_director.stop()
	RunState.end_run()


func _on_enemy_killed(_enemy_id: StringName, position: Vector2, _score_value: int, xp_value: int) -> void:
	var orb: Node = _xp_orb_pool.acquire()
	if orb == null:
		return
	orb.activate({"position": position, "xp_value": xp_value})
