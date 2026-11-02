extends CharacterBody3D

signal score_updated(score: int, survival_time: float)
signal damage_taken(amount: int)
signal health_changed(current_health: int, max_health: int)
signal player_died(final_score: int, survival_time: float)
signal checkpoint_reached(checkpoint_name: String)
signal respawned(checkpoint_name: String)
signal death_count_changed(death_count: int)

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 20.0
const DECELERATION: float = 24.0
const ROTATION_SPEED: float = 12.0

@export var max_health: int = 1

@onready var visual_root: Node3D = $VisualRoot
@onready var left_leg_pivot: Node3D = $VisualRoot/LeftLegPivot
@onready var right_leg_pivot: Node3D = $VisualRoot/RightLegPivot
@onready var left_arm_pivot: Node3D = $VisualRoot/LeftArmPivot
@onready var right_arm_pivot: Node3D = $VisualRoot/RightArmPivot

var health: int = 1
var score: int = 0
var death_count: int = 0
var survival_time: float = 0.0
var _game_over: bool = false
var _last_reported_second: int = -1
var _has_checkpoint: bool = false
var _checkpoint_name: String = ""
var _checkpoint_position: Vector3 = Vector3.ZERO
var _respawning: bool = false
var _spawn_position: Vector3 = Vector3.ZERO
var _run_cycle: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
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
	_update_run_animation(delta, direction != Vector3.ZERO and is_on_floor())

	var target_velocity: Vector3 = direction * SPEED
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var adjustment: float = ACCELERATION if direction != Vector3.ZERO else DECELERATION
	horizontal_velocity = horizontal_velocity.move_toward(target_velocity, adjustment * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()


func take_damage(amount: int) -> void:
	if _game_over or _respawning or amount <= 0:
		return

	health = maxi(health - amount, 0)
	damage_taken.emit(amount)
	health_changed.emit(health, max_health)
	if health == 0:
		death_count += 1
		death_count_changed.emit(death_count)
		_respawning = true
		call_deferred("_respawn_at_checkpoint")


func set_checkpoint(checkpoint_position: Vector3, checkpoint_name: String) -> void:
	if _has_checkpoint and _checkpoint_name == checkpoint_name:
		return

	_checkpoint_position = checkpoint_position
	_checkpoint_name = checkpoint_name
	_has_checkpoint = true
	checkpoint_reached.emit(_checkpoint_name)


func _respawn_at_checkpoint() -> void:
	global_position = _checkpoint_position if _has_checkpoint else _spawn_position
	velocity = Vector3.ZERO
	health = max_health
	_respawning = false
	health_changed.emit(health, max_health)
	respawned.emit(_checkpoint_name)


func game_over() -> void:
	if _game_over:
		return

	_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit(score, survival_time)


func _update_run_animation(delta: float, is_running: bool) -> void:
	if is_running:
		_run_cycle += delta * 11.0
		var swing: float = sin(_run_cycle) * 0.55
		left_leg_pivot.rotation.x = swing
		right_leg_pivot.rotation.x = -swing
		left_arm_pivot.rotation.x = -swing * 0.65
		right_arm_pivot.rotation.x = swing * 0.65
		visual_root.position.y = absf(sin(_run_cycle * 2.0)) * 0.045
	else:
		var recovery: float = minf(delta * 10.0, 1.0)
		left_leg_pivot.rotation.x = lerpf(left_leg_pivot.rotation.x, 0.0, recovery)
		right_leg_pivot.rotation.x = lerpf(right_leg_pivot.rotation.x, 0.0, recovery)
		left_arm_pivot.rotation.x = lerpf(left_arm_pivot.rotation.x, 0.0, recovery)
		right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, 0.0, recovery)
		visual_root.position.y = lerpf(visual_root.position.y, 0.0, recovery)


func _ensure_input_action(action_name: StringName, physical_keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)
