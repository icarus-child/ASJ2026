shader_type canvas_item;

uniform bool hit = false;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (hit) {
		COLOR = vec4(1.0, 0.2, 0.3, COLOR.a > 0.0 ? 1.0 : 0.0);
	}
}