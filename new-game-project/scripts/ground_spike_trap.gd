extends AnimatableBody2D

enum State { IDLE, WARNING, ACTIVE, RETRACTING }
var current_state: State = State.IDLE

@onready var spike_root: Node2D = $SpikeRoot
@onready var trigger_area: Area2D = $TriggerArea
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/DamageShape
@onready var sfx: AudioStreamPlayer2D = $TrapSFX

var tap_sound = preload("res://assets/sounds/tap.wav")

func _ready() -> void:
	damage_shape.disabled = true
	spike_root.position.y = 10 # Retracted inside block

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if current_state == State.IDLE:
			_trigger_trap()

func _trigger_trap() -> void:
	current_state = State.WARNING
	
	# Play mechanical warning click
	if sfx and tap_sound:
		sfx.stream = tap_sound
		sfx.pitch_scale = 1.9
		sfx.play()

	# Warning vibration / rumble
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 1.5, 0.06)
	tween.tween_property(self, "position:y", position.y + 1.5, 0.06)
	tween.tween_property(self, "position:y", position.y, 0.08)
	tween.tween_interval(0.06)
	tween.tween_callback(_thrust_spikes)

func _thrust_spikes() -> void:
	current_state = State.ACTIVE
	
	# Snap spikes UP quickly (deadly thrust)
	if sfx and tap_sound:
		sfx.pitch_scale = 0.8
		sfx.play()

	var thrust_tween = create_tween()
	thrust_tween.tween_property(spike_root, "position:y", -11.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	thrust_tween.tween_callback(func():
		damage_shape.disabled = false
		_check_damage_overlapping()
	)

	# Keep active for 0.75s, then retract
	thrust_tween.tween_interval(0.75)
	thrust_tween.tween_callback(_retract_spikes)

func _retract_spikes() -> void:
	current_state = State.RETRACTING
	damage_shape.disabled = true

	var retract_tween = create_tween()
	retract_tween.tween_property(spike_root, "position:y", 10.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Cooldown delay before resetting to IDLE
	retract_tween.tween_interval(0.8)
	retract_tween.tween_callback(func():
		current_state = State.IDLE
		# If player is still standing on the trap, trigger again!
		for b in trigger_area.get_overlapping_bodies():
			if b.is_in_group("player") or b.name == "Player":
				_trigger_trap()
				break
	)

func _check_damage_overlapping() -> void:
	if current_state != State.ACTIVE:
		return
	for b in damage_area.get_overlapping_bodies():
		if b.has_method("take_damage"):
			b.take_damage(global_position)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if current_state == State.ACTIVE:
		if body.has_method("take_damage"):
			body.take_damage(global_position)
