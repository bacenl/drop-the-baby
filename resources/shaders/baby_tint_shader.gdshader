shader_type canvas_item;

uniform float original_color_weight : hint_range(0.0, 1.0) = 0.5;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

// Blacklisted colors (up to 6)
uniform vec3 blacklist_color_1 : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blacklist_color_2 : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blacklist_color_3 : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blacklist_color_4 : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blacklist_color_5 : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 blacklist_color_6 : source_color = vec3(0.0, 0.0, 0.0);

bool is_blacklisted(vec3 color) {
	if (distance(color, blacklist_color_1) <= tolerance) return true;
	if (distance(color, blacklist_color_2) <= tolerance) return true;
	if (distance(color, blacklist_color_3) <= tolerance) return true;
	if (distance(color, blacklist_color_4) <= tolerance) return true;
	if (distance(color, blacklist_color_5) <= tolerance) return true;
	if (distance(color, blacklist_color_6) <= tolerance) return true;
	return false;
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);

	// Check if pixel is blacklisted (within tolerance of any blacklist color)
	if (is_blacklisted(original.rgb)) {
		COLOR = original;
	} else {
		vec3 blended = original.rgb * original_color_weight + tint_color.rgb * (1.0 - original_color_weight);
		COLOR = vec4(blended, original.a);
	}
}
