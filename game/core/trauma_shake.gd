class_name TraumaShake
extends RefCounted
## Pure trauma-accumulator screen-shake model (design D15). Trauma is a
## [code]0..1[/code] value that decays linearly over time; the sampled
## offset scales with trauma SQUARED (a standard trauma-shake technique:
## small trauma barely shakes, large trauma shakes hard), producing a
## whole-pixel [Vector2i] so the shake never blurs the pixel grid (design
## D3's snap-to-pixel rule).

var _max_offset_px: float
var _decay_per_s: float
var _trauma: float = 0.0


func _init(max_offset_px: float = 4.0, decay_per_s: float = 1.8) -> void:
	_max_offset_px = max_offset_px
	_decay_per_s = decay_per_s


## Adds [param amount] trauma, clamped to [code]1.0[/code]. Repeated hits
## stack (design D15's per-event trauma amounts: player hit 0.5, enemy
## death 0.15, player death 1.0).
func add(amount: float) -> void:
	_trauma = clamp(_trauma + amount, 0.0, 1.0)


## Advances trauma decay by [param delta] seconds and returns this
## frame's whole-pixel shake offset, sampled from [param rng] on both
## axes independently.
func tick(delta: float, rng: RandomNumberGenerator) -> Vector2i:
	var offset := Vector2i(
		int(round(_max_offset_px * _trauma * _trauma * rng.randf_range(-1.0, 1.0))),
		int(round(_max_offset_px * _trauma * _trauma * rng.randf_range(-1.0, 1.0)))
	)
	_trauma = max(_trauma - _decay_per_s * delta, 0.0)
	return offset


## The current trauma value, mostly for tests.
func get_trauma() -> float:
	return _trauma
