extends Area3D

@export var checkpoint_name: String = "Checkpoint"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or not body.has_method("set_checkpoint"):
		return

	body.call("set_checkpoint", global_position + Vector3.UP * 0.15, checkpoint_name)