shader_type canvas_item;

// Authored sprite + organic burn masks. Not a global tint dissolve.

uniform sampler2D burn_mask : hint_default_white;
uniform vec4 burn_tint : source_color = vec4(1.0, 0.42, 0.12, 1.0);
uniform vec4 char_color : source_color = vec4(0.12, 0.09, 0.07, 1.0);
uniform float heat_amount : hint_range(0.0, 1.0) = 0.0;
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
uniform float char_amount : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
uniform bool edge_char = true;
uniform bool hole_burn = true;
uniform bool melt = false;
uniform bool is_metal = false;
uniform bool is_glass = false;
uniform bool is_oil = false;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb;
	float alpha = tex.a;

	if (alpha < 0.02) {
		discard;
	}

	float mask = texture(burn_mask, UV * 0.92 + vec2(0.04)).r;
	float edge = smoothstep(0.15, 0.85, mask);

	// Heating: warm edge only.
	if (heat_amount > 0.001) {
		float rim = pow(1.0 - abs(UV.x - 0.5) * abs(UV.y - 0.5) * 3.5, 2.0);
		col = mix(col, burn_tint.rgb, heat_amount * 0.35 * rim);
	}

	// Burning: localized char + glowing cracks/holes from mask.
	if (burn_amount > 0.001) {
		float char_zone = smoothstep(0.2, 0.9, burn_amount + edge * 0.45);
		if (edge_char) {
			col = mix(col, char_color.rgb, char_zone * 0.75);
			col = mix(col, burn_tint.rgb, (1.0 - edge) * burn_amount * 0.55);
		} else {
			col = mix(col, burn_tint.rgb, burn_amount * 0.4);
			col = mix(col, char_color.rgb, burn_amount * 0.35 * edge);
		}
		if (hole_burn) {
			float hole = step(mask, dissolve * 0.95 + burn_amount * 0.25);
			alpha *= 1.0 - hole * smoothstep(0.15, 0.7, burn_amount);
			float rim_glow = smoothstep(0.0, 0.15, abs(mask - (dissolve * 0.95 + burn_amount * 0.25)));
			col += burn_tint.rgb * rim_glow * burn_amount * 0.8;
		}
		if (melt) {
			col = mix(col, burn_tint.rgb * 0.7, burn_amount * 0.25);
			alpha *= mix(1.0, 0.85, burn_amount);
		}
	}

	if (char_amount > 0.001) {
		col = mix(col, char_color.rgb, char_amount * 0.85);
		alpha *= mix(1.0, 0.7, char_amount);
	}

	float ember = glow_strength * (0.4 + 0.6 * sin(TIME * 10.0 + UV.x * 12.0));
	col += burn_tint.rgb * ember * 0.4;

	if (is_metal) {
		float rim = pow(max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0, 2.0);
		col += burn_tint.rgb * glow_strength * rim * 0.35;
	}
	if (is_glass) {
		col = mix(col, vec3(0.85, 0.95, 1.0), 0.08);
	}
	if (is_oil && burn_amount > 0.1) {
		col = mix(col, burn_tint.rgb, 0.35 * burn_amount);
	}

	COLOR = vec4(col, alpha * COLOR.a);
}
