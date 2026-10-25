extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Subtle energy shimmer on the barrier
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position)
