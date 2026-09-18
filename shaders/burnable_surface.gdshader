shader_type canvas_item;

uniform sampler2D albedo_tex : hint_default_white;
uniform vec4 base_color : source_color = vec4(0.94, 0.9, 0.82, 1.0);
uniform vec4 edge_color : source_color = vec4(0.75, 0.7, 0.6, 1.0);
uniform vec4 burn_tint : source_color = vec4(1.0, 0.42, 0.12, 1.0);
uniform vec4 char_color : source_color = vec4(0.12, 0.09, 0.07, 1.0);
uniform float heat_amount : hint_range(0.0, 1.0) = 0.0;
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
uniform float char_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform int style = 0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform bool is_glass = false;
uniform bool is_oil = false;
uniform bool is_metal = false;

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

float rim_factor(vec2 uv) {
	float e = max(abs(uv.x - 0.5), abs(uv.y - 0.5));
	return smoothstep(0.38, 0.5, e);
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 tex = texture(albedo_tex, uv);
	vec3 col = mix(base_color.rgb, tex.rgb, 0.72);
	col = mix(col, edge_color.rgb, rim_factor(UV) * 0.45);

	if (style == 1) {
		float grain = sin(uv.x * 42.0 + sin(uv.y * 6.0) * 2.0) * 0.04;
		col += grain;
	} else if (style == 2) {
		col = mix(col, vec3(0.35, 0.55, 0.22), 0.15);
	} else if (style == 3) {
		float weave = step(0.5, fract(uv.x * 18.0)) * step(0.5, fract(uv.y * 18.0));
		col = mix(col, col * 0.88, weave * 0.35);
	}

	if (is_oil) {
		float gloss = pow(max(1.0 - length(UV - vec2(0.5)), 0.0), 2.4) * 0.35;
		col += vec3(0.2, 0.25, 0.3) * gloss;
	}
	if (is_metal) {
		float sheen = pow(abs(sin(UV.x * 3.14159)), 1.5) * 0.2;
		col += sheen;
	}

	col = mix(col, burn_tint.rgb, heat_amount * 0.4);
	col = mix(col, burn_tint.rgb, burn_amount * 0.75);
	col = mix(col, char_color.rgb, max(char_amount, burn_amount * 0.55));

	float n = noise(uv * 14.0 + vec2(burn_amount * 3.0, char_amount));
	float edge_burn = smoothstep(0.15, 0.85, burn_amount + n * 0.25);
	col = mix(col, char_color.rgb * 0.7, edge_burn * burn_amount * 0.5);

	float ember = glow_strength * (0.35 + 0.65 * sin(TIME * 9.0 + UV.x * 8.0));
	col += burn_tint.rgb * ember * 0.35;

	float alpha = tex.a * base_color.a;
	if (is_glass) {
		alpha = mix(0.28, 0.55, rim_factor(UV));
		col = mix(col, vec3(0.85, 0.95, 1.0), 0.2);
	}
	if (is_oil) {
		alpha = mix(0.75, 0.95, max(1.0 - length(UV - vec2(0.5)) * 1.2, 0.0));
	}

	float dissolve_n = noise(uv * 22.0 + TIME * 0.15);
	float hole = step(dissolve_n, dissolve * 1.05);
	alpha *= 1.0 - hole;
	if (char_amount > 0.4) {
		alpha *= mix(1.0, 0.75, char_amount);
	}

	COLOR = vec4(col, alpha);
}
