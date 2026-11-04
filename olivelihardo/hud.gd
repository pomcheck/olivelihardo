extends CanvasLayer

var _death_count_label: Label
var _menu_overlay: ColorRect
var _menu_title: Label
var _menu_subtitle: Label
var _start_button: Button
var _resume_button: Button
var _restart_button: Button
var _emote_overlay: ColorRect
var _death_flash: ColorRect
var _death_fade: ColorRect
var _player: CharacterBody3D
var _hovered_emote: StringName = &""
var _has_started: bool = false
var _death_sequence_active: bool = false
var _camera_rest_position: Vector3 = Vector3.ZERO
var _camera_shake_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		push_error("HUD: Kein Spieler in der Gruppe 'player' gefunden.")
	_build_interface()
	if _player != null:
		_player.connect("death_count_changed", Callable(self, "_on_death_count_changed"))
		_player.connect("death_started", Callable(self, "_play_death_sequence"))
		_on_death_count_changed(int(_player.get("death_count")))
	if get_tree().has_meta(&"restart_after_death"):
		get_tree().remove_meta(&"restart_after_death")
		_has_started = true
		_menu_overlay.visible = false
		get_tree().paused = false
	else:
		_show_menu(true)
		get_tree().paused = true


func _build_interface() -> void:
	var hud_root: Control = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	_death_count_label = Label.new()
	_death_count_label.anchor_left = 0.5
	_death_count_label.anchor_right = 0.5
	_death_count_label.offset_left = -180.0
	_death_count_label.offset_top = 22.0
	_death_count_label.offset_right = 180.0
	_death_count_label.offset_bottom = 68.0
	_death_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_death_count_label.add_theme_font_size_override("font_size", 28)
	_death_count_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.43, 1.0))
	hud_root.add_child(_death_count_label)

	_menu_overlay = ColorRect.new()
	_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.color = Color(0.035, 0.055, 0.055, 0.9)
	_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_root.add_child(_menu_overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420.0, 0.0)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.17, 0.16, 1.0)
	panel_style.border_color = Color(0.78, 0.54, 0.26, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(28.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	_menu_title = Label.new()
	_menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_title.add_theme_font_size_override("font_size", 30)
	_menu_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.43, 1.0))
	content.add_child(_menu_title)

	_menu_subtitle = Label.new()
	_menu_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_menu_subtitle)

	_start_button = _create_menu_button("ENTER THE SHOWROOM")
	_start_button.pressed.connect(_start_game)
	content.add_child(_start_button)

	_resume_button = _create_menu_button("RESUME")
	_resume_button.pressed.connect(_resume_game)
	content.add_child(_resume_button)

	_restart_button = _create_menu_button("RESTART SHOWROOM")
	_restart_button.pressed.connect(_restart_game)
	content.add_child(_restart_button)
	_build_emote_wheel(hud_root)
	_death_flash = _create_screen_layer(hud_root, Color(1.0, 0.02, 0.015, 0.0))
	_death_fade = _create_screen_layer(hud_root, Color(0.0, 0.0, 0.0, 0.0))


func _create_screen_layer(hud_root: Control, initial_color: Color) -> ColorRect:
	var layer: ColorRect = ColorRect.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.color = initial_color
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.visible = false
	hud_root.add_child(layer)
	return layer


func _play_death_sequence() -> void:
	if _death_sequence_active:
		return
	_death_sequence_active = true
	_death_flash.visible = true
	_death_flash.color.a = 0.82
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(_death_flash, "color:a", 0.0, 0.15)
	flash_tween.tween_callback(_hide_death_flash)
	_start_camera_shake()

	await get_tree().create_timer(0.15).timeout
	_death_fade.visible = true
	_death_fade.color.a = 0.0
	var fade_out: Tween = create_tween()
	fade_out.tween_property(_death_fade, "color:a", 1.0, 0.4)
	await fade_out.finished

	get_tree().set_meta(&"restart_after_death", true)
	get_tree().paused = false
	var reload_error: Error = get_tree().reload_current_scene()
	if reload_error != OK:
		get_tree().remove_meta(&"restart_after_death")
		push_error("HUD: Die Szene konnte nach dem Tod nicht neu geladen werden (%s)." % error_string(reload_error))
		if _player != null and _player.has_method("respawn_at_checkpoint"):
			_player.call("respawn_at_checkpoint")
		var recovery_tween: Tween = create_tween()
		recovery_tween.tween_property(_death_fade, "color:a", 0.0, 0.4)
		await recovery_tween.finished
		_death_fade.visible = false
		_death_sequence_active = false


func _hide_death_flash() -> void:
	_death_flash.visible = false


func _start_camera_shake() -> void:
	if _player == null:
		return
	var camera: Camera3D = _player.get_node_or_null("Camera3D") as Camera3D
	if camera == null or _camera_shake_active:
		return
	_camera_rest_position = camera.position
	_camera_shake_active = true
	var shake_tween: Tween = create_tween()
	shake_tween.tween_method(_apply_camera_shake.bind(camera), 0.0, 1.0, 0.32)
	shake_tween.tween_callback(_finish_camera_shake.bind(camera))


func _apply_camera_shake(progress: float, camera: Camera3D) -> void:
	var strength: float = (1.0 - progress) * 0.2
	camera.position = _camera_rest_position + Vector3(
		sin(progress * 79.0) * strength,
		cos(progress * 61.0) * strength * 0.6,
		0.0
	)


func _finish_camera_shake(camera: Camera3D) -> void:
	if is_instance_valid(camera):
		camera.position = _camera_rest_position
	_camera_shake_active = false


func _create_menu_button(button_text: String) -> Button:
	var button: Button = Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_color_override("font_color", Color(0.96, 0.91, 0.78, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	var button_style: StyleBoxFlat = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.33, 0.31, 1.0)
	button_style.border_color = Color(0.48, 0.62, 0.53, 1.0)
	button_style.set_border_width_all(1)
	button_style.set_corner_radius_all(4)
	button_style.set_content_margin_all(10.0)
	button.add_theme_stylebox_override("normal", button_style)
	var hover_style: StyleBoxFlat = button_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.28, 0.44, 0.38, 1.0)
	button.add_theme_stylebox_override("hover", hover_style)
	return button


func _build_emote_wheel(hud_root: Control) -> void:
	_emote_overlay = ColorRect.new()
	_emote_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emote_overlay.color = Color(0.025, 0.04, 0.04, 0.45)
	_emote_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_emote_overlay.visible = false
	hud_root.add_child(_emote_overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_emote_overlay.add_child(center)

	var wheel: Control = Control.new()
	wheel.custom_minimum_size = Vector2(480.0, 360.0)
	center.add_child(wheel)

	var wheel_panel: PanelContainer = PanelContainer.new()
	wheel_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wheel_style: StyleBoxFlat = StyleBoxFlat.new()
	wheel_style.bg_color = Color(0.12, 0.17, 0.16, 0.88)
	wheel_style.border_color = Color(0.78, 0.54, 0.26, 1.0)
	wheel_style.set_border_width_all(2)
	wheel_style.set_corner_radius_all(90)
	wheel_panel.add_theme_stylebox_override("panel", wheel_style)
	wheel.add_child(wheel_panel)

	var title: Label = Label.new()
	title.text = "EMOTES"
	title.position = Vector2(175.0, 18.0)
	title.size = Vector2(130.0, 40.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.43, 1.0))
	wheel.add_child(title)

	var center_label: Label = Label.new()
	center_label.text = "DANCE\nBREAK"
	center_label.position = Vector2(180.0, 142.0)
	center_label.size = Vector2(120.0, 64.0)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wheel.add_child(center_label)

	_add_emote_button(wheel, "GROOVE", &"groove", Vector2(175.0, 65.0))
	_add_emote_button(wheel, "SPIN", &"spin", Vector2(315.0, 145.0))
	_add_emote_button(wheel, "WAVE", &"wave", Vector2(175.0, 245.0))
	_add_emote_button(wheel, "BOUNCE", &"bounce", Vector2(35.0, 145.0))

	var hint: Label = Label.new()
	hint.text = "RELEASE F: DANCE  /  ESC: CLOSE"
	hint.position = Vector2(110.0, 318.0)
	hint.size = Vector2(260.0, 24.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	wheel.add_child(hint)


func _add_emote_button(wheel: Control, button_text: String, emote_name: StringName, button_position: Vector2) -> void:
	var button: Button = _create_menu_button(button_text)
	button.position = button_position
	button.size = Vector2(130.0, 54.0)
	button.mouse_entered.connect(_on_emote_hovered.bind(emote_name))
	button.mouse_exited.connect(_on_emote_unhovered.bind(emote_name))
	wheel.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if key_event.keycode == KEY_ESCAPE and key_event.pressed and not key_event.echo:
		if _emote_overlay.visible:
			_close_emote_wheel()
		elif _has_started and get_tree().paused:
			_resume_game()
		elif _has_started:
			_show_menu(false)
			get_tree().paused = true
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_F and _has_started:
		if key_event.pressed and not key_event.echo:
			if not get_tree().paused and not _emote_overlay.visible:
				_hovered_emote = &""
				_emote_overlay.visible = true
			get_viewport().set_input_as_handled()
		elif not key_event.pressed and _emote_overlay.visible:
			if _hovered_emote != &"":
				_select_emote(_hovered_emote)
			else:
				_close_emote_wheel()
			get_viewport().set_input_as_handled()


func _show_menu(is_start_menu: bool) -> void:
	_menu_overlay.visible = true
	_start_button.visible = is_start_menu
	_resume_button.visible = not is_start_menu
	_restart_button.visible = not is_start_menu
	if is_start_menu:
		_menu_title.text = "FURNITURE HATES YOU"
		_menu_subtitle.text = "A quiet trip through the showroom. Probably.\n\nWASD: MOVE    SPACE: JUMP\nSHIFT: SNEAK    F: EMOTES    ESC: PAUSE"
	else:
		_menu_title.text = "SHOWROOM PAUSED"
		_menu_subtitle.text = "Everything is frozen. Take a breather.\n\nWASD: MOVE    SPACE: JUMP\nSHIFT: SNEAK    F: EMOTES    ESC: RESUME"


func _start_game() -> void:
	_has_started = true
	get_tree().paused = false
	_menu_overlay.visible = false


func _resume_game() -> void:
	get_tree().paused = false
	_menu_overlay.visible = false


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _select_emote(emote_name: StringName) -> void:
	if _player != null:
		_player.play_emote(emote_name)
	_close_emote_wheel()


func _on_emote_hovered(emote_name: StringName) -> void:
	_hovered_emote = emote_name


func _on_emote_unhovered(emote_name: StringName) -> void:
	if _hovered_emote == emote_name:
		_hovered_emote = &""


func _close_emote_wheel() -> void:
	_emote_overlay.visible = false
	_hovered_emote = &""


func _on_death_count_changed(new_death_count: int) -> void:
	_death_count_label.text = "DEATHS  %02d" % new_death_count