class_name XpOrb
extends Area2D
## Pooled XP pickup (design D14; xp-and-upgrades spec capability). Spawned
## by [code]game.gd[/code] on [signal EventBus.enemy_killed], carrying
## [member EnemyData.xp_value]. Passive on the [code]pickup[/code] physics
## layer (design D11: pickups are scanned, they never scan); the player's
## [code]PickupMagnet[/code] Area2D does the scanning and calls [method
## collect] once this orb is within [code]PICKUP_RADIUS[/code].

signal despawn_requested

var xp_value: int = 0
var _active: bool = false


## Pooled-node contract (design D10 interfaces). [param params] keys:
## [code]"position"[/code] (Vector2) and [code]"xp_value"[/code] (int).
func activate(params: Dictionary) -> void:
	xp_value = params.get("xp_value", 0)
	global_position = params.get("position", Vector2.ZERO)
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	_active = true
	reset_physics_interpolation()


func deactivate() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


## Called by the player's [code]PickupMagnet[/code] once this orb overlaps
## it (design D11). Grants XP and requests despawn; a no-op once already
## collected, guarding against a double-collect in the same physics frame
## before the pool's deferred release runs.
func collect() -> void:
	if not _active:
		return
	_active = false
	RunState.add_xp(xp_value)
	despawn_requested.emit()
