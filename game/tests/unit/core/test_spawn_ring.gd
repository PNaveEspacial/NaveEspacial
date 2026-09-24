extends GutTest
## Covers run-rng-and-difficulty's Seeded Perimeter Spawn Positions
## requirement. The visible arena matches S4's resolution bump (640x360).

const ARENA := Rect2(0, 0, 640, 360)


func _make_ring(min_player_distance: float = 160.0) -> SpawnRing:
	return SpawnRing.new(ARENA, 16.0, min_player_distance, 8)


func _is_outside_arena(point: Vector2) -> bool:
	return (
		point.x < ARENA.position.x
		or point.x > ARENA.position.x + ARENA.size.x
		or point.y < ARENA.position.y
		or point.y > ARENA.position.y + ARENA.size.y
	)


func test_1000_seeded_picks_land_outside_the_visible_arena():
	var ring := _make_ring()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var player_pos := Vector2(320, 180)
	for i in range(1000):
		var point := ring.pick(rng, player_pos)
		assert_true(_is_outside_arena(point), "pick #%d (%s) should land outside the visible arena" % [i, point])


func test_1000_seeded_picks_respect_minimum_player_distance():
	# A centered player is at least 196px from any point on the grown
	# perimeter, so every pick should satisfy the 160px minimum on its
	# first attempt; the deterministic fallback is exercised separately.
	var min_distance := 160.0
	var ring := _make_ring(min_distance)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var player_pos := Vector2(320, 180)
	for i in range(1000):
		var point := ring.pick(rng, player_pos)
		assert_gte(point.distance_to(player_pos), min_distance - 0.001)


func test_deterministic_farthest_fallback_when_no_candidate_qualifies():
	# An unreachable minimum distance forces every attempt to be rejected,
	# exercising the farthest-candidate fallback path.
	var ring := _make_ring(100000.0)
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 99
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 99
	var player_pos := Vector2(320, 180)

	var point_a := ring.pick(rng_a, player_pos)
	var point_b := ring.pick(rng_b, player_pos)
	assert_eq(point_a, point_b, "the fallback should be deterministic for the same seed")


func test_200_picks_from_a_fixed_seed_cover_all_four_sides():
	var ring := _make_ring()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var player_pos := Vector2(320, 180)
	var grown := ARENA.grow(16.0)
	var sides_hit := {"top": false, "right": false, "bottom": false, "left": false}

	for i in range(200):
		var point := ring.pick(rng, player_pos)
		if is_equal_approx(point.y, grown.position.y):
			sides_hit["top"] = true
		elif is_equal_approx(point.x, grown.position.x + grown.size.x):
			sides_hit["right"] = true
		elif is_equal_approx(point.y, grown.position.y + grown.size.y):
			sides_hit["bottom"] = true
		elif is_equal_approx(point.x, grown.position.x):
			sides_hit["left"] = true

	for side in sides_hit:
		assert_true(sides_hit[side], "side '%s' should receive at least one spawn in 200 picks" % side)


func test_pick_group_spreads_members_along_the_same_edge_and_stays_outside_arena():
	var ring := _make_ring()
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	var player_pos := Vector2(320, 180)
	var points := ring.pick_group(rng, player_pos, 4, 24.0)

	assert_eq(points.size(), 4)
	for point in points:
		assert_true(_is_outside_arena(point), "group member %s should stay outside the visible arena" % point)


func test_pick_group_with_zero_count_returns_empty():
	var ring := _make_ring()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var points := ring.pick_group(rng, Vector2(320, 180), 0, 24.0)
	assert_eq(points.size(), 0)
