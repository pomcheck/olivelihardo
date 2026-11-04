extends FurnitureEnemy
class_name FlyingArmchair

enum FlightPhase { READY, LIFTING, PAUSING, DIVING }

@export var lift_height: float = 4.0
@export var pause_duration: float = 0.5
@export var dive_speed: float = 14.0
@export var dive_horizontal_speed: float = 8.0

var _flight_phase: FlightPhase = FlightPhase.READY
var _pause_remaining: float = 0.0
var _launch_height: float = 0.0
var _last_known_player_position: Vector3 = Vector3.ZERO
var _flight_tween: Tween


func reset_to_sleeping() -> void:
	if _flight_tween != null and _flight_tween.is_running():
		_flight_tween.kill()
	_flight_phase = FlightPhase.READY
	_pause_remaining = 0.0
	super.reset_to_sleeping()


func execute_attack(delta: float) -> void:
	match _flight_phase:
		FlightPhase.READY:
			_begin_flight()
		FlightPhase.LIFTING:
			velocity = Vector3.ZERO
		FlightPhase.PAUSING:
			velocity = Vector3.ZERO
			_pause_remaining -= delta
			if _pause_remaining <= 0.0:
				_flight_phase = FlightPhase.DIVING
				velocity.y = -dive_speed
		FlightPhase.DIVING:
			if is_on_floor():
				velocity = Vector3.ZERO
				start_cooldown()
				return
			var dive_direction: Vector3 = _last_known_player_position - global_position
			dive_direction.y = 0.0
			if dive_direction.length_squared() > 0.001:
				dive_direction = dive_direction.normalized()
				_move_horizontally(dive_direction, dive_horizontal_speed, delta)
			velocity.y = move_toward(velocity.y, -dive_speed, 28.0 * delta)


func should_apply_gravity() -> bool:
	return current_state == State.COOLDOWN or _flight_phase == FlightPhase.READY or _flight_phase == FlightPhase.DIVING


func on_cooldown_finished() -> void:
	_flight_phase = FlightPhase.READY
	global_position = home_position
	velocity = Vector3.ZERO


func _begin_flight() -> void:
	_flight_phase = FlightPhase.LIFTING
	_launch_height = position.y
	_last_known_player_position = player.global_position if is_instance_valid(player) else global_position
	_flight_tween = create_tween()
	_flight_tween.tween_property(self, "position:y", _launch_height + lift_height, 0.55)
	_flight_tween.tween_callback(_begin_pause)


func _begin_pause() -> void:
	_flight_phase = FlightPhase.PAUSING
	_pause_remaining = pause_duration