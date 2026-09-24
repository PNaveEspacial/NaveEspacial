extends GutTest
## Covers xp-and-upgrades' Upgrade Effect Application requirement and
## StatBlock's add-then-mult-then-compound formula and per-stat clamps.


func _make_modifier(stat: StatBlock.Stat, op: StatModifier.Op, value: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = stat
	modifier.op = op
	modifier.value = value
	return modifier


func test_applying_an_add_modifier_increases_the_stat():
	var stats := StatBlock.new({StatBlock.Stat.FIRE_RATE: 10.0})
	stats.apply(_make_modifier(StatBlock.Stat.FIRE_RATE, StatModifier.Op.ADD, 5.0))
	assert_almost_eq(stats.value(StatBlock.Stat.FIRE_RATE), 15.0, 0.0001)


func test_formula_applies_add_then_mult_then_compound_in_order():
	var stats := StatBlock.new({StatBlock.Stat.DAMAGE: 10.0})
	stats.apply(_make_modifier(StatBlock.Stat.DAMAGE, StatModifier.Op.ADD, 5.0))
	stats.apply(_make_modifier(StatBlock.Stat.DAMAGE, StatModifier.Op.MULT, 0.5))
	stats.apply(_make_modifier(StatBlock.Stat.DAMAGE, StatModifier.Op.COMPOUND, 0.1))
	stats.apply(_make_modifier(StatBlock.Stat.DAMAGE, StatModifier.Op.COMPOUND, 0.1))

	# (10 + 5) * (1 + 0.5) * (1 + 0.1) * (1 + 0.1) = 15 * 1.5 * 1.1 * 1.1 = 27.225
	assert_almost_eq(stats.value(StatBlock.Stat.DAMAGE), 27.225, 0.001)


func test_multiple_add_and_mult_modifiers_accumulate_before_combining():
	var stats := StatBlock.new({StatBlock.Stat.MOVE_SPEED: 100.0})
	stats.apply(_make_modifier(StatBlock.Stat.MOVE_SPEED, StatModifier.Op.ADD, 10.0))
	stats.apply(_make_modifier(StatBlock.Stat.MOVE_SPEED, StatModifier.Op.ADD, 10.0))
	stats.apply(_make_modifier(StatBlock.Stat.MOVE_SPEED, StatModifier.Op.MULT, 0.1))
	stats.apply(_make_modifier(StatBlock.Stat.MOVE_SPEED, StatModifier.Op.MULT, 0.1))

	# (100 + 10 + 10) * (1 + 0.1 + 0.1) = 120 * 1.2 = 144
	assert_almost_eq(stats.value(StatBlock.Stat.MOVE_SPEED), 144.0, 0.0001)


func test_move_speed_never_goes_negative():
	var stats := StatBlock.new({StatBlock.Stat.MOVE_SPEED: 10.0})
	stats.apply(_make_modifier(StatBlock.Stat.MOVE_SPEED, StatModifier.Op.ADD, -1000.0))
	assert_gte(stats.value(StatBlock.Stat.MOVE_SPEED), 0.0)


func test_projectile_count_floors_at_one():
	var stats := StatBlock.new({StatBlock.Stat.PROJECTILE_COUNT: 1.0})
	stats.apply(_make_modifier(StatBlock.Stat.PROJECTILE_COUNT, StatModifier.Op.MULT, -0.9))
	assert_gte(stats.value(StatBlock.Stat.PROJECTILE_COUNT), 1.0)


func test_missing_base_stat_defaults_to_zero():
	var stats := StatBlock.new({})
	stats.apply(_make_modifier(StatBlock.Stat.BULLET_SPEED, StatModifier.Op.ADD, 50.0))
	assert_almost_eq(stats.value(StatBlock.Stat.BULLET_SPEED), 50.0, 0.0001)


func test_value_int_rounds_to_nearest_int():
	var stats := StatBlock.new({StatBlock.Stat.PROJECTILE_COUNT: 1.0})
	stats.apply(_make_modifier(StatBlock.Stat.PROJECTILE_COUNT, StatModifier.Op.ADD, 1.6))
	assert_eq(stats.value_int(StatBlock.Stat.PROJECTILE_COUNT), 3)
