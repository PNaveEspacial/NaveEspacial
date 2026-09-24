extends GutTest
## Covers run-rng-and-difficulty's Monotonic Difficulty Curve requirement.


func _make_curve(params: DifficultyParams) -> DifficultyCurve:
	return DifficultyCurve.new(params)


func test_wave_one_baseline_matches_the_documented_values():
	var params := DifficultyParams.new()
	var curve := _make_curve(params)
	assert_almost_eq(curve.budget(1), params.budget_base, 0.001)
	assert_eq(curve.max_alive(1), params.max_alive_base)
	assert_almost_eq(curve.hp_multiplier(1), 1.0, 0.001)
	assert_almost_eq(curve.speed_multiplier(1), 1.0, 0.001)
	assert_almost_eq(curve.wave_duration_s(1), params.duration_base, 0.001)


func test_every_output_is_non_decreasing_across_waves_1_to_200():
	var curve := _make_curve(DifficultyParams.new())
	var prev_budget := -INF
	var prev_max_alive := -1
	var prev_hp := -INF
	var prev_speed := -INF
	var prev_duration := -INF
	for wave in range(1, 201):
		var budget := curve.budget(wave)
		var max_alive := curve.max_alive(wave)
		var hp := curve.hp_multiplier(wave)
		var speed := curve.speed_multiplier(wave)
		var duration := curve.wave_duration_s(wave)
		assert_gte(budget, prev_budget, "budget should not decrease at wave %d" % wave)
		assert_gte(max_alive, prev_max_alive, "max_alive should not decrease at wave %d" % wave)
		assert_gte(hp, prev_hp, "hp_multiplier should not decrease at wave %d" % wave)
		assert_gte(speed, prev_speed, "speed_multiplier should not decrease at wave %d" % wave)
		assert_gte(duration, prev_duration, "wave_duration_s should not decrease at wave %d" % wave)
		prev_budget = budget
		prev_max_alive = max_alive
		prev_hp = hp
		prev_speed = speed
		prev_duration = duration


func test_capped_outputs_stay_within_their_configured_cap():
	var params := DifficultyParams.new()
	var curve := _make_curve(params)
	assert_lte(curve.speed_multiplier(500), params.speed_cap)
	assert_eq(curve.max_alive(500), params.max_alive_cap)
	assert_lte(curve.wave_duration_s(500), params.duration_cap)


func test_type_weight_is_zero_before_unlock_wave():
	var curve := _make_curve(DifficultyParams.new())
	var enemy := EnemyData.new()
	enemy.spawn_weight = 3.0
	enemy.unlock_wave = 5

	assert_eq(curve.type_weight(enemy, 1), 0.0)
	assert_eq(curve.type_weight(enemy, 4), 0.0)
	assert_eq(curve.type_weight(enemy, 5), 3.0)
	assert_eq(curve.type_weight(enemy, 10), 3.0)
