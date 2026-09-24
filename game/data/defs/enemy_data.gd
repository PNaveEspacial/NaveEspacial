class_name EnemyData
extends Resource
## Data-driven enemy definition (design D13). Enemy behavior scripts read
## every stat from here rather than hardcoding constants.
##
## S4 introduced the subset [DifficultyCurve.type_weight] needs (moved up
## from S5.T1's original scope because the pure [DifficultyCurve] contract
## is typed against [EnemyData]). S5 adds [member behavior] and
## [member cost] for [code]WaveComposer[/code]; S9 adds the remaining
## combat fields (hp, speed, damage, bullet stats, and so on).

## The two enemy behaviors this MVP ships with (design D13).
enum Behavior { CHASE, KEEP_DISTANCE }

## Stable identifier, used as the [code]StringName[/code] key in wave plans.
@export var id: StringName = &""

## How this enemy type moves toward and engages the player.
@export var behavior: Behavior = Behavior.CHASE

## Spawn-budget cost of one instance of this enemy type, spent by
## [code]WaveComposer[/code] against [method DifficultyCurve.budget].
@export var cost: float = 1.0

## Relative likelihood this enemy type is picked once unlocked. A weight of
## 0 or less means the entry is never eligible.
@export var spawn_weight: float = 1.0

## The first wave (inclusive) at which this enemy type may appear. Before
## this wave, [method DifficultyCurve.type_weight] returns 0 for it.
@export var unlock_wave: int = 1
