shader_type canvas_item;

// Sangue em camadas: a densidade acumulada (alfa do render target) decide entre
// película fina translúcida e poça funda quase preta. Nada de brilho de gelatina:
// só um fio de luz na borda molhada, que é o que o olho lê como líquido.

uniform float limiar = 0.34;

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
	float massa = smoothstep(limiar, limiar + 0.12, a);
	vec3 n = normalize(vec3(-(ax1 - ax2) * 5.0, -(ay1 - ay2) * 5.0, 1.0));
	float brilho = pow(max(dot(n, normalize(vec3(-0.4, -0.5, 0.8))), 0.0), 40.0);
	float dens = smoothstep(limiar, 0.9, a);
	// película fina = vermelho vivo e translúcido; poça = vinho quase preto
	vec3 fino = vec3(0.46, 0.015, 0.025);
	vec3 fundo = vec3(0.075, 0.0, 0.006);
	vec3 cor = mix(fino, fundo, dens * 0.92);
	// beirada seca: o que está espalhado e ralo puxa para marrom, não para rosa
	cor = mix(cor, cor * vec3(1.15, 0.60, 0.52), (1.0 - smoothstep(0.10, 0.55, a)) * 0.55);
	float alfa = massa * mix(0.55, 0.96, dens);
	COLOR = vec4(cor + vec3(brilho) * 0.10, alfa);
}
