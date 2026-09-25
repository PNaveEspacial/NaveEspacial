extends GutTest
## Covers design D6's glyph-coverage requirement: the pixel UI font must
## render every character actually used by the game, including the
## Spanish diacritics/punctuation the `es` column of `game/i18n/strings.csv`
## depends on.

const FONT_PATH := "res://assets/fonts/press_start_2p/PressStart2P-Regular.ttf"
const CSV_PATH := "res://i18n/strings.csv"
const _REQUIRED_EXTRA_CHARS := "áéíóúüñÁÉÍÓÚÜÑ¿¡"


func _collect_csv_characters() -> Dictionary:
	var chars := {}
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "strings.csv should be readable at %s" % CSV_PATH)
	if file == null:
		return chars
	var first := true
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() == 1 and line[0] == "":
			continue
		if first:
			first = false
			continue
		# Only the en/es value columns matter for rendering coverage; the
		# key column itself is never shown to a player.
		for column_index in range(1, line.size()):
			for character in line[column_index]:
				chars[character] = true
	file.close()
	return chars


func test_font_covers_every_character_used_in_strings_csv():
	var font: Font = load(FONT_PATH)
	assert_not_null(font, "%s should load" % FONT_PATH)
	if font == null:
		return
	var chars := _collect_csv_characters()
	assert_gt(chars.size(), 0, "expected at least one character collected from strings.csv")
	for character in chars:
		if character == "\n" or character == "\r":
			continue
		assert_true(font.has_char(character.unicode_at(0)), "font is missing glyph for '%s' (U+%04X)" % [character, character.unicode_at(0)])


func test_font_covers_required_spanish_diacritics_and_punctuation():
	var font: Font = load(FONT_PATH)
	assert_not_null(font, "%s should load" % FONT_PATH)
	if font == null:
		return
	for character in _REQUIRED_EXTRA_CHARS:
		assert_true(font.has_char(character.unicode_at(0)), "font is missing required glyph '%s' (U+%04X)" % [character, character.unicode_at(0)])
