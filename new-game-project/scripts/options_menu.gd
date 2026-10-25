extends Control

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/AudioGrid/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/AudioGrid/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/AudioGrid/SFXSlider
@onready var mute_checkbox: CheckBox = $MarginContainer/VBoxContainer/MuteCheckBox

@onready var btn_left: Button = $MarginContainer/VBoxContainer/ControlsGrid/BtnLeft
@onready var btn_right: Button = $MarginContainer/VBoxContainer/ControlsGrid/BtnRight
@onready var btn_jump: Button = $MarginContainer/VBoxContainer/ControlsGrid/BtnJump
@onready var btn_blink: Button = $MarginContainer/VBoxContainer/ControlsGrid/BtnBlink

@onready var reset_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var back_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer/BackButton

var rebinding_action: String = ""

func _ready() -> void:
	# Initialize Audio UI
	if GameManager:
		master_slider.value = GameManager.master_volume
		music_slider.value = GameManager.music_volume
		sfx_slider.value = GameManager.sfx_volume
		mute_checkbox.button_pressed = GameManager.is_muted

	master_slider.value_changed.connect(func(val): GameManager.set_master_volume(val))
	music_slider.value_changed.connect(func(val): GameManager.set_music_volume(val))
	sfx_slider.value_changed.connect(func(val): GameManager.set_sfx_volume(val))
	mute_checkbox.toggled.connect(func(val): GameManager.set_mute(val))

	# Initialize Controls UI
	btn_left.pressed.connect(func(): _start_rebinding("move_left", btn_left))
	btn_right.pressed.connect(func(): _start_rebinding("move_right", btn_right))
	btn_jump.pressed.connect(func(): _start_rebinding("jump", btn_jump))
	btn_blink.pressed.connect(func(): _start_rebinding("teleport", btn_blink))

	reset_btn.pressed.connect(_on_reset_pressed)
	back_btn.pressed.connect(_on_back_pressed)

	_update_rebind_buttons()

func _update_rebind_buttons() -> void:
	btn_left.text = "LEFT: " + _get_action_key_name("move_left", "A")
	btn_right.text = "RIGHT: " + _get_action_key_name("move_right", "D")
	btn_jump.text = "JUMP: " + _get_action_key_name("jump", "SPACE")
	btn_blink.text = "BLINK: " + _get_action_key_name("teleport", "SHIFT")

func _get_action_key_name(action: String, default_name: String) -> String:
	if InputMap.has_action(action):
		var events = InputMap.action_get_events(action)
		for ev in events:
			if ev is InputEventKey:
				return OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
	return default_name

func _start_rebinding(action: String, btn: Button) -> void:
	rebinding_action = action
	btn.text = "PRESS ANY KEY..."

func _unhandled_input(event: InputEvent) -> void:
	if rebinding_action != "" and event is InputEventKey and event.pressed:
		var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if GameManager:
			GameManager.rebind_action(rebinding_action, keycode)
		rebinding_action = ""
		_update_rebind_buttons()
		get_viewport().set_input_as_handled()

func _on_reset_pressed() -> void:
	if GameManager:
		GameManager.rebind_action("move_left", KEY_A)
		GameManager.rebind_action("move_right", KEY_D)
		GameManager.rebind_action("jump", KEY_SPACE)
		GameManager.rebind_action("teleport", KEY_SHIFT)
		GameManager.set_master_volume(1.0)
		GameManager.set_music_volume(0.8)
		GameManager.set_sfx_volume(1.0)
		GameManager.set_mute(false)
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 1.0
		mute_checkbox.button_pressed = false
	_update_rebind_buttons()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
