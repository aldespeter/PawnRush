extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var survived = body.take_damage(global_position)
		# If this is the bottom pit (not a slime) and player survived, respawn on safe ground
		if not get_parent().name.begins_with("Slime") and survived:
			if body.has_method("respawn_at_last_safe_position"):
				body.respawn_at_last_safe_position()
			else:
				body.global_position = Vector2(-52, 14)
				body.velocity = Vector2.ZERO
