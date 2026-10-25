extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var shadow_charger: CharacterBody2D = $ShadowCharger
@onready var cutscene_dialog: CanvasLayer = $CutsceneDialog
@onready var special_trigger: Area2D = $SpecialEnemyTrigger

var has_triggered_encounter: bool = false
var pending_encounter: bool = false
var normal_zoom: Vector2 = Vector2(4, 4)
var cinematic_zoom: Vector2 = Vector2(4.8, 4.8)

func _ready() -> void:
	if special_trigger:
		special_trigger.body_entered.connect(_on_special_trigger_entered)
	if cutscene_dialog:
		cutscene_dialog.continue_pressed.connect(_on_continue_pressed)
	if shadow_charger:
		shadow_charger.emerged.connect(_on_enemy_emerged)

func _physics_process(_delta: float) -> void:
	if pending_encounter and not has_triggered_encounter:
		if player and player.is_on_floor():
			_start_encounter()

func _on_special_trigger_entered(body: Node2D) -> void:
	if has_triggered_encounter or pending_encounter or not (body is CharacterBody2D and body.name == "Player"):
		return
	
	if body.is_on_floor():
		_start_encounter()
	else:
		# Player passed through trigger while in air; defer encounter until safe touchdown
		pending_encounter = true

func _start_encounter() -> void:
	has_triggered_encounter = true
	pending_encounter = false
	if special_trigger:
		special_trigger.set_deferred("monitoring", false)
	
	# Pause player physics and freeze movement
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	var anim = player.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("idle")
	
	# Spawn special enemy out of the ground to the left of the player
	if shadow_charger:
		shadow_charger.spawn_from_ground(player)

func _on_enemy_emerged() -> void:
	# Calculate midpoint framing between player and shadow charger
	var midpoint = (player.global_position + shadow_charger.global_position) / 2.0
	var cam_target_local = camera.to_local(midpoint)
	
	# Smoothly tween camera to focus on both characters and zoom in
	var cam_tween = create_tween()
	cam_tween.set_parallel(true)
	cam_tween.tween_property(camera, "position", cam_target_local, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cam_tween.tween_property(camera, "zoom", cinematic_zoom, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	cam_tween.chain().tween_callback(func():
		# Display typewriter animated dialogue
		if cutscene_dialog:
			cutscene_dialog.show_encounter_dialog()
	)

func _on_continue_pressed() -> void:
	# Restore normal camera position and zoom
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(camera, "position", Vector2(0, -8), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(camera, "zoom", normal_zoom, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	return_tween.chain().tween_callback(func():
		# Unpause player
		player.set_physics_process(true)
		# Trigger 3-blink telegraph and charge sequence
		if shadow_charger:
			shadow_charger.start_charge_sequence()
	)

