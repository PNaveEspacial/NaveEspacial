class_name LocaleResolver
extends RefCounted
## Pure OS-locale-to-supported-language resolution (design D16).
## [constant SUPPORTED] and [constant FALLBACK] MUST stay in sync with
## [constant ProfileRules.SUPPORTED_LANGUAGES] (S13, which predates this
## file and could not reference it yet) -- both currently list exactly
## [code]["es", "en"][/code].

const SUPPORTED: PackedStringArray = ["es", "en"]
const FALLBACK := "en"


## Maps an OS locale string (for example [code]"es_ES"[/code],
## [code]"es-419"[/code], or [code]"fr_FR"[/code]) to one of
## [constant SUPPORTED]. Lowercases, splits on the first [code]_[/code] or
## [code]-[/code], and matches the language prefix; an empty, malformed, or
## unrecognized prefix returns [constant FALLBACK].
static func resolve(os_locale: String) -> String:
	var normalized := os_locale.to_lower()
	var separator_index := -1
	for separator in ["_", "-"]:
		var idx := normalized.find(separator)
		if idx != -1 and (separator_index == -1 or idx < separator_index):
			separator_index = idx
	var prefix := normalized if separator_index == -1 else normalized.substr(0, separator_index)
	if SUPPORTED.has(prefix):
		return prefix
	return FALLBACK


## Returns [param saved] when it is a non-empty supported language
## (design D16: an explicit Settings choice always overrides OS
## resolution); otherwise resolves [param os_locale].
static func effective(saved: String, os_locale: String) -> String:
	if saved != "" and SUPPORTED.has(saved):
		return saved
	return resolve(os_locale)
