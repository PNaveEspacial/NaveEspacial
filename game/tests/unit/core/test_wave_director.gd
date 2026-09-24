extends GutTest
## Covers enemies-and-waves' Infinite WaveDirector Loop requirement: once a
## wave's clear/timeout condition is reached, the director requests the
## next wave from the core composer with a difficulty value >= the previous
## wave's.
##
## enemy_pool/enemy_bullet_pool are left unset, so [code]activate()[/code]
## is never called and only the sequencing (not pooled scenes) is
## exercised: with no enemy_pool, every scheduled group is still marked
## spawned once its due time passes (design D9's "fully spawned" condition
## only tracks scheduling, not successful activation), and no enemy is ever
## "alive", so the wave clears as soon as it is fully spawned.

const _PAST_DUE_DELTA_S := 999.0
const _PAST_BREATHER_DELTA_S := 3.0

var _director: WaveDirector
var _params: DifficultyParams


func _make_roster() -> Array[EnemyData]:
	var drone := EnemyData.new()
	drone.id = &"drone"
	drone.behavior = EnemyData.Behavior.CHASE
	drone.cost = 1.0
	drone.spawn_weight = 1.0
	drone.unlock_wave = 1
	var roster: Array[EnemyData] = [drone]
	return roster


func before_each():
	_params = DifficultyParams.new()
	_director = autofree(WaveDirector.new())
	_director.roster = _make_roster()
	_director.difficulty_params = _params


func test_start_composes_wave_1():
	_director.start(RunRng.new(777))
	assert_eq(_director.current_wave, 1)


func test_new_wave_requested_after_clear_with_non_decreasing_difficulty():
	_director.start(RunRng.new(777))
	assert_eq(_director.current_wave, 1)

	_director.tick(_PAST_DUE_DELTA_S)
	assert_eq(_director.current_wave, 1, "wave should not advance before the breather elapses")

	_director.tick(_PAST_BREATHER_DELTA_S)
	assert_eq(_director.current_wave, 2, "director should request wave 2 after wave 1 clears")

	var curve := DifficultyCurve.new(_params)
	assert_gte(
		curve.budget(_director.current_wave),
		curve.budget(_director.current_wave - 1),
		"wave 2's difficulty should be >= wave 1's"
	)


func test_loop_keeps_advancing_across_several_waves():
	_director.start(RunRng.new(42))
	for expected_wave in range(2, 6):
		_director.tick(_PAST_DUE_DELTA_S)
		_director.tick(_PAST_BREATHER_DELTA_S)
		assert_eq(_director.current_wave, expected_wave)


func test_stop_halts_further_ticks():
	_director.start(RunRng.new(1))
	_director.stop()
	_director.tick(_PAST_DUE_DELTA_S)
	_director.tick(_PAST_BREATHER_DELTA_S)
	assert_eq(_director.current_wave, 1, "stop() must freeze the wave count")
