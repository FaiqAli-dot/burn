shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.12, 0.09, 0.08, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.05, 0.04, 0.035, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.035;
uniform float time_scale = 0.08;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.x * 6.0 + TIME * time_scale) * 1.2) * 0.015;
	float y = clamp(uv.y + wave, 0.0, 1.0);
	vec3 col = mix(top_color.rgb, bottom_color.rgb, y);

	float ember = smoothstep(0.72, 1.0, uv.y) * 0.05;
	col += vec3(0.18, 0.06, 0.02) * ember;

	vec2 centered = uv - vec2(0.5);
	float vig = 1.0 - dot(centered, centered) * vignette_strength * 2.2;
	col *= vig;

	float g = hash(uv * vec2(920.0, 1280.0) + TIME * 0.4);
	col += (g - 0.5) * grain_strength;

	COLOR = vec4(col, 1.0);
}
