extends Node
## Language policy autoload (design D7, D16). No `class_name`, for the
## same reason as [code]event_bus.gd[/code]/[code]save_store.gd[/code].
## Registered as the 4th autoload, after [code]SaveStore[/code] (S13) --
## it needs [member SaveStore.language] already loaded to resolve the
## effective locale at boot.

func _ready() -> void:
	TranslationServer.set_locale(LocaleResolver.effective(SaveStore.language, OS.get_locale()))


## Sets the active locale to [param lang] and persists it as an explicit
## choice (design D16: only an explicit Settings choice is saved; without
## one, the game keeps following the OS locale on every future launch).
func set_language(lang: String) -> void:
	TranslationServer.set_locale(lang)
	SaveStore.language = lang
	SaveStore.save()
