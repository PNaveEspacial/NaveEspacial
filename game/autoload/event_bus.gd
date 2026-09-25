extends Node
## Signals-only autoload (design D7). No `class_name`: the autoload name
## `EventBus` already provides global access, and a `class_name` here
## would collide with it (an engine error). Tests load this script
## directly with [code]load("res://autoload/event_bus.gd").new()[/code]
## rather than referencing a global class.
##
## Every signal in the design's EventBus contract is declared up front,
## even though S8 only emits a subset (run_started, player_health_changed,
## player_died, xp_changed, score_changed). Later slices (S10-S16) wire
## the rest without touching this file's shape again.
##
## [signal damage_dealt] is the one addition beyond design D7's literal
## interface list (S16): the design specifies floating damage numbers
## must trigger "on every damage event with the exact damage amount", but
## names no signal for it, and both damage entry points ([code]
## Player.take_damage[/code], [code]Enemy.take_damage[/code]) already fire
## before this slice. A broadcast signal here -- matching [signal
## enemy_killed]'s existing position-carrying shape -- lets [code]
## game.gd[/code] spawn the pooled [code]DamageNumber[/code] the same way
## it already spawns pooled [code]XpOrb[/code]s on [signal enemy_killed],
## instead of threading a new pool reference through every damage call
## site and [WaveDirector]'s [method Enemy.activate] params.

signal run_started(seed: int)
signal wave_started(wave: int)
signal enemy_killed(enemy_id: StringName, position: Vector2, score_value: int, xp_value: int)
signal player_health_changed(hp: int, max_hp: int)
signal player_died()
signal xp_changed(xp: int, xp_to_next: int, level: int)
signal score_changed(score: int)
signal level_up_ready(pending: int)
signal stats_changed()
signal run_ended(score: int, best: int, is_new_best: bool)
signal shake_requested(trauma: float)
signal damage_dealt(position: Vector2, amount: float)
