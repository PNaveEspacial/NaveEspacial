class_name StatBlock
extends RefCounted
## Aggregates a base stat value with every applied [StatModifier] (design
## D14): [code]value = clamp((base + sum(ADD)) * (1 + sum(MULT)) *
## product(1 + COMPOUND_i))[/code]. Each stat has its own floor (and, where
## relevant, ceiling) so no combination of upgrades can push it negative or
## unbounded.

enum Stat { MAX_HP, MOVE_SPEED, FIRE_RATE, DAMAGE, PROJECTILE_COUNT, BULLET_SPEED, PICKUP_RADIUS }

## [min, max] clamp bounds per stat. INF means "no ceiling".
const _CLAMPS := {
	Stat.MAX_HP: [1.0, INF],
	Stat.MOVE_SPEED: [0.0, INF],
	Stat.FIRE_RATE: [0.01, INF],
	Stat.DAMAGE: [0.0, INF],
	Stat.PROJECTILE_COUNT: [1.0, INF],
	Stat.BULLET_SPEED: [0.0, INF],
	Stat.PICKUP_RADIUS: [0.0, INF],
}

var _base: Dictionary
var _add: Dictionary = {}
var _mult: Dictionary = {}
var _compound: Dictionary = {}


## [param base] is keyed by [enum Stat]; any stat missing from it defaults
## to 0.0 before modifiers are applied.
func _init(base: Dictionary) -> void:
	_base = base.duplicate()
	for stat in Stat.values():
		_add[stat] = 0.0
		_mult[stat] = 0.0
		_compound[stat] = []


func apply(modifier: StatModifier) -> void:
	match modifier.op:
		StatModifier.Op.ADD:
			_add[modifier.stat] += modifier.value
		StatModifier.Op.MULT:
			_mult[modifier.stat] += modifier.value
		StatModifier.Op.COMPOUND:
			_compound[modifier.stat].append(modifier.value)


## The clamped float value of [param stat] after every applied modifier.
func value(stat: Stat) -> float:
	var base: float = _base.get(stat, 0.0)
	var add_amount: float = _add[stat]
	var mult_amount: float = _mult[stat]
	var result: float = (base + add_amount) * (1.0 + mult_amount)
	for compound_value in _compound[stat]:
		result *= 1.0 + float(compound_value)
	var bounds: Array = _CLAMPS[stat]
	return clampf(result, bounds[0], bounds[1])


## [method value] rounded to the nearest int (for stats like
## [constant Stat.PROJECTILE_COUNT] that must be whole numbers).
func value_int(stat: Stat) -> int:
	return int(round(value(stat)))
