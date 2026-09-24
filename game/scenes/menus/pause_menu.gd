class_name PauseMenu
extends CanvasLayer
## Optional pause overlay (design D18; game-flow-ui spec capability). The
## [code]pause[/code] action toggles it, stopping gameplay simulation
## (via [member SceneTree.paused]) without ending the run. Ignored while
## [LevelUpScreen] is open: that screen does not listen to [code]pause[/code]
## itself, so this menu must check its visibility before toggling (design
## D14's level-up flow explicitly leaves [code]pause[/code] unhandled
## while it is showing).

@onready var _resume_button: Button = $CenterContainer/VBox/ResumeButton
@onready var _menu_button: Button = $CenterContainer/VBox/MenuButton

## Set by the owning scene (design D10-style caller-owns-wiring).
var _level_up_screen: LevelUpScreen = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func set_level_up_screen(screen: LevelUpScreen) -> void:
	_level_up_screen = screen


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _level_up_screen != null and _level_up_screen.visible:
		return
	if visible:
		_resume()
	else:
		_open()
	get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	_resume()


func _on_menu_pressed() -> void:
	_resume()
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")


func _open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
