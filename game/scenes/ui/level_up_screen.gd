class_name LevelUpScreen
extends CanvasLayer
## Level-up pause + upgrade offer screen (design D14's level-up flow;
## xp-and-upgrades spec capability). On [signal EventBus.level_up_ready],
## pauses the [SceneTree] (this layer itself keeps processing via
## [constant Node.PROCESS_MODE_WHEN_PAUSED]) and rolls [method
## UpgradeRoller.roll] against [member pool], [member RunState.stacks],
## and the seeded UPGRADES stream -- always exactly 3 distinct offers
## (design D14's guaranteed-3-offer contract, backed by [member pool]'s 3
## uncapped fillers). Picking a card applies its effect, decrements
## [member RunState.pending_level_ups], and either re-rolls (more levels
## pending) or closes and unpauses, granting [member
## PlayerBaseStats.resume_invuln_s] i-frames.

## The full 9-entry upgrade pool this run draws offers from (design D14:
## 6 capped + 3 uncapped fillers). Set directly on this scene, so
## [code]game.gd[/code] only needs to instance and open it.
@export var pool: Array[UpgradeData] = []

@onready var _cards: Array[UpgradeCard] = [
	$CenterContainer/VBox/HBox/Card1, $CenterContainer/VBox/HBox/Card2, $CenterContainer/VBox/HBox/Card3
]

var _player: Player = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	for card in _cards:
		card.picked.connect(_on_card_picked)
	EventBus.level_up_ready.connect(_on_level_up_ready)


## Set by the owning scene: needed to grant resume i-frames and apply
## heal-amount upgrades (design D10-style caller-owns-wiring pattern).
func set_player(player: Player) -> void:
	_player = player


func _on_level_up_ready(_pending: int) -> void:
	if visible:
		return
	# Deferred: level_up_ready can fire mid-physics-tick (RunState.add_xp,
	# called from XpOrb.collect(), called while Player polls its pickup
	# magnet); pausing the tree waits until that call stack unwinds.
	_show_offer.call_deferred()


func _show_offer() -> void:
	get_tree().paused = true
	visible = true
	var offer := UpgradeRoller.roll(
		pool, RunState.stacks, RunState.rng.stream(RunRng.Stream.UPGRADES), _cards.size()
	)
	for i in range(_cards.size()):
		_cards[i].set_upgrade(offer[i])


func _on_card_picked(upgrade: UpgradeData) -> void:
	_apply_upgrade(upgrade)
	RunState.pending_level_ups -= 1
	EventBus.stats_changed.emit()
	if RunState.pending_level_ups > 0:
		_show_offer()
	else:
		_close()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	var current_stacks: int = RunState.stacks.get(upgrade.id, 0)
	RunState.stacks[upgrade.id] = current_stacks + 1
	for modifier in upgrade.modifiers:
		RunState.stats.apply(modifier)
	if upgrade.heal_amount > 0 and _player != null:
		_player.heal(upgrade.heal_amount)
	if upgrade.score_bonus_per_level > 0:
		RunState.add_score(upgrade.score_bonus_per_level * RunState.level)


func _close() -> void:
	visible = false
	get_tree().paused = false
	if _player != null:
		_player.grant_invulnerability(RunState.base_stats.resume_invuln_s)
