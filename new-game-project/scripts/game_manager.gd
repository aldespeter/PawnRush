extends Node

signal coin_collected(total_coins: int)
signal lives_changed(current_lives: int)
signal level_changed(level_name: String)
signal stars_updated

const MAX_LIVES = 3
var lives: int = 3
var coins: int = 0
var level_coins: int = 0
var current_level_index: int = 0
var has_sword: bool = false

# Track best stars per level (1 to 4)
var level_stars: Dictionary = {
	1: 0,
	2: 0,
	3: 0,
	4: 0
}

var levels: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/win_screen.tscn"
]

var music_player: AudioStreamPlayer
var coin_sfx_player: AudioStreamPlayer
var hurt_sfx_player: AudioStreamPlayer
var life_sfx_player: AudioStreamPlayer

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var is_muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio()

func _setup_audio() -> void:
	music_player = AudioStreamPlayer.new()
	var music_stream = load("res://assets/music/time_for_adventure.mp3")
	if music_stream:
		music_player.stream = music_stream
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		add_child(music_player)
		music_player.play()

	coin_sfx_player = AudioStreamPlayer.new()
	var coin_stream = load("res://assets/sounds/coin.wav")
	if coin_stream:
		coin_sfx_player.stream = coin_stream
		coin_sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(coin_sfx_player)

	hurt_sfx_player = AudioStreamPlayer.new()
	var hurt_stream = load("res://assets/sounds/hurt.wav")
	if hurt_stream:
		hurt_sfx_player.stream = hurt_stream
		hurt_sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(hurt_sfx_player)

	life_sfx_player = AudioStreamPlayer.new()
	var life_stream = load("res://assets/sounds/power_up.wav")
	if life_stream:
		life_sfx_player.stream = life_stream
		life_sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
		life_sfx_player.pitch_scale = 1.5
		add_child(life_sfx_player)

func _update_audio_volumes() -> void:
	if is_muted:
		if music_player: music_player.volume_db = -80.0
		if coin_sfx_player: coin_sfx_player.volume_db = -80.0
		if hurt_sfx_player: hurt_sfx_player.volume_db = -80.0
		if life_sfx_player: life_sfx_player.volume_db = -80.0
	else:
		if music_player:
			music_player.volume_db = linear_to_db(max(0.001, music_volume * master_volume))
		var sfx_db = linear_to_db(max(0.001, sfx_volume * master_volume))
		if coin_sfx_player: coin_sfx_player.volume_db = sfx_db
		if hurt_sfx_player: hurt_sfx_player.volume_db = sfx_db
		if life_sfx_player: life_sfx_player.volume_db = sfx_db

func set_master_volume(val: float) -> void:
	master_volume = clamp(val, 0.0, 1.0)
	_update_audio_volumes()

func set_music_volume(val: float) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	_update_audio_volumes()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	_update_audio_volumes()

func set_mute(val: bool) -> void:
	is_muted = val
	_update_audio_volumes()

func rebind_action(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Clear previous key events for this action
	var events = InputMap.action_get_events(action_name)
	for ev in events:
		if ev is InputEventKey:
			InputMap.action_erase_event(action_name, ev)

	var new_key = InputEventKey.new()
	new_key.physical_keycode = keycode
	InputMap.action_add_event(action_name, new_key)

func start_level(level_idx: int) -> void:
	current_level_index = clamp(level_idx - 1, 0, levels.size() - 1)
	level_coins = 0
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(levels[current_level_index])

func add_coin() -> void:
	coins += 1
	level_coins += 1
	if coin_sfx_player and not is_muted:
		coin_sfx_player.play()
	coin_collected.emit(coins)

func complete_level(level_idx: int) -> int:
	var stars = 1
	if level_coins >= 3:
		stars = 3
	elif level_coins >= 2:
		stars = 2

	var current_best = level_stars.get(level_idx, 0)
	if stars > current_best:
		level_stars[level_idx] = stars
	
	stars_updated.emit()
	return stars

func get_total_stars() -> int:
	var total = 0
	for lvl in level_stars:
		total += level_stars[lvl]
	return total

func take_damage() -> bool:
	lives -= 1
	if hurt_sfx_player and not is_muted:
		hurt_sfx_player.play()
	lives_changed.emit(lives)

	if lives <= 0:
		lives = MAX_LIVES
		level_coins = 0
		lives_changed.emit(lives)
		Engine.time_scale = 0.5
		var timer = get_tree().create_timer(0.6)
		timer.timeout.connect(func():
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
		)
		return false
	return true

func add_life() -> void:
	if lives < MAX_LIVES:
		lives += 1
		if life_sfx_player and not is_muted:
			life_sfx_player.play()
		lives_changed.emit(lives)

func reset_lives() -> void:
	lives = MAX_LIVES
	lives_changed.emit(lives)

func next_level() -> void:
	level_coins = 0
	current_level_index += 1
	if current_level_index < levels.size():
		get_tree().change_scene_to_file(levels[current_level_index])
	else:
		current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/dashboard.tscn")

func restart_game() -> void:
	coins = 0
	level_coins = 0
	lives = MAX_LIVES
	current_level_index = 0
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dashboard.tscn")

func replay_current_level() -> void:
	level_coins = 0
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_dashboard() -> void:
	level_coins = 0
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/dashboard.tscn")
