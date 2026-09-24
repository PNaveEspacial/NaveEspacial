extends GutTest
## Covers run-rng-and-difficulty's Full-Run Determinism requirement: the
## same seed and the same ordered sequence of upgrade choices must
## reproduce identical wave compositions, spawn positions, and upgrade
## offers on every replay. Drives RunRng + DifficultyCurve + WaveComposer +
## SpawnRing + LevelCurve + UpgradeRoller together, with no Node/scene
## involvement.

const _ARENA := Rect2(0, 0, 640, 360)
const _PLAYER_POS := Vector2(320, 180)
const _WAVE_COUNT := 10


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


func _make_upgrade(id: String, max_stacks: int, weight: float = 1.0) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = StringName(id)
	upgrade.max_stacks = max_stacks
	upgrade.weight = weight
	return upgrade


func _make_upgrade_pool() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = [
		_make_upgrade("fire_rate", 5),
		_make_upgrade("damage", 5),
		_make_upgrade("move_speed", 4),
		_make_upgrade("repair", 0, 0.5),
		_make_upgrade("salvage", 0, 0.5),
		_make_upgrade("overclock", 0, 0.5),
	]
	return pool


## Drives waves 1..10 with a fixed, ordered choice rule (always pick offer
## index 0), returning the collected wave compositions, spawn positions,
## and upgrade offers for comparison across replays.
func _run_core_simulation(seed: int) -> Dictionary:
	var rng := RunRng.new(seed)
	var curve := DifficultyCurve.new(DifficultyParams.new())
	var composer := WaveComposer.new(curve, _make_roster())
	var ring := SpawnRing.new(_ARENA, 16.0, 160.0, 8)
	var level_curve := LevelCurve.new()
	var pool := _make_upgrade_pool()

	var stacks := {}
	var level := 1
	var xp := 0

	var wave_compositions: Array = []
	var spawn_positions: Array = []
	var upgrade_offers: Array = []

	for wave in range(1, _WAVE_COUNT + 1):
		var plan := composer.compose(wave, rng.stream(RunRng.Stream.WAVES))

		var composition: Array = []
		var wave_spawns: Array = []
		for group in plan.groups:
			composition.append({"enemy_id": group.enemy_id, "count": group.count, "at_time_s": group.at_time_s})
			wave_spawns.append(ring.pick_group(rng.stream(RunRng.Stream.SPAWNS), _PLAYER_POS, group.count))
		wave_compositions.append(composition)
		spawn_positions.append(wave_spawns)

		var xp_result := level_curve.add_xp(level, xp, level_curve.xp_to_next(level))
		level = xp_result["level"]
		xp = xp_result["xp"]

		var offer := UpgradeRoller.roll(pool, stacks, rng.stream(RunRng.Stream.UPGRADES), 3)
		var offer_ids: Array = []
		for upgrade in offer:
			offer_ids.append(upgrade.id)
		upgrade_offers.append(offer_ids)

		# Fixed, ordered choice: always take the first offered upgrade.
		var chosen := offer[0]
		stacks[chosen.id] = stacks.get(chosen.id, 0) + 1

	return {
		"wave_compositions": wave_compositions,
		"spawn_positions": spawn_positions,
		"upgrade_offers": upgrade_offers,
	}


func test_replaying_a_seed_with_identical_choices_reproduces_the_runs_core_outputs():
	var seed := 20260924
	var run_a := _run_core_simulation(seed)
	var run_b := _run_core_simulation(seed)

	assert_eq(run_a["wave_compositions"], run_b["wave_compositions"], "wave compositions should match across replays")
	assert_eq(run_a["spawn_positions"], run_b["spawn_positions"], "spawn positions should match across replays")
	assert_eq(run_a["upgrade_offers"], run_b["upgrade_offers"], "upgrade offers should match across replays")


func test_a_different_seed_diverges_from_the_original():
	var run_a := _run_core_simulation(1)
	var run_b := _run_core_simulation(2)
	assert_ne(run_a["wave_compositions"], run_b["wave_compositions"], "different seeds should diverge")
