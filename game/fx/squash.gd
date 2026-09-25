class_name Squash
extends RefCounted
## Squash-and-stretch pulse helper (design D15): sets [param node]'s
## [member Node2D.scale] to [param scale] then tweens it back to
## [constant Vector2.ONE] over [param duration_s]. Used for fire recoil,
## enemy hit, orb pickup feedback, and enemy spawn pop-in.

static func pulse(node: Node2D, scale: Vector2, duration_s: float) -> void:
	node.scale = scale
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE, duration_s)
