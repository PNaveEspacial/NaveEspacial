extends GutTest
## Covers localization's First-Launch Locale Resolution requirement
## (design D16).

func test_es_es_resolves_to_spanish():
	assert_eq(LocaleResolver.resolve("es_ES"), "es")


func test_es_419_resolves_to_spanish():
	assert_eq(LocaleResolver.resolve("es-419"), "es")


func test_uppercase_es_resolves_to_spanish():
	assert_eq(LocaleResolver.resolve("ES"), "es")


func test_en_us_resolves_to_english():
	assert_eq(LocaleResolver.resolve("en_US"), "en")


func test_unsupported_locale_falls_back_to_english():
	assert_eq(LocaleResolver.resolve("fr_FR"), "en")


func test_empty_locale_falls_back_to_english():
	assert_eq(LocaleResolver.resolve(""), "en")


func test_saved_choice_overrides_os_resolution():
	assert_eq(LocaleResolver.effective("en", "es_ES"), "en")
	assert_eq(LocaleResolver.effective("es", "en_US"), "es")


func test_empty_saved_choice_falls_back_to_os_resolution():
	assert_eq(LocaleResolver.effective("", "es_ES"), "es")


func test_unsupported_saved_choice_falls_back_to_os_resolution():
	assert_eq(LocaleResolver.effective("fr", "es_ES"), "es")
