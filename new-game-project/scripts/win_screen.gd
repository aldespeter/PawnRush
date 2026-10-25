extends Control

@onready var stars_label: Label = $VBoxContainer/StarsLabel
@onready var coins_label: Label = $VBoxContainer/CoinsLabel
@onready var play_again_btn: Button = $VBoxContainer/PlayAgainButton
@onready var dashboard_btn: Button = $VBoxContainer/DashboardButton
@onready var exit_btn: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	if GameManager:
		stars_label.text = "TOTAL STARS: " + str(GameManager.get_total_stars()) + " / 12 ★"
		coins_label.text = "TOTAL COINS: " + str(GameManager.coins)
	play_again_btn.pressed.connect(_on_play_again_pressed)
	dashboard_btn.pressed.connect(_on_dashboard_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func _on_play_again_pressed() -> void:
	if GameManager:
		GameManager.start_level(1)

func _on_dashboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
