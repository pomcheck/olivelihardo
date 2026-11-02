extends FurnitureEnemy
class_name SpinningStool

@export var spin_speed: float = 18.0
@export var zigzag_strength: float = 0.85
@export var zigzag_frequency: float = 3.5
@export var attack_duration: float = 2.5

var _attack_time: float = 0.0


func execute_attack(delta: float) -> void:
	_attack_time += delta
	if _attack_time >= attack_duration:
		start_cooldown()
		return

	rotation.y += spin_speed * delta
	var direction: Vector3 = _player_direction()
	if direction == Vector3.ZERO:
		return
	var sideways: Vector3 = Vector3(-direction.z, 0.0, direction.x)
	var zigzag_direction: Vector3 = (
		direction + sideways * sin(_attack_time * zigzag_frequency) * zigzag_strength
	).normalized()
	_move_horizontally(zigzag_direction, move_speed, delta)


func on_cooldown_finished() -> void:
	_attack_time = 0.0