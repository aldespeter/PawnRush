extends CharacterBody2D

signal teleported

const SPEED = 135.0
const JUMP_VELOCITY = -290.0
const MAX_JUMPS = 2
const TELEPORT_DISTANCE = 75.0
const TELEPORT_COOLDOWN = 1.5

@export var can_double_jump: bool = true
@export var has_sword: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var teleport_ray: RayCast2D = $TeleportRay
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var teleport_sound: AudioStreamPlayer2D = $TeleportSound

var ghost_scene = preload("res://scenes/teleport_ghost.tscn")

var facing_direction: float = 1.0
var jump_count: int = 0
var last_safe_position: Vector2 = Vector2.ZERO
var can_teleport: bool = true
var has_air_teleport: bool = true
var teleport_timer: float = 0.0
var is_teleporting_anim: bool = false

var is_invulnerable: bool = false
var invuln_timer: float = 0.0

# Dash ability variables (Hold CTRL + press D or S)
const DASH_SPEED: float = 380.0
const DASH_DURATION: float = 0.20
const DASH_COOLDOWN: float = 0.60
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var dash_direction: float = 1.0
var dash_ghost_timer: float = 0.0

# Ground Slam ability variables (when airborne, press S or DOWN or C)
const SLAM_SPEED: float = 650.0
var is_ground_slamming: bool = false
var camera_shake_intensity: float = 0.0
var camera_shake_timer: float = 0.0
var _slam_ghost_timer: float = 0.0

# Slide ability variables (when on floor, press S or DOWN or C)
const SLIDE_SPEED: float = 280.0
const SLIDE_DURATION: float = 0.45
const SLIDE_FRICTION: float = 380.0
const SLIDE_SLOPE_BOOST: float = 450.0
var is_sliding: bool = false
var slide_timer: float = 0.0
var slide_direction: float = 1.0
var slide_dust_timer: float = 0.0

func _ready() -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	last_safe_position = global_position
	floor_max_angle = deg_to_rad(52.0)
	floor_snap_length = 12.0

func _unhandled_input(event: InputEvent) -> void:
	var is_ctrl_held = Input.is_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_CTRL)
	if not is_ctrl_held:
		var is_down_event = (
			(InputMap.has_action("ground_slam") and event.is_action_pressed("ground_slam"))
			or event.is_action_pressed("ui_down")
			or (event is InputEventKey and event.pressed and not event.echo and (
				event.physical_keycode in [KEY_S, KEY_DOWN, KEY_C] or event.keycode in [KEY_S, KEY_DOWN, KEY_C]
			))
		)
		if is_down_event:
			if not is_on_floor() and not is_dashing and not is_ground_slamming and not is_sliding:
				perform_ground_slam()
				return
			elif is_on_floor() and not is_dashing and not is_sliding:
				perform_slide()
				return

func _physics_process(delta: float) -> void:
	# Process camera vibration / screen shake
	if camera_shake_timer > 0.0:
		camera_shake_timer -= delta
		var cam = get_node_or_null("Camera2D") as Camera2D
		if not cam:
			cam = get_viewport().get_camera_2d()
		if cam:
			if camera_shake_timer <= 0.0:
				cam.offset = Vector2.ZERO
			else:
				var damp = clampf(camera_shake_timer / 0.35, 0.25, 1.0)
				cam.offset = Vector2(
					randf_range(-camera_shake_intensity * damp, camera_shake_intensity * damp),
					randf_range(-camera_shake_intensity * damp, camera_shake_intensity * damp)
				)

	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	# Process active dash
	if is_dashing:
		dash_timer -= delta
		dash_ghost_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
		if dash_ghost_timer <= 0.0:
			dash_ghost_timer = 0.05
			_spawn_ghost()
		if has_sword:
			_check_dash_slash_enemies()
		if dash_timer <= 0.0:
			is_dashing = false
			animated_sprite.modulate = Color(1, 1, 1, 1)
			velocity.x = dash_direction * SPEED
		move_and_slide()
		update_animation(dash_direction)
		return

	# Process active slide
	if is_sliding:
		slide_timer -= delta
		slide_dust_timer -= delta
		if slide_dust_timer <= 0.0:
			slide_dust_timer = 0.07
			_spawn_slide_dust()

		# Slope boost or friction
		var floor_normal = get_floor_normal()
		if floor_normal.x * slide_direction < -0.15:
			# Downhill slope acceleration!
			velocity.x += -floor_normal.x * SLIDE_SLOPE_BOOST * delta
			velocity.x = clampf(velocity.x, -450.0, 450.0)
		elif floor_normal.x * slide_direction > 0.15:
			# Uphill slope deceleration
			velocity.x = move_toward(velocity.x, 0.0, (SLIDE_FRICTION * 1.8) * delta)
		else:
			# Flat floor deceleration
			velocity.x = move_toward(velocity.x, 0.0, SLIDE_FRICTION * delta)

		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()

		# Jump cancel
		var wants_jump_slide = (
			(InputMap.has_action("jump") and Input.is_action_just_pressed("jump"))
			or Input.is_action_just_pressed("ui_accept")
		)
		if wants_jump_slide and is_on_floor():
			var ceiling_ray = get_node_or_null("CeilingRay") as RayCast2D
			if not ceiling_ray or not ceiling_ray.is_colliding():
				_stop_slide()
				velocity.y = JUMP_VELOCITY
				jump_count = 1
				if jump_sound:
					jump_sound.pitch_scale = 1.0
					jump_sound.play()
				return

		# End slide timer check or low ceiling continuation
		if slide_timer <= 0.0 or abs(velocity.x) < 15.0:
			var ceiling_ray = get_node_or_null("CeilingRay") as RayCast2D
			if ceiling_ray and ceiling_ray.is_colliding():
				# Keep sliding/crouching forward through low tunnel!
				velocity.x = slide_direction * 75.0
			else:
				_stop_slide()
		return

	# Process active ground slam
	if is_ground_slamming:
		velocity.x = 0.0
		velocity.y = SLAM_SPEED
		is_invulnerable = true
		invuln_timer = max(invuln_timer, 0.3)
		animated_sprite.modulate = Color(1.8, 1.4, 0.8, 1.0)
		_slam_ghost_timer -= delta
		if _slam_ghost_timer <= 0.0:
			_slam_ghost_timer = 0.04
			_spawn_ghost()
		move_and_slide()
		if is_on_floor():
			_on_ground_slam_landed()
		update_animation(0.0)
		return

	# Add the gravity (do not reset jump count while travelling upward)
	if not is_on_floor() or velocity.y < 0.0:
		velocity += get_gravity() * delta
	else:
		has_air_teleport = true
		jump_count = 0
		if velocity.y >= 0.0:
			last_safe_position = global_position

	# Handle teleport cooldown timer
	if teleport_timer > 0.0:
		teleport_timer -= delta
		if teleport_timer <= 0.0:
			can_teleport = true

	# Handle invulnerability i-frames
	if invuln_timer > 0.0:
		invuln_timer -= delta
		# Flicker alpha between 0.35 and 1.0
		animated_sprite.modulate.a = 0.35 if fmod(invuln_timer * 14.0, 2.0) > 1.0 else 1.0
		if invuln_timer <= 0.0:
			is_invulnerable = false
			animated_sprite.modulate = Color(1, 1, 1, 1)

	# Handle jump (including double jump)
	var wants_jump = (
		(InputMap.has_action("jump") and Input.is_action_just_pressed("jump"))
		or Input.is_action_just_pressed("ui_accept")
	)
	if wants_jump:
		if is_on_floor() and velocity.y >= 0.0:
			velocity.y = JUMP_VELOCITY
			jump_count = 1
			if jump_sound:
				jump_sound.pitch_scale = 1.0
				jump_sound.play()
		elif can_double_jump and jump_count < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			jump_count += 1
			if jump_sound:
				jump_sound.pitch_scale = 1.25
				jump_sound.play()

	# Get input direction
	var direction := 0.0
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		direction += 1.0

	# Movement & deceleration
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Update facing direction directly from movement
	if direction > 0.0 or velocity.x > 3.0:
		facing_direction = 1.0
		animated_sprite.flip_h = false
	elif direction < 0.0 or velocity.x < -3.0:
		facing_direction = -1.0
		animated_sprite.flip_h = true

	# Handle Teleportation
	var wants_teleport = (
		Input.is_action_just_pressed("teleport")
		or (InputMap.has_action("blink") and Input.is_action_just_pressed("blink"))
	)

	if wants_teleport and can_teleport and (is_on_floor() or has_air_teleport):
		perform_teleport()

	# Handle Dash (Hold CTRL and press D or S / A)
	var is_ctrl_held = Input.is_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_CTRL)
	if is_ctrl_held and dash_cooldown <= 0.0:
		if Input.is_key_pressed(KEY_D) or Input.is_action_just_pressed("move_right"):
			perform_dash(1.0)
			return
		elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_action_just_pressed("move_left"):
			perform_dash(-1.0)
	# Handle Ground Slam or Slide (Airborne: slam / Ground: slide)
	var wants_down = not is_ctrl_held and (
		(InputMap.has_action("ground_slam") and (Input.is_action_just_pressed("ground_slam") or Input.is_action_pressed("ground_slam")))
		or Input.is_action_just_pressed("ui_down")
		or Input.is_physical_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_S)
		or Input.is_physical_key_pressed(KEY_DOWN)
		or Input.is_key_pressed(KEY_DOWN)
		or Input.is_physical_key_pressed(KEY_C)
		or Input.is_key_pressed(KEY_C)
	)
	if not is_dashing and not is_ground_slamming and not is_sliding and wants_down:
		if not is_on_floor():
			perform_ground_slam()
			return
		else:
			perform_slide()
			return

	move_and_slide()
	update_animation(direction)

func perform_ground_slam() -> void:
	if is_ground_slamming or is_on_floor():
		return
	is_ground_slamming = true
	_slam_ghost_timer = 0.0
	velocity.x = 0.0
	velocity.y = SLAM_SPEED
	is_invulnerable = true
	invuln_timer = 0.6
	animated_sprite.modulate = Color(1.8, 1.4, 0.8, 1.0)
	_spawn_ghost()
	if jump_sound:
		jump_sound.pitch_scale = 0.65
		jump_sound.play()

func _on_ground_slam_landed() -> void:
	is_ground_slamming = false
	velocity = Vector2.ZERO
	animated_sprite.modulate = Color(1, 1, 1, 1)
	
	# Trigger strong camera vibration / screen shake
	trigger_screen_shake(14.0, 0.35)
	
	# Play heavy impact sound
	if teleport_sound:
		teleport_sound.pitch_scale = 0.50
		teleport_sound.play()
	
	_spawn_ghost()
	_spawn_slam_shockwave()
	
	# Detect and break any breakable blocks under player feet
	# 1. Slide collisions
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider and collider.has_method("break_block"):
			collider.break_block()
			
	# 2. Direct downward raycasts across player base width (-12 to +12)
	var space_state = get_world_2d().direct_space_state
	if space_state:
		for offset_x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
			var ray_params = PhysicsRayQueryParameters2D.create(
				global_position + Vector2(offset_x, 0),
				global_position + Vector2(offset_x, 22)
			)
			ray_params.collide_with_areas = true
			ray_params.collide_with_bodies = true
			var hit = space_state.intersect_ray(ray_params)
			if hit and hit.collider and hit.collider.has_method("break_block"):
				hit.collider.break_block()

func _spawn_slam_shockwave() -> void:
	var dust = CPUParticles2D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 18
	dust.lifetime = 0.35
	dust.explosiveness = 1.0
	dust.direction = Vector2(0, -1)
	dust.spread = 80.0
	dust.gravity = Vector2(0, 300)
	dust.initial_velocity_min = 60.0
	dust.initial_velocity_max = 120.0
	dust.scale_amount_min = 2.0
	dust.scale_amount_max = 3.5
	dust.color = Color(0.95, 0.9, 0.75, 0.9)
	dust.global_position = global_position + Vector2(0, 2)
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(dust)
		dust.emitting = true
		get_tree().create_timer(0.5).timeout.connect(dust.queue_free)

func trigger_screen_shake(intensity: float = 14.0, duration: float = 0.35) -> void:
	camera_shake_intensity = intensity
	camera_shake_timer = duration

func perform_dash(dir: float) -> void:
	if is_dashing or dash_cooldown > 0.0:
		return
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	dash_direction = dir
	facing_direction = dir
	animated_sprite.flip_h = (dir < 0.0)
	dash_ghost_timer = 0.0
	_spawn_ghost()
	is_invulnerable = true
	invuln_timer = max(invuln_timer, DASH_DURATION + 0.15)
	if has_sword:
		animated_sprite.modulate = Color(1.2, 1.8, 2.5, 1.0)
	if jump_sound:
		jump_sound.pitch_scale = 1.6
		jump_sound.play()

func perform_slide(dir: float = 0.0) -> void:
	if is_sliding or is_dashing:
		return
	if not is_on_floor():
		var space = get_world_2d().direct_space_state if get_world_2d() else null
		if space:
			var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 14))
			query.collision_mask = 1
			var hit = space.intersect_ray(query)
			if not hit:
				return
	is_sliding = true
	slide_timer = SLIDE_DURATION
	slide_dust_timer = 0.0
	
	if dir != 0.0:
		slide_direction = dir
	elif abs(velocity.x) > 10.0:
		slide_direction = signf(velocity.x)
	else:
		slide_direction = facing_direction
		
	velocity.x = slide_direction * SLIDE_SPEED
	
	# Lower collision shape to allow passing under 8px low clearance tunnels
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.position = Vector2(0, -3.5)
		if col.shape is CircleShape2D:
			col.shape.radius = 3.5
			
	# Aerodynamic forward slide posture
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.rotation_degrees = 55.0 * slide_direction
		animated_sprite.position = Vector2(0, -6)
	
	_spawn_slide_dust()
	
	if jump_sound:
		jump_sound.pitch_scale = 1.65
		jump_sound.play()

func _stop_slide() -> void:
	if not is_sliding:
		return
	is_sliding = false
	slide_timer = 0.0
	
	# Restore standard standing collision shape
	var col = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.position = Vector2(0, -6)
		if col.shape is CircleShape2D:
			col.shape.radius = 5.5
			
	# Restore sprite orientation
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.rotation_degrees = 0.0
		animated_sprite.position = Vector2(0, -12)

func _spawn_slide_dust() -> void:
	var dust = CPUParticles2D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 4
	dust.lifetime = 0.22
	dust.direction = Vector2(-slide_direction, -0.4)
	dust.spread = 30.0
	dust.gravity = Vector2(0, 120)
	dust.initial_velocity_min = 25.0
	dust.initial_velocity_max = 55.0
	dust.scale_amount_min = 1.5
	dust.scale_amount_max = 2.5
	dust.color = Color(0.9, 0.85, 0.75, 0.8)
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(dust)
		dust.global_position = global_position + Vector2(-slide_direction * 4, 1)
		dust.emitting = true
		if get_tree():
			get_tree().create_timer(0.3).timeout.connect(dust.queue_free)
		else:
			dust.queue_free()

func _check_dash_slash_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.get("is_dead"):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 30.0:
				if enemy.has_method("slice_kill"):
					enemy.slice_kill(self)

func perform_teleport() -> void:
	can_teleport = false
	teleport_timer = TELEPORT_COOLDOWN
	if not is_on_floor():
		has_air_teleport = false

	# Spawn Ghost at old position
	_spawn_ghost()

	# Check wall collision using RayCast
	teleport_ray.target_position = Vector2(facing_direction * TELEPORT_DISTANCE, 0)
	teleport_ray.force_raycast_update()

	var target_x: float
	if teleport_ray.is_colliding():
		var col_point = teleport_ray.get_collision_point()
		var dist = abs(col_point.x - global_position.x) - 10.0
		target_x = global_position.x + (facing_direction * max(0.0, dist))
	else:
		target_x = global_position.x + (facing_direction * TELEPORT_DISTANCE)

	global_position.x = target_x
	velocity.y = min(velocity.y, 0.0) # Reset falling speed for snappy feel

	if teleport_sound:
		teleport_sound.play()

	is_teleporting_anim = true
	animated_sprite.play("teleport")
	teleported.emit()

	# Reset anim lock quickly
	var tween = create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(func(): is_teleporting_anim = false)

func _spawn_ghost() -> void:
	if ghost_scene:
		var ghost = ghost_scene.instantiate()
		ghost.global_position = global_position + animated_sprite.position
		get_parent().add_child(ghost)
		ghost.flip_h = animated_sprite.flip_h

func take_damage(source_pos: Vector2 = Vector2.ZERO) -> bool:
	if is_invulnerable:
		return true

	is_invulnerable = true
	invuln_timer = 1.2

	# Knockback
	var knockback_dir = 1.0 if global_position.x >= source_pos.x else -1.0
	velocity = Vector2(knockback_dir * 130.0, -180.0)

	if GameManager:
		return GameManager.take_damage()
	return true

func update_animation(direction: float) -> void:
	if is_teleporting_anim or is_sliding:
		return

	if not is_on_floor():
		animated_sprite.play("jump")
	elif direction != 0.0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func is_blink_available() -> bool:
	return can_teleport and (is_on_floor() or has_air_teleport)

func get_teleport_cooldown_left() -> float:
	return max(0.0, teleport_timer)

func respawn_at_last_safe_position() -> void:
	global_position = last_safe_position + Vector2(0, -6)
	velocity = Vector2.ZERO
	jump_count = 0
