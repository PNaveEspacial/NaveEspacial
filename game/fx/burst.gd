class_name Burst
extends GPUParticles2D
## Pooled, one-shot death-burst particles (design D15). Implements the
## pooled-node contract (design D10): [method activate]/[method
## deactivate] and [signal despawn_requested], emitted once its own
## [member GPUParticles2D.lifetime] elapses after [method
## GPUParticles2D.restart].

signal despawn_requested

var _time_left: float = 0.0


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		despawn_requested.emit()


## Pooled-node contract (design D10 interfaces). [param params] keys:
## [code]"position"[/code] (Vector2).
func activate(params: Dictionary) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	global_position = params.get("position", Vector2.ZERO)
	visible = true
	_time_left = lifetime
	restart()
	emitting = true


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	emitting = false
	_time_left = 0.0
