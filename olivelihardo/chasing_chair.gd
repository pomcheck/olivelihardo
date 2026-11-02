extends FurnitureEnemy
class_name ChasingChair

@export var defuse_distance: float = 3.0

var _has_chased: bool = false


func execute_attack(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_has_chased = true
	if global_position.distance_to(player.global_position) <= defuse_distance:
		defuse_here()
		return
	_move_toward_player(delta, move_speed)