extends CharacterBody3D

signal score_updated(score: int, survival_time: float)
signal damage_taken(amount: int)
signal health_changed(current_health: int, max_health: int)
signal player_died(final_score: int, survival_time: float)

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 20.0
const DECELERATION: float = 24.0
const ROTATION_SPEED: float = 12.0

@export var max_health: int = 1

@onready var visual_root: Node3D = $VisualRoot

var health: int = 1
var score: int = 0
var survival_time: float = 0.0
var _game_over: bool = false
var _last_reported_second: int = -1


func _ready() -> void:
	add_to_group("player")
	health = max_health
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	_ensure_input_action(&"move_forward", KEY_W)
	_ensure_input_action(&"move_backward", KEY_S)
	_ensure_input_action(&"move_left", KEY_A)
	_ensure_input_action(&"move_right", KEY_D)
	_ensure_input_action(&"jump", KEY_SPACE)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if _game_over:
		return

	survival_time += delta
	var elapsed_seconds: int = int(floor(survival_time))
	if elapsed_seconds != _last_reported_second:
		_last_reported_second = elapsed_seconds
		score = elapsed_seconds * 10
		score_updated.emit(score, survival_time)


func _physics_process(delta: float) -> void:
	if _game_over:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor() and Input.is_action_just_pressed(&"jump"):
		velocity.y = JUMP_VELOCITY

	var input_direction: Vector2 = Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_backward"
	)
	var direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y).normalized()
	if direction != Vector3.ZERO:
		var desired_yaw: float = atan2(-direction.x, -direction.z)
		visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y,
			desired_yaw,
			minf(ROTATION_SPEED * delta, 1.0)
		)

	var target_velocity: Vector3 = direction * SPEED
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var adjustment: float = ACCELERATION if direction != Vector3.ZERO else DECELERATION
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, adjustment * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()


func take_damage(amount: int) -> void:
	if _game_over or amount <= 0:
		return

	health = maxi(health - amount, 0)
	damage_taken.emit(amount)
	health_changed.emit(health, max_health)
	if health == 0:
		game_over()


func game_over() -> void:
	if _game_over:
		return

	_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit(score, survival_time)


func _ensure_input_action(action_name: StringName, physical_keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)
