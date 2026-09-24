extends GutTest
## Covers xp-and-upgrades' Non-Decreasing XP-to-Level Curve requirement.


func test_required_xp_never_decreases_across_levels_1_to_20():
	var curve := LevelCurve.new()
	var previous := -1
	for level in range(1, 21):
		var required := curve.xp_to_next(level)
		assert_gte(required, 1, "xp_to_next(%d) should be at least 1" % level)
		assert_gte(required, previous, "xp_to_next should not decrease at level %d" % level)
		previous = required


func test_add_xp_with_no_level_up_keeps_the_same_level():
	var curve := LevelCurve.new()
	var required := curve.xp_to_next(1)
	var result := curve.add_xp(1, 0, required - 1)
	assert_eq(result["level"], 1)
	assert_eq(result["xp"], required - 1)
	assert_eq(result["levels_gained"], 0)


func test_add_xp_carries_over_a_single_level_up():
	var curve := LevelCurve.new()
	var required := curve.xp_to_next(1)
	var result := curve.add_xp(1, 0, required)
	assert_eq(result["level"], 2)
	assert_eq(result["xp"], 0)
	assert_eq(result["levels_gained"], 1)


func test_add_xp_carries_over_multiple_level_ups_in_one_call():
	var curve := LevelCurve.new()
	var huge_gain := curve.xp_to_next(1) + curve.xp_to_next(2) + curve.xp_to_next(3) + 5
	var result := curve.add_xp(1, 0, huge_gain)
	assert_eq(result["level"], 4)
	assert_eq(result["xp"], 5)
	assert_eq(result["levels_gained"], 3)
