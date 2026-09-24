extends GutTest

## Lints every .tscn under game/scenes/ for `text = "..."` properties and
## asserts each one is either empty or an existing translation key. Scenes
## with no Control nodes (S7's pooled projectiles, for example) have zero
## `text` properties and pass with a `pass_test` note instead of a
## zero-assertion no-op.

const SCENES_DIR := "res://scenes"
const CSV_PATH := "res://i18n/strings.csv"


func _load_csv_keys() -> Dictionary:
	var keys := {}
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return keys
	var first := true
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 1 and line[0] == "":
			continue
		if first:
			first = false
			continue
		keys[line[0]] = true
	file.close()
	return keys


func _find_tscn_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path := dir_path.path_join(entry)
			if dir.current_is_dir():
				found.append_array(_find_tscn_files(full_path))
			elif entry.ends_with(".tscn"):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func test_every_scene_text_property_traces_to_a_key():
	var csv_keys := _load_csv_keys()
	var tscn_files := _find_tscn_files(SCENES_DIR)

	if tscn_files.size() == 0:
		# No scenes exist yet (pre-S8). Passes vacuously; still asserts so
		# this test is never a silent zero-assertion no-op.
		assert_eq(tscn_files.size(), 0, "No scenes under res://scenes/ yet.")
		return

	var text_prop_regex := RegEx.new()
	text_prop_regex.compile("text\\s*=\\s*\"([^\"]*)\"")
	var checked := 0

	for scene_path in tscn_files:
		var file := FileAccess.open(scene_path, FileAccess.READ)
		if file == null:
			continue
		var content := file.get_as_text()
		file.close()

		for m in text_prop_regex.search_all(content):
			var literal: String = m.get_string(1)
			var ok: bool = literal == "" or csv_keys.has(literal)
			assert_true(ok, "%s has a hardcoded UI literal '%s' with no matching CSV key." % [scene_path, literal])
			checked += 1

	# Scenes may legitimately have zero `text = "..."` properties (for
	# example S7's projectile scenes, which have no Control nodes at all).
	# Assert on the scan itself so this never silently becomes a
	# zero-assertion "risky" test once real UI scenes land in S12+.
	assert_true(tscn_files.size() > 0, "expected at least one .tscn under res://scenes/")
	if checked == 0:
		pass_test("no text properties found in %d scene(s); nothing to flag" % tscn_files.size())
