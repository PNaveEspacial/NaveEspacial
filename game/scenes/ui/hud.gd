class_name Hud
extends CanvasLayer
## In-run HUD (design D18; game-flow-ui spec capability): real-time HP,
## XP progress toward next level, level, score, and wave number.
##
## [EventBus] only re-emits *changes*, so a value that has not changed
## since the run started (for example wave 0 before the first
## [signal EventBus.wave_started]) needs an explicit initial read here --
## [member set_player] (design D10-style caller-owns-wiring) covers HP,
## and [method _ready] reads [RunState]'s own already-public fields for
## score/level/wave/xp.

@onready var _hp_bar: ProgressBar = $Root/TopLeft/HpBar
@onready var _xp_bar: ProgressBar = $Root/TopLeft/XpBar
@onready var _level_label: Label = $Root/TopLeft/LevelLabel
@onready var _score_label: Label = $Root/TopRight/ScoreLabel
@onready var _wave_label: Label = $Root/TopRight/WaveLabel

## A private [LevelCurve] just to recompute the current
## [code]xp_to_next[/code] for the initial XP bar range -- [RunState] does
## not expose its own instance, and [signal EventBus.xp_changed] has not
## fired yet at the start of a run.
var _level_curve := LevelCurve.new()


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.xp_changed.connect(_on_xp_changed)
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.wave_started.connect(_on_wave_started)
	_on_xp_changed(RunState.xp, _level_curve.xp_to_next(RunState.level), RunState.level)
	_on_score_changed(RunState.score)
	_on_wave_started(RunState.wave)


## Set by the owning scene once the player exists, so the HP bar starts
## correct instead of waiting for the first damage event.
func set_player(player: Player) -> void:
	var max_hp := int(round(RunState.stats.value(StatBlock.Stat.MAX_HP)))
	_on_health_changed(int(round(player.get_hp())), max_hp)


func _on_health_changed(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func _on_xp_changed(xp: int, xp_to_next: int, level: int) -> void:
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = xp
	_level_label.text = "%s %d" % [tr("HUD_LEVEL"), level]


func _on_score_changed(score: int) -> void:
	_score_label.text = "%s %d" % [tr("HUD_SCORE"), score]


func _on_wave_started(wave: int) -> void:
	_wave_label.text = tr("WAVE_LABEL").format({"n": wave})
