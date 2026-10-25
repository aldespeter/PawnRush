extends Area2D

signal sword_claimed

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_collected: bool = false

func _ready() -> void:
	# Floating bobbing animation
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -3.0, 0.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 3.0, 0.75).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is CharacterBody2D:
		is_collected = true
		if not collision_shape:
			collision_shape = get_node_or_null("CollisionShape2D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		# Enable sword on player and GameManager
		if "has_sword" in body:
			body.has_sword = true
			
		var gm = null
		if body.is_inside_tree():
			gm = body.get_node_or_null("/root/GameManager")
		if not gm and body.get_parent() and body.get_parent().get_parent():
			gm = body.get_parent().get_parent().get_node_or_null("GameManager")
		if not gm and is_inside_tree():
			gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.has_sword = true
			
		sword_claimed.emit()
		
		if is_inside_tree():
			if not pickup_sound:
				pickup_sound = get_node_or_null("PickupSound")
			if pickup_sound:
				pickup_sound.pitch_scale = 1.2
				pickup_sound.play()
				
			if not particles:
				particles = get_node_or_null("CPUParticles2D")
			if particles:
				particles.amount = 26
				particles.initial_velocity_min = 40.0
				particles.initial_velocity_max = 85.0
				particles.emitting = true
				
			if not sprite:
				sprite = get_node_or_null("Sprite2D")
			if sprite:
				var fade_tween = create_tween()
				if fade_tween:
					fade_tween.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.25)
					fade_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
			
			var scene_tree = get_tree()
			if scene_tree:
				var hud = scene_tree.get_first_node_in_group("hud")
				if not hud and scene_tree.current_scene:
					hud = scene_tree.current_scene.get_node_or_null("HUD")
				if hud and hud.has_method("show_message"):
					hud.show_message("SECRET SWORD CLAIMED! DASH TO SLICE ENEMIES!")
				scene_tree.create_timer(0.6).timeout.connect(queue_free)
		else:
			queue_free()
