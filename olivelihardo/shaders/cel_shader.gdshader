shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform bool use_albedo_texture = false;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.28;
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.72;
uniform vec3 shadow_tint : source_color = vec3(0.58, 0.62, 0.72);
uniform vec3 highlight_tint : source_color = vec3(1.08, 1.03, 0.94);
uniform vec3 ambient_fill : source_color = vec3(0.28, 0.25, 0.22);

void fragment() {
	vec4 base_color = albedo_color;
	if (use_albedo_texture) {
		base_color *= texture(albedo_texture, UV);
	}
	ALBEDO = base_color.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float lambert = max(dot(NORMAL, LIGHT), 0.0);
	float band = lambert < shadow_threshold
		? 0.55
		: (lambert < highlight_threshold ? 0.8 : 1.0);
	vec3 tint = lambert < shadow_threshold
		? shadow_tint
		: (lambert >= highlight_threshold ? highlight_tint : vec3(1.0));
	vec3 direct_light = LIGHT_COLOR * ATTENUATION * band * tint * lambert;
	DIFFUSE_LIGHT += ALBEDO * (ambient_fill + direct_light);
}
