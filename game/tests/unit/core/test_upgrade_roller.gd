extends GutTest
## Covers xp-and-upgrades' Pick-1-of-3, Seeded Upgrade Offers, and the
## design's guaranteed-3-distinct-offer contract for UpgradeRoller.


func _make_upgrade(id: String, max_stacks: int, weight: float = 1.0) -> UpgradeData:
	var upgrade := UpgradeData.new()
	upgrade.id = StringName(id)
	upgrade.max_stacks = max_stacks
	upgrade.weight = weight
	return upgrade


## 3 capped + 3 uncapped, matching validate_pool's min_uncapped=3 invariant.
func _make_pool() -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = [
		_make_upgrade("fire_rate", 5),
		_make_upgrade("damage", 5),
		_make_upgrade("move_speed", 4),
		_make_upgrade("repair", 0, 0.5),
		_make_upgrade("salvage", 0, 0.5),
		_make_upgrade("overclock", 0, 0.5),
	]
	return pool


func test_offer_from_a_pool_larger_than_3_has_no_duplicates():
	var pool := _make_pool()
	var rng := RandomNumberGenerator.new()
	rng.seed = 10
	var offer := UpgradeRoller.roll(pool, {}, rng, 3)

	assert_eq(offer.size(), 3)
	var ids := {}
	for upgrade in offer:
		assert_false(ids.has(upgrade.id), "offer should not repeat id '%s'" % upgrade.id)
		ids[upgrade.id] = true


func test_offer_from_a_pool_of_exactly_3_returns_all_of_them():
	var pool: Array[UpgradeData] = [
		_make_upgrade("a", 0, 1.0),
		_make_upgrade("b", 0, 1.0),
		_make_upgrade("c", 0, 1.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var offer := UpgradeRoller.roll(pool, {}, rng, 3)

	assert_eq(offer.size(), 3)
	var ids := {}
	for upgrade in offer:
		ids[upgrade.id] = true
	assert_true(ids.has(&"a"))
	assert_true(ids.has(&"b"))
	assert_true(ids.has(&"c"))


func test_maxing_every_capped_upgrade_still_yields_exactly_3_distinct_fillers():
	var pool := _make_pool()
	var stacks := {
		&"fire_rate": 5,
		&"damage": 5,
		&"move_speed": 4,
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var offer := UpgradeRoller.roll(pool, stacks, rng, 3)

	assert_eq(offer.size(), 3, "even with every capped upgrade maxed, the offer must have exactly 3 entries")
	var ids := {}
	for upgrade in offer:
		assert_eq(upgrade.max_stacks, 0, "offer should only contain uncapped fillers once every capped upgrade is maxed")
		assert_false(ids.has(upgrade.id), "offer should not repeat id '%s'" % upgrade.id)
		ids[upgrade.id] = true


func test_same_seed_and_prior_draws_reproduce_the_same_offer():
	var pool := _make_pool()
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	# Consume an identical number of prior draws on both, simulating an
	# earlier level-up already rolled in this run.
	for i in range(7):
		rng_a.randf()
		rng_b.randf()

	var offer_a := UpgradeRoller.roll(pool, {}, rng_a, 3)
	var offer_b := UpgradeRoller.roll(pool, {}, rng_b, 3)

	for i in range(3):
		assert_eq(offer_a[i].id, offer_b[i].id, "offer index %d should match between replays" % i)


func test_fillers_are_underweighted_while_capped_options_remain():
	# Statistical check: with capped entries still eligible, a filler
	# (weight 0.5 * FILLER_WEIGHT_FACTOR = 0.125 effective) should appear
	# far less often across many rolls than when it is the only kind left.
	var pool: Array[UpgradeData] = [
		_make_upgrade("capped_a", 5, 1.0),
		_make_upgrade("capped_b", 5, 1.0),
		_make_upgrade("filler_a", 0, 1.0),
		_make_upgrade("filler_b", 0, 1.0),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	var filler_appearances := 0
	var total_rolls := 300
	for i in range(total_rolls):
		var offer := UpgradeRoller.roll(pool, {}, rng, 2)
		for upgrade in offer:
			if upgrade.max_stacks == 0:
				filler_appearances += 1

	# Effective weights while capped remain: capped 1.0 each, filler
	# 1.0*0.25=0.25 each. Fillers should land well under half the slots.
	var max_expected: float = total_rolls * 2 * 0.4
	assert_lt(float(filler_appearances), max_expected, "fillers should be under-weighted while capped options remain")


func test_validate_pool_flags_too_few_uncapped_entries():
	var pool: Array[UpgradeData] = [
		_make_upgrade("a", 5),
		_make_upgrade("b", 5),
		_make_upgrade("filler", 0),
	]
	var errors := UpgradeRoller.validate_pool(pool, 3)
	assert_gt(errors.size(), 0)


func test_validate_pool_flags_duplicate_ids():
	var pool: Array[UpgradeData] = _make_pool()
	pool.append(_make_upgrade("fire_rate", 5))
	var errors := UpgradeRoller.validate_pool(pool, 3)
	var found_duplicate := false
	for error in errors:
		if error.contains("Duplicate"):
			found_duplicate = true
	assert_true(found_duplicate)


func test_validate_pool_flags_non_positive_weight():
	var pool: Array[UpgradeData] = _make_pool()
	pool.append(_make_upgrade("broken", 0, 0.0))
	var errors := UpgradeRoller.validate_pool(pool, 3)
	var found_weight_error := false
	for error in errors:
		if error.contains("non-positive weight"):
			found_weight_error = true
	assert_true(found_weight_error)


func test_validate_pool_returns_empty_for_a_valid_pool():
	var errors := UpgradeRoller.validate_pool(_make_pool(), 3)
	assert_eq(errors.size(), 0)
