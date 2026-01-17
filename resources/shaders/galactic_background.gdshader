shader_type canvas_item;

// Main colors
uniform vec4 background_color : source_color = vec4(0.02, 0.01, 0.05, 1.0);
uniform vec4 nebula_color_1 : source_color = vec4(0.4, 0.1, 0.6, 1.0);
uniform vec4 nebula_color_2 : source_color = vec4(0.1, 0.3, 0.7, 1.0);
uniform vec4 nebula_color_3 : source_color = vec4(0.7, 0.2, 0.4, 1.0);

// Star settings
uniform float star_density : hint_range(0.0, 500.0) = 200.0;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.0;
uniform float star_flicker_speed : hint_range(0.0, 10.0) = 2.0;

// Nebula/fog settings
uniform float nebula_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float nebula_scale : hint_range(0.1, 10.0) = 2.0;
uniform float fog_distortion : hint_range(0.0, 1.0) = 0.3;
uniform float fog_speed : hint_range(0.0, 1.0) = 0.1;

// Animation
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;

// Quintic interpolation for ultra-smooth noise
vec2 quintic(vec2 x) {
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// Better hash using sine - less patterned
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash2(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.2031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// Gradient noise for smoother results
vec2 grad(vec2 p) {
    float h = hash(p) * 6.28318;
    return vec2(cos(h), sin(h));
}

// Perlin-style gradient noise - much smoother than value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Quintic interpolation for C2 continuity (smoother than smoothstep)
    vec2 u = quintic(f);

    // Gradient vectors at corners
    vec2 ga = grad(i + vec2(0.0, 0.0));
    vec2 gb = grad(i + vec2(1.0, 0.0));
    vec2 gc = grad(i + vec2(0.0, 1.0));
    vec2 gd = grad(i + vec2(1.0, 1.0));

    // Distance vectors to corners
    vec2 pa = f - vec2(0.0, 0.0);
    vec2 pb = f - vec2(1.0, 0.0);
    vec2 pc = f - vec2(0.0, 1.0);
    vec2 pd = f - vec2(1.0, 1.0);

    // Dot products
    float va = dot(ga, pa);
    float vb = dot(gb, pb);
    float vc = dot(gc, pc);
    float vd = dot(gd, pd);

    // Bilinear interpolation
    return 0.5 + 0.5 * mix(mix(va, vb, u.x), mix(vc, vd, u.x), u.y);
}

// Fractal Brownian Motion with more octaves for smoother detail
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float max_value = 0.0;

    // More octaves for smoother gradients
    for (int i = 0; i < 7; i++) {
        value += amplitude * noise(p * frequency);
        max_value += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value / max_value; // Normalize
}

// Generate stars with smooth flickering
float stars(vec2 uv, float time) {
    float star_field = 0.0;

    // Multiple star layers for depth
    for (int layer = 0; layer < 3; layer++) {
        float layer_scale = 1.0 + float(layer) * 0.5;
        float layer_brightness = 1.0 - float(layer) * 0.25;

        vec2 star_uv = uv * star_density * layer_scale;
        vec2 grid_id = floor(star_uv);
        vec2 grid_uv = fract(star_uv) - 0.5;

        // Random position within cell
        vec2 offset = vec2(hash(grid_id), hash2(grid_id)) - 0.5;
        offset *= 0.8;

        float dist = length(grid_uv - offset);

        // Star visibility (only some cells have stars)
        float show = step(0.85 - float(layer) * 0.05, hash(grid_id + 100.0));

        // Smooth flicker using multiple sine waves
        float flicker_phase = hash(grid_id + 200.0) * 6.28;
        float flicker_freq = 1.0 + hash(grid_id + 300.0) * 3.0;
        float flicker = sin(time * star_flicker_speed * flicker_freq + flicker_phase) * 0.5 + 0.5;
        flicker += sin(time * star_flicker_speed * flicker_freq * 0.7 + flicker_phase * 1.3) * 0.25 + 0.25;
        flicker = flicker * 0.5; // Normalize
        flicker = flicker * 0.4 + 0.6; // Range 0.6 to 1.0

        // Some stars twinkle more dramatically with smooth transition
        float twinkle_amount = smoothstep(0.85, 0.95, hash(grid_id + 400.0));
        float dramatic_flicker = pow(sin(time * star_flicker_speed * 1.5 + flicker_phase) * 0.5 + 0.5, 2.0);
        dramatic_flicker = dramatic_flicker * 0.7 + 0.3;
        flicker = mix(flicker, dramatic_flicker, twinkle_amount);

        // Star size varies
        float star_size = 0.015 + hash(grid_id + 500.0) * 0.025;
        star_size *= layer_brightness;

        // Smooth star shape with soft glow falloff
        float star = exp(-dist * dist / (star_size * star_size * 0.5)); // Gaussian falloff
        float glow = exp(-dist * dist / (star_size * star_size * 8.0)) * 0.4; // Wider soft glow

        star_field += (star + glow) * show * flicker * layer_brightness * star_brightness;
    }

    return star_field;
}

// Nebula clouds with smooth gradients
vec3 nebula(vec2 uv, float time) {
    // Distort UV for flowing effect
    vec2 distort_uv = uv * nebula_scale * 0.5;
    float distortion = fbm(distort_uv + time * fog_speed * 0.5) * fog_distortion;
    vec2 nebula_uv = uv * nebula_scale + vec2(distortion, -distortion * 0.7);

    // Multiple nebula layers with smooth blending
    float n1 = fbm(nebula_uv);
    float n2 = fbm(nebula_uv * 1.3 + vec2(5.2, 1.3) + time * fog_speed * 0.3);
    float n3 = fbm(nebula_uv * 0.7 + vec2(-3.7, 2.8) - time * fog_speed * 0.2);

    // Soft cloud shapes with wide smoothstep ranges
    n1 = smoothstep(0.25, 0.75, n1);
    n2 = smoothstep(0.3, 0.7, n2);
    n3 = smoothstep(0.35, 0.65, n3);

    // Extra smoothing pass
    n1 = n1 * n1 * (3.0 - 2.0 * n1);
    n2 = n2 * n2 * (3.0 - 2.0 * n2);
    n3 = n3 * n3 * (3.0 - 2.0 * n3);

    // Mix nebula colors
    vec3 nebula_col = vec3(0.0);
    nebula_col += nebula_color_1.rgb * n1 * nebula_color_1.a;
    nebula_col += nebula_color_2.rgb * n2 * nebula_color_2.a;
    nebula_col += nebula_color_3.rgb * n3 * nebula_color_3.a;

    return nebula_col * nebula_intensity;
}

// Smooth foggy distortion overlay
float fog_wisps(vec2 uv, float time) {
    vec2 fog_uv = uv * 2.0;

    // Moving fog layers
    float f1 = fbm(fog_uv + vec2(time * fog_speed * 0.5, time * fog_speed * 0.2));
    float f2 = fbm(fog_uv * 1.2 - vec2(time * fog_speed * 0.3, time * fog_speed * 0.4));

    float fog = f1 * f2;
    fog = smoothstep(0.15, 0.55, fog);
    fog = fog * fog * (3.0 - 2.0 * fog); // Extra smoothing

    return fog * 0.12;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * time_scale;

    // Start with background color
    vec3 color = background_color.rgb;

    // Add nebula clouds
    color += nebula(uv, time);

    // Add foggy wisps
    float fog = fog_wisps(uv, time);
    color += vec3(fog) * nebula_color_1.rgb * 0.5;

    // Add stars on top
    float star_layer = stars(uv, time);
    color += vec3(star_layer);

    // Smooth vignette for depth
    float vignette = 1.0 - smoothstep(0.3, 0.9, length(uv - 0.5)) * 0.25;
    color *= vignette;

    COLOR = vec4(color, 1.0);
}
