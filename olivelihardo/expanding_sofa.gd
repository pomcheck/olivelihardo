extends FurnitureEnemy
class_name ExpandingSofa

@export var expansion_scale: float = 3.5
@export var expansion_duration: float = 1.2

var _expanded: bool = false
var _expansion_tween: Tween


func execute_attack(delta: float) -> void:
	_move_toward_player(delta, move_speed)
	if not _expanded:
		_expanded = true
		_expansion_tween = create_tween()
		_expansion_tween.tween_property(
			self,
			"scale",
			Vector3(expansion_scale, 1.0, expansion_scale),
			expansion_duration
		)
		_expansion_tween.tween_callback(_finish_expansion_attack)


func on_player_hit() -> void:
	super.on_player_hit()
	_shrink_sofa()


func on_cooldown_finished() -> void:
	super.on_cooldown_finished()
	_expanded = false
	scale = Vector3.ONE


func _finish_expansion_attack() -> void:
	if current_state == State.ATTACKING:
		start_cooldown()
		_shrink_sofa()


func _shrink_sofa() -> void:
	if _expansion_tween != null and _expansion_tween.is_running():
		_expansion_tween.kill()
	_expansion_tween = create_tween()
	_expansion_tween.tween_property(self, "scale", Vector3.ONE, 0.45)