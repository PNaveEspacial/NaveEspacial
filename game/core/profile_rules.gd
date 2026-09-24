class_name ProfileRules
extends RefCounted
## Pure sanitization and merge rules for [code]user://save.cfg[/code]
## (design D17). [SaveStore] is the only caller; kept separate so the
## defensive-read rules stay unit-testable without touching disk.
##
## [constant SUPPORTED_LANGUAGES] duplicates [code]LocaleResolver.SUPPORTED[/code]
## (S15) on purpose: S13 lands before S15's [code]core/locale_resolver.gd[/code]
## exists, and [ProfileRules] must not forward-reference a class that isn't
## in the project yet. Both lists must stay in sync (["es", "en"]).

const SUPPORTED_LANGUAGES: PackedStringArray = ["es", "en"]

## Clamps a raw loaded profile dictionary to safe values: a negative or
## non-integer [code]best_score[/code] becomes [code]0[/code], and an
## unsupported [code]language[/code] is dropped (empty string, meaning
## "follow the OS locale" per design D16). [param raw] may be missing
## either key entirely.
static func sanitize(raw: Dictionary) -> Dictionary:
	var best_score: int = 0
	var raw_score: Variant = raw.get("best_score")
	if (raw_score is int or raw_score is float) and raw_score >= 0:
		best_score = int(raw_score)

	var language: String = ""
	var raw_language: Variant = raw.get("language")
	if raw_language is String and SUPPORTED_LANGUAGES.has(raw_language):
		language = raw_language

	return {"best_score": best_score, "language": language}


## Returns the new best score: [param score] only replaces [param best]
## when it is strictly greater.
static func merge_best(best: int, score: int) -> int:
	return score if score > best else best
