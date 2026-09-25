class_name DamageNumber
extends Label
## Pooled floating damage-number label (design D15). Implements the
## pooled-node contract (design D10): [method activate]/[method
## deactivate] and [signal despawn_requested].

signal despawn_requested

const _RISE_PX := 12.0
const _DURATION_S := 0.5

var _tween: Tween


## Pooled-node contract (design D10 interfaces). [param params] keys:
## [code]"position"[/code] (Vector2), [code]"amount"[/code] (float, the
## exact damage dealt).
func activate(params: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	var amount: float = params.get("amount", 0.0)
	text = str(int(round(amount)))
	global_position = params.get("position", Vector2.ZERO)
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	visible = true

	if _tween != null and _tween.is_valid():
		_tween.kill()
	var start_pos := global_position
	var end_pos := start_pos + Vector2(0.0, -_RISE_PX)
	_tween = create_tween()
	_tween.tween_method(
		func(t: float) -> void:
			global_position = start_pos.lerp(end_pos, t).round()
			modulate.a = 1.0 - t,
		0.0,
		1.0,
		_DURATION_S
	)
	_tween.tween_callback(despawn_requested.emit)


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if _tween != null and _tween.is_valid():
		_tween.kill()
