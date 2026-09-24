class_name UpgradeRoller
extends RefCounted
## Rolls level-up upgrade offers (design D14). [method roll] ALWAYS returns
## exactly [param count] distinct entries, given the pool precondition that
## [method validate_pool] checks: at least [param count] uncapped entries,
## so there are always enough eligible entries even once every capped
## upgrade is maxed out.

## Weight multiplier applied to an uncapped (filler) entry while at least
## one capped entry is still eligible, so fillers are under-weighted until
## the capped pool runs out.
const FILLER_WEIGHT_FACTOR := 0.25


## Rolls [param count] distinct [UpgradeData] from [param pool], consuming
## draws from [param rng]. [param stacks] maps upgrade id -> times picked
## so far this run. Asserts the pool has enough eligible entries; callers
## should validate the pool with [method validate_pool] ahead of time.
static func roll(
	pool: Array[UpgradeData], stacks: Dictionary, rng: RandomNumberGenerator, count: int = 3
) -> Array[UpgradeData]:
	var eligible: Array[UpgradeData] = []
	for upgrade in pool:
		var current_stacks: int = stacks.get(upgrade.id, 0)
		if upgrade.max_stacks == 0 or current_stacks < upgrade.max_stacks:
			eligible.append(upgrade)

	assert(
		eligible.size() >= count,
		"UpgradeRoller.roll requires at least %d eligible entries, got %d" % [count, eligible.size()]
	)

	var any_capped_eligible := false
	for upgrade in eligible:
		if upgrade.max_stacks > 0:
			any_capped_eligible = true
			break

	var remaining := eligible.duplicate()
	var weights: Array[float] = []
	for upgrade in remaining:
		weights.append(_effective_weight(upgrade, any_capped_eligible))

	var result: Array[UpgradeData] = []
	for i in range(count):
		var picked_index := _weighted_pick(weights, rng)
		result.append(remaining[picked_index])
		remaining.remove_at(picked_index)
		weights.remove_at(picked_index)

	return result


## Returns human-readable error strings for anything [param pool] violates:
## fewer than [param min_uncapped] uncapped entries, duplicate ids, or a
## non-positive weight. An empty result means the pool is valid.
static func validate_pool(pool: Array[UpgradeData], min_uncapped: int = 3) -> PackedStringArray:
	var errors := PackedStringArray()
	var uncapped_count := 0
	var seen_ids := {}

	for upgrade in pool:
		if upgrade.max_stacks == 0:
			uncapped_count += 1
		if seen_ids.has(upgrade.id):
			errors.append("Duplicate upgrade id: %s" % upgrade.id)
		else:
			seen_ids[upgrade.id] = true
		if upgrade.weight <= 0.0:
			errors.append("Upgrade '%s' has a non-positive weight: %s" % [upgrade.id, upgrade.weight])

	if uncapped_count < min_uncapped:
		errors.append(
			"Pool has %d uncapped entries, fewer than the required minimum %d" % [uncapped_count, min_uncapped]
		)

	return errors


static func _effective_weight(upgrade: UpgradeData, any_capped_eligible: bool) -> float:
	if upgrade.max_stacks > 0:
		return upgrade.weight
	if any_capped_eligible:
		return upgrade.weight * FILLER_WEIGHT_FACTOR
	return upgrade.weight


static func _weighted_pick(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights:
		total += weight
	var roll_value := rng.randf() * total
	var cumulative := 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll_value < cumulative:
			return i
	return weights.size() - 1
