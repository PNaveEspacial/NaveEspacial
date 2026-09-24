class_name WaveComposer
extends RefCounted
## Pure function turning a wave number and RNG draws into a concrete wave
## plan (design D9). Spends [method DifficultyCurve.budget] over the
## roster's eligible enemy types (weighted by
## [method DifficultyCurve.type_weight], gated by [member EnemyData.cost]),
## packed into groups of 2-5 scheduled across the first 70% of the wave's
## duration.

## One planned wave: its duration, concurrent-enemy cap, and spawn groups.
class WavePlan:
	var wave: int
	var duration_s: float
	var max_alive: int
	var groups: Array[SpawnGroup] = []

## One scheduled burst of same-type enemies within a [WavePlan].
class SpawnGroup:
	var enemy_id: StringName
	var count: int
	var at_time_s: float

const _MIN_GROUP_SIZE := 2
const _MAX_GROUP_SIZE := 5
const _SCHEDULE_WINDOW_FRACTION := 0.7

var _curve: DifficultyCurve
var _roster: Array[EnemyData]


func _init(curve: DifficultyCurve, roster: Array[EnemyData]) -> void:
	_curve = curve
	_roster = roster


## Composes wave [param wave]'s plan, consuming draws from [param rng].
func compose(wave: int, rng: RandomNumberGenerator) -> WavePlan:
	var plan := WavePlan.new()
	plan.wave = wave
	plan.duration_s = _curve.wave_duration_s(wave)
	plan.max_alive = _curve.max_alive(wave)

	var unlocked: Array[EnemyData] = []
	var unlocked_weights: Array[float] = []
	for enemy in _roster:
		var weight := _curve.type_weight(enemy, wave)
		if weight > 0.0 and enemy.cost > 0.0:
			unlocked.append(enemy)
			unlocked_weights.append(weight)

	if unlocked.is_empty():
		return plan

	var remaining_budget := _curve.budget(wave)
	var groups: Array[SpawnGroup] = []

	while true:
		var affordable: Array[EnemyData] = []
		var affordable_weights: Array[float] = []
		for i in range(unlocked.size()):
			if unlocked[i].cost <= remaining_budget:
				affordable.append(unlocked[i])
				affordable_weights.append(unlocked_weights[i])
		if affordable.is_empty():
			break

		var enemy := _pick_weighted(affordable, affordable_weights, rng)
		var max_count_by_budget := int(remaining_budget / enemy.cost)
		var desired_count := _MIN_GROUP_SIZE + rng.randi_range(0, _MAX_GROUP_SIZE - _MIN_GROUP_SIZE)
		var count := maxi(1, mini(desired_count, max_count_by_budget))

		var group := SpawnGroup.new()
		group.enemy_id = enemy.id
		group.count = count
		groups.append(group)
		remaining_budget -= count * enemy.cost

	var schedule_window := plan.duration_s * _SCHEDULE_WINDOW_FRACTION
	var times: Array[float] = []
	for i in range(groups.size()):
		times.append(rng.randf() * schedule_window)
	times.sort()
	for i in range(groups.size()):
		groups[i].at_time_s = times[i]

	plan.groups = groups
	return plan


## Weighted-random selection (without replacement is not needed here: the
## roster stays eligible across the whole compose call).
static func _pick_weighted(pool: Array[EnemyData], weights: Array[float], rng: RandomNumberGenerator) -> EnemyData:
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := rng.randf() * total
	var cumulative := 0.0
	for i in range(pool.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return pool[i]
	return pool[pool.size() - 1]
