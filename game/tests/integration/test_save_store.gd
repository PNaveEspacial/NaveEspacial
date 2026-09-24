extends GutTest
## Covers game-flow-ui's Best Score Persistence and Defensive Persisted-Data
## Read requirements (design D17). Uses a temp [code]user://[/code] path so
## these tests never touch the project's real save file, and loads a fresh
## [code]save_store.gd[/code] instance per test rather than the live
## [code]SaveStore[/code] autoload, so state never leaks between tests.

const _SAVE_STORE_SCRIPT := "res://autoload/save_store.gd"

var _save_path: String


func before_each():
	_save_path = "user://test_save_store_%d.cfg" % randi()


func after_each():
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists(_save_path.get_file()):
		dir.remove(_save_path.get_file())
	if dir.file_exists(_save_path.get_file() + ".bad"):
		dir.remove(_save_path.get_file() + ".bad")


func _new_store() -> Node:
	var store: Node = autofree(load(_SAVE_STORE_SCRIPT).new())
	store.save_path = _save_path
	return store


func test_missing_file_falls_back_to_defaults_without_raising():
	var store := _new_store()
	store.load_profile()
	assert_eq(store.best_score, 0)
	assert_eq(store.language, "")


func test_corrupt_file_falls_back_to_defaults_without_raising():
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	# An unterminated section header is a genuine ConfigFile parse error
	# (probed directly against this project's Godot 4.7.2 binary); a plain
	# unstructured string is parsed leniently as an empty config instead.
	file.store_string("[profile\nbest_score = 5")
	file.close()

	var store := _new_store()
	store.load_profile()
	assert_engine_error("ConfigFile parse error", "loading a corrupt file is expected to log one engine parse error")
	assert_eq(store.best_score, 0)
	assert_eq(store.language, "")

	var dir := DirAccess.open("user://")
	assert_true(dir.file_exists(_save_path.get_file() + ".bad"), "corrupt file should be renamed to '.bad'")


func test_higher_score_replaces_best():
	var store := _new_store()
	store.load_profile()
	var replaced: bool = store.submit_score(100)
	assert_true(replaced, "a first, positive score should always beat the default best of 0")
	assert_eq(store.best_score, 100)


func test_lower_or_equal_score_does_not_overwrite():
	var store := _new_store()
	store.load_profile()
	store.submit_score(100)

	var replaced_lower: bool = store.submit_score(50)
	assert_false(replaced_lower, "a lower score should not overwrite the stored best")
	assert_eq(store.best_score, 100)

	var replaced_equal: bool = store.submit_score(100)
	assert_false(replaced_equal, "an equal score should not overwrite the stored best")
	assert_eq(store.best_score, 100)


func test_best_persists_across_a_simulated_reload():
	var first_store := _new_store()
	first_store.load_profile()
	first_store.submit_score(250)

	var second_store := _new_store()
	second_store.load_profile()
	assert_eq(second_store.best_score, 250, "a fresh instance reading the same save_path should see the persisted best")
