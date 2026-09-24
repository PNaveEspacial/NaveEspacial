extends GutTest
## Covers player-ship's Cadence-Limited Firing Toward Cursor requirement.

const _DELTA_60HZ := 1.0 / 60.0
const _DELTA_30HZ := 1.0 / 30.0
const _DELTA_144HZ := 1.0 / 144.0


func _hold_for_seconds(cadence: FireCadence, delta: float, seconds: float, sps: float) -> int:
	var frames := int(round(seconds / delta))
	var total := 0
	for i in range(frames):
		total += cadence.tick(delta, true, sps)
	return total


func test_first_press_fires_immediately():
	var cadence := FireCadence.new()
	var fired := cadence.tick(_DELTA_60HZ, true, 5.0)
	assert_eq(fired, 1, "the first held tick should fire immediately")


## Observed on the real Godot 4.7.2 binary: double-precision drift in the
## accumulated deltas and the 0.1s interval can tip the boundary tick over
## at some frame rates (144Hz observed 11, not 10). The spec's own scenario
## ("Bullet count matches cadence over a hold window") already documents
## this as "within one bullet due to frame timing", so these assert a
## tolerance of 1 rather than exact equality.
func test_ten_shots_per_second_for_one_second_at_60hz():
	var cadence := FireCadence.new()
	var total := _hold_for_seconds(cadence, _DELTA_60HZ, 1.0, 10.0)
	assert_true(total >= 9 and total <= 11, "expected ~10 shots, got %d" % total)


func test_ten_shots_per_second_for_one_second_at_30hz():
	var cadence := FireCadence.new()
	var total := _hold_for_seconds(cadence, _DELTA_30HZ, 1.0, 10.0)
	assert_true(total >= 9 and total <= 11, "expected ~10 shots, got %d" % total)


func test_ten_shots_per_second_for_one_second_at_144hz():
	var cadence := FireCadence.new()
	var total := _hold_for_seconds(cadence, _DELTA_144HZ, 1.0, 10.0)
	assert_true(total >= 9 and total <= 11, "expected ~10 shots, got %d" % total)


func test_bullet_count_matches_cadence_within_one_bullet():
	# An odd cadence (7 sps) that does not divide the frame step evenly.
	var sps := 7.0
	var interval := 1.0 / sps
	var cadence := FireCadence.new()
	var total := _hold_for_seconds(cadence, _DELTA_60HZ, 1.0, sps)
	var expected: float = floor(1.0 / interval)
	assert_true(
		total >= expected - 1 and total <= expected + 1,
		"expected %d shots within one bullet, got %d" % [expected, total]
	)


func test_releasing_and_repressing_does_not_create_a_burst():
	var cadence := FireCadence.new()
	# 10 sps -> a 0.1s interval -> 6 frames at 60Hz.
	assert_eq(cadence.tick(_DELTA_60HZ, true, 10.0), 1, "first press fires")
	for i in range(3):
		cadence.tick(_DELTA_60HZ, true, 10.0)
	# Release right before the interval elapses, then re-press one frame later.
	cadence.tick(_DELTA_60HZ, false, 10.0)
	var fired := cadence.tick(_DELTA_60HZ, true, 10.0)
	assert_lte(fired, 1, "re-pressing must not bank the withheld cooldown into a burst")


func test_not_held_never_fires():
	var cadence := FireCadence.new()
	var total := 0
	for i in range(30):
		total += cadence.tick(_DELTA_60HZ, false, 10.0)
	assert_eq(total, 0)
