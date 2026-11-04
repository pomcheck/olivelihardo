extends CharacterBody3D
class_name FurnitureEnemy

const TOON_SHADER: Shader = preload("res://shaders/toon_cel.gdshader")

enum State { SLEEPING, AWAKENING, ATTACKING, COOLDOWN }

@export var detection_radius: float = 6.0
@export var move_speed: float = 3.5
@export var attack_cooldown: float = 2.0

@onready var visual_root: Node3D = $VisualRoot
@onready var touch_area: Area3D = $TouchArea

var current_state: State = State.SLEEPING
var player: CharacterBody3D
var _cooldown_remaining: float = 0.0
var home_position: Vector3 = Vector3.ZERO
var _home_yaw: float = 0.0
var _must_rearm: bool = false
var _defused: bool = false
var _base_visual_scale: Vector3 = Vector3.ONE
var _wake_tween: Tween


func _ready() -> void:
	add_to_group("furniture_enemies")
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	home_position = global_position
	_home_yaw = rotation.y
	_base_visual_scale = visual_root.scale
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(50.0)
	_apply_toon_materials(visual_root)
	touch_area.body_entered.connect(_on_touch_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if should_apply_gravity() and not is_on_floor():
		velocity += get_gravity() * delta

	match current_state:
		State.SLEEPING:
			_stop_horizontal_motion(delta)
			if is_instance_valid(player) and not _defused:
				var player_distance: float = global_position.distance_to(player.global_position)
				if _must_rearm:
					if player_distance > detection_radius * 1.35:
						_must_rearm = false
				elif player_distance <= detection_radius:
					_begin_awakening()
		State.AWAKENING:
			_stop_horizontal_motion(delta)
		State.ATTACKING:
			execute_attack(delta)
		State.COOLDOWN:
			_return_to_home(delta)
			_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
			if _cooldown_remaining == 0.0 and _is_at_home():
				current_state = State.SLEEPING
				_must_rearm = true
				on_cooldown_finished()

	move_and_slide()
	if global_position.y < home_position.y - 4.0:
		global_position = home_position
		velocity = Vector3.ZERO
		start_cooldown()


func execute_attack(delta: float) -> void:
	_move_toward_player(delta, move_speed)


func on_player_hit() -> void:
	start_cooldown()


func on_cooldown_finished() -> void:
	pass


func should_apply_gravity() -> bool:
	return true


func start_cooldown() -> void:
	if current_state == State.COOLDOWN or _defused:
		return
	current_state = State.COOLDOWN
	_cooldown_remaining = attack_cooldown
	_must_rearm = true


func defuse_here() -> void:
	_defused = true
	current_state = State.SLEEPING
	velocity = Vector3.ZERO
	touch_area.set_deferred("monitoring", false)
	visual_root.rotation.z = PI * 0.5


func reset_to_sleeping() -> void:
	if _wake_tween != null and _wake_tween.is_running():
		_wake_tween.kill()
	current_state = State.SLEEPING
	_cooldown_remaining = 0.0
	_must_rearm = true
	_defused = false
	global_position = home_position
	rotation.y = _home_yaw
	velocity = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	visual_root.scale = _base_visual_scale
	touch_area.set_deferred("monitoring", true)
	on_cooldown_finished()


func _apply_toon_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			mesh_instance.material_override = _make_toon_material(
				mesh_instance.material_override as StandardMaterial3D
			)
		elif mesh_instance.mesh != null:
			for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
				var source_material: Material = mesh_instance.get_surface_override_material(surface_index)
				if source_material == null:
					source_material = mesh_instance.mesh.surface_get_material(surface_index)
				if source_material is StandardMaterial3D:
					mesh_instance.set_surface_override_material(
						surface_index,
						_make_toon_material(source_material as StandardMaterial3D)
					)
	for child: Node in node.get_children():
		_apply_toon_materials(child)


func _make_toon_material(source: StandardMaterial3D) -> ShaderMaterial:
	var toon_material: ShaderMaterial = ShaderMaterial.new()
	toon_material.shader = TOON_SHADER
	toon_material.set_shader_parameter("albedo_color", source.albedo_color)
	toon_material.set_shader_parameter("albedo_texture", source.albedo_texture)
	toon_material.set_shader_parameter("use_albedo_texture", source.albedo_texture != null)
	toon_material.set_shader_parameter(
		"texture_scale",
		Vector2(source.uv1_scale.x, source.uv1_scale.y)
	)
	return toon_material


func _begin_awakening() -> void:
	current_state = State.AWAKENING
	SoundManager.play_sfx(&"aggro")
	var resting_scale: Vector3 = visual_root.scale
	_wake_tween = create_tween()
	_wake_tween.tween_property(visual_root, "scale", resting_scale * Vector3(1.08, 0.92, 1.08), 0.15)
	_wake_tween.tween_property(visual_root, "scale", resting_scale, 0.15)
	_wake_tween.tween_callback(_finish_awakening)


func _finish_awakening() -> void:
	current_state = State.ATTACKING
	SoundManager.play_sfx(&"attack")


func _player_direction() -> Vector3:
	if not is_instance_valid(player):
		return Vector3.ZERO

	var direction: Vector3 = player.global_position - global_position
	direction.y = 0.0
	return direction.normalized()


func _move_toward_player(delta: float, speed: float) -> void:
	if not is_instance_valid(player):
		_stop_horizontal_motion(delta)
		return
	_move_safely_toward(player.global_position, speed, delta)


func _move_safely_toward(target_position: Vector3, speed: float, delta: float) -> void:
	var desired_direction: Vector3 = target_position - global_position
	desired_direction.y = 0.0
	if desired_direction.length_squared() <= 0.001:
		_stop_horizontal_motion(delta)
		return
	desired_direction = desired_direction.normalized()
	var movement_direction: Vector3 = _choose_safe_direction(desired_direction, target_position)
	if movement_direction == Vector3.ZERO:
		_stop_horizontal_motion(delta)
		return
	_face_direction(movement_direction, delta)
	_move_horizontally(movement_direction, speed, delta)


func _choose_safe_direction(desired_direction: Vector3, target_position: Vector3) -> Vector3:
	var angles: Array[float] = [0.0, PI / 4.0, -PI / 4.0, PI / 2.0, -PI / 2.0, PI * 3.0 / 4.0, -PI * 3.0 / 4.0, PI]
	var best_direction: Vector3 = Vector3.ZERO
	var best_progress: float = -INF
	for angle: float in angles:
		var candidate: Vector3 = desired_direction.rotated(Vector3.UP, angle).normalized()
		if not _has_ground_ahead(candidate) or _has_wall_ahead(candidate):
			continue
		var next_position: Vector3 = global_position + candidate * 1.5
		var progress: float = global_position.distance_to(target_position) - next_position.distance_to(target_position)
		if progress > best_progress:
			best_progress = progress
			best_direction = candidate
	return best_direction


func _has_ground_ahead(direction: Vector3) -> bool:
	var ray_start: Vector3 = global_position + direction * 0.9 + Vector3.UP * 1.25
	return not _raycast_world(ray_start, ray_start + Vector3.DOWN * 2.5).is_empty()


func _has_wall_ahead(direction: Vector3) -> bool:
	var ray_start: Vector3 = global_position + Vector3.UP * 0.8
	return not _raycast_world(ray_start, ray_start + direction * 1.25).is_empty()


func _raycast_world(ray_start: Vector3, ray_end: Vector3) -> Dictionary:
	var excluded_bodies: Array[RID] = [get_rid()]
	if is_instance_valid(player):
		excluded_bodies.append(player.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		collision_mask,
		excluded_bodies
	)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _return_to_home(delta: float) -> void:
	_move_safely_toward(home_position, move_speed, delta)
	rotation.y = lerp_angle(rotation.y, _home_yaw, minf(6.0 * delta, 1.0))


func _is_at_home() -> bool:
	var horizontal_offset: Vector2 = Vector2(global_position.x - home_position.x, global_position.z - home_position.z)
	return horizontal_offset.length() < 0.3 and absf(global_position.y - home_position.y) < 0.6


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() <= 0.001:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(8.0 * delta, 1.0))


func _move_horizontally(direction: Vector3, speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction.x * speed, speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, speed * 6.0 * delta)


func _stop_horizontal_motion(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)


func _on_touch_area_body_entered(body: Node3D) -> void:
	if current_state != State.ATTACKING or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.call("take_damage", 1)
	on_player_hit()