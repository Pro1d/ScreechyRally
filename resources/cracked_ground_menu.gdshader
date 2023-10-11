// NOTE: Shader automatically converted from Godot Engine 3.5.1.stable's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;
varying vec2 w_vertex;
uniform sampler2D crackle_tex : hint_albedo;
uniform float scale : hint_range(0.0, 100.0, 0.1);
const float noise_scale_factor = 7.5;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void vertex() {
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float mask = mix(clamp(noise(UV * scale * noise_scale_factor) * 2.5, 0.0, 1.0), 1.0, 0.5);
	float dark_details = 1.0;
	
	if (mask < 1.0)
		dark_details = mix(texture(crackle_tex, fract(UV * scale)).r, 1.0, mask);
	
	COLOR = vec4(color.rgb * dark_details, color.a);
}
