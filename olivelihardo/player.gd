extends CharacterBody3D


const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 20.0
const DECELERATION: float = 24.0
const MOUSE_SENSITIVITY: float = 0.002
const MIN_LOOK_ANGLE: float = -PI * 89.0 / 180.0
const MAX_LOOK_ANGLE: float = PI * 89.0 / 180.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_ensure_input_action(&"move_forward", KEY_W)
	_ensure_input_action(&"move_backward", KEY_S)
	_ensure_input_action(&"move_left", KEY_A)
	_ensure_input_action(&"move_right", KEY_D)
	_ensure_input_action(&"jump", KEY_SPACE)
	camera.rotation.x = clampf(camera.rotation.x, MIN_LOOK_ANGLE, MAX_LOOK_ANGLE)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion: InputEventMouseMotion = event
		rotate_y(-mouse_motion.relative.x * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(
			camera.rotation.x - mouse_motion.relative.y * MOUSE_SENSITIVITY,
			MIN_LOOK_ANGLE,
			MAX_LOOK_ANGLE
		)
	elif event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
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
	var direction: Vector3 = (
		global_transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)
	).normalized()
	var target_velocity: Vector3 = direction * SPEED
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var adjustment: float = ACCELERATION if direction != Vector3.ZERO else DECELERATION
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, adjustment * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()


func _ensure_input_action(action_name: StringName, physical_keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)
