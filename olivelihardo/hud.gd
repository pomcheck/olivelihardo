extends CanvasLayer

var _player: CharacterBody3D
var _score_label: Label
var _health_label: Label
var _damage_label: Label
var _game_over_overlay: ColorRect
var _final_score_label: Label
var _name_input: LineEdit
var _leaderboard_label: Label
var _save_status_label: Label
var _save_button: Button
var _final_score: int = 0
var _final_survival_time: float = 0.0
var _score_saved: bool = false


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		push_error("HUD: Kein Spieler in der Gruppe 'player' gefunden.")
		return

	_build_interface()
	_player.connect("score_updated", Callable(self, "_on_score_updated"))
	_player.connect("damage_taken", Callable(self, "_on_damage_taken"))
	_player.connect("health_changed", Callable(self, "_on_health_changed"))
	_player.connect("player_died", Callable(self, "_on_player_died"))
	_on_score_updated(int(_player.get("score")), float(_player.get("survival_time")))
	_on_health_changed(int(_player.get("health")), int(_player.get("max_health")))


func _build_interface() -> void:
	var hud_root: Control = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	_score_label = Label.new()
	_score_label.position = Vector2(24.0, 20.0)
	_score_label.size = Vector2(360.0, 48.0)
	_score_label.add_theme_font_size_override("font_size", 24)
	hud_root.add_child(_score_label)

	_health_label = Label.new()
	_health_label.position = Vector2(24.0, 58.0)
	_health_label.size = Vector2(240.0, 28.0)
	hud_root.add_child(_health_label)

	_damage_label = Label.new()
	_damage_label.position = Vector2(24.0, 86.0)
	_damage_label.size = Vector2(320.0, 28.0)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))
	hud_root.add_child(_damage_label)

	_game_over_overlay = ColorRect.new()
	_game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_overlay.color = Color(0.02, 0.04, 0.03, 0.86)
	_game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_game_over_overlay.visible = false
	hud_root.add_child(_game_over_overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_over_overlay.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 0.0)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.12, 0.09, 1.0)
	panel_style.border_color = Color(0.52, 0.68, 0.32, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(22.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	var title: Label = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	_final_score_label = Label.new()
	_final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_score_label.add_theme_font_size_override("font_size", 20)
	content.add_child(_final_score_label)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Spielername"
	_name_input.max_length = 24
	content.add_child(_name_input)

	_save_button = Button.new()
	_save_button.text = "Score speichern"
	_save_button.pressed.connect(_on_save_button_pressed)
	content.add_child(_save_button)

	_save_status_label = Label.new()
	_save_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_save_status_label)

	var leaderboard_title: Label = Label.new()
	leaderboard_title.text = "BESTENLISTE"
	leaderboard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_title.add_theme_font_size_override("font_size", 18)
	content.add_child(leaderboard_title)

	_leaderboard_label = Label.new()
	_leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leaderboard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_leaderboard_label)

	var restart_button: Button = Button.new()
	restart_button.text = "Neustart"
	restart_button.pressed.connect(_on_restart_button_pressed)
	content.add_child(restart_button)


func _on_score_updated(current_score: int, current_survival_time: float) -> void:
	_score_label.text = "Zeit: %d s    Score: %d" % [int(current_survival_time), current_score]


func _on_damage_taken(amount: int) -> void:
	_damage_label.text = "Getroffen! Schaden: %d" % amount


func _on_health_changed(current_health: int, max_health: int) -> void:
	_health_label.text = "Gesundheit: %d / %d" % [current_health, max_health]


func _on_player_died(final_score: int, final_survival_time: float) -> void:
	_final_score = final_score
	_final_survival_time = final_survival_time
	_score_saved = false
	_final_score_label.text = "Erreichter Score: %d" % _final_score
	_save_status_label.text = ""
	_save_button.disabled = false
	_game_over_overlay.visible = true
	_refresh_leaderboard()


func _on_save_button_pressed() -> void:
	if _score_saved:
		return

	DatabaseManager.save_score(_name_input.text, _final_score, _final_survival_time)
	_score_saved = true
	_save_button.disabled = true
	_save_status_label.text = "Score gespeichert"
	_refresh_leaderboard()


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _refresh_leaderboard() -> void:
	var top_scores: Array = DatabaseManager.get_top_scores(5)
	if top_scores.is_empty():
		_leaderboard_label.text = "Noch keine Einträge"
		return

	var lines: PackedStringArray = PackedStringArray()
	for index: int in range(top_scores.size()):
		var entry: Dictionary = top_scores[index]
		lines.append("%d. %s  |  %d" % [
			index + 1,
			str(entry.get("player_name", "Unbekannt")),
			int(entry.get("score", 0))
		])
	_leaderboard_label.text = "\n".join(lines)