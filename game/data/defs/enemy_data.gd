class_name EnemyData
extends Resource
## Data-driven enemy definition (design D13). Enemy behavior scripts read
## every stat from here rather than hardcoding constants.
##
## S4 introduced the subset [DifficultyCurve.type_weight] needs (moved up
## from S5.T1's original scope because the pure [DifficultyCurve] contract
## is typed against [EnemyData]). S5 added [member behavior] and
## [member cost] for [code]WaveComposer[/code]; S9 adds the remaining
## combat, visual, and bullet fields S10's Enemy scene reads.

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

## Base hit points before [method DifficultyCurve.hp_multiplier] scales it.
@export var base_hp: float = 3.0

## Base move speed before [method DifficultyCurve.speed_multiplier] scales
## it, in pixels/second.
@export var move_speed: float = 60.0

## Acceleration passed to [method Steering.approach], in pixels/second^2.
@export var accel: float = 240.0

## Damage applied to the player on a [code]Hurtbox[/code] overlap (design
## D11; read via the [code]get_contact_damage()[/code] duck-typed
## contract [Player] expects).
@export var contact_damage: float = 1.0

## Score awarded to [code]RunState[/code] on this enemy's death.
@export var score_value: int = 10

## XP carried by the pickup this enemy drops on death (S11).
@export var xp_value: int = 5

## The sprite sheet this enemy's visual reads from (design D13: currently
## always [code]ships_packed.png[/code]).
@export var texture: Texture2D

## Index into [member texture]'s 32x32 grid (row-major, 4 columns), used
## to build the [AtlasTexture] region S10's Enemy scene renders.
@export var frame: int = 0

## Radius used for the [code]Hurtbox[/code]/contact collision shape.
@export var hurt_radius: float = 12.0

## Seconds after spawning before this enemy may fire (design D13's
## KEEP_DISTANCE behavior; ignored by CHASE).
@export var spawn_grace_s: float = 0.5

## KEEP_DISTANCE's inner band: back off when closer than this.
@export var range_min: float = 90.0

## KEEP_DISTANCE's outer band: approach when farther than this.
@export var range_max: float = 160.0

## Seconds between shots for KEEP_DISTANCE enemies (difficulty-scaled by
## the Enemy scene, not here).
@export var fire_interval_s: float = 2.0

## Seconds a shot's telegraph flash plays before the bullet actually
## fires (design D13: "no instant snipes").
@export var telegraph_s: float = 0.25

## Speed and damage of this enemy's own [code]EnemyBullet[/code], when
## [member behavior] is [constant Behavior.KEEP_DISTANCE].
@export var bullet_speed: float = 260.0
@export var bullet_damage: float = 1.0
