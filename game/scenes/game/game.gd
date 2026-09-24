extends Node2D
## Run scene (S10 scope): starts a run, wires the player to its bullet
## pool, and drives enemy spawning through [WaveDirector]. HUD, pause, and
## game-over all land in a later slice (S14).

@onready var _player: Player = $World/Player
@onready var _player_bullet_pool: NodePool = $Pools/PlayerBulletPool
@onready var _enemy_pool: NodePool = $Pools/EnemyPool
@onready var _enemy_bullet_pool: NodePool = $Pools/EnemyBulletPool
@onready var _wave_director: WaveDirector = $WaveDirector


func _ready() -> void:
	if RunState.rng == null:
		RunState.prepare_new_run()
	_player.bullet_pool = _player_bullet_pool
	_player.died.connect(_on_player_died)

	_wave_director.target = _player
	_wave_director.enemy_pool = _enemy_pool
	_wave_director.enemy_bullet_pool = _enemy_bullet_pool
	_wave_director.start(RunState.rng)


func _on_player_died() -> void:
	_wave_director.stop()
	RunState.end_run()
