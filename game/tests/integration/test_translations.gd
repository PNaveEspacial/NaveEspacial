extends GutTest

## Validates game/i18n/strings.csv: key format, no duplicates, no empty
## English cells. An empty Spanish cell is allowed pre-translation (S15
## fills every remaining cell and adds the missing-fallback runtime test).

const CSV_PATH := "res://i18n/strings.csv"
const KEY_REGEX_PATTERN := "^[A-Z][A-Z0-9_]*$"


func _read_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "strings.csv should be readable at %s" % CSV_PATH)
	if file == null:
		return rows
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 1 and line[0] == "":
			continue
		rows.append(line)
	file.close()
	return rows


func test_header_is_keys_en_es():
	var rows := _read_rows()
	assert_gt(rows.size(), 0, "CSV should have at least a header row.")
	if rows.size() == 0:
		return
	var header := rows[0]
	assert_eq(header, PackedStringArray(["keys", "en", "es"]), "Header must stay 'keys,en,es'.")


func test_every_key_matches_convention():
	var regex := RegEx.new()
	regex.compile(KEY_REGEX_PATTERN)
	var rows := _read_rows()
	for i in range(1, rows.size()):
		var key: String = rows[i][0]
		var match_result := regex.search(key)
		assert_not_null(match_result, "Key '%s' should match %s" % [key, KEY_REGEX_PATTERN])


func test_no_duplicate_keys():
	var rows := _read_rows()
	var seen := {}
	for i in range(1, rows.size()):
		var key: String = rows[i][0]
		assert_false(seen.has(key), "Key '%s' should not appear twice." % key)
		seen[key] = true


func test_no_empty_english_cell():
	var rows := _read_rows()
	for i in range(1, rows.size()):
		var key: String = rows[i][0]
		var en: String = rows[i][1] if rows[i].size() > 1 else ""
		assert_ne(en, "", "Key '%s' should have a non-empty English value." % key)


## S15 extension: missing-fallback behavior (design D16). Uses synthetic,
## in-memory [Translation] resources rather than real gaps in
## strings.csv, since S15.T9 fills every remaining Spanish cell -- this
## keeps the fallback contract tested even once the real CSV has no more
## naturally occurring holes to exercise it against.
var _added_translations: Array[Translation] = []
var _previous_locale: String = ""


func before_each():
	_previous_locale = TranslationServer.get_locale()


func after_each():
	for translation in _added_translations:
		TranslationServer.remove_translation(translation)
	_added_translations.clear()
	TranslationServer.set_locale(_previous_locale)


func _add_translation(locale: String, messages: Dictionary) -> void:
	var translation := Translation.new()
	translation.locale = locale
	for key in messages:
		translation.add_message(key, messages[key])
	TranslationServer.add_translation(translation)
	_added_translations.append(translation)


func test_key_present_in_english_but_missing_in_spanish_falls_back_to_english():
	_add_translation("en", {"TEST_MISSING_FALLBACK_KEY": "English Only Value"})
	_add_translation("es", {})
	TranslationServer.set_locale("es")
	assert_eq(tr("TEST_MISSING_FALLBACK_KEY"), "English Only Value")


func test_key_absent_from_both_columns_returns_the_key_itself():
	TranslationServer.set_locale("es")
	assert_eq(tr("TEST_TOTALLY_UNKNOWN_KEY"), "TEST_TOTALLY_UNKNOWN_KEY", "a key missing from every translation should never render blank")
