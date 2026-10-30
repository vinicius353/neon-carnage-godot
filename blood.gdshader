shader_type canvas_item;

// Sangue líquido barato: 5 leituras de textura (antes eram 29) e descarta pixels vazios.

uniform float limiar = 0.42;

void fragment() {
	float a0 = texture(TEXTURE, UV).a;
	if (a0 < 0.004) {
		discard;
	}
	vec2 px = TEXTURE_PIXEL_SIZE * 1.5;
	float ax1 = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float ax2 = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float ay1 = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float ay2 = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float a = (a0 * 2.0 + ax1 + ax2 + ay1 + ay2) / 6.0;
	float massa = smoothstep(limiar, limiar + 0.1, a);
	vec3 n = normalize(vec3(-(ax1 - ax2) * 6.0, -(ay1 - ay2) * 6.0, 1.0));
	float brilho = pow(max(dot(n, normalize(vec3(-0.4, -0.5, 0.8))), 0.0), 24.0);
	float dens = smoothstep(limiar, 0.88, a);
	vec3 cor = mix(vec3(0.22, 0.0, 0.015), vec3(0.62, 0.035, 0.05), dens);
	cor *= 0.72 + 0.4 * dens;
	COLOR = vec4(cor + vec3(brilho) * 0.45, massa * 0.95);
}
