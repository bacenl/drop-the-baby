shader_type canvas_item;

// Outline color
uniform vec4 outline_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Outline width in pixels
uniform float outline_width: hint_range(0.0, 20.0) = 2.0;
// Number of samples for smooth outline (higher = smoother but slower)
uniform int samples: hint_range(4, 32) = 16;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    vec4 sprite_color = texture(TEXTURE, UV);

    // If pixel is already opaque, just show it
    if (sprite_color.a > 0.5) {
        COLOR = sprite_color;
    } else {
        // Sample in a circle around this pixel
        float outline_alpha = 0.0;
        float angle_step = 6.28318 / float(samples);

        for (int i = 0; i < samples; i++) {
            float angle = float(i) * angle_step;
            vec2 offset = vec2(cos(angle), sin(angle)) * size;
            outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
        }

        // Also sample at smaller radius for thin parts
        for (int i = 0; i < samples; i++) {
            float angle = float(i) * angle_step + angle_step * 0.5;
            vec2 offset = vec2(cos(angle), sin(angle)) * size * 0.5;
            outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
        }

        COLOR = vec4(outline_color.rgb, outline_alpha * outline_color.a);
    }
}
