extends CanvasLayer

@onready var title_label: Label = $ColorRect/Panel/VBoxContainer/TitleLabel
@onready var stars_label: Label = $ColorRect/Panel/VBoxContainer/StarsLabel
@onready var coins_label: Label = $ColorRect/Panel/VBoxContainer/CoinsLabel
@onready var next_btn: Button = $ColorRect/Panel/VBoxContainer/HBoxContainer/NextButton
@onready var replay_btn: Button = $ColorRect/Panel/VBoxContainer/HBoxContainer/ReplayButton
@onready var dashboard_btn: Button = $ColorRect/Panel/VBoxContainer/DashboardButton

var level_index: int = 1

func setup(level_num: int) -> void:
	level_index = level_num
	var stars = GameManager.complete_level(level_index)
	
	var star_str = ""
	for i in range(3):
		if i < stars:
			star_str += "★ "
		else:
			star_str += "☆ "
	stars_label.text = star_str.strip_edges()
	coins_label.text = "COINS COLLECTED: " + str(GameManager.level_coins) + " / 3"

	if level_index >= 4:
		next_btn.text = "VICTORY"

func _ready() -> void:
	next_btn.pressed.connect(_on_next_pressed)
	replay_btn.pressed.connect(_on_replay_pressed)
	dashboard_btn.pressed.connect(_on_dashboard_pressed)

func _on_next_pressed() -> void:
	queue_free()
	if level_index >= 4:
		get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
	else:
		GameManager.next_level()

func _on_replay_pressed() -> void:
	queue_free()
	GameManager.level_coins = 0
	get_tree().reload_current_scene()

func _on_dashboard_pressed() -> void:
	queue_free()
	GameManager.level_coins = 0
	get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
