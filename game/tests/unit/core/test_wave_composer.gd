extends GutTest
## Covers run-rng-and-difficulty's Deterministic Wave Composition requirement.


func _make_roster() -> Array[EnemyData]:
	var drone := EnemyData.new()
	drone.id = &"drone"
	drone.behavior = EnemyData.Behavior.CHASE
	drone.cost = 1.0
	drone.spawn_weight = 1.0
	drone.unlock_wave = 1

	var gunship := EnemyData.new()
	gunship.id = &"gunship"
	gunship.behavior = EnemyData.Behavior.KEEP_DISTANCE
	gunship.cost = 2.0
	gunship.spawn_weight = 1.0
	gunship.unlock_wave = 3

	var roster: Array[EnemyData] = [drone, gunship]
	return roster


func _make_composer() -> WaveComposer:
	var curve := DifficultyCurve.new(DifficultyParams.new())
	return WaveComposer.new(curve, _make_roster())


func _sum_cost(groups: Array, roster: Array[EnemyData]) -> float:
	var cost_by_id := {}
	for enemy in roster:
		cost_by_id[enemy.id] = enemy.cost
	var total := 0.0
	for group in groups:
		total += group.count * float(cost_by_id[group.enemy_id])
	return total


func test_same_seed_and_wave_reproduce_identical_composition():
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777

	var plan_a := _make_composer().compose(5, rng_a)
	var plan_b := _make_composer().compose(5, rng_b)

	assert_eq(plan_a.groups.size(), plan_b.groups.size())
	for i in range(plan_a.groups.size()):
		assert_eq(plan_a.groups[i].enemy_id, plan_b.groups[i].enemy_id)
		assert_eq(plan_a.groups[i].count, plan_b.groups[i].count)
		assert_almost_eq(plan_a.groups[i].at_time_s, plan_b.groups[i].at_time_s, 0.0001)


func test_composition_scales_with_difficulty():
	var composer := _make_composer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var early_plan := composer.compose(1, rng)
	var later_plan := composer.compose(30, rng)
	var roster := _make_roster()

	assert_gte(
		_sum_cost(later_plan.groups, roster),
		_sum_cost(early_plan.groups, roster),
		"wave 30 should spend at least as much budget as wave 1"
	)


func test_groups_are_scheduled_within_70_percent_of_wave_duration():
	var composer := _make_composer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var plan := composer.compose(10, rng)
	var window := plan.duration_s * 0.7

	assert_gt(plan.groups.size(), 0, "wave 10 should compose at least one group")
	for group in plan.groups:
		assert_gte(group.at_time_s, 0.0)
		assert_lte(group.at_time_s, window)


func test_only_unlocked_types_appear():
	var composer := _make_composer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	# gunship unlocks at wave 3; wave 1 must only ever compose drones.
	var plan := composer.compose(1, rng)
	assert_gt(plan.groups.size(), 0, "wave 1 should still compose drone groups")
	for group in plan.groups:
		assert_eq(group.enemy_id, &"drone", "wave 1 should not spawn gunship before its unlock wave")
