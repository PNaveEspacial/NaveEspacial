class_name EnemyData
extends Resource
## Data-driven enemy definition (design D13). Enemy behavior scripts read
## every stat from here rather than hardcoding constants.
##
## S4 note: only the fields [DifficultyCurve.type_weight] needs are defined
## here (moved up from S5.T1's original scope because the pure
## [DifficultyCurve] contract is typed against [EnemyData]). S5 extends this
## same file with [code]behavior[/code] and [code]cost[/code] for
## [code]WaveComposer[/code]; S9 adds the remaining combat fields.

## Stable identifier, used as the [code]StringName[/code] key in wave plans.
@export var id: StringName = &""

## Relative likelihood this enemy type is picked once unlocked. A weight of
## 0 or less means the entry is never eligible.
@export var spawn_weight: float = 1.0

## The first wave (inclusive) at which this enemy type may appear. Before
## this wave, [method DifficultyCurve.type_weight] returns 0 for it.
@export var unlock_wave: int = 1
