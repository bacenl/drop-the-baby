extends Node

## Global singleton for managing game state and events.
## Access via Global from anywhere in the project.

# Game state signals
signal game_started
signal game_ended(score: int)
signal game_paused
signal game_resumed
signal return_to_main_menu

# Score signals
signal score_changed(new_score: int)
signal high_score_changed(new_high_score: int)

# Reputation signals
signal reputation_changed(new_reputation: int)

# Baby signals
signal baby_collected(baby: Baby)
signal baby_dropped(baby: Baby)
signal baby_success
signal baby_lost

# Baby queue
signal update_next_duck(int)

# Game state
enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.MAIN_MENU

# Control variables (read-only, updated by state functions)
var game_is_started: bool = false
var game_is_paused: bool = false
var game_is_over: bool = false
var in_main_menu: bool = true

# Game globals
var CENTER: Vector2 = Vector2(0, 0)

# Score tracking
var score: int = 0
var high_score: int = 0

var MAX_REPUTATION: int = 3
var reputation: int


func _ready() -> void:
	_load_high_score()
	bind_callbacks()

func bind_callbacks() -> void:
	game_started.connect(_on_game_started)
	game_ended.connect(_on_game_ended)
	game_paused.connect(_on_game_paused)
	game_resumed.connect(_on_game_resumed)
	return_to_main_menu.connect(_on_return_to_main_menu)
	baby_success.connect(_on_baby_success)
	baby_lost.connect(_on_baby_lost)


func start_game() -> void:
	game_started.emit()


func end_game(final_score: int = -1) -> void:
	game_ended.emit(final_score)


func pause_game() -> void:
	if current_state == GameState.PLAYING:
		game_paused.emit()


func resume_game() -> void:
	if current_state == GameState.PAUSED:
		game_resumed.emit()


func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()


func go_to_main_menu() -> void:
	return_to_main_menu.emit()


# Signal callbacks
func _on_game_started() -> void:
	score = 0
	reputation = MAX_REPUTATION
	current_state = GameState.PLAYING
	_update_control_vars()
	score_changed.emit(score)


func _on_game_ended(final_score: int) -> void:
	if final_score >= 0:
		score = final_score

	current_state = GameState.GAME_OVER
	_update_control_vars()

	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)
		_save_high_score()


func _on_game_paused() -> void:
	current_state = GameState.PAUSED
	_update_control_vars()
	get_tree().paused = true


func _on_game_resumed() -> void:
	current_state = GameState.PLAYING
	_update_control_vars()
	get_tree().paused = false


func _on_return_to_main_menu() -> void:
	get_tree().paused = false
	current_state = GameState.MAIN_MENU
	_update_control_vars()
	score = 0


func _update_control_vars() -> void:
	game_is_started = current_state == GameState.PLAYING or current_state == GameState.PAUSED
	game_is_paused = current_state == GameState.PAUSED
	game_is_over = current_state == GameState.GAME_OVER
	in_main_menu = current_state == GameState.MAIN_MENU


func set_score(new_score: int) -> void:
	score = new_score
	score_changed.emit(score)


func _on_baby_success() -> void:
	score += 1
	score_changed.emit(score)


func _on_baby_lost() -> void:
	if not is_playing():
		return
	reputation -= 1
	reputation_changed.emit(reputation)
	if reputation <= 0:
		end_game(score)


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_paused() -> bool:
	return current_state == GameState.PAUSED


func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


func is_in_menu() -> bool:
	return current_state == GameState.MAIN_MENU


# High score persistence
func _load_high_score() -> void:
	if FileAccess.file_exists("user://high_score.save"):
		var file := FileAccess.open("user://high_score.save", FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()


func _save_high_score() -> void:
	var file := FileAccess.open("user://high_score.save", FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
