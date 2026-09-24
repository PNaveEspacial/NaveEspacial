extends Node2D
## Minimal run scene (S8 scope): starts a run and wires the player to its
## bullet pool. Wave spawning ([code]WaveDirector[/code]), HUD, pause, and
## game-over all land in later slices (S10, S14).

@onready var _player: Player = $World/Player
@onready var _player_bullet_pool: NodePool = $Pools/PlayerBulletPool


func _ready() -> void:
	if RunState.rng == null:
		RunState.prepare_new_run()
	_player.bullet_pool = _player_bullet_pool
	_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	RunState.end_run()
