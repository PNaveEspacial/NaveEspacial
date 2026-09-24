class_name Steering
extends RefCounted
## Pure steering primitives (design D13). Each function returns a velocity
## (or an accel-limited step toward one) in world units per second;
## nothing here touches a Node, the physics server, or global randomness
## -- callers (S10's Enemy scene) apply the result via [method
## CharacterBody2D.move_and_slide].

## A velocity of magnitude [param speed] pointing from [param pos]
## straight toward [param target]. Returns [constant Vector2.ZERO] when
## [param pos] and [param target] coincide.
static func seek(pos: Vector2, target: Vector2, speed: float) -> Vector2:
	var to_target := target - pos
	if to_target.length() < 0.001:
		return Vector2.ZERO
	return to_target.normalized() * speed


## Keeps [param pos] within [code][param range_min, param range_max][/code]
## of [param target] (design D13's "gunship" behavior): approaches when
## farther than [param range_max], backs off when closer than [param
## range_min], and strafes perpendicular to the target in between --
## the strafe direction follows the sign of [param strafe_sign].
static func keep_distance(
	pos: Vector2,
	target: Vector2,
	range_min: float,
	range_max: float,
	strafe_sign: int,
	speed: float
) -> Vector2:
	var to_target := target - pos
	var distance := to_target.length()
	if distance < 0.001:
		return Vector2.ZERO
	var direction := to_target / distance
	if distance > range_max:
		return direction * speed
	if distance < range_min:
		return -direction * speed
	var sign_value: float = 1.0 if strafe_sign >= 0 else -1.0
	var perpendicular := Vector2(-direction.y, direction.x) * sign_value
	return perpendicular * speed


## Moves [param current] toward [param desired] by at most [param accel] *
## [param delta] units this call -- an accel-limited velocity
## interpolation, not a teleport. Reaches [param desired] exactly once
## within one step's reach.
static func approach(current: Vector2, desired: Vector2, accel: float, delta: float) -> Vector2:
	var max_delta := accel * delta
	var diff := desired - current
	if diff.length() <= max_delta:
		return desired
	return current + diff.normalized() * max_delta
