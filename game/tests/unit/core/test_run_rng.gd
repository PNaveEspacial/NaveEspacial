extends GutTest
## Covers run-rng-and-difficulty's Seeded Run RNG requirement.


func _draw_sequence(rng: RandomNumberGenerator, count: int) -> Array[int]:
	var values: Array[int] = []
	for i in range(count):
		values.append(rng.randi())
	return values


func test_same_seed_reproduces_identical_stream_sequences():
	var a := RunRng.new(1234)
	var b := RunRng.new(1234)
	for stream_id in RunRng.Stream.values():
		var seq_a := _draw_sequence(a.stream(stream_id), 20)
		var seq_b := _draw_sequence(b.stream(stream_id), 20)
		assert_eq(seq_a, seq_b, "stream %d should reproduce the same sequence for the same seed" % stream_id)


func test_different_seeds_diverge():
	var a := RunRng.new(1)
	var b := RunRng.new(2)
	var seq_a := _draw_sequence(a.stream(RunRng.Stream.WAVES), 20)
	var seq_b := _draw_sequence(b.stream(RunRng.Stream.WAVES), 20)
	assert_ne(seq_a, seq_b, "different seeds should produce different sequences")


func test_heavy_spawns_draws_never_shift_upgrades():
	var untouched := RunRng.new(9001)
	var heavy := RunRng.new(9001)

	# Consume a large, variable number of draws from SPAWNS on `heavy` only,
	# simulating rejection sampling. UPGRADES must be unaffected on both.
	var spawns_rng := heavy.stream(RunRng.Stream.SPAWNS)
	for i in range(500):
		spawns_rng.randf()

	var expected := _draw_sequence(untouched.stream(RunRng.Stream.UPGRADES), 20)
	var actual := _draw_sequence(heavy.stream(RunRng.Stream.UPGRADES), 20)
	assert_eq(actual, expected, "heavy SPAWNS draws should not shift the UPGRADES stream")


func test_get_seed_returns_the_master_seed():
	var rng := RunRng.new(42)
	assert_eq(rng.get_seed(), 42)


func test_seed_format_round_trips():
	var seeds := [0, 1, 42, 0xA3F219C0, 0xFFFFFFFF]
	for seed in seeds:
		var display := SeedFormat.to_display(seed)
		assert_eq(SeedFormat.from_display(display), seed, "round trip should preserve seed %d" % seed)


func test_seed_format_matches_documented_shape():
	assert_eq(SeedFormat.to_display(0xA3F219C0), "A3F2-19C0")


func test_seed_format_rejects_invalid_display_text():
	assert_eq(SeedFormat.from_display("not-a-seed"), -1)
	assert_eq(SeedFormat.from_display(""), -1)
	assert_eq(SeedFormat.from_display("A3F219C0"), -1)
