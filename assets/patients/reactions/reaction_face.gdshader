shader_type canvas_item;

uniform bool full_portrait = false;
uniform sampler2D feature_mask : filter_linear, repeat_disable;

void fragment() {
	vec2 cell = fract(UV * 3.0);
	if (full_portrait) {
		vec2 face = (cell - vec2(0.5, 0.34)) / vec2(0.17, 0.24);
		COLOR.a *= 1.0 - smoothstep(0.88, 1.0, length(face));
	} else {
		// Give the wider grin a few extra pixels inside the face, keeping hair,
		// glasses frames, neck and clothing on the unchanged body underneath.
		float mask = texture(feature_mask, cell).r;
		mask = max(mask, texture(feature_mask, cell + vec2(0.04, 0.0)).r);
		mask = max(mask, texture(feature_mask, cell - vec2(0.04, 0.0)).r);
		COLOR.a *= mask;
	}
}
