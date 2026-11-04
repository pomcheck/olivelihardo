extends CharacterBody3D

signal score_updated(score: int, survival_time: float)
signal damage_taken(amount: int)
signal health_changed(current_health: int, max_health: int)
signal player_died(final_score: int, survival_time: float)
signal death_started
signal checkpoint_reached(checkpoint_name: String)
signal respawned(checkpoint_name: String)
signal death_count_changed(death_count: int)

const SPEED: float = 5.0
const SNEAK_SPEED: float = 1.8
const JUMP_VELOCITY: float = 4.5
const ACCELERATION: float = 20.0
const DECELERATION: float = 24.0
const ROTATION_SPEED: float = 12.0

@export var max_health: int = 1

@onready var visual_root: Node3D = $VisualRoot
@onready var player_collision: CollisionShape3D = $CollisionShape3D
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
var _standing_capsule_height: float = 1.8
var _is_sneaking: bool = false
var _active_emote: StringName = &""
var _emote_time: float = 0.0
var _facing_yaw: float = 0.0
var _spin_yaw_offset: float = 0.0
var _turn_lean: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_spawn_position = global_position
	health = max_health
	_facing_yaw = visual_root.rotation.y
	var source_shape: CapsuleShape3D = player_collision.shape as CapsuleShape3D
	if source_shape != null:
		var unique_shape: CapsuleShape3D = source_shape.duplicate() as CapsuleShape3D
		player_collision.shape = unique_shape
		_standing_capsule_height = unique_shape.height
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	_ensure_input_action(&"move_forward", KEY_W)
	_ensure_input_action(&"move_backward", KEY_S)
	_ensure_input_action(&"move_left", KEY_A)
	_ensure_input_action(&"move_right", KEY_D)
	_ensure_input_action(&"jump", KEY_SPACE)
	_ensure_input_action(&"sneak", KEY_SHIFT)
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
	if _respawning:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	_is_sneaking = Input.is_action_pressed(&"sneak")
	_update_sneak_pose(delta)
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
		_facing_yaw = lerp_angle(
			_facing_yaw,
			desired_yaw,
			minf(ROTATION_SPEED * delta, 1.0)
		)
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var is_moving: bool = horizontal_speed > 0.1 and is_on_floor()
	_update_run_animation(delta, is_moving and not _is_sneaking)
	visual_root.rotation.y = _facing_yaw + _spin_yaw_offset

	var current_speed: float = SNEAK_SPEED if _is_sneaking else SPEED
	var target_velocity: Vector3 = direction * current_speed
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var adjustment: float = ACCELERATION if direction != Vector3.ZERO else DECELERATION
	if _is_sneaking:
		adjustment *= 0.7
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
		velocity = Vector3.ZERO
		SoundManager.play_sfx(&"hit")
		flash_damage()
		death_started.emit()


func set_checkpoint(checkpoint_position: Vector3, checkpoint_name: String) -> void:
	if _has_checkpoint and _checkpoint_name == checkpoint_name:
		return

	_checkpoint_position = checkpoint_position
	_checkpoint_name = checkpoint_name
	_has_checkpoint = true
	checkpoint_reached.emit(_checkpoint_name)


func respawn_at_checkpoint() -> void:
	global_position = _checkpoint_position if _has_checkpoint else _spawn_position
	velocity = Vector3.ZERO
	health = max_health
	_respawning = false
	health_changed.emit(health, max_health)
	respawned.emit(_checkpoint_name)
	SoundManager.play_sfx(&"respawn")


func flash_damage() -> void:
	var overlay_material: StandardMaterial3D = StandardMaterial3D.new()
	overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_material.albedo_color = Color(1.0, 0.04, 0.02, 0.72)
	_set_damage_overlay(visual_root, overlay_material)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(overlay_material, "albedo_color:a", 0.0, 0.18)
	flash_tween.tween_callback(_clear_damage_overlay.bind(visual_root))


func _set_damage_overlay(node: Node, overlay_material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = overlay_material
	for child: Node in node.get_children():
		_set_damage_overlay(child, overlay_material)


func _clear_damage_overlay(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = null
	for child: Node in node.get_children():
		_clear_damage_overlay(child)


func game_over() -> void:
	if _game_over:
		return

	_game_over = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_died.emit(score, survival_time)


func play_emote(emote_name: StringName) -> void:
	if emote_name not in [&"groove", &"spin", &"wave", &"bounce"]:
		return
	_active_emote = emote_name
	_emote_time = 0.0
	_spin_yaw_offset = 0.0


func _update_sneak_pose(delta: float) -> void:
	var capsule: CapsuleShape3D = player_collision.shape as CapsuleShape3D
	if capsule == null:
		return

	var target_height: float = 1.15 if _is_sneaking else _standing_capsule_height
	capsule.height = move_toward(capsule.height, target_height, delta * 3.0)
	player_collision.position.y = capsule.height * 0.5


func _update_run_animation(delta: float, is_running: bool) -> void:
	if _active_emote != &"":
		_update_dance_animation(delta)
		return

	if is_running:
		_run_cycle += delta * 11.0
		var swing: float = sin(_run_cycle) * 0.55
		left_leg_pivot.rotation.x = swing
		right_leg_pivot.rotation.x = -swing
		left_arm_pivot.rotation.x = -swing * 0.65
		right_arm_pivot.rotation.x = swing * 0.65
		var speed_factor: float = clampf(Vector2(velocity.x, velocity.z).length() / SPEED, 0.0, 1.0)
		visual_root.position.y = -0.22 if _is_sneaking else absf(sin(_run_cycle * 2.0)) * 0.075 * speed_factor
	else:
		var recovery: float = minf(delta * 10.0, 1.0)
		left_leg_pivot.rotation.x = lerpf(left_leg_pivot.rotation.x, 0.0, recovery)
		right_leg_pivot.rotation.x = lerpf(right_leg_pivot.rotation.x, 0.0, recovery)
		left_arm_pivot.rotation.x = lerpf(left_arm_pivot.rotation.x, 0.0, recovery)
		right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, 0.0, recovery)
		visual_root.position.y = lerpf(visual_root.position.y, -0.22 if _is_sneaking else 0.0, recovery)
	_turn_lean = lerpf(_turn_lean, -clampf(velocity.x * 0.035, -0.12, 0.12), minf(delta * 8.0, 1.0))
	visual_root.rotation.z = _turn_lean


func _update_dance_animation(delta: float) -> void:
	_emote_time += delta
	if _emote_time >= 2.8:
		_active_emote = &""
		_spin_yaw_offset = 0.0
		return

	var dance_cycle: float = sin(_emote_time * TAU * 1.5)
	left_arm_pivot.rotation.x = 0.0
	right_arm_pivot.rotation.x = 0.0
	left_leg_pivot.rotation.x = 0.0
	right_leg_pivot.rotation.x = 0.0
	visual_root.position.y = -0.22 if _is_sneaking else 0.0
	match _active_emote:
		&"groove":
			left_arm_pivot.rotation.x = dance_cycle * 0.9
			right_arm_pivot.rotation.x = -dance_cycle * 0.9
			left_leg_pivot.rotation.x = dance_cycle * 0.35
			right_leg_pivot.rotation.x = -dance_cycle * 0.35
		&"spin":
			_spin_yaw_offset += delta * TAU * 1.2
			left_arm_pivot.rotation.x = -0.8
			right_arm_pivot.rotation.x = -0.8
		&"wave":
			right_arm_pivot.rotation.x = -1.7 + absf(dance_cycle) * 0.75
			left_arm_pivot.rotation.x = 0.2
		&"bounce":
			visual_root.position.y += absf(dance_cycle) * 0.22
			left_arm_pivot.rotation.x = dance_cycle * 0.45
			right_arm_pivot.rotation.x = -dance_cycle * 0.45


func _ensure_input_action(action_name: StringName, physical_keycode: Key) -> void:
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)
