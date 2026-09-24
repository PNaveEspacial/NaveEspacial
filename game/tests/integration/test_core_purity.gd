extends GutTest
## Enforces the domain/shell dependency rule from design D1: shell -> domain
## is allowed, domain -> shell is forbidden. Every [code].gd[/code] file
## under [code]res://core/[/code] and [code]res://data/defs/[/code] must
## stay free of Node/SceneTree access, global engine singletons, file I/O,
## autoload references, and unseeded global randomness.

const _PURE_DIRS := ["res://core", "res://data/defs"]

## D7's autoload names. Pure core must never reach into shell-owned state.
const _AUTOLOAD_NAMES := ["EventBus", "SaveStore", "Settings", "RunState"]

const _FORBIDDEN_SUBSTRINGS := [
	"extends Node",
	"get_tree(",
	"Input.",
	"OS.",
	"Engine.",
	"Time.",
	"FileAccess",
	"DirAccess",
]

const _RANDOM_FUNCTION_NAMES := ["randi(", "randf(", "randomize("]


func _collect_gd_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return files
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			files.append_array(_collect_gd_files(full_path))
		elif entry.ends_with(".gd"):
			files.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return files


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


## Drops full-line comments (doc comments explaining forbidden APIs, such as
## "draws two `randi()` values", must not trip the lint) before scanning for
## forbidden patterns. Inline trailing comments are intentionally left in
## place: real code on that line is still linted.
func _strip_full_line_comments(text: String) -> String:
	var kept: PackedStringArray = []
	for line in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			kept.append(line)
	return "\n".join(kept)


## True when [param text] calls a global random function without a receiver
## (for example bare [code]randi()[/code] instead of [code]rng.randi()[/code]).
func _has_receiverless_random_call(text: String) -> bool:
	for pattern in _RANDOM_FUNCTION_NAMES:
		var search_from := 0
		while true:
			var idx := text.find(pattern, search_from)
			if idx == -1:
				break
			var preceding_char := "" if idx == 0 else text.substr(idx - 1, 1)
			if preceding_char != ".":
				return true
			search_from = idx + 1
	return false


func test_pure_core_files_exist_to_lint():
	var total := 0
	for dir_path in _PURE_DIRS:
		total += _collect_gd_files(dir_path).size()
	assert_gt(total, 0, "expected at least one .gd file under core/ or data/defs/ to lint")


func test_pure_core_has_no_shell_dependencies():
	for dir_path in _PURE_DIRS:
		for path in _collect_gd_files(dir_path):
			var text := _strip_full_line_comments(_read_text(path))
			for forbidden in _FORBIDDEN_SUBSTRINGS:
				assert_false(text.contains(forbidden), "%s should not contain '%s'" % [path, forbidden])
			for autoload_name in _AUTOLOAD_NAMES:
				assert_false(
					text.contains(autoload_name + "."),
					"%s should not reference autoload '%s'" % [path, autoload_name]
				)
			assert_false(
				_has_receiverless_random_call(text),
				"%s should not call a receiver-less random function; use an explicit RandomNumberGenerator" % path
			)
