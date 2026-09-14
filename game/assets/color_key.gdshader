shader_type canvas_item;

// The source artwork is retained unchanged. Remove its magenta key at render time.
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    if (source.r > 0.70 && source.b > 0.65 && source.g < 0.45) {
        COLOR.a = 0.0;
    }
}
