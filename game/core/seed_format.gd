class_name SeedFormat
extends RefCounted
## Formats a 32-bit run seed as a hyphenated 8-digit hex string, and parses
## it back (design D8). The display format is the run's public identity,
## shown on the game-over screen and eventually accepted as manual seed
## input.

const _HEX_REGEX_PATTERN := "^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$"


## "A3F2-19C0" for a seed of 0xA3F219C0. Only the low 32 bits are used.
static func to_display(seed: int) -> String:
	var unsigned_seed := seed & 0xFFFFFFFF
	var hex := "%08X" % unsigned_seed
	return "%s-%s" % [hex.substr(0, 4), hex.substr(4, 4)]


## Parses a "XXXX-XXXX" display string back into its 32-bit seed value.
## Returns -1 when [param text] does not match the expected format.
static func from_display(text: String) -> int:
	var normalized := text.strip_edges().to_upper()
	var regex := RegEx.new()
	regex.compile(_HEX_REGEX_PATTERN)
	if not regex.search(normalized):
		return -1
	var compact := normalized.replace("-", "")
	return ("0x" + compact).hex_to_int()
