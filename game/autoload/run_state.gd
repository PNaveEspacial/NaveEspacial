extends Node
## Run-scoped state (design D7): the current run's seed, seeded [RunRng],
## player [StatBlock], and progression counters. No `class_name`, for the
## same reason as [code]event_bus.gd[/code].
##
## Registered as the 2nd autoload (after [code]EventBus[/code]), ahead of
## `SaveStore`/`Settings` in this project's actual build order -- those
## land in S13/S15, after Player already depends on RunState in S8. This
## differs from design D7's prose listing order (EventBus, SaveStore,
## Settings, RunState); S13's own task explicitly registers SaveStore
## 3rd, confirming RunState is 2nd in the real slice sequence.

## Path to the [PlayerBaseStats] Resource this run's [StatBlock] is seeded
## from.
@export var base_stats_path: String = "res://data/player/player_base_stats.tres"

var run_seed: int = 0
var rng: RunRng
var stats: StatBlock
var base_stats: PlayerBaseStats
var score: int = 0
var xp: int = 0
var level: int = 1
var wave: int = 0
var kills: int = 0
var stacks: Dictionary = {}
var pending_level_ups: int = 0

var _level_curve := LevelCurve.new()


func _ready() -> void:
	base_stats = load(base_stats_path)


## Generates a fresh seed and starts a run with it (design D18's main
## menu Play action).
func prepare_new_run() -> void:
	randomize()
	start_run(randi())


## (Re)initializes every run-scoped field for [param new_seed] and emits
## [signal EventBus.run_started].
func start_run(new_seed: int) -> void:
	run_seed = new_seed
	rng = RunRng.new(new_seed)
	stats = _make_stat_block()
	score = 0
	xp = 0
	level = 1
	wave = 0
	kills = 0
	stacks = {}
	pending_level_ups = 0
	EventBus.run_started.emit(run_seed)


func add_score(amount: int) -> void:
	score += amount
	EventBus.score_changed.emit(score)


## Adds [param amount] XP via [LevelCurve], advancing [member level] and
## emitting [signal EventBus.level_up_ready] once per level gained.
func add_xp(amount: int) -> void:
	var result := _level_curve.add_xp(level, xp, amount)
	level = result.level
	xp = result.xp
	EventBus.xp_changed.emit(xp, _level_curve.xp_to_next(level), level)
	if result.levels_gained > 0:
		pending_level_ups += result.levels_gained
		EventBus.level_up_ready.emit(pending_level_ups)


## Ends the run: submits [member score] to [SaveStore] (design D17/D18)
## and emits [signal EventBus.run_ended] with the persisted best and
## whether this run set a new one. The only caller is [GameOver], after
## its death-delay fx window (design D18's flow).
func end_run() -> void:
	var is_new_best := SaveStore.submit_score(score)
	EventBus.run_ended.emit(score, SaveStore.best_score, is_new_best)


func _make_stat_block() -> StatBlock:
	var base := {
		StatBlock.Stat.MAX_HP: base_stats.max_hp,
		StatBlock.Stat.MOVE_SPEED: base_stats.move_speed,
		StatBlock.Stat.FIRE_RATE: base_stats.fire_rate,
		StatBlock.Stat.DAMAGE: base_stats.damage,
		StatBlock.Stat.PROJECTILE_COUNT: base_stats.projectile_count,
		StatBlock.Stat.BULLET_SPEED: base_stats.bullet_speed,
		StatBlock.Stat.PICKUP_RADIUS: base_stats.pickup_radius,
	}
	return StatBlock.new(base)
