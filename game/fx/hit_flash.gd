class_name HitFlash
extends RefCounted
## Triggers [code]entity_fx.gdshader[/code]'s flash uniform on a sprite
## (design D15). A pure static helper: no state of its own, since each
## sprite's [ShaderMaterial] is already [code]resource_local_to_scene[/code]
## and holds its own [code]flash_amount[/code].

const _FLASH_DURATION_S := 0.08


## Sets [param sprite]'s shader material [code]flash_amount[/code] to 1.0
## and tweens it back to 0.0 over [constant _FLASH_DURATION_S]. A no-op
## if [param sprite] has no [ShaderMaterial].
static func flash(sprite: Sprite2D) -> void:
	var material := sprite.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("flash_amount", 1.0)
	var tween := sprite.create_tween()
	tween.tween_method(
		func(value: float) -> void: material.set_shader_parameter("flash_amount", value),
		1.0,
		0.0,
		_FLASH_DURATION_S
	)
