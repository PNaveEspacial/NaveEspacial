class_name LevelCurve
extends RefCounted
## Pure XP-to-next-level function and XP application (design D14).
## [method xp_to_next] is always >= 1 and strictly increasing as level
## increases.

var _base: int
var _linear: int
var _quadratic: float


func _init(base: int = 5, linear: int = 3, quadratic: float = 0.5) -> void:
	_base = base
	_linear = linear
	_quadratic = quadratic


## XP required to go from [param level] to [param level] + 1.
func xp_to_next(level: int) -> int:
	var required: float = _base + _linear * level + _quadratic * level * level
	return maxi(1, int(ceil(required)))


## Applies [param gained] XP on top of [param xp] at [param level], carrying
## over any number of level-ups. Returns
## [code]{level, xp, levels_gained}[/code].
func add_xp(level: int, xp: int, gained: int) -> Dictionary:
	var current_level := level
	var current_xp := xp + gained
	var levels_gained := 0
	while current_xp >= xp_to_next(current_level):
		current_xp -= xp_to_next(current_level)
		current_level += 1
		levels_gained += 1
	return {"level": current_level, "xp": current_xp, "levels_gained": levels_gained}
