shader_type canvas_item;

// Acabamento pixel: poucas cores por canal, leve tom frio e vinheta. Roda em 640x360, então é barato.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float levels = 6.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	c = floor(c * levels + 0.5) / levels;
	c = c * vec3(0.94, 0.98, 1.06);
	float v = smoothstep(0.35, 0.9, distance(SCREEN_UV, vec2(0.5)));
	c *= 1.0 - v * 0.5;
	COLOR = vec4(c, 1.0);
}
