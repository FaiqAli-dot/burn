shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.12, 0.09, 0.08, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.05, 0.04, 0.035, 1.0);
uniform vec4 accent_color : source_color = vec4(0.55, 0.28, 0.12, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.52;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.032;
uniform float warm_lift : hint_range(0.0, 0.2) = 0.05;
uniform float haze : hint_range(0.0, 1.0) = 0.12;
uniform float time_scale = 0.06;
uniform float fire_glow : hint_range(0.0, 1.5) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.x * 5.0 + TIME * time_scale) * 1.1) * 0.012;
	float y = clamp(uv.y + wave, 0.0, 1.0);
	vec3 col = mix(top_color.rgb, bottom_color.rgb, y);

	float floor_glow = smoothstep(0.55, 1.0, uv.y);
	col += accent_color.rgb * floor_glow * (0.045 + warm_lift);

	float cloud = noise(uv * vec2(3.5, 2.0) + vec2(TIME * 0.02, 0.0));
	col = mix(col, mix(col, accent_color.rgb, 0.15), cloud * haze);

	col += vec3(0.22, 0.08, 0.02) * fire_glow * smoothstep(0.35, 0.95, uv.y) * 0.35;

	vec2 centered = uv - vec2(0.5);
	float vig = 1.0 - dot(centered, centered) * vignette_strength * 2.4;
	col *= clamp(vig, 0.35, 1.0);

	float g = hash(uv * vec2(940.0, 1320.0) + TIME * 0.35);
	col += (g - 0.5) * grain_strength;

	COLOR = vec4(col, 1.0);
}
