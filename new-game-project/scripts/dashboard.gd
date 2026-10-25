extends Control

@onready var total_stars_label: Label = $VBoxContainer/TotalStarsLabel
@onready var play_button: Button = $VBoxContainer/Buttons/PlayButton
@onready var options_button: Button = $VBoxContainer/Buttons/OptionsButton
@onready var quit_button: Button = $VBoxContainer/Buttons/QuitButton

@onready var lvl_1_btn: Button = $VBoxContainer/LevelGrid/Level1Button
@onready var lvl_2_btn: Button = $VBoxContainer/LevelGrid/Level2Button
@onready var lvl_3_btn: Button = $VBoxContainer/LevelGrid/Level3Button
@onready var lvl_4_btn: Button = $VBoxContainer/LevelGrid/Level4Button

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	lvl_1_btn.pressed.connect(func(): GameManager.start_level(1))
	lvl_2_btn.pressed.connect(func(): GameManager.start_level(2))
	lvl_3_btn.pressed.connect(func(): GameManager.start_level(3))
	lvl_4_btn.pressed.connect(func(): GameManager.start_level(4))

	_update_stars_display()

func _update_stars_display() -> void:
	if not GameManager:
		return
	total_stars_label.text = "★ TOTAL STARS: " + str(GameManager.get_total_stars()) + " / 12"

	lvl_1_btn.text = "LEVEL 1\n" + _format_stars(1)
	lvl_2_btn.text = "LEVEL 2\n" + _format_stars(2)
	lvl_3_btn.text = "LEVEL 3\n" + _format_stars(3)
	lvl_4_btn.text = "LEVEL 4\n" + _format_stars(4)

func _format_stars(lvl: int) -> String:
	var count = GameManager.level_stars.get(lvl, 0)
	var str_val = ""
	for i in range(3):
		if i < count:
			str_val += "★ "
		else:
			str_val += "☆ "
	return str_val.strip_edges()

func _on_play_pressed() -> void:
	GameManager.start_level(1)

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
