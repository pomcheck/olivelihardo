shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform bool use_albedo_texture = false;
uniform vec2 texture_scale = vec2(1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.28;
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.72;
uniform float band_softness : hint_range(0.001, 0.1) = 0.025;
uniform vec3 shadow_tint : source_color = vec3(0.72, 0.75, 0.82);
uniform vec3 ambient_fill : source_color = vec3(0.28, 0.25, 0.22);
uniform vec3 rim_color : source_color = vec3(0.62, 0.78, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.2;
uniform float outline_strength : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 base_color = albedo_color;
	if (use_albedo_texture) {
		base_color *= texture(albedo_texture, UV * texture_scale);
	}

	float facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float edge = pow(1.0 - facing, 3.0);
	ALBEDO = base_color.rgb * (1.0 - edge * outline_strength);
	EMISSION = rim_color * edge * rim_strength * 0.12;
	ROUGHNESS = 0.9;
}

void light() {
	float lambert = max(dot(NORMAL, LIGHT), 0.0);
	float shadow_band = smoothstep(
		shadow_threshold - band_softness,
		shadow_threshold + band_softness,
		lambert
	);
	float highlight_band = smoothstep(
		highlight_threshold - band_softness,
		highlight_threshold + band_softness,
		lambert
	);
	float light_level = mix(0.5, 0.78, shadow_band);
	light_level = mix(light_level, 1.0, highlight_band);

	vec3 direct_light = LIGHT_COLOR * ATTENUATION * lambert * light_level;
	vec3 light_tint = mix(shadow_tint, vec3(1.0), shadow_band);
	DIFFUSE_LIGHT += ALBEDO * (ambient_fill + direct_light * light_tint);
}
