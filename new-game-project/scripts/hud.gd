extends CanvasLayer

@onready var lives_label: Label = $MarginContainer/VBoxContainer/LivesLabel
@onready var coin_label: Label = $MarginContainer/VBoxContainer/CoinLabel
@onready var blink_label: Label = $MarginContainer/VBoxContainer/BlinkLabel
@onready var level_label: Label = $MarginContainer/TopRightBox/LevelLabel
@onready var pause_btn: Button = $MarginContainer/TopRightBox/PauseButton

@onready var pause_menu: ColorRect = $PauseMenu
@onready var resume_btn: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var replay_btn: Button = $PauseMenu/Panel/VBoxContainer/ReplayButton
@onready var dashboard_btn: Button = $PauseMenu/Panel/VBoxContainer/DashboardButton

var player: CharacterBody2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if GameManager:
		GameManager.coin_collected.connect(_on_coin_collected)
		GameManager.lives_changed.connect(_on_lives_changed)
		_on_coin_collected(GameManager.coins)
		_on_lives_changed(GameManager.lives)

	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_parent().get_node_or_null("Player")

	_setup_level_title()

	# Pause menu button connections
	if pause_btn:
		pause_btn.pressed.connect(toggle_pause)
	if resume_btn:
		resume_btn.pressed.connect(resume_game)
	if replay_btn:
		replay_btn.pressed.connect(replay_level)
	if dashboard_btn:
		dashboard_btn.pressed.connect(go_to_dashboard)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Escape key pressed
		toggle_pause()

func toggle_pause() -> void:
	if pause_menu.visible:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	get_tree().paused = true
	pause_menu.visible = true

func resume_game() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func replay_level() -> void:
	resume_game()
	GameManager.replay_current_level()

func go_to_dashboard() -> void:
	resume_game()
	GameManager.return_to_dashboard()

func _setup_level_title() -> void:
	if not get_tree().current_scene:
		return
	var scene_path = get_tree().current_scene.scene_file_path
	if "level_1" in scene_path:
		set_level_title("PHASE 1: EMERALD MEADOWS", Color(0.4, 1.0, 0.5))
	elif "level_2" in scene_path:
		set_level_title("PHASE 2: AUTUMN CANYON", Color(1.0, 0.82, 0.3))
	elif "level_3" in scene_path:
		set_level_title("PHASE 3: FROZEN CRYPT", Color(0.4, 0.85, 1.0))
	elif "level_4" in scene_path:
		set_level_title("PHASE 4: VOID CITADEL", Color(1.0, 0.35, 0.45))

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_parent().get_node_or_null("Player")

	if player:
		if player.has_method("get_teleport_cooldown_left"):
			var cd_left = player.get_teleport_cooldown_left()
			if cd_left <= 0.0 and player.is_blink_available():
				blink_label.text = "[SHIFT/J] BLINK: READY"
				blink_label.modulate = Color(0.2, 1.0, 1.0) # Bright Cyan
			else:
				blink_label.text = "[BLINK]: " + ("%.1f" % max(0.1, cd_left)) + "s"
				blink_label.modulate = Color(1.0, 0.7, 0.2) # Amber/Orange

func _on_coin_collected(total_coins: int) -> void:
	if coin_label:
		coin_label.text = "COINS: " + str(total_coins)

func _on_lives_changed(current_lives: int) -> void:
	if lives_label:
		var hearts = ""
		for i in range(GameManager.MAX_LIVES):
			if i < current_lives:
				hearts += "♥ "
			else:
				hearts += "♡ "
		lives_label.text = "LIVES: " + hearts.strip_edges()

func set_level_title(title: String, title_color: Color = Color(1.0, 0.85, 0.2)) -> void:
	if level_label:
		level_label.text = title
		level_label.modulate = title_color

func show_message(msg: String, duration: float = 3.0) -> void:
	var banner = Label.new()
	banner.text = msg
	banner.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	banner.add_theme_font_size_override("font_size", 10)
	banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	banner.add_theme_constant_override("outline_size", 3)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.anchor_top = 0.22
	banner.anchor_bottom = 0.22
	banner.offset_left = -300
	banner.offset_right = 300
	banner.offset_top = -20
	banner.offset_bottom = 20
	add_child(banner)
	
	banner.modulate.a = 0.0
	var tween = banner.create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	tween.tween_callback(banner.queue_free)
