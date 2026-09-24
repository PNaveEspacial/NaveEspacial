class_name SpawnRing
extends RefCounted
## Seeded perimeter spawn positions (design D9). Every generated position
## lies strictly outside [param arena], and single-point picks respect a
## minimum distance from the player when possible.
##
## S4 correction: [member _min_player_distance]'s default scales with the
## S4 resolution bump (480x270 -> 640x360), so the design's documented
## 120.0 px default becomes 160.0 px here (120 * 640/480).

var _arena: Rect2
var _margin: float
var _min_player_distance: float
var _max_attempts: int


func _init(arena: Rect2, margin: float = 16.0, min_player_distance: float = 160.0, max_attempts: int = 8) -> void:
	_arena = arena
	_margin = margin
	_min_player_distance = min_player_distance
	_max_attempts = max_attempts


## Picks one spawn position, rejecting candidates closer than
## [member _min_player_distance] for up to [member _max_attempts] tries.
## When every attempt is rejected, deterministically returns the farthest
## candidate seen.
func pick(rng: RandomNumberGenerator, player_pos: Vector2) -> Vector2:
	var best_point := Vector2.ZERO
	var best_distance := -1.0
	for attempt in range(_max_attempts):
		var candidate := _random_perimeter_point(rng)
		var distance := candidate.distance_to(player_pos)
		if distance >= _min_player_distance:
			return candidate
		if distance > best_distance:
			best_distance = distance
			best_point = candidate
	return best_point


## Picks one anchor via [method pick], plus [param count] - 1 members
## spread within +/-[param spread] px along the same perimeter edge.
func pick_group(
	rng: RandomNumberGenerator, player_pos: Vector2, count: int, spread: float = 24.0
) -> PackedVector2Array:
	var points := PackedVector2Array()
	if count <= 0:
		return points
	var anchor := pick(rng, player_pos)
	points.append(anchor)
	for i in range(count - 1):
		var offset := rng.randf_range(-spread, spread)
		points.append(_offset_along_edge(anchor, offset))
	return points


func _grown_arena() -> Rect2:
	return _arena.grow(_margin)


## Uniformly samples a point on the grown arena's perimeter, parametrized
## by cumulative edge length: top, right, bottom, then left.
func _random_perimeter_point(rng: RandomNumberGenerator) -> Vector2:
	var rect := _grown_arena()
	var perimeter := 2.0 * (rect.size.x + rect.size.y)
	var t := rng.randf() * perimeter

	if t < rect.size.x:
		return Vector2(rect.position.x + t, rect.position.y)
	t -= rect.size.x

	if t < rect.size.y:
		return Vector2(rect.position.x + rect.size.x, rect.position.y + t)
	t -= rect.size.y

	if t < rect.size.x:
		return Vector2(rect.position.x + rect.size.x - t, rect.position.y + rect.size.y)
	t -= rect.size.x

	return Vector2(rect.position.x, rect.position.y + rect.size.y - t)


## Moves [param anchor] by [param offset] px along whichever edge of the
## grown arena it lies on, clamped so it never crosses a corner.
func _offset_along_edge(anchor: Vector2, offset: float) -> Vector2:
	var rect := _grown_arena()
	var left := rect.position.x
	var right := rect.position.x + rect.size.x
	var top := rect.position.y
	var bottom := rect.position.y + rect.size.y

	if is_equal_approx(anchor.y, top):
		return Vector2(clampf(anchor.x + offset, left, right), top)
	if is_equal_approx(anchor.x, right):
		return Vector2(right, clampf(anchor.y + offset, top, bottom))
	if is_equal_approx(anchor.y, bottom):
		return Vector2(clampf(anchor.x + offset, left, right), bottom)
	return Vector2(left, clampf(anchor.y + offset, top, bottom))
