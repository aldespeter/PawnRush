extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Gentle hovering animation
	var start_y = sprite.position.y
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", start_y - 4.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", start_y + 2.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body is CharacterBody2D:
		if GameManager:
			GameManager.add_life()
		queue_free()
