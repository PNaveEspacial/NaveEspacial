extends GutTest
## Validates every Resource under game/data/: it loads without error, its
## id (where present) is unique, every UpgradeData's name_key/desc_key
## exists in game/i18n/strings.csv, weights/stack caps are sane, and the
## real 9-entry upgrade pool passes UpgradeRoller.validate_pool.

const DATA_DIR := "res://data"
const CSV_PATH := "res://i18n/strings.csv"

const UPGRADE_PATHS: PackedStringArray = [
	"res://data/upgrades/fire_rate.tres",
	"res://data/upgrades/damage.tres",
	"res://data/upgrades/move_speed.tres",
	"res://data/upgrades/max_hp.tres",
	"res://data/upgrades/multishot.tres",
	"res://data/upgrades/pickup_radius.tres",
	"res://data/upgrades/repair.tres",
	"res://data/upgrades/salvage.tres",
	"res://data/upgrades/overclock.tres",
]


func _find_tres_files(dir_path: String) -> PackedStringArray:
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
				found.append_array(_find_tres_files(full_path))
			elif entry.ends_with(".tres"):
				found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


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


func test_every_data_resource_loads_without_error():
	var paths := _find_tres_files(DATA_DIR)
	assert_gt(paths.size(), 0, "expected at least one .tres under res://data/")
	for path in paths:
		var resource := load(path)
		assert_not_null(resource, "%s should load without error" % path)


func test_ids_are_unique_across_data_resources():
	var paths := _find_tres_files(DATA_DIR)
	var seen := {}
	for path in paths:
		var resource: Resource = load(path)
		var id_value: Variant = resource.get("id")
		if id_value == null:
			continue
		assert_false(seen.has(id_value), "duplicate resource id '%s' (%s and %s)" % [id_value, seen.get(id_value), path])
		seen[id_value] = path


func test_upgrade_translation_keys_exist_in_csv():
	var csv_keys := _load_csv_keys()
	for path in UPGRADE_PATHS:
		var upgrade: UpgradeData = load(path)
		assert_true(
			csv_keys.has(String(upgrade.name_key)),
			"%s: name_key '%s' missing from strings.csv" % [path, upgrade.name_key]
		)
		assert_true(
			csv_keys.has(String(upgrade.desc_key)),
			"%s: desc_key '%s' missing from strings.csv" % [path, upgrade.desc_key]
		)


func test_upgrade_weights_and_stack_caps_are_sane():
	for path in UPGRADE_PATHS:
		var upgrade: UpgradeData = load(path)
		assert_gt(upgrade.weight, 0.0, "%s: weight should be positive" % path)
		assert_gte(upgrade.max_stacks, 0, "%s: max_stacks should not be negative" % path)


func test_real_upgrade_pool_passes_validate_pool():
	var pool: Array[UpgradeData] = []
	for path in UPGRADE_PATHS:
		pool.append(load(path))
	var errors := UpgradeRoller.validate_pool(pool, 3)
	assert_eq(errors.size(), 0, "real upgrade pool should be valid: %s" % str(errors))
