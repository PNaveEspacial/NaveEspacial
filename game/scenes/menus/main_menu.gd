class_name MainMenu
extends Control
## The project's main scene (design D18; game-flow-ui spec capability).
## Play starts a fresh seeded run and switches to [code]game.tscn[/code];
## Settings toggles an embedded panel (populated with the language
## selector in S15); Quit exits. Design D5: the OS mouse cursor is
## visible here, unlike the confined/hidden crosshair mode gameplay uses.

@onready var _play_button: Button = $CenterContainer/VBox/PlayButton
@onready var _settings_button: Button = $CenterContainer/VBox/SettingsButton
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton
@onready var _settings_panel: Control = $SettingsPanel
@onready var _settings_back_button: Button = $SettingsPanel/CenterContainer/VBox/BackButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_settings_panel.visible = false
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_back_button.pressed.connect(_on_settings_back_pressed)


func _on_play_pressed() -> void:
	RunState.prepare_new_run()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_settings_pressed() -> void:
	_settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	_settings_panel.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()
