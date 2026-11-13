shader_type canvas_item;

// Keep the new portraits' body pixels fixed while eyes and mouths animate.
void fragment() {
	vec2 cell = fract(UV * 3.0);
	vec2 face = (cell - vec2(0.5, 0.34)) / vec2(0.17, 0.24);
	COLOR.a *= 1.0 - smoothstep(0.88, 1.0, length(face));
}
