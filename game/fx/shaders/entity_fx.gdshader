shader_type canvas_item;

// Hit-flash + pixel-erosion dissolve (design D15). Applied to Player and
// Enemy sprites via a `resource_local_to_scene = true` ShaderMaterial, so
// each instance's flash/dissolve state is independent even though every
// enemy shares one pooled scene.

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float edge_width : hint_range(0.0, 0.5) = 0.08;

// Cheap per-texel hash: no noise texture needed, and operating on whole
// source pixels (`floor(UV / TEXTURE_PIXEL_SIZE)`) keeps the dissolve
// edge on the pixel grid instead of eroding sub-pixel gradients.
float pixel_hash(vec2 texel) {
	vec2 p = fract(texel * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	float noise = pixel_hash(texel);

	vec3 rgb = mix(tex_color.rgb, flash_color.rgb, flash_amount * flash_color.a);
	float alpha = tex_color.a;

	if (dissolve > 0.0) {
		if (noise < dissolve) {
			alpha = 0.0;
		} else if (noise < dissolve + edge_width) {
			rgb = edge_color.rgb;
		}
	}

	COLOR = vec4(rgb, alpha);
}
