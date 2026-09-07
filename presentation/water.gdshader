shader_type canvas_item;
void fragment() {
    vec4 water = texture(TEXTURE, UV);
    float ripple = sin(UV.y * 38.0 + TIME * 1.4 + sin(UV.x * 12.0)) * 0.025;
    COLOR = vec4(water.rgb + vec3(ripple * 0.4, ripple, ripple), water.a);
}
