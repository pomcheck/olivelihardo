extends CanvasLayer

var _death_count_label: Label
var _menu_overlay: ColorRect
var _menu_title: Label
var _menu_subtitle: Label
var _start_button: Button
var _resume_button: Button
var _restart_button: Button
var _has_started: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("HUD: Kein Spieler in der Gruppe 'player' gefunden.")
	_build_interface()
	if player != null:
		player.connect("death_count_changed", Callable(self, "_on_death_count_changed"))
		_on_death_count_changed(int(player.get("death_count")))
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


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return

	if _has_started and get_tree().paused:
		_resume_game()
	elif _has_started:
		_show_menu(false)
		get_tree().paused = true
	get_viewport().set_input_as_handled()


func _show_menu(is_start_menu: bool) -> void:
	_menu_overlay.visible = true
	_start_button.visible = is_start_menu
	_resume_button.visible = not is_start_menu
	_restart_button.visible = not is_start_menu
	if is_start_menu:
		_menu_title.text = "FURNITURE HATES YOU"
		_menu_subtitle.text = "A quiet trip through the showroom. Probably."
	else:
		_menu_title.text = "SHOWROOM PAUSED"
		_menu_subtitle.text = "Everything is frozen. Take a breather."


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


func _on_death_count_changed(new_death_count: int) -> void:
	_death_count_label.text = "DEATHS  %02d" % new_death_count