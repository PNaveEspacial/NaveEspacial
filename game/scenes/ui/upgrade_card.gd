class_name UpgradeCard
extends Button
## One upgrade offer card (design D14; xp-and-upgrades spec capability).
## Displays an [UpgradeData]'s icon and name/desc, resolved through
## [method Object.tr] against its [member UpgradeData.name_key]/[member
## UpgradeData.desc_key] (design D16: static-looking text still goes
## through a key, it is just assembled at runtime instead of authored as
## a literal in the [code].tscn[/code]). Emits [signal picked] with the
## card's [UpgradeData] when clicked or confirmed (a [Button] already
## handles both mouse and keyboard/gamepad activation).

signal picked(upgrade: UpgradeData)

var upgrade: UpgradeData


func _ready() -> void:
	pressed.connect(_on_pressed)


func set_upgrade(data: UpgradeData) -> void:
	upgrade = data
	icon = data.icon
	text = "%s\n%s" % [tr(data.name_key), tr(data.desc_key)]


func _on_pressed() -> void:
	picked.emit(upgrade)
