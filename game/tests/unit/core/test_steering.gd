extends GutTest
## Covers enemies-and-waves' Player-Seeking Behavior requirement's pure
## primitives (design D13).


func test_seek_returns_speed_magnitude_toward_target():
	var result := Steering.seek(Vector2(0, 0), Vector2(10, 0), 5.0)
	assert_almost_eq(result.length(), 5.0, 0.001)
	assert_almost_eq(result.x, 5.0, 0.001)
	assert_almost_eq(result.y, 0.0, 0.001)


func test_seek_returns_zero_when_coincident():
	var result := Steering.seek(Vector2(3, 3), Vector2(3, 3), 5.0)
	assert_eq(result, Vector2.ZERO)


func test_keep_distance_approaches_when_farther_than_range_max():
	var pos := Vector2(0, 0)
	var target := Vector2(200, 0)
	var result := Steering.keep_distance(pos, target, 50.0, 100.0, 1, 40.0)
	assert_almost_eq(result.x, 40.0, 0.001)
	assert_almost_eq(result.y, 0.0, 0.001)


func test_keep_distance_backs_off_when_closer_than_range_min():
	var pos := Vector2(0, 0)
	var target := Vector2(10, 0)
	var result := Steering.keep_distance(pos, target, 50.0, 100.0, 1, 40.0)
	assert_almost_eq(result.x, -40.0, 0.001)
	assert_almost_eq(result.y, 0.0, 0.001)


func test_keep_distance_strafes_perpendicular_in_between():
	var pos := Vector2(0, 0)
	var target := Vector2(75, 0)
	var to_target := (target - pos).normalized()
	var result := Steering.keep_distance(pos, target, 50.0, 100.0, 1, 40.0)
	assert_almost_eq(result.length(), 40.0, 0.001)
	assert_almost_eq(result.dot(to_target), 0.0, 0.001)


func test_keep_distance_strafe_sign_flips_direction():
	var pos := Vector2(0, 0)
	var target := Vector2(75, 0)
	var positive := Steering.keep_distance(pos, target, 50.0, 100.0, 1, 40.0)
	var negative := Steering.keep_distance(pos, target, 50.0, 100.0, -1, 40.0)
	assert_almost_eq(positive.x, -negative.x, 0.001)
	assert_almost_eq(positive.y, -negative.y, 0.001)


func test_keep_distance_returns_zero_when_coincident():
	var result := Steering.keep_distance(Vector2(5, 5), Vector2(5, 5), 50.0, 100.0, 1, 40.0)
	assert_eq(result, Vector2.ZERO)


func test_approach_moves_partway_toward_a_far_desired_velocity():
	var current := Vector2.ZERO
	var desired := Vector2(100, 0)
	var result := Steering.approach(current, desired, 50.0, 0.1)
	assert_almost_eq(result.x, 5.0, 0.001)
	assert_almost_eq(result.y, 0.0, 0.001)


func test_approach_reaches_desired_exactly_when_within_reach():
	var current := Vector2(98, 0)
	var desired := Vector2(100, 0)
	var result := Steering.approach(current, desired, 50.0, 0.1)
	assert_eq(result, desired)


func test_approach_converges_over_repeated_calls():
	var current := Vector2.ZERO
	var desired := Vector2(100, 0)
	for i in range(50):
		current = Steering.approach(current, desired, 50.0, 0.1)
	assert_almost_eq(current.x, 100.0, 0.01)
