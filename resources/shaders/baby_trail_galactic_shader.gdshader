shader_type canvas_item;

uniform vec4 edge_color : source_color = vec4(0.6, 0.4, 1.0, 1.0);
uniform vec4 center_color : source_color = vec4(0.2, 0.1, 0.5, 0.3);
uniform float edge_width : hint_range(0.0, 0.5) = 0.15;
uniform float spark_density : hint_range(0.0, 50.0) = 20.0;
uniform float spark_brightness : hint_range(0.0, 2.0) = 1.0;
uniform float spark_size : hint_range(0.0, 0.5) = 0.08;
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform float tail_fade_power : hint_range(0.5, 5.0) = 1.0;
uniform float line_length : hint_range(1.0, 2000.0) = 100.0;
uniform float line_width : hint_range(1.0, 200.0) = 20.0;
uniform float wiggle_amount : hint_range(0.0, 0.2) = 0.05;
uniform float wiggle_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wiggle_frequency : hint_range(0.0, 20.0) = 5.0;
uniform float edge_wiggle_amount : hint_range(0.0, 0.3) = 0.1;
uniform float edge_wiggle_speed : hint_range(0.0, 10.0) = 4.0;
uniform float edge_wiggle_frequency : hint_range(0.0, 50.0) = 15.0;

// Hash function for pseudo-random numbers
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Generate sparkling particles
float sparks(vec2 uv, float time, float aspect) {
    float sparkle = 0.0;

    // Adjust UV to account for aspect ratio so sparks are round
    vec2 adjusted_uv = vec2(uv.x * aspect, uv.y);

    // Create multiple layers of sparks at different scales
    for (int i = 0; i < 3; i++) {
        float scale = float(i + 1) * 10.0;
        vec2 spark_uv = adjusted_uv * spark_density * scale;

        // Grid-based spark positions
        vec2 grid_id = floor(spark_uv);
        vec2 grid_uv = fract(spark_uv) - 0.5;

        // Random offset within each cell
        vec2 offset = vec2(hash(grid_id), hash(grid_id + 100.0)) - 0.5;
        offset *= 0.8;

        vec2 spark_pos = grid_uv - offset;
        float dist = length(spark_pos);

        // Sparkle intensity with time variation
        float flicker = sin(time * (3.0 + hash(grid_id) * 5.0) + hash(grid_id) * 6.28) * 0.5 + 0.5;
        flicker = pow(flicker, 3.0);

        // Only show some sparks based on random threshold
        float show = step(0.7, hash(grid_id + 50.0));

        // Spark shape - sharp falloff
        float spark = smoothstep(spark_size, 0.0, dist) * flicker * show;

        sparkle += spark * (1.0 / float(i + 1));
    }

    return sparkle * spark_brightness;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;

    // For Line2D with texture mode "Tile" or "Stretch":
    // UV.x = position along the line (0 = start, 1 = end)
    // UV.y = position across width (0 = one edge, 1 = other edge)

    // Add wiggle effect - offset UV.y based on position and time
    float wiggle = sin(uv.x * wiggle_frequency + TIME * wiggle_speed) * wiggle_amount;
    wiggle *= uv.x; // More wiggle towards the tail
    uv.y += wiggle;

    // Calculate distance from center (0.5) normalized to 0-1
    float dist_from_center = abs(uv.y - 0.5) * 2.0; // 0 at center, 1 at edges

    // Edge wiggle - makes the edges "dent in" with uneven wavy noise
    float t = TIME * edge_wiggle_speed;
    float x = uv.x * edge_wiggle_frequency;

    // Layer multiple waves with different frequencies and phases for uneven look
    float edge_noise = sin(x + t) * 0.4;
    edge_noise += sin(x * 1.7 + t * 0.8 + 2.1) * 0.25;
    edge_noise += sin(x * 3.1 + t * 1.2 + 4.3) * 0.15;
    edge_noise += sin(x * 0.6 + t * 0.5 + 1.0) * 0.2;

    // Add hash-based variation to break up regularity
    float cell = floor(uv.x * edge_wiggle_frequency * 0.5);
    float cell_rand = hash(vec2(cell, 0.0));
    edge_noise += (cell_rand - 0.5) * 0.3 * sin(t * 2.0 + cell_rand * 6.28);

    // Normalize and apply
    edge_noise = edge_noise * 0.5 + 0.5; // Remap to 0-1
    float edge_dent = edge_noise * edge_wiggle_amount * (0.3 + uv.x * 0.7); // More dent towards tail

    // Apply edge dent - shrinks the effective width
    float effective_edge = 1.0 - edge_dent;
    float adjusted_dist = dist_from_center / max(effective_edge, 0.01);
    adjusted_dist = clamp(adjusted_dist, 0.0, 1.5);

    // Create solid edges with transparent center (using adjusted distance for denting)
    float edge_alpha = smoothstep(1.0 - edge_width * 2.0, 1.0, adjusted_dist);
    float center_alpha = (1.0 - adjusted_dist) * 0.3;

    // Combine edge and center
    float base_alpha = max(edge_alpha, center_alpha);

    // Fade towards tail (UV.x = 0 at head, 1 at tail for typical trail setup)
    float tail_fade = pow(1.0 - uv.x, tail_fade_power);

    // Mix colors based on distance from center (use adjusted for consistency)
    vec4 base_color = mix(center_color, edge_color, adjusted_dist);

    // Calculate aspect ratio (length / width) for proper spark scaling
    float aspect = line_length / line_width;

    // Add sparkling particles
    float spark_effect = sparks(uv, time, aspect);

    // Sparks fade with the tail
    spark_effect *= tail_fade;

    // Final color with sparks
    vec3 final_color = base_color.rgb + vec3(spark_effect);

    // Final alpha: combine base shape alpha with color alpha and tail fade
    float final_alpha = base_alpha * base_color.a * tail_fade;

    // Add spark contribution to alpha
    final_alpha = max(final_alpha, spark_effect * 0.8);

    COLOR = vec4(final_color, final_alpha);
}
