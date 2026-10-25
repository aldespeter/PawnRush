extends StaticBody2D

signal block_shattered

@export var reward_type: String = "none" # "coin", "life", "none"
@export var reward_scene: PackedScene = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var crack_overlay: Sprite2D = $CrackOverlay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var debris_particles: CPUParticles2D = $DebrisParticles
@onready var break_sound: AudioStreamPlayer2D = $BreakSound

var is_broken: bool = false

func _ready() -> void:
	if debris_particles:
		debris_particles.emitting = false

func _on_slam_detector_body_entered(body: Node2D) -> void:
	if is_broken:
		return
	if body is CharacterBody2D:
		if body.get("is_ground_slamming") == true or body.velocity.y > 300.0:
			break_block()

func break_block() -> void:
	if is_broken:
		return
	is_broken = true
	
	# Disable collision immediately so player can pass through
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Hide block visuals
	if sprite:
		sprite.visible = false
	if crack_overlay:
		crack_overlay.visible = false
	
	# Burst rock debris particles
	if debris_particles:
		debris_particles.emitting = true
	
	# Play crumble audio
	if break_sound:
		break_sound.pitch_scale = randf_range(1.3, 1.6)
		break_sound.play()
	
	# Spawn hidden reward
	_spawn_reward()
	
	block_shattered.emit()
	
	# Clean up node after particles finish
	get_tree().create_timer(0.6).timeout.connect(queue_free)

func _spawn_reward() -> void:
	if reward_scene:
		var reward = reward_scene.instantiate()
		reward.global_position = global_position
		get_parent().call_deferred("add_child", reward)
	elif reward_type == "coin":
		var coin_res = load("res://scenes/coin.tscn")
		if coin_res:
			var coin = coin_res.instantiate()
			coin.global_position = global_position
			get_parent().call_deferred("add_child", coin)
	elif reward_type == "life":
		var life_res = load("res://scenes/life_pickup.tscn")
		if life_res:
			var life = life_res.instantiate()
			life.global_position = global_position
			get_parent().call_deferred("add_child", life)
