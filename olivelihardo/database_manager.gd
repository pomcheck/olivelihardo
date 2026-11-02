extends Node

const SCORE_FILE_PATH: String = "user://highscores.dat"
const MAX_STORED_SCORES: int = 100


func save_score(player_name: String, score: int, survival_time: float) -> void:
	var normalized_name: String = player_name.strip_edges()
	if normalized_name.is_empty():
		normalized_name = "Unbekannt"

	var scores: Array = _read_scores()
	scores.append({
		"player_name": normalized_name,
		"score": maxi(score, 0),
		"survival_time": maxf(survival_time, 0.0)
	})
	scores.sort_custom(_sort_scores)
	if scores.size() > MAX_STORED_SCORES:
		scores.resize(MAX_STORED_SCORES)

	var file: FileAccess = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Highscores konnten nicht gespeichert werden.")
		return
	file.store_string(JSON.stringify(scores, "\t"))


func get_top_scores(limit: int = 5) -> Array:
	if limit <= 0:
		return []

	var scores: Array = _read_scores()
	scores.sort_custom(_sort_scores)
	return scores.slice(0, mini(limit, scores.size()))


func _read_scores() -> Array:
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		return []

	var file: FileAccess = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ)
	if file == null:
		return []

	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	if not parsed_data is Array:
		return []

	var valid_scores: Array = []
	for entry: Variant in parsed_data:
		if not entry is Dictionary:
			continue

		var score_value: Variant = entry.get("score", 0)
		var time_value: Variant = entry.get("survival_time", 0.0)
		if typeof(score_value) not in [TYPE_INT, TYPE_FLOAT]:
			continue
		if typeof(time_value) not in [TYPE_INT, TYPE_FLOAT]:
			continue

		valid_scores.append({
			"player_name": str(entry.get("player_name", "Unbekannt")),
			"score": int(score_value),
			"survival_time": float(time_value)
		})
	return valid_scores


func _sort_scores(first: Dictionary, second: Dictionary) -> bool:
	var first_score: int = int(first.get("score", 0))
	var second_score: int = int(second.get("score", 0))
	if first_score == second_score:
		return float(first.get("survival_time", 0.0)) > float(second.get("survival_time", 0.0))
	return first_score > second_score
