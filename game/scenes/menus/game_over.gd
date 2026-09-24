class_name GameOver
extends CanvasLayer
## Game-over overlay (design D18; game-flow-ui spec capability). On
## [signal EventBus.player_died], waits [constant _DEATH_DELAY_S] (the fx
## placeholder window -- real dissolve/burst/shake fx land in S16) before
## calling [method RunState.end_run], which submits the score to
## [SaveStore] and emits [signal EventBus.run_ended]. This is the ONLY
## caller of [method RunState.end_run] (design D18's flow moved it here
## from [code]game.gd[/code]'s immediate, pre-S14 placeholder call).

const _DEATH_DELAY_S := 1.0

@onready var _score_label: Label = $CenterContainer/VBox/ScoreLabel
@onready var _seed_label: Label = $CenterContainer/VBox/SeedLabel
@onready var _best_label: Label = $CenterContainer/VBox/BestLabel
@onready var _new_best_label: Label = $CenterContainer/VBox/NewBestLabel
@onready var _retry_button: Button = $CenterContainer/VBox/RetryButton
@onready var _menu_button: Button = $CenterContainer/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_new_best_label.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_ended.connect(_on_run_ended)


func _on_player_died() -> void:
	await get_tree().create_timer(_DEATH_DELAY_S).timeout
	RunState.end_run()


func _on_run_ended(score: int, best: int, is_new_best: bool) -> void:
	_score_label.text = "%s %d" % [tr("GAMEOVER_SCORE"), score]
	_seed_label.text = "%s %s" % [tr("GAMEOVER_SEED"), SeedFormat.to_display(RunState.run_seed)]
	_best_label.text = "%s %d" % [tr("GAMEOVER_BEST"), best]
	_new_best_label.visible = is_new_best
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_retry_pressed() -> void:
	_close()
	RunState.prepare_new_run()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	_close()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _close() -> void:
	visible = false
	get_tree().paused = false
