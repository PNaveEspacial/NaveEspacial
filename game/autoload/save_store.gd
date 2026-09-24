extends Node
## Defensive [code]user://save.cfg[/code] reader/writer (design D17). No
## `class_name`, for the same reason as [code]event_bus.gd[/code]: the
## autoload name `SaveStore` already provides global access, and tests
## load this script directly with [code]load("res://autoload/save_store.gd").new()[/code]
## rather than referencing a global class.
##
## Registered as the 3rd autoload (after [code]EventBus[/code] and
## [code]RunState[/code]), per this slice's own task -- design D7's prose
## lists SaveStore 2nd, but `RunState`'s own header comment already
## documents the real build-order deviation.

const _SAVE_PATH_DEFAULT := "user://save.cfg"

## Path to the save file. A plain [code]var[/code] (not a constant) so
## tests can point it at a temp path instead of the real [code]user://[/code]
## profile.
var save_path: String = _SAVE_PATH_DEFAULT

var best_score: int = 0
var language: String = ""


func _ready() -> void:
	load_profile()


## Loads [member save_path] into [member best_score]/[member language].
## [constant ERR_FILE_NOT_FOUND] silently falls back to defaults (first
## launch). Any other read/parse error renames the unreadable file to
## [code]<save_path>.bad[/code] (best effort) and also falls back to
## defaults, so a corrupt file never raises and never blocks startup.
## Loaded values always pass through [method ProfileRules.sanitize].
func load_profile() -> void:
	var config := ConfigFile.new()
	var err := config.load(save_path)
	if err == ERR_FILE_NOT_FOUND:
		_reset_to_defaults()
		return
	if err != OK:
		DirAccess.rename_absolute(save_path, save_path + ".bad")
		_reset_to_defaults()
		return

	var raw := {
		"best_score": config.get_value("profile", "best_score", 0),
		"language": config.get_value("settings", "language", ""),
	}
	var sanitized := ProfileRules.sanitize(raw)
	best_score = sanitized.best_score
	language = sanitized.language


## Writes the current [member best_score]/[member language] to [member
## save_path].
func save() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("profile", "best_score", best_score)
	config.set_value("settings", "language", language)
	config.save(save_path)


## Updates [member best_score] via [method ProfileRules.merge_best] and
## saves only when [param score] beats the stored best. Returns
## [code]true[/code] when a new best was recorded.
func submit_score(score: int) -> bool:
	var merged := ProfileRules.merge_best(best_score, score)
	if merged == best_score:
		return false
	best_score = merged
	save()
	return true


func _reset_to_defaults() -> void:
	best_score = 0
	language = ""
