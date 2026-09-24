class_name PlayerBaseStats
extends Resource
## Player base stat values (design D7) that seed [StatBlock] at run start,
## plus the two invulnerability timings from the player-ship spec
## capability. Upgrades (design D14) apply on top of these via
## [StatModifier]; they never edit this Resource.

@export var max_hp: float = 5.0
@export var move_speed: float = 140.0
@export var fire_rate: float = 4.0
@export var damage: float = 1.0
@export var projectile_count: float = 1.0
@export var bullet_speed: float = 420.0
@export var pickup_radius: float = 28.0

## Seconds of invulnerability granted after taking damage.
@export var invuln_s: float = 1.0

## Seconds of invulnerability granted on resuming from the level-up screen
## (design D14's level-up flow; wired when S12 lands).
@export var resume_invuln_s: float = 0.5
