extends Sprite2D

func set_properties(p_texture: Texture2D, p_region: Rect2, p_flip_h: bool) -> void:
	texture = p_texture
	region_enabled = true
	region_rect = p_region
	flip_h = p_flip_h
	modulate = Color(0.2, 0.8, 1.0, 0.75) # Glowing cyan/blue ghost

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
