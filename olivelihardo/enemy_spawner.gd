extends Node3D

@export var enemy_scene: PackedScene = preload("res://enemy_tree.tscn")
@export var spawn_interval_min: float = 5.0
@export var spawn_interval_max: float = 10.0
@export var max_enemies: int = 8
@export var spawn_points: Array[Vector3] = [
	Vector3(-6.0, 0.0, 4.0),
	Vector3(6.0, 0.0, -5.0),
	Vector3(-5.0, 2.0, -21.0),
	Vector3(24.0, 3.2, -21.0)
]

var _spawn_timer: Timer


func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_start_spawn_timer()


func _on_spawn_timer_timeout() -> void:
	if get_tree().get_nodes_in_group("enemies").size() < max_enemies:
		_spawn_enemy()
	_start_spawn_timer()


func _spawn_enemy() -> void:
	if spawn_points.is_empty():
		return

	var enemy: Node3D = enemy_scene.instantiate() as Node3D
	if enemy == null:
		push_error("Die EnemyTree-Szene hat keinen Node3D-Root.")
		return

	var world: Node = get_tree().current_scene
	world.add_child(enemy)
	enemy.global_position = spawn_points[randi_range(0, spawn_points.size() - 1)]


func _start_spawn_timer() -> void:
	_spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	_spawn_timer.start()