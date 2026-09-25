shader_type canvas_item;

// Drifting 2-layer starfield background (design D15): a full-rect
// ColorRect on CanvasLayer -10, so it renders behind every gameplay
// sprite. Each layer's stars step by whole pixels per frame
// (`floor(FRAGCOORD.xy + floor(TIME * speed))`), never sub-pixel, so the
// background stays on the pixel grid like everything else (design D3).

uniform float speed_layer1 : hint_range(0.0, 60.0) = 8.0;
uniform float speed_layer2 : hint_range(0.0, 60.0) = 20.0;
uniform float density_layer1 : hint_range(0.0, 1.0) = 0.985;
uniform float density_layer2 : hint_range(0.0, 1.0) = 0.995;
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float pixel_hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec2 pixel = FRAGCOORD.xy;

	vec2 cell1 = floor(pixel + vec2(floor(TIME * speed_layer1), 0.0));
	float star1 = step(density_layer1, pixel_hash(cell1));

	vec2 cell2 = floor(pixel + vec2(floor(TIME * speed_layer2), 0.0));
	float star2 = step(density_layer2, pixel_hash(cell2 + vec2(91.0, 27.0)));

	float brightness = max(star1 * 0.6, star2);
	COLOR = vec4(star_color.rgb, brightness);
}
