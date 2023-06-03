shader_type canvas_item;
render_mode blend_mix;
const vec2 MOTION = vec2(-15.0, -10.0);
const float SPEED = 0.7;
const float PI = 3.1415926535897932384626433837951;
const float PERIOD = 15.0;
uniform float shininess = 2.0;
uniform vec4 shiny_color = vec4(vec3(1), 0.90);

float close_to_border(vec2 uv, sampler2D tex, vec2 p) {
	return (
		texture(tex, uv + vec2(p.x, 0)).a *
		texture(tex, uv + vec2(-p.x, 0)).a *
		texture(tex, uv + vec2(0, p.y)).a *
		texture(tex, uv + vec2(0, -p.y)).a
	);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV) * vec4(MODULATE);
	vec2 uv = SCREEN_UV * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float t = (dot(uv, MOTION) + TIME * SPEED * 2.0 * PI);
	float i = max(1.0 - abs(mod(t, PERIOD) - PERIOD / 2.0) * shininess, 0.0);
	float k = close_to_border(UV, TEXTURE, 1.5*TEXTURE_PIXEL_SIZE);
	color.rgb = mix(color.rgb, shiny_color.rgb, i * shiny_color.a * k);
	COLOR = color;
}