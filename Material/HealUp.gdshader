shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform float intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec3 glow = glow_color.rgb * glow_color.a * intensity;
    COLOR = vec4(color.rgb + glow, color.a);
}