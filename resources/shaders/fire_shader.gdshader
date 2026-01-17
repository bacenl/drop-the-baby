shader_type canvas_item;

// Fire colors
uniform vec4 color1 : source_color = vec4(1.0, 0.9, 0.0, 1.0); // Yellow/white at bottom
uniform vec4 color2 : source_color = vec4(1.0, 0.2, 0.0, 1.0); // Orange/red at top

// Y position range for gradient (in UV space, 0 = top, 1 = bottom)
uniform float y_position_1 : hint_range(0.0, 1.0) = 1.0; // Bottom
uniform float y_position_2 : hint_range(0.0, 1.0) = 0.5; // Top

// Wiggle parameters
uniform float wiggle_speed : hint_range(0.0, 20.0) = 1.0;
uniform float wiggle_strength : hint_range(0.0, 0.5) = 0.1;
uniform float wiggle_frequency : hint_range(0.0, 50.0) = 1.0;

// Spark/noise parameters for top edge
uniform float spark_intensity : hint_range(0.0, 0.3) = 0.1;
uniform float spark_speed : hint_range(0.0, 20.0) = 5.0;

// Color wiggle parameters
uniform float color_wiggle_speed : hint_range(0.0, 10.0) = 3.0;
uniform float color_wiggle_strength : hint_range(0.0, 0.5) = 0.2;

// Transparency
uniform float transparency : hint_range(0.0, 1.0) = 1.0;

// Simple hash function for pseudo-random noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Smooth noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Quintic interpolation for extra smoothness
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for smoother, more natural noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    // Sample texture without any deformation
    vec4 tex_color = texture(TEXTURE, UV);

    // Calculate noisy, wiggly top edge
    float edge_noise = noise(vec2(UV.x * 20.0, TIME * spark_speed)) * spark_intensity;
    edge_noise += noise(vec2(UV.x * 35.0 + 100.0, TIME * spark_speed * 1.5)) * spark_intensity * 0.5;
    float noisy_top = y_position_2 - edge_noise;

    // Above the noisy top edge, keep original texture
    if (UV.y < noisy_top) {
        COLOR = tex_color;
    } else {
        // Calculate wiggle for the color gradient
        float wiggle = sin(UV.y * wiggle_frequency + TIME * wiggle_speed) * wiggle_strength;
        wiggle += sin(UV.y * wiggle_frequency * 0.5 + TIME * wiggle_speed * 1.3) * wiggle_strength * 0.5;
        wiggle += noise(vec2(UV.x * 10.0, UV.y * 10.0 + TIME * wiggle_speed)) * wiggle_strength * 0.3;

        // Calculate gradient factor based on Y position, with wiggle applied
        float gradient_range = y_position_1 - noisy_top;
        float wiggled_y = UV.y + wiggle;
        float gradient_factor = clamp((wiggled_y - noisy_top) / gradient_range, 0.0, 1.0);

        // Interpolate between colors with time-based wiggle
        float color_wiggle = sin(TIME * color_wiggle_speed + UV.x * 10.0) * color_wiggle_strength;
        color_wiggle += sin(TIME * color_wiggle_speed * 1.7 + UV.y * 8.0) * color_wiggle_strength * 0.5;
        float wiggled_gradient = clamp(gradient_factor + color_wiggle, 0.0, 1.0);

        vec4 fire_color = mix(color2, color1, wiggled_gradient);

        // Apply fire color to texture, with transparency
        COLOR = vec4(fire_color.rgb, tex_color.a * transparency);
    }
}
