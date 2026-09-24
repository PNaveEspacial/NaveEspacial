extends GutTest
## Covers player-ship's Health and Invulnerability Frames and Death State
## requirements. Instantiates player.tscn directly so the RunState/EventBus
## autoloads are exactly as they are in-game.

var _player: Player


func before_each():
	RunState.start_run(1)
	var scene: PackedScene = load("res://scenes/player/player.tscn")
	_player = scene.instantiate() as Player
	add_child_autofree(_player)


func test_damage_during_invulnerability_is_ignored():
	_player.take_damage(1.0)
	var hp_after_first_hit := _player.get_hp()
	_player.take_damage(1.0)
	assert_eq(_player.get_hp(), hp_after_first_hit, "a second hit inside the i-frame window must not change hp")


func test_damage_after_invulnerability_expires_applies():
	_player.take_damage(1.0)
	var hp_after_first_hit := _player.get_hp()
	var invuln_s: float = RunState.base_stats.invuln_s
	_player._physics_process(invuln_s + 0.5)
	_player.take_damage(1.0)
	assert_almost_eq(_player.get_hp(), hp_after_first_hit - 1.0, 0.01)


func test_zero_health_triggers_death():
	var max_hp := RunState.stats.value(StatBlock.Stat.MAX_HP)
	_player.take_damage(max_hp)
	assert_true(_player.is_dead())
	assert_eq(_player.get_hp(), 0.0)


func test_damage_beyond_max_hp_still_only_dies_once():
	var max_hp := RunState.stats.value(StatBlock.Stat.MAX_HP)
	_player.take_damage(max_hp * 10.0)
	assert_true(_player.is_dead())
	assert_eq(_player.get_hp(), 0.0, "hp should clamp at 0, not go negative")


func test_input_is_ignored_after_death():
	var max_hp := RunState.stats.value(StatBlock.Stat.MAX_HP)
	_player.take_damage(max_hp)
	var position_before := _player.global_position
	_player._physics_process(1.0)
	assert_eq(_player.global_position, position_before, "no movement should occur once dead")


func test_grant_invulnerability_blocks_a_subsequent_hit():
	_player.grant_invulnerability(1.0)
	var hp_before := _player.get_hp()
	_player.take_damage(1.0)
	assert_eq(_player.get_hp(), hp_before, "a granted invulnerability window should block damage like a hit-triggered one")
