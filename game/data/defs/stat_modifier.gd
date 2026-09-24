class_name StatModifier
extends Resource
## One stat change applied by [StatBlock] (design D14): add a flat amount,
## add to the multiplier bucket, or multiply in as an independent compound
## factor.

## How [member value] combines into [StatBlock.value]'s formula:
## [code]clamp((base + sum(ADD)) * (1 + sum(MULT)) * product(1 + COMPOUND))[/code].
enum Op { ADD, MULT, COMPOUND }

@export var stat: StatBlock.Stat = StatBlock.Stat.MAX_HP
@export var op: Op = Op.ADD
@export var value: float = 0.0
