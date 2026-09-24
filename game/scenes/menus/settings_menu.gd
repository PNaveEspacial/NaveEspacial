class_name SettingsMenu
extends VBoxContainer
## Embedded language-selector panel (design D16; localization spec
## capability), instanced inside [code]main_menu.tscn[/code]'s
## [code]SettingsPanel[/code] (S14's stub, now populated). Selecting a
## language calls [method Settings.set_language] immediately -- a live
## switch, no restart -- and rebuilds this panel's own dynamic text (the
## [OptionButton]'s item labels) on [constant Node.NOTIFICATION_TRANSLATION_CHANGED],
## since [method OptionButton.add_item] bakes a resolved string, not a
## live translation key the engine can auto-retranslate the way static
## [code].tscn[/code] [code]text = "KEY"[/code] properties are.

signal back_pressed

const _LANGUAGE_KEYS := {"es": "LANG_ES", "en": "LANG_EN"}

@onready var _language_option: OptionButton = $LanguageRow/LanguageOption
@onready var _back_button: Button = $BackButton


func _ready() -> void:
	_rebuild_language_items()
	_language_option.item_selected.connect(_on_language_selected)
	_back_button.pressed.connect(_on_back_pressed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_rebuild_language_items()


func _rebuild_language_items() -> void:
	var current := TranslationServer.get_locale().substr(0, 2)
	_language_option.clear()
	for lang in LocaleResolver.SUPPORTED:
		_language_option.add_item(tr(_LANGUAGE_KEYS[lang]))
		_language_option.set_item_metadata(_language_option.item_count - 1, lang)
		if lang == current:
			_language_option.select(_language_option.item_count - 1)


func _on_language_selected(index: int) -> void:
	var lang: String = _language_option.get_item_metadata(index)
	Settings.set_language(lang)


func _on_back_pressed() -> void:
	back_pressed.emit()
