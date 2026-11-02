extends CharacterBody3D

enum State { SLEEPING, AWAKENING, CHASING }

@export var detection_radius: float = 6.0
@export var speed: float = 3.5
@export var turn_speed: float = 4.0
@export var can_chase: bool = true

@onready var touch_area: Area3D = $TouchArea
@onready var visual_root: Node3D = $VisualRoot

var _player: CharacterBody3D
var _base_visual_scale: Vector3
var _state: State = State.SLEEPING


func _ready() -> void:
	add_to_group("enemies")
	_base_visual_scale = visual_root.scale
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(50.0)
	touch_area.body_entered.connect(_on_touch_area_body_entered)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	match _state:
		State.SLEEPING:
			velocity.x = move_toward(velocity.x, 0.0, speed * delta)
			velocity.z = move_toward(velocity.z, 0.0, speed * delta)
			if can_chase and is_instance_valid(_player) and global_position.distance_to(_player.global_position) < detection_radius:
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
	if _has_ground_ahead(direction_to_player):
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta)


func _has_ground_ahead(direction: Vector3) -> bool:
	var ray_start: Vector3 = global_position + direction * 0.8 + Vector3.UP * 1.25
	var ray_end: Vector3 = ray_start + Vector3.DOWN * 2.5
	var excluded_bodies: Array[RID] = [get_rid()]
	if is_instance_valid(_player):
		excluded_bodies.append(_player.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		collision_mask,
		excluded_bodies
	)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _on_touch_area_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.call("take_damage", 1)
	elif body.has_method("game_over"):
		body.call("game_over")