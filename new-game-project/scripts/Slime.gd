extends Node2D

const SPEED = 60

var direction = 1
var is_dead: bool = false

@onready var ray_cast_r: RayCast2D = $RayCastR
@onready var ray_cast_l: RayCast2D = $RayCastL
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var killzone: Area2D = $killzone

func _ready() -> void:
	add_to_group("enemies")

func _process(delta: float) -> void:
	if is_dead:
		return
	if ray_cast_r and ray_cast_r.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_l and ray_cast_l.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta

func slice_kill(slasher: Node2D = null) -> void:
	if is_dead:
		return
	is_dead = true
	
	# Disable killzone collision immediately so it cannot hurt the player
	if killzone:
		killzone.monitoring = false
		killzone.monitorable = false
		var col = killzone.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col:
			col.set_deferred("disabled", true)
	
	# Hide sprite
	if animated_sprite:
		animated_sprite.visible = false
	
	# Determine slime theme color (purple or green)
	var is_purple = "purple" in name.to_lower() or (animated_sprite and animated_sprite.sprite_frames and "purple" in str(animated_sprite.sprite_frames.resource_path).to_lower())
	var splatter_color = Color(0.85, 0.3, 0.95, 1.0) if is_purple else Color(0.35, 0.95, 0.4, 1.0)
	
	# Burst splatter particles
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 22
	particles.lifetime = 0.45
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 350)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = splatter_color
	particles.global_position = global_position + Vector2(0, -6)
	get_parent().add_child(particles)
	particles.emitting = true
	
	# Blade arc / spark burst
	var sparks = CPUParticles2D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 14
	sparks.lifetime = 0.25
	sparks.explosiveness = 1.0
	sparks.spread = 45.0
	sparks.direction = Vector2(1, -0.5) if (slasher and slasher.global_position.x < global_position.x) else Vector2(-1, -0.5)
	sparks.initial_velocity_min = 90.0
	sparks.initial_velocity_max = 150.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 2.5
	sparks.color = Color(0.4, 0.95, 1.0, 1.0)
	sparks.global_position = global_position + Vector2(0, -6)
	get_parent().add_child(sparks)
	sparks.emitting = true
	
	# Play slash sound
	var sound = AudioStreamPlayer2D.new()
	sound.stream = load("res://assets/sounds/explosion.wav")
	sound.volume_db = -4.0
	sound.pitch_scale = randf_range(1.65, 1.9)
	get_parent().add_child(sound)
	sound.global_position = global_position
	sound.play()
	sound.finished.connect(sound.queue_free)
	
	# Floating "+100 SLICED!" label
	var score_label = Label.new()
	score_label.text = "+100 SLICED!"
	score_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	score_label.add_theme_font_size_override("font_size", 8)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	score_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	score_label.add_theme_constant_override("outline_size", 2)
	score_label.global_position = global_position + Vector2(-40, -22)
	score_label.z_index = 10
	get_parent().add_child(score_label)
	
	var label_tween = score_label.create_tween()
	label_tween.tween_property(score_label, "global_position:y", score_label.global_position.y - 18, 0.6)
	label_tween.parallel().tween_property(score_label, "modulate:a", 0.0, 0.6)
	label_tween.tween_callback(score_label.queue_free)
	
	# Screen shake via slasher / player
	if slasher and slasher.has_method("trigger_screen_shake"):
		slasher.trigger_screen_shake(9.0, 0.22)
	
	# Hit-stop impact pause
	Engine.time_scale = 0.06
	get_tree().create_timer(0.05, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	
	get_tree().create_timer(0.55).timeout.connect(func():
		particles.queue_free()
		sparks.queue_free()
		queue_free()
	)
