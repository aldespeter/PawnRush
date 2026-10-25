extends CanvasLayer

signal continue_pressed

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/VBox/TitleLabel
@onready var message_label: Label = $CenterContainer/PanelContainer/VBox/MessageLabel
@onready var continue_btn: Button = $CenterContainer/PanelContainer/VBox/ContinueButton
@onready var click_sound: AudioStreamPlayer = $ClickSound

var full_message: String = "A Shadow Charger has emerged and is preparing to dash towards you!\n\nHold [CTRL] and press [D] or [S] to DASH away from the enemy!"
var type_tween: Tween

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)

func show_encounter_dialog() -> void:
	visible = true
	message_label.text = full_message
	message_label.visible_ratio = 0.0
	continue_btn.disabled = true
	continue_btn.modulate.a = 0.4
	
	if type_tween:
		type_tween.kill()
	type_tween = create_tween()
	# Animated writing typewriter effect over 1.4s
	type_tween.tween_property(message_label, "visible_ratio", 1.0, 1.4).set_trans(Tween.TRANS_LINEAR)
	type_tween.tween_callback(func():
		continue_btn.disabled = false
		continue_btn.modulate.a = 1.0
		continue_btn.grab_focus()
	)

func _on_continue_pressed() -> void:
	if click_sound:
		click_sound.play()
	visible = false
	continue_pressed.emit()
