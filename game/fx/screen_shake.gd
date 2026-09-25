extends Camera2D
## Whole-pixel screen shake (design D15), driven by the pure
## [TraumaShake] and [signal EventBus.shake_requested] (player hit 0.5,
## enemy death 0.15, player death 1.0). Attached directly to `game.tscn`'s
## existing [Camera2D] -- shake uses [member Camera2D.offset], never
## [member Node2D.position], so it never disturbs the fixed-arena camera
## design D5 relies on.

var _shake := TraumaShake.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.shake_requested.connect(_on_shake_requested)


func _process(delta: float) -> void:
	offset = Vector2(_shake.tick(delta, _rng))


func _on_shake_requested(trauma: float) -> void:
	_shake.add(trauma)
