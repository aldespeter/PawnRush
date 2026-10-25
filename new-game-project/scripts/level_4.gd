extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var killzone: Area2D = $killzone

func _ready() -> void:
	if killzone:
		killzone.body_entered.connect(_on_killzone_body_entered)

func _on_killzone_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == "Player":
		if body.has_method("take_damage"):
			var is_alive = body.take_damage(body.global_position)
			if is_alive and body.has_method("respawn_at_last_safe_position"):
				body.respawn_at_last_safe_position()
