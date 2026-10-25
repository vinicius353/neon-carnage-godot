shader_type canvas_item;

// Sangue líquido: as manchas (alpha acumulado) são borradas e cortadas por um limiar,
// o que funde gotas vizinhas numa poça lisa. O brilho úmido vem do gradiente do alpha.

uniform float limiar = 0.42;

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * 2.0;
	float a = 0.0;
	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			a += texture(TEXTURE, UV + vec2(float(i), float(j)) * px).a;
		}
	}
	a /= 25.0;
	float ax = texture(TEXTURE, UV + vec2(px.x, 0.0)).a - texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float ay = texture(TEXTURE, UV + vec2(0.0, px.y)).a - texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float massa = smoothstep(limiar, limiar + 0.08, a);
	vec3 n = normalize(vec3(-ax * 6.0, -ay * 6.0, 1.0));
	float brilho = pow(max(dot(n, normalize(vec3(-0.4, -0.5, 0.8))), 0.0), 24.0);
	vec3 cor = mix(vec3(0.38, 0.01, 0.03), vec3(0.62, 0.03, 0.05), smoothstep(limiar, 0.9, a));
	COLOR = vec4(cor + vec3(brilho) * 0.55, massa * 0.95);
}
