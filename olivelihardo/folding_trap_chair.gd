extends FurnitureEnemy
class_name FoldingTrapChair

@export var dash_speed: float = 14.0
@export var dash_duration: float = 0.28

var _dash_direction: Vector3 = Vector3.ZERO
var _dash_remaining: float = 0.0


func execute_attack(delta: float) -> void:
	if _dash_remaining <= 0.0:
		_dash_direction = _player_direction()
		if _dash_direction == Vector3.ZERO:
			return
		_dash_remaining = dash_duration
		_face_direction(_dash_direction, delta)

	_dash_remaining -= delta
	if _dash_remaining > 0.0:
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		start_cooldown()


func on_cooldown_finished() -> void:
	super.on_cooldown_finished()
	_dash_remaining = 0.0