shader_type canvas_item;

uniform float scale: hint_range(0.5, 2.0) = 1.0;

void vertex() {
	// Scale vertices from center of the control
	VERTEX *= scale;
}
