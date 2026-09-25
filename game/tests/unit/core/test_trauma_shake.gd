extends GutTest
## Covers game-feel's Whole-Pixel Screen Shake requirement's pure
## accumulator (design D15).

var _rng: RandomNumberGenerator


func before_each():
	_rng = RandomNumberGenerator.new()
	_rng.seed = 1


func test_every_sampled_offset_is_an_integer_vector2i():
	var shake := TraumaShake.new(4.0, 1.8)
	shake.add(1.0)
	for i in range(30):
		var offset := shake.tick(0.016, _rng)
		assert_typeof(offset, TYPE_VECTOR2I)


func test_offset_magnitude_stays_bounded_by_max_offset_px():
	var max_offset := 4.0
	var shake := TraumaShake.new(max_offset, 0.0)
	shake.add(1.0)
	for i in range(60):
		var offset := shake.tick(0.016, _rng)
		assert_true(abs(offset.x) <= max_offset, "x offset %d should not exceed max_offset_px %s" % [offset.x, max_offset])
		assert_true(abs(offset.y) <= max_offset, "y offset %d should not exceed max_offset_px %s" % [offset.y, max_offset])


func test_trauma_decays_to_zero_over_time():
	var shake := TraumaShake.new(4.0, 1.8)
	shake.add(1.0)
	for i in range(200):
		shake.tick(0.05, _rng)
	assert_eq(shake.get_trauma(), 0.0)


func test_zero_trauma_produces_zero_offset():
	var shake := TraumaShake.new(4.0, 1.8)
	var offset := shake.tick(0.016, _rng)
	assert_eq(offset, Vector2i.ZERO)


func test_trauma_does_not_exceed_one_when_added_repeatedly():
	var shake := TraumaShake.new(4.0, 0.0)
	for i in range(10):
		shake.add(0.5)
	assert_eq(shake.get_trauma(), 1.0)
