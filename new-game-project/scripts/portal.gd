extends Area2D

@export var is_level_exit: bool = true
@export var target_portal: Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var modal_scene = preload("res://scenes/level_complete.tscn")
var is_active: bool = true

func _ready() -> void:
	# Magical portal pulse animation
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.7).set_trans(Tween.TRANS_SINE)

	var color_tween = create_tween().set_loops()
	color_tween.tween_property(sprite, "modulate", Color(0.2, 0.9, 1.0, 0.9), 0.9)
	color_tween.tween_property(sprite, "modulate", Color(0.8, 0.3, 1.0, 0.9), 0.9)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	if body.name == "Player" or body is CharacterBody2D:
		if is_level_exit:
			is_active = false
			var level_num = 1
			if get_tree().current_scene:
				var scene_path = get_tree().current_scene.scene_file_path
				if "level_2" in scene_path:
					level_num = 2
				elif "level_3" in scene_path:
					level_num = 3
				elif "level_4" in scene_path:
					level_num = 4

			var modal = modal_scene.instantiate()
			get_tree().root.add_child(modal)
			modal.setup(level_num)
		elif target_portal:
			is_active = false
			body.global_position = target_portal.global_position
			var timer = get_tree().create_timer(1.0)
			timer.timeout.connect(func(): is_active = true)
