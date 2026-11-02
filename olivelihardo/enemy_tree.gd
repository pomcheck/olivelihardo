extends CharacterBody3D

enum State { SLEEPING, AWAKENING, CHASING }

@export var detection_radius: float = 6.0
@export_range(30.0, 180.0, 1.0) var vision_angle_degrees: float = 120.0
@export var speed: float = 3.5
@export var turn_speed: float = 4.0
@export var can_chase: bool = true

@onready var touch_area: Area3D = $TouchArea
@onready var visual_root: Node3D = $VisualRoot
@onready var foliage: MeshInstance3D = $VisualRoot/Leaves

var _player: CharacterBody3D
var _base_visual_scale: Vector3
var _state: State = State.SLEEPING
var _avoidance_direction: Vector3 = Vector3.ZERO
var _avoidance_time_left: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	_base_visual_scale = visual_root.scale
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(50.0)
	touch_area.body_entered.connect(_on_touch_area_body_entered)
	_set_foliage_tint()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	match _state:
		State.SLEEPING:
			velocity.x = move_toward(velocity.x, 0.0, speed * delta)
			velocity.z = move_toward(velocity.z, 0.0, speed * delta)
			if can_chase and _can_see_player():
				_begin_awakening()
		State.AWAKENING:
			velocity.x = move_toward(velocity.x, 0.0, speed * delta)
			velocity.z = move_toward(velocity.z, 0.0, speed * delta)
		State.CHASING:
			if is_instance_valid(_player):
				_chase_player(delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, speed * delta)
				velocity.z = move_toward(velocity.z, 0.0, speed * delta)

	move_and_slide()


func _begin_awakening() -> void:
	_state = State.AWAKENING
	var wake_scale: Vector3 = _base_visual_scale * Vector3(1.0, 1.25, 1.0)
	var wake_tween: Tween = create_tween()
	wake_tween.tween_property(visual_root, "scale", wake_scale, 0.15)
	wake_tween.tween_property(visual_root, "scale", _base_visual_scale, 0.15)
	wake_tween.tween_callback(_start_chasing)


func _start_chasing() -> void:
	_state = State.CHASING


func _chase_player(delta: float) -> void:
	var target_position: Vector3 = _player.global_position
	target_position.y = global_position.y
	var direction_to_player: Vector3 = target_position - global_position
	if direction_to_player.length_squared() <= 0.001:
		return

	direction_to_player = direction_to_player.normalized()
	var current_basis: Basis = global_basis
	look_at(target_position, Vector3.UP)
	var target_basis: Basis = global_basis
	global_basis = current_basis.slerp(
		target_basis,
		clampf(turn_speed * delta, 0.0, 1.0)
	)

	_avoidance_time_left = maxf(_avoidance_time_left - delta, 0.0)
	var steering_direction: Vector3 = direction_to_player
	if _avoidance_time_left > 0.0 and _is_direction_safe(_avoidance_direction):
		steering_direction = _avoidance_direction
	elif not _is_direction_safe(direction_to_player):
		_avoidance_direction = _choose_safe_route(direction_to_player, target_position)
		_avoidance_time_left = 0.45
		steering_direction = _avoidance_direction
	else:
		_avoidance_direction = Vector3.ZERO

	velocity.x = steering_direction.x * speed
	velocity.z = steering_direction.z * speed


func _can_see_player() -> bool:
	if not is_instance_valid(_player):
		return false

	var offset_to_player: Vector3 = _player.global_position - global_position
	if offset_to_player.length() > detection_radius:
		return false

	var direction_to_player: Vector3 = Vector3(offset_to_player.x, 0.0, offset_to_player.z).normalized()
	var forward_direction: Vector3 = Vector3(-global_basis.z.x, 0.0, -global_basis.z.z).normalized()
	var minimum_dot: float = cos(deg_to_rad(vision_angle_degrees * 0.5))
	return forward_direction.dot(direction_to_player) >= minimum_dot and _has_line_of_sight_to(_player)


func _has_line_of_sight_to(target: Node3D) -> bool:
	var ray_start: Vector3 = global_position + Vector3.UP * 1.25
	var ray_end: Vector3 = target.global_position + Vector3.UP * 0.9
	var excluded_bodies: Array[RID] = [get_rid(), target.get_rid()]
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		collision_mask,
		excluded_bodies
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _is_direction_safe(direction: Vector3) -> bool:
	if direction.length_squared() < 0.001:
		return false
	return not _has_wall_ahead(direction) and _has_ground_ahead(direction)


func _has_wall_ahead(direction: Vector3) -> bool:
	var ray_start: Vector3 = global_position + Vector3.UP * 0.85
	var ray_end: Vector3 = ray_start + direction.normalized() * 1.35
	return not _raycast_world(ray_start, ray_end).is_empty()


func _has_ground_ahead(direction: Vector3) -> bool:
	var ray_start: Vector3 = global_position + direction.normalized() * 0.9 + Vector3.UP * 1.25
	var ray_end: Vector3 = ray_start + Vector3.DOWN * 2.5
	return not _raycast_world(ray_start, ray_end).is_empty()


func _raycast_world(ray_start: Vector3, ray_end: Vector3) -> Dictionary:
	var excluded_bodies: Array[RID] = [get_rid()]
	if is_instance_valid(_player):
		excluded_bodies.append(_player.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		collision_mask,
		excluded_bodies
	)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _choose_safe_route(desired_direction: Vector3, target_position: Vector3) -> Vector3:
	var candidate_angles: Array[float] = [
		PI / 4.0,
		-PI / 4.0,
		PI / 2.0,
		-PI / 2.0,
		PI * 3.0 / 4.0,
		-PI * 3.0 / 4.0,
		PI
	]
	var best_direction: Vector3 = Vector3.ZERO
	var best_score: float = -INF
	for angle: float in candidate_angles:
		var candidate: Vector3 = desired_direction.rotated(Vector3.UP, angle).normalized()
		if not _is_direction_safe(candidate):
			continue
		var projected_position: Vector3 = global_position + candidate * 1.5
		var progress: float = global_position.distance_to(target_position) - projected_position.distance_to(target_position)
		if progress > best_score:
			best_score = progress
			best_direction = candidate
	return best_direction


func _set_foliage_tint() -> void:
	var source_material: StandardMaterial3D = foliage.get_active_material(0) as StandardMaterial3D
	if source_material == null:
		return

	var instance_material: StandardMaterial3D = source_material.duplicate() as StandardMaterial3D
	instance_material.albedo_color = Color(0.4, 0.5, 0.24, 1.0) if not can_chase else Color(0.18, 0.42, 0.12, 1.0)
	foliage.material_override = instance_material


func _on_touch_area_body_entered(body: Node3D) -> void:
	if not can_chase or _state != State.CHASING or not body.is_in_group("player"):
		return
	if not _has_line_of_sight_to(body):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", 1)
	elif body.has_method("game_over"):
		body.call("game_over")