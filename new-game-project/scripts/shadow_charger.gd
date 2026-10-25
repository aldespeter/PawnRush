extends CharacterBody2D

signal emerged

enum State { HIDDEN, EMERGING, PAUSED_CUTSCENE, TELEGRAPH, DASHING, COOLDOWN, PATROL }

@export var dash_speed: float = 360.0
@export var patrol_speed: float = 40.0
@export var charge_distance: float = 240.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var killzone_shape: CollisionShape2D = $killzone/CollisionShape2D
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var alert_sound: AudioStreamPlayer2D = $AlertSound
@onready var dash_sound: AudioStreamPlayer2D = $DashSound

var current_state: State = State.HIDDEN
var surface_y: float = 0.0
var dash_direction: float = -1.0
var distance_dashed: float = 0.0
var cooldown_timer: float = 0.0
var player_ref: Node2D = null

func _ready() -> void:
	surface_y = position.y
	# Start buried slightly in the ground
	position.y = surface_y + 18.0
	visible = false
	killzone_shape.disabled = true
	dash_trail.emitting = false
	dust_particles.emitting = false

func spawn_from_ground(player: Node2D) -> void:
	player_ref = player
	current_state = State.EMERGING
	
	# Position to the LEFT of the player
	if player_ref:
		global_position.x = player_ref.global_position.x - 70.0
		surface_y = player_ref.global_position.y
		global_position.y = surface_y + 18.0
	else:
		surface_y = position.y
		position.y = surface_y + 18.0
		
	visible = true
	dust_particles.emitting = true
	
	if alert_sound:
		alert_sound.pitch_scale = 0.7
		alert_sound.play()
	
	# Tween up out of the stone terrace
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", surface_y, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		current_state = State.PAUSED_CUTSCENE
		emerged.emit()
	)

func start_charge_sequence() -> void:
	# Called when player clicks CONTINUE
	current_state = State.TELEGRAPH
	
	# Determine dash direction towards player
	if player_ref:
		dash_direction = -1.0 if player_ref.global_position.x < global_position.x else 1.0
	animated_sprite.flip_h = (dash_direction > 0.0)
	
	# Blink 3 times before charging
	var blink_tween = create_tween()
	# Blink 1
	blink_tween.tween_property(animated_sprite, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.12)
	blink_tween.tween_callback(func(): if alert_sound: alert_sound.pitch_scale = 1.2; alert_sound.play())
	blink_tween.tween_property(animated_sprite, "modulate", Color(0.85, 0.15, 0.25, 1.0), 0.12)
	# Blink 2
	blink_tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.12)
	blink_tween.tween_callback(func(): if alert_sound: alert_sound.pitch_scale = 1.4; alert_sound.play())
	blink_tween.tween_property(animated_sprite, "modulate", Color(0.85, 0.15, 0.25, 1.0), 0.12)
	# Blink 3
	blink_tween.tween_property(animated_sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.14)
	blink_tween.tween_callback(func(): if alert_sound: alert_sound.pitch_scale = 1.7; alert_sound.play())
	blink_tween.tween_property(animated_sprite, "modulate", Color(0.85, 0.15, 0.25, 1.0), 0.10)
	
	# Unleash Dash
	blink_tween.tween_callback(_launch_dash)

func _launch_dash() -> void:
	current_state = State.DASHING
	distance_dashed = 0.0
	killzone_shape.disabled = false
	dash_trail.emitting = true
	
	if dash_sound:
		dash_sound.pitch_scale = 1.1
		dash_sound.play()

func _physics_process(delta: float) -> void:
	match current_state:
		State.DASHING:
			velocity.x = dash_direction * dash_speed
			velocity.y = 0.0
			move_and_slide()
			
			distance_dashed += abs(velocity.x) * delta
			if distance_dashed >= charge_distance or is_on_wall():
				_enter_cooldown()
				
		State.COOLDOWN:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if not is_on_floor():
				velocity.y += 980.0 * delta
			move_and_slide()
			cooldown_timer -= delta
			if cooldown_timer <= 0.0:
				current_state = State.PATROL
				
		State.PATROL:
			velocity.x = dash_direction * patrol_speed
			if not is_on_floor():
				velocity.y += 980.0 * delta
			if is_on_wall():
				dash_direction *= -1.0
				animated_sprite.flip_h = (dash_direction > 0.0)
			move_and_slide()
			
		_:
			velocity = Vector2.ZERO

func _enter_cooldown() -> void:
	current_state = State.COOLDOWN
	cooldown_timer = 1.4
	dash_trail.emitting = false
	killzone_shape.disabled = false
	velocity = Vector2.ZERO
